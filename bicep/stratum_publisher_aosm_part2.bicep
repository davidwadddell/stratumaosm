param publisherName string 
param artifactStore string 
param location string = resourceGroup().location
param nsdGroup string 
param cnfName string 
param nsdvName string
param nfdgroupName string
param nfdversion string
param resourceExists bool = false

// Publisher resource
resource publisher 'Microsoft.HybridNetwork/publishers@2023-09-01' existing = {
  name: publisherName
}

// Artifact store resource
resource acrArtifactStore 'Microsoft.HybridNetwork/publishers/artifactStores@2023-09-01' existing = {
  parent: publisher
  name: artifactStore
}

// Load Helm charts configuration
var helm_charts = loadJsonContent('../parameters/stratum-helm-charts.json')

// Create NFD group resource
resource nfd 'Microsoft.HybridNetwork/publishers/networkfunctiondefinitiongroups@2023-09-01' existing = {
  name: nfdgroupName
  parent: publisher
}

// Create NSDG group resource 
resource nsdg 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups@2023-09-01' existing = {
  parent: publisher
  name: nsdGroup
}

// Load NFD parameter schema from JSON file
// This schema is used to define the parameters for the NFD ARM template
//
var dval = loadJsonContent('../jsons/Stratum_NFDV_parameter_schema.json')

// Define NFAs for each Helm chart

var nFAs = [for (hchart, index) in helm_charts.charts: {
  artifactType: 'HelmPackage'
  name: hchart.name
  dependsOnProfile: null
  artifactProfile: {
    artifactStore: {
      id: acrArtifactStore.id
    }
    helmArtifactProfile: {
      helmPackageName: hchart.chartName
      helmPackageVersionRange: hchart.versionRange
      registryValuesPaths: hchart.registryValuesPaths
      imagePullSecretsValuesPaths: hchart.imagePullSecretsValuesPaths
    }
  }
  deployParametersMappingRuleProfile: {
    applicationEnablement: 'Enabled'
    helmMappingRuleProfile: {
      releaseNamespace: hchart.releaseNamespace
      releaseName: hchart.releaseName
      helmPackageVersion: '{deployParameters.charts[${index}].Version}'
      values: '{deployParameters.charts[${index}].Values}'
      options: {
        installOptions: {
          atomic: 'false'
          wait: 'true'
          timeout: '100'
        }
      }
    }
  }
}]

// Create NFD version resource
// The "deployParameters" property is used to define the parameters for the NFD ARM template (using schema defined above)
// The "networkFunctionApplications" property is used to define the NFAs for each Helm chart
//
resource nfdv 'Microsoft.HybridNetwork/publishers/networkfunctiondefinitiongroups/networkfunctiondefinitionversions@2023-09-01' = {
  parent: nfd
  name: nfdversion
  location: location
  properties:{
    deployParameters: string(dval)
    networkFunctionType: 'ContainerizedNetworkFunction'
    networkFunctionTemplate: {
      nfviType: 'AzureArcKubernetes'
      networkFunctionApplications: nFAs
    }
  }
}

// Create global configuration group schema resource from JSON file
resource globalCnfSchema 'Microsoft.Hybridnetwork/publishers/configurationGroupSchemas@2023-09-01' = {
  parent: publisher
  name: 'StratumGlobalConfiguration'
  location: location
  properties: {
    schemaDefinition: string(loadJsonContent('../jsons/Stratum_CGS_global_schema.json'))
  }
}

// Create site configuration group schema resource from JSON file
resource siteCnfSchema 'Microsoft.Hybridnetwork/publishers/configurationGroupSchemas@2023-09-01' = {
  parent: publisher
  name: 'StratumSiteConfiguration'
  location: location
  properties: {
    schemaDefinition: string(loadJsonContent('../jsons/Stratum_CGS_site_schema.json'))
  }
}

// Load contents of NSD configuration mapping JSON file
// This file is used by the NSDG to map the configuration parameters to the NFD parameters
//
var chartsString = string(loadJsonContent('../jsons/Stratum_NSDG_config_mapping.json'))

// Create NSDV resource
//
// The "configurationGroupSchemaReferences" property is used to define the configuration group schemas for the NSD
// These are the global and site configuration schemas defined above
//
// The "nfvisFromSite" property is used to define the NFVI for the NSD
// This points to the NAKS cluster created above
//
// The "resourceElementTemplates" property is used to define the NFDs for the NSD
// The "parameterValues" property is used to define the parameters for the NFD ARM template (using schema defined above)
// The key configuration is the "charts" property which is used to define the configuration for the Helm charts for the NFD
//

resource nsdg_1_0_0 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups/networkservicedesignversions@2023-09-01' = {
  parent: nsdg
  name: nsdvName
  location: location
  properties: { 
    description: 'Stratum NSD.' 
    versionState: 'Active'
    configurationGroupSchemaReferences: {
      StratumGlobalConfiguration: {
        id: globalCnfSchema.id
      }
      StratumSiteConfiguration: {
        id: siteCnfSchema.id
      }      
    } 
    nfvisFromSite: {
      naksCluster: {
        type: 'AzureArcKubernetes'
        name: 'naksCluster'
      }
    } 
    resourceElementTemplates: [
      { 
        name: cnfName
        type: 'NetworkFunctionDefinition'
        configuration: {
          templateType: 'ArmTemplate'
          parameterValues: '{"publisherName": "${publisherName}", "nfdgroupName": "${nfdgroupName}", "nfdvId": "${nfdv.id}", "nfdversion": "${nfdversion}", "charts": ${chartsString}, "nfvId": "{nfvis(\'naksCluster\').customLocationReference.id}", "cnfName": "${cnfName}"}'
          artifactProfile: {
            artifactStoreReference: {
              id: acrArtifactStore.id
            }
            artifactName: 'stratumnfdvtemplate'
            artifactVersion: '1.0.0'
           }
        } 
      }
    ] 
  }
}
