import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# Policy document used across tests
_policy_document = """{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::example-bucket/*"]
    }
  ]
}"""

_items = [
    # Test 1: Default naming - clusterName + metadata.name
    metav1alpha1.CompositionTest {
        metadata.name = "default-naming"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "my-service"
                spec = {
                    clusterName = "prod-cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/ABC123"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "my-sa"
                        namespace = "my-ns"
                    }
                }
            }
            # Role and Policy should use clusterName-name pattern
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "prod-cluster-my-service"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata.name = "prod-cluster-my-service"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "RolePolicyAttachment"
                    metadata.name = "prod-cluster-my-service"
                }
            ]
        }
    }

    # Test 2: Role and policy name prefixes
    metav1alpha1.CompositionTest {
        metadata.name = "name-prefixes"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "loki"
                spec = {
                    clusterName = "cluster-x"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-west-2.amazonaws.com/id/XYZ789"
                    role.namePrefix = "irsa-"
                    policy.namePrefix = "pol-"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "loki"
                        namespace = "logging"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "irsa-cluster-x-loki"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata.name = "pol-cluster-x-loki"
                }
            ]
        }
    }

    # Test 3: Name overrides take precedence
    metav1alpha1.CompositionTest {
        metadata.name = "name-overrides"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "test"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/TEST"
                    role = {
                        namePrefix = "ignored-"
                        nameOverride = "exact-role-name"
                    }
                    policy = {
                        namePrefix = "ignored-"
                        nameOverride = "exact-policy-name"
                        document = _policy_document
                    }
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "exact-role-name"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata.name = "exact-policy-name"
                }
            ]
        }
    }

    # Test 4: Default labels applied
    metav1alpha1.CompositionTest {
        metadata.name = "default-labels"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "labeled-service"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/LABEL"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "cluster-labeled-service"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/irsa" = "labeled-service"
                        }
                    }
                }
            ]
        }
    }

    # Test 5: User labels merged with defaults
    metav1alpha1.CompositionTest {
        metadata.name = "user-labels-merged"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "custom"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/CUSTOM"
                    labels = {
                        team = "platform"
                        env = "prod"
                    }
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "cluster-custom"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/irsa" = "custom"
                            team = "platform"
                            env = "prod"
                        }
                    }
                }
            ]
        }
    }

    # Test 6: Provider config defaults to clusterName
    metav1alpha1.CompositionTest {
        metadata.name = "provider-config-default"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/PROV"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "my-cluster-test"
                    spec.providerConfigRef = {
                        name = "my-cluster"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }

    # Test 7: Explicit provider config ref
    metav1alpha1.CompositionTest {
        metadata.name = "explicit-provider-config"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "test"
                spec = {
                    clusterName = "cluster"
                    providerConfigRef.name = "shared-aws"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/PROV"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "cluster-test"
                    spec.providerConfigRef = {
                        name = "shared-aws"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }

    # Test 8: Permissions boundary applied
    metav1alpha1.CompositionTest {
        metadata.name = "permissions-boundary"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "bounded"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/BOUND"
                    permissionsBoundary = "arn:aws:iam::123456789012:policy/boundary"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "cluster-bounded"
                    spec.forProvider.permissionsBoundary = "arn:aws:iam::123456789012:policy/boundary"
                }
            ]
        }
    }

    # Test 9: Default AWS tags
    metav1alpha1.CompositionTest {
        metadata.name = "default-tags"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "tagged"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/TAG"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "cluster-tagged"
                    spec.forProvider.tags = {
                        hops = "true"
                    }
                }
            ]
        }
    }

    # Test 10: User tags merged with defaults
    metav1alpha1.CompositionTest {
        metadata.name = "user-tags-merged"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "tagged"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/USERTAG"
                    tags = {
                        team = "platform"
                        service = "logging"
                    }
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "cluster-tagged"
                    spec.forProvider.tags = {
                        hops = "true"
                        team = "platform"
                        service = "logging"
                    }
                }
            ]
        }
    }

    # Test 11: Usage resources render when all resources ready
    metav1alpha1.CompositionTest {
        metadata.name = "usage-renders-when-ready"
        spec = {
            compositionPath = "apis/irsas/composition.yaml"
            xrdPath = "apis/irsas/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.IRSA {
                metadata.name = "usage-test"
                spec = {
                    clusterName = "cluster"
                    accountId = "123456789012"
                    oidc = "oidc.eks.us-east-1.amazonaws.com/id/USAGE"
                    policy.document = _policy_document
                    serviceAccount = {
                        name = "sa"
                        namespace = "ns"
                    }
                }
            }
            observedResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "cluster-usage-test"
                        annotations = {"crossplane.io/composition-resource-name" = "role"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}, {type = "Synced", status = "True"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/cluster-usage-test"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata = {
                        name = "cluster-usage-test"
                        annotations = {"crossplane.io/composition-resource-name" = "policy"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}, {type = "Synced", status = "True"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:policy/cluster-usage-test"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "RolePolicyAttachment"
                    metadata = {
                        name = "cluster-usage-test"
                        annotations = {"crossplane.io/composition-resource-name" = "attachment"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}, {type = "Synced", status = "True"}]
                        atProvider = {id = "cluster-usage-test/arn:aws:iam::123456789012:policy/cluster-usage-test"}
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "usage-test-role-protects-attachment"
                }
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "usage-test-policy-protects-attachment"
                }
            ]
        }
    }
]

items = _items
