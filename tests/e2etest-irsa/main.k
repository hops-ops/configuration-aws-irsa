import base64
import datetime
import file
import math
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_now = str(int(math.floor(datetime.ticks())))

_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

_test_policy_document = """{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::example-bucket/*"]
    }
  ]
}"""

# Unique cluster name so multiple runs don't conflict in AWS
_test_cluster = "e2e-irsa-" + _now
_namespace = "default"
_region = "us-east-2"

# AWS account ID for E2E tests - update this for your environment
_account_id = "034489662075"

_items = [
    metav1alpha1.E2ETest {
        metadata.name = "irsa-e2e"
        spec = {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "None"
            }
            defaultConditions = ["Ready"]
            timeoutSeconds = 4500
            cleanupTimeoutSeconds = 600
            skipDelete = False

            extraResources = [
                # AWS credentials secret
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = _namespace
                    }
                    data.creds = _base64_creds
                }
                # AWS ProviderConfig
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = _test_cluster
                        namespace = _namespace
                    }
                    spec.credentials = {
                        source = "Secret"
                        secretRef = {
                            namespace = _namespace
                            name = "aws-creds"
                            key = "creds"
                        }
                    }
                }
            ]

            manifests = [
                awsv1alpha1.IRSA {
                    metadata = {
                        name = "e2etest-irsa"
                        namespace = _namespace
                    }
                    spec = {
                        clusterName = _test_cluster
                        accountId = _account_id
                        # Use a fake OIDC provider - the role will be created but won't be assumable
                        # This is fine for E2E testing the resource creation
                        oidc = "oidc.eks." + _region + ".amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
                        policy.document = _test_policy_document
                        serviceAccount = {
                            name = "irsa-sa"
                            namespace = _namespace
                        }
                        tags = {
                            "e2etest" = "true"
                            "test-run" = _now
                        }
                    }
                }
            ]
        }
    }
]

items = _items
