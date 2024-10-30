
import models.v1beta1 as v1beta1
import models.v1beta2 as v1beta2
import models.v1beta3 as v1beta3
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

oxr = option("params").oxr # observed composite resource
_ocds = option("params").ocds # observed composed resources
_dxr = option("params").dxr # desired composite resource
dcds = option("params").dcds # desired composed resources

_metadata = lambda name: str -> any {
    {
        name = oxr.spec.id
        annotations = { "krm.kcl.dev/composition-resource-name" = name }
    }
}

_region = "us-east-1"
if oxr.spec?.parameters?.region:
    _region = oxr.spec.parameters.region

_items = [
    v1beta1.InternetGateway {
        metadata = _metadata("gateway")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1InternetGatewaySpecForProvider{
            region = _region
            vpcIdSelector.matchControllerRef = True
        }
    },
    v1beta1.MainRouteTableAssociation {
        metadata = _metadata("mainRouteTableAssociation")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1MainRouteTableAssociationSpecForProvider{
            region = _region
            routeTableIdSelector.matchControllerRef = True
            vpcIdSelector.matchControllerRef = True
        }
    },
    v1beta1.RouteTable {
        metadata = _metadata("routeTable")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1RouteTableSpecForProvider{
            region = _region
            vpcIdSelector.matchControllerRef = True
        }
    },
    v1beta1.Route {
        metadata = _metadata("route")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1RouteSpecForProvider{
            region = _region
            routeTableIdSelector.matchControllerRef = True
            destinationCidrBlock = "0.0.0.0/0"
            gatewayIdSelector.matchControllerRef = True
        }
    },
    v1beta1.SecurityGroupRule {
        metadata = _metadata("securityGroupRule")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1SecurityGroupRuleSpecForProvider{
            region = _region
            description = "I am too lazy to write descriptions"
            type = "ingress"
            fromPort = 5432
            toPort = 5432
            protocol = "tcp"
            cidrBlocks = ["0.0.0.0/0"]
            securityGroupIdSelector.matchControllerRef = True
        }
    },
    v1beta1.SecurityGroup {
        metadata = _metadata("securityGroup")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1SecurityGroupSpecForProvider{
            region = _region
            description = "I am too lazy to write descriptions"
            vpcIdSelector.matchControllerRef = True
        }
    },
    v1beta1.VPC {
        metadata = _metadata("vpc")
        spec.forProvider = v1beta1.Ec2AwsUpboundIoV1beta1VPCSpecForProvider{
            region = _region
            cidrBlock = "11.0.0.0/16"
            enableDnsSupport = True
            enableDnsHostnames = True
        }
    },
    v1beta1.SubnetGroup {
        metadata = _metadata("subnetgroup")
        spec.forProvider = v1beta1.RdsAwsUpboundIoV1beta1SubnetGroupSpecForProvider{
            region = _region
            description = "I'm too lazy to write a good description"
            subnetIdSelector.matchControllerRef = True
        }
    },
    v1beta2.Instance {
        metadata = _metadata("rdsinstance")
        spec.forProvider = v1beta2.RdsAwsUpboundIoV1beta2InstanceSpecForProvider{
            region = _region
            dbSubnetGroupNameSelector.matchControllerRef = True
            vpcSecurityGroupIdSelector.matchControllerRef = True
            username = "masteruser"
            engine = "postgres"
            skipFinalSnapshot = True
            publiclyAccessible = True
            allocatedStorage = 200
            passwordSecretRef = v1beta2.RdsAwsUpboundIoV1beta2InstanceSpecForProviderPasswordSecretRef {
                name = oxr.spec.id + "-password"
                namespace = oxr.spec.claimRef.namespace
                key = "password"
            }
            identifier = oxr.spec.id
            if oxr.spec.parameters.size == "small":
                instanceClass = "db.m5.large"
            elif oxr.spec.parameters.size == "medium":
                instanceClass = "db.m5.2xlarge"
            else:
                instanceClass = "db.m5.8xlarge"
            engineVersion = oxr.spec.parameters.version
        }
    }
]

items = _items
# _items = [{
#     apiVersion = "kubernetes.crossplane.io/v1alpha2"
#     kind = "Object"
#     metadata = {
#         name = oxr.spec.id + "-secret"
#         annotations = {
#             "krm.kcl.dev/ready": "True"
#             "krm.kcl.dev/composition-resource-name" = "sql-secret"
#         }
#     }
#     spec = {
#         references = [{
#             patchesFrom = {
#                 apiVersion = "rds.aws.upbound.io/v1beta1"
#                 kind = "Instance"
#                 name = oxr.spec.id
#                 namespace = "crossplane-system"
#                 fieldPath = "spec.forProvider.username"
#             }
#             toFieldPath = "stringData.username"
#         }, {
#             patchesFrom = {
#                 apiVersion = "v1"
#                 kind = "Secret"
#                 name = oxr.spec.id + "-password"
#                 namespace = oxr.spec.claimRef.namespace
#                 fieldPath = "data.password"
#             }
#             toFieldPath = "data.password"
#         }, {
#             patchesFrom = {
#                 apiVersion = "rds.aws.upbound.io/v1beta1"
#                 kind = "Instance"
#                 name = oxr.spec.id
#                 namespace = "crossplane-system"
#                 fieldPath = "status.atProvider.address"
#             }
#             toFieldPath = "stringData.endpoint"
#         }]
#         forProvider.manifest = {
#             apiVersion = "v1"
#             kind = "Secret"
#             metadata = {
#                 name = oxr.spec.id
#                 namespace = oxr.spec.claimRef.namespace
#             }
#             data.port = "NTQzMg=="
#         }
#         providerConfigRef.name = oxr.spec.id + "-sql"
#     }
# }, {
#     **oxr
#     if "rdsinstance" in ocds:
#         status.address = ocds["rdsinstance"].Resource.status.atProvider.address
# }]

# _zoneList = [
#     { zone = "a", cidrBlock = "11.0.0.0/24" },
#     { zone = "b", cidrBlock = "11.0.1.0/24"  },
#     { zone = "c", cidrBlock = "11.0.2.0/24"  }
# ]

# _items += [{
#     apiVersion = "ec2.aws.upbound.io/v1beta1"
#     kind = "RouteTableAssociation"
#     metadata = {
#         name = oxr.spec.id + "-1" + _data.zone
#         annotations = {
#             "krm.kcl.dev/composition-resource-name" = "routeTableAssociation1" + _data.zone
#         }
#     }
#     spec.forProvider = {
#         region = _region
#         routeTableIdSelector.matchControllerRef = True
#         subnetIdSelector = {
#             matchControllerRef = True
#             matchLabels.zone = _region + _data.zone
#         }
#     }
# } for _data in _zoneList]

# _items += [{
#     apiVersion = "ec2.aws.upbound.io/v1beta1"
#     kind = "Subnet"
#     metadata = {
#         name = oxr.spec.id + "-" + _data.zone
#         annotations = {
#             "krm.kcl.dev/composition-resource-name" = "subnet-" + _data.zone
#         }
#         labels = {
#             zone = _region + _data.zone
#         }
#     }
#     spec.forProvider = {
#         region = _region
#         availabilityZone = _region + _data.zone
#         cidrBlock = _data.cidrBlock
#         vpcIdSelector.matchControllerRef = True
#     }
# } for _data in _zoneList]

# items = _items
