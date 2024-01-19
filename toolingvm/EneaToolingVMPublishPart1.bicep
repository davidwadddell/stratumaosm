param location string
param vmTemplateVersion string
param vmImageVersion string
param nfTemplateVersion string
param publisherName string
param artifactStoreName string
param artifactManifestName string
param nfdgName string
param nsdgName string
param vmImageName string
param vmTemplateName string
param nfTemplateName string


// The existing publisher resource under which the NFDV and NSDV will be created.
resource publisher 'Microsoft.HybridNetwork/publishers@2023-04-01-preview' existing = {
  name:  publisherName
  scope: resourceGroup()
}

// The existing artifactStore using which NF artifacts are onboarded.
resource acrArtifactStore 'Microsoft.HybridNetwork/publishers/artifactStores@2023-04-01-preview' existing = {
  parent: publisher
  name: artifactStoreName
}

// Create ArtifactManifest with NF artifacts details. This resource helps in fetching ACR credentails to onboard artifacts.
resource acrArtifactManifest 'Microsoft.Hybridnetwork/publishers/artifactStores/artifactManifests@2023-04-01-preview' = {
  parent: acrArtifactStore
  name: artifactManifestName
  location: location
  properties: {
    artifacts: [
      {
        artifactName:  vmImageName
        artifactType: 'OCIArtifact'
        artifactVersion: vmImageVersion
      }
      {
        artifactName:  vmTemplateName
        artifactType: 'OCIArtifact'
        artifactVersion: vmTemplateVersion
      }
      {
        artifactName:  nfTemplateName
        artifactType: 'OCIArtifact'
        artifactVersion: nfTemplateVersion
      }
    ]
  }
}

// Create the Network Function Definition Group (NFDG) which is a collection of Network Function Definition Versions (NFDV).
resource nexusVnfNfdg 'Microsoft.Hybridnetwork/publishers/networkfunctiondefinitiongroups@2023-04-01-preview' = {
  parent: publisher
  name: nfdgName
  location: location
  properties: {
		description: 'Enea Tooling VM nfdg'
  }
}

// Create the Network Service Definition Group (NSDG) which is a collection of Network Servcie Definition Versions (NSDV).
resource nexusVnfNsdg 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups@2023-04-01-preview' = {
  parent: publisher
  location: location
  name: nsdgName
  properties: {
    description: 'Enea Tooling VM nsdg'
  }
  
}
