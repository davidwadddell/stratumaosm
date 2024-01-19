// This File creates the Site Network Service (SNS) using the pre-created publisher resources,
// which brings up the VNF on Nexus cluster.

param location string
param nfviFromSite string
param customlocationId string
param nsdVersion string

param existingPublisherName string
param existingNsdgName string
param existingCgsName string
param snsName string
param cgvName string
param siteName string

// Read the cloud init UserData and Network Data as base64 encoded strings from files directly.
var cloudInitData = {
  userData : loadFileAsBase64('nsd/values/userData.txt')
  networkData : loadFileAsBase64('nsd/values/networkData.txt')
}

// Below code overwrites cloud-init user and network data in CGV from the data read from above files.
var nexusVnfCgvConfig = loadJsonContent('nsd/values/nexusVnfCgValue.json')
var vnfConfig = nexusVnfCgvConfig['nexusVnfConfig']

var cgv = {
  nexusVnfConfig : union(vnfConfig, cloudInitData)
}


// Create CGV, the user input for Nexus VNF creation
resource nexusVnfCgv 'Microsoft.HybridNetwork/configurationGroupValues@2023-04-01-preview' = {
  name: cgvName
  location: location
  properties: {
    publisherName: existingPublisherName
    publisherScope: 'Private'
    configurationGroupSchemaName: existingCgsName
    configurationGroupSchemaOfferingLocation: location
    configurationValue: string(union(nexusVnfCgvConfig, cgv))
  }
}

// Create Site resource, the logical representation of the target location on to which Nexus VNF will be deployed.
resource nexusVnfSite 'Microsoft.HybridNetwork/sites@2023-04-01-preview' = {
  name: siteName
  location: location
  properties: {
    nfvis : [
      {
        name: nfviFromSite
        nfviType: 'AzureOperatorNexus'
        customLocationReference: {
          id: customlocationId
        }
      }
    ]
  }
}

// Create SNS resource to instantiate the Nexus VNF.
resource nexusVnfSns 'Microsoft.HybridNetwork/sitenetworkservices@2023-04-01-preview' = {
  name: snsName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteReference: {
      id: nexusVnfSite.id
    }
    publisherName: existingPublisherName
    publisherScope: 'Private'
    networkServiceDesignGroupName: existingNsdgName
    networkServiceDesignVersionName: nsdVersion
    networkServiceDesignVersionOfferingLocation: location  
    desiredStateConfigurationGroupValueReferences: {
      nexusVnfConfiguration: {
        id: nexusVnfCgv.id
      }
    }
  }
}
