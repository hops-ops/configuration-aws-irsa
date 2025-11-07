
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
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "irsa-cluster-x-loki"
                    }
                    spec: {
                        deletionPolicy: "Orphan"
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
                    apiVersion: "iam.aws.upbound.io/v1beta1"
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
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "RolePolicyAttachment"
                    metadata: {
                        name: "cluster-x-loki-role-policy-attachment"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "shared-aws"
                        }
                        forProvider: {
                            policyArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    irsa: "loki"
                                }
                            }
                            roleSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    irsa: "loki"
                                }
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/xirsas/composition.yaml"
            xrPath: "examples/xirsas/example.yaml"
            xrdPath: "apis/xirsas/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-irsa-render-minimal"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.upbound.io/v1beta1"
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
                    apiVersion: "iam.aws.upbound.io/v1beta1"
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
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "RolePolicyAttachment"
                    metadata: {
                        name: "minimal-cluster-metrics-role-policy-attachment"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "minimal-cluster"
                        }
                        forProvider: {
                            policyArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    irsa: "metrics"
                                }
                            }
                            roleSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    irsa: "metrics"
                                }
                            }
                        }
                    }
                }
            ]
            compositionPath: "apis/xirsas/composition.yaml"
            xrPath: "examples/xirsas/example-minimal.yaml"
            xrdPath: "apis/xirsas/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    }
]
items= _items
