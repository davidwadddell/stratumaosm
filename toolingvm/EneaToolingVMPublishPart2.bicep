// This File creates the Network Function Definition Version (NFDV) and Network Servcie Definition Version (NSDV) resources using the pre-created publisher resources.
// The artifacts (VM image, ARM templates) is expected to uploaded prior to executing this script.

param location string
param nfDefinitionVersion string
param nsDesignVersion string
param uploadedNfArmTemplateVersion string
param uploadedVmTemplateVersion string
param uploadedVmImageVersion string
param nfviFromSite string

param existingPublisherName string
param existingArtifactStoreName string
param existingNfdgName string
param existingNsdgName string
param uploadedVmImageName string
param uploadedVmTemplateName string
param uploadedNfTemplateName string
param nexusVnfCgsName string


// The existing publisher resource under which the NFDV and NSDV will be created.
resource publisher 'Microsoft.HybridNetwork/publishers@2023-04-01-preview' existing = {
  name: existingPublisherName
  scope: resourceGroup()
}

// The existing artifactStore using which NF artifacts are onboarded.
resource acrArtifactStore 'Microsoft.HybridNetwork/publishers/artifactStores@2023-04-01-preview' existing = {
  parent: publisher
  name: existingArtifactStoreName
}

// Create the Network Function Definition Group (NFDG) which is a collection of Network Function Definition Versions (NFDV).
resource nexusVnfNfdg 'Microsoft.Hybridnetwork/publishers/networkfunctiondefinitiongroups@2023-04-01-preview' existing = {
  parent: publisher
  name: existingNfdgName
}

// Create the NFDV which provides details about
// Scehma - Expected Json Schema for the input parameters to instantiate the NF
// ArtifactProfiles - Indication about the NF artifacts location. 
resource nexusVnfNfdv 'Microsoft.Hybridnetwork/publishers/networkfunctiondefinitiongroups/networkfunctiondefinitionversions@2023-04-01-preview' = {
  parent: nexusVnfNfdg
  name: nfDefinitionVersion
  location: location
  properties: {
    versionState: 'Preview'
    deployParameters: string(loadJsonContent('nf/schemas/nfDeployParameters.json'))
    networkFunctionType: 'VirtualNetworkFunction'
    networkFunctionTemplate: {
      nfviType: 'AzureOperatorNexus'
      networkFunctionApplications: [
        {
          artifactType: 'ImageFile'
          name: 'nexusVnfImageRole'
          dependsOnProfile: null
          artifactProfile: {
            imageArtifactProfile: {
                imageName: uploadedVmImageName
                imageVersion: uploadedVmImageVersion
            }
            artifactStore: {
                id: acrArtifactStore.id
            }
          }
          deployParametersMappingRuleProfile: null
        }
        {
          artifactType: 'ArmTemplate'
          name: 'nexusVnfTemplateRole'
          dependsOnProfile: null
          artifactProfile: {
            templateArtifactProfile: {
              templateName: uploadedVmTemplateName
              templateVersion: uploadedVmTemplateVersion
            }
            artifactStore: {
                id: acrArtifactStore.id
            }
          }
          deployParametersMappingRuleProfile: {
            templateMappingRuleProfile: {
              templateParameters: string(loadJsonContent('nf/schemas/vmTemplateMappingRule.json'))
            }
          }
        }
      ]
    }
  }
}

// Create the Configuration Group Schema (CGS) which is the Json schema to be followed while providing input to instantiate the Site Network Service.
resource nexusVnfCgSchema 'Microsoft.Hybridnetwork/publishers/configurationGroupSchemas@2023-04-01-preview' = {
  parent: publisher
  name: nexusVnfCgsName
  location: location
  properties: {
    schemaDefinition: string(loadJsonContent('nsd/schemas/nexusVnfCgSchema.json'))
  }
}


// Create the Network Service Definition Group (NSDG) which is a collection of Network Servcie Definition Versions (NSDV).
resource nexusVnfNsdg 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups@2023-04-01-preview' existing = {
  parent: publisher
  name: existingNsdgName
}

// Create Network Service Design Version which contains below info to instantiate the Site Network Service
// CG schema(s) to be followed.
// Resource Element Templates - To instantiate the Network function(s), which together form the Site Network Service.
resource nexusVnfNsdv 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups/networkservicedesignversions@2023-04-01-preview' = {
  parent: nexusVnfNsdg
  name: nsDesignVersion
  location: location
  properties: {
    description: 'Nexus VNF NSDV.'
    versionState: 'Preview'
    configurationGroupSchemaReferences: {
      nexusVnfConfiguration: {
        id: nexusVnfCgSchema.id
      }
    }
    nfvisFromSite: {
      nfvi1: {
        name: nfviFromSite // We can take it as parameter from CGV
        type: 'AzureOperatorNexus'
      }
    }
    resourceElementTemplates: [
      {
        configuration: {
          artifactProfile: {
            artifactStoreReference: {
              id: acrArtifactStore.id
            }
            artifactName:  uploadedNfTemplateName
            artifactVersion: uploadedNfArmTemplateVersion
          }
          templateType: 'ArmTemplate'
          parameterValues: string(loadJsonContent('nsd/schemas/nfTemplateParameters.json'))
        }
        name: 'nexusVnfNetworkFunction'
        type: 'NetworkFunctionDefinition'
      }
    ]
  }
}
