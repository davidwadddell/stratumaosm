param publisherName string 
param artifactStore string 
param location string = resourceGroup().location
param artifactManifestName string 
param nsdGroup string 
param nfdgroupName string
param armTemplateName string 
param armTemplateVersion string
param resourceExists bool = false

// Publisher resource
resource publisher 'Microsoft.HybridNetwork/publishers@2023-04-01-preview' = {
  name: publisherName
  location: location
  properties: {
    scope: 'Private'
  }
}

// Artifact store resource
resource acrArtifactStore 'Microsoft.HybridNetwork/publishers/artifactStores@2023-04-01-preview' = {
  parent: publisher
  name: artifactStore
  location:location
  properties: {
    storeType: 'AzureContainerRegistry'
    replicationStrategy: 'SingleReplication'    
  }
}

// Load Helm charts configuration
var helm_charts = loadJsonContent('../parameters/stratum-helm-charts.json')

// Load images configuration
var image_list = loadJsonContent('../parameters/stratum-images.json')

// Create array of Helm charts artifact definitions
var hartifacts = [for hchart in helm_charts.charts: {
  artifactName: hchart.chartName
  artifactType: 'OCIArtifact'
  artifactVersion: hchart.version
}]

// Create array of images artifact definitions
var iartifacts = [for himage in image_list.images: {
  artifactName: himage.name
  artifactType: 'OCIArtifact'
  artifactVersion: himage.version
}]

// Create array of ARM templates artifact definitions
var tartifacts = [{
  artifactType: 'OCIArtifact'
  artifactName: 'stratumnfdvtemplate'
  artifactVersion: '1.0.0'
}]

// Merge all artifact definitions into one array
var artifact_list = union (hartifacts, iartifacts, tartifacts)

// Create artifact manifest resource using the artifact list
resource acrArtifactManifest 'Microsoft.Hybridnetwork/publishers/artifactStores/artifactManifests@2023-04-01-preview' = {
  parent: acrArtifactStore
  name: artifactManifestName
  location: location
  properties: {
    artifacts: artifact_list
  }
}

// Create NFD group resource
resource nfd 'Microsoft.HybridNetwork/publishers/networkfunctiondefinitiongroups@2022-09-01-preview' = {
  name: nfdgroupName
  parent: publisher
  location:location
  properties: {
    description: 'Stratum NFD group'
  }
}

// Create NSDG group resource 
resource nsdg 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups@2023-04-01-preview' = {
  parent: publisher
  name: nsdGroup
  location: location
  properties: {
    description: 'Stratum NSD group.'
  }
}
