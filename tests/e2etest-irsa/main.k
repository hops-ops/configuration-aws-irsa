import file
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_aws_secret_key = file.read_env("AWS_SECRET_KEY")
_aws_access_key = file.read_env("AWS_ACCESS_KEY")

_test_policy_document = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\"s3:GetObject\"],\n      \"Resource\": [\"arn:aws:s3:::example-bucket/*\"]\n    }\n  ]\n}"

_credential_data = "aws_access_key_id=${_aws_access_key}\naws_secret_access_key=${_aws_secret_key}"

_items = [
    metav1alpha1.E2ETest{
        metadata.name: ""
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                awsv1alpha1.IRSA{
                    metadata: {
                        name: "irsa"
                        namespace: "default"
                    }
                    spec: {
                        clusterName: "default"
                        accountId: "123456789012"
                        name: "e2e-test-irsa"
                        oidc: "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
                        policy: _test_policy_document
                        serviceAccount: {
                            name: "irsa-sa"
                            namespace: "default"
                        }
                    }
                }
            ]
            extraResources: [
                {
                    apiVersion: "v1"
                    kind: "Secret"
                    metadata: {
                        name: "aws-creds"
                        namespace: "default"
                    }
                    stringData: {
                        "creds": _credential_data
                    }
                },
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"
                    }
                    spec: {
                        credentials: {
                            source: "Secret"
                            secretRef: {
                                namespace: "default"
                                name: "aws-creds"
                                key: "creds"
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items= _items
