param publisherName string 
param location string = resourceGroup().location
param nsdGroup string 
param nsdvName string
param globalCgvName string
param siteCgvName string 
param snsName string 
param siteName string 
param aksClusterName string 
param aksClusterGroup string
param resourceExists bool = false

// Refer to custom location already created
resource cl 'Microsoft.ExtendedLocation/customLocations@2021-10-01-preview' existing = {
  scope: resourceGroup(aksClusterGroup)  
  name: aksClusterName
}

// Create site
// Refers to NFVIS cluster created in the custom location
//
resource site 'Microsoft.HybridNetwork/sites@2023-04-01-preview' =  {
  name: siteName
  location: location
  properties: {
    nfvis : [
      {
        name: 'naksCluster'
        nfviType: 'AzureArcKubernetes'
        customLocationReference: {
          id: cl.id
        }
      }
    ]
  }
}

// Create global configuration schema from json file
resource globalCgv 'Microsoft.HybridNetwork/configurationGroupValues@2023-04-01-preview' = {
  name: globalCgvName
  location: location
  properties: {
    publisherName: publisherName
    publisherScope: 'Private'
    configurationGroupSchemaName: 'StratumGlobalConfiguration'
    configurationGroupSchemaOfferingLocation: location
    configurationValue: string(loadJsonContent('../jsons/Stratum_Global_CGV.json'))
  }
}

// Create site configuration schema from json file
resource siteCgv 'Microsoft.HybridNetwork/configurationGroupValues@2023-04-01-preview' = {
  name: siteCgvName
  location: location
  properties: {
    publisherName: publisherName
    publisherScope: 'Private'
    configurationGroupSchemaName: 'StratumSiteConfiguration'
    configurationGroupSchemaOfferingLocation: location
    configurationValue: string(loadJsonContent('../jsons/Stratum_Site_CGV.json'))
  }
}

// Create SNS
// This will do the actual deploy of the application on the Site, which is the NFVIS (NAKS) cluster
// Refers to site created above, global and site configuration schemas  

resource sns 'Microsoft.HybridNetwork/sitenetworkservices@2023-04-01-preview' = {
  name: snsName
  location: location
  identity: {
   type: 'SystemAssigned'
  }
  properties: {
    publisherName: publisherName
    publisherScope: 'Private'
    networkServiceDesignGroupName: nsdGroup
    networkServiceDesignVersionName: nsdvName
    networkServiceDesignVersionOfferingLocation: location
    siteReference: {
      id: site.id
    }
    desiredStateConfigurationGroupValueReferences: {
      StratumGlobalConfiguration: {
        id: globalCgv.id
      }
      StratumSiteConfiguration: {
        id: siteCgv.id
      }      
    }
  }
}
