
import models.com.tech.unbounded.hops.v1alpha1 as hopsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_full_assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Federated\": \"arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890\"\n      },\n      \"Action\": \"sts:AssumeRoleWithWebIdentity\",\n      \"Condition\": {\n        \"StringEquals\": {\n          \"oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890:sub\": \"system:serviceaccount:loki:loki\"\n        }\n      }\n    }\n  ]\n}\n"

_full_policy_document = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"LokiStorage\",\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"s3:ListBucket\",\n        \"s3:PutObject\",\n        \"s3:GetObject\",\n        \"s3:DeleteObject\"\n      ],\n      \"Resource\": [\n        \"arn:aws:s3:::example-loki-chunks\",\n        \"arn:aws:s3:::example-loki-chunks/*\",\n        \"arn:aws:s3:::example-loki-ruler\",\n        \"arn:aws:s3:::example-loki-ruler/*\"\n      ]\n    }\n  ]\n}\n"

_minimal_assume_role_policy = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Federated\": \"arn:aws:iam::210987654321:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MINIMAL1234567890\"\n      },\n      \"Action\": \"sts:AssumeRoleWithWebIdentity\",\n      \"Condition\": {\n        \"StringEquals\": {\n          \"oidc.eks.us-east-1.amazonaws.com/id/MINIMAL1234567890:sub\": \"system:serviceaccount:metrics:metrics\"\n        }\n      }\n    }\n  ]\n}\n"

_minimal_policy_document = _full_policy_document

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-irsa-render-full"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "irsa-cluster-x-loki"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "shared-aws"
                        }
                        forProvider: {
                            assumeRolePolicy: _full_assume_role_policy
                            permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-boundary"
                            tags: {
                                hops: "true"
                                team: "platform"
                                service: "logging"
                            }
                        }
                    }
                },
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Policy"
                    metadata: {
                        name: "irsa-cluster-x-loki"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "shared-aws"
                        }
                        forProvider: {
                            policy: _full_policy_document
                            tags: {
                                hops: "true"
                                team: "platform"
                                service: "logging"
                            }
                        }
                    }
                },
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "RolePolicyAttachment"
                    metadata: {
                        name: "irsa-cluster-x-loki"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "shared-aws"
                        }
                        forProvider: {
                            policyArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "hops.ops.com.ai/irsa": "loki"
                                }
                            }
                            roleSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "hops.ops.com.ai/irsa": "loki"
                                }
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-role-irsa-cluster-x-loki-by-rpa-irsa-cluster-x-loki"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "RolePolicyAttachment"
                            resourceRef: {
                                name: "irsa-cluster-x-loki"
                            }
                        }
                        of: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "Role"
                            resourceRef: {
                                name: "irsa-cluster-x-loki"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-policy-irsa-cluster-x-loki-by-rpa-irsa-cluster-x-loki"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "RolePolicyAttachment"
                            resourceRef: {
                                name: "irsa-cluster-x-loki"
                            }
                        }
                        of: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "Policy"
                            resourceRef: {
                                name: "irsa-cluster-x-loki"
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/irsas/composition.yaml"
            xrPath: "examples/irsas/example.yaml"
            xrdPath: "apis/irsas/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-irsa-render-minimal"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "minimal-cluster-metrics"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "minimal-cluster"
                        }
                        forProvider: {
                            assumeRolePolicy: _minimal_assume_role_policy
                            tags: {
                                hops: "true"
                            }
                        }
                    }
                },
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Policy"
                    metadata: {
                        name: "minimal-cluster-metrics"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "minimal-cluster"
                        }
                        forProvider: {
                            policy: _minimal_policy_document
                            tags: {
                                hops: "true"
                            }
                        }
                    }
                },
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "RolePolicyAttachment"
                    metadata: {
                        name: "minimal-cluster-metrics"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "minimal-cluster"
                        }
                        forProvider: {
                            policyArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "hops.ops.com.ai/irsa": "metrics"
                                }
                            }
                            roleSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "hops.ops.com.ai/irsa": "metrics"
                                }
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-role-minimal-cluster-metrics-by-rpa-minimal-cluster-metrics"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "RolePolicyAttachment"
                            resourceRef: {
                                name: "minimal-cluster-metrics"
                            }
                        }
                        of: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "Role"
                            resourceRef: {
                                name: "minimal-cluster-metrics"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-policy-minimal-cluster-metrics-by-rpa-minimal-cluster-metrics"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "RolePolicyAttachment"
                            resourceRef: {
                                name: "minimal-cluster-metrics"
                            }
                        }
                        of: {
                            apiVersion: "iam.aws.m.upbound.io/v1beta1"
                            kind: "Policy"
                            resourceRef: {
                                name: "minimal-cluster-metrics"
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/irsas/composition.yaml"
            xrPath: "examples/irsas/example-minimal.yaml"
            xrdPath: "apis/irsas/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    }
]
items= _items
