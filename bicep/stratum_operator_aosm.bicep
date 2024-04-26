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
param globalCgsName string
param siteCgsName string
param nfdgroupName string
param nfdversion string
param resourceExists bool = false

// Refer to custom location already created
resource cl 'Microsoft.ExtendedLocation/customLocations@2023-09-01' existing = {
  scope: resourceGroup(aksClusterGroup)  
  name: aksClusterName
}

// Refer to resources already created
resource publisher 'Microsoft.HybridNetwork/publishers@2023-09-01' existing = {
  name: publisherName
  scope: resourceGroup()
}

resource nfd 'Microsoft.HybridNetwork/publishers/networkfunctiondefinitiongroups@2023-09-01' existing = {
  name: nfdgroupName
  parent: publisher
}
 
resource nsdg 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups@2023-09-01' existing = {
  parent: publisher
  name: nsdGroup
}
 
resource nfdv 'Microsoft.HybridNetwork/publishers/networkfunctiondefinitiongroups/networkfunctiondefinitionversions@2023-09-01' existing = {
  name: nfdversion
  parent: nfd
}
 
resource nsdv 'Microsoft.Hybridnetwork/publishers/networkservicedesigngroups/networkservicedesignversions@2023-09-01' existing = {
  parent: nsdg
  name: nsdvName
}

resource globalCgs 'Microsoft.HybridNetwork/publishers/configurationGroupSchemas@2023-09-01' existing = {
  name: globalCgsName
  parent: publisher
}

resource siteCgs 'Microsoft.HybridNetwork/publishers/configurationGroupSchemas@2023-09-01' existing = {
  name: siteCgsName
  parent: publisher
}

// Create site
// Refers to NFVIS cluster created in the custom location
//
resource site 'Microsoft.HybridNetwork/sites@2023-09-01' =  {
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
resource globalCgv 'Microsoft.HybridNetwork/configurationGroupValues@2023-09-01' = {
  name: globalCgvName
  location: location
  properties: {
    configurationGroupSchemaResourceReference: {
      id: globalCgs.id
      idType: 'Open'
    }      
    configurationType: 'Open'
    configurationValue: string(loadJsonContent('../jsons/Stratum_Global_CGV.json'))
  }
}

// Create site configuration schema from json file
resource siteCgv 'Microsoft.HybridNetwork/configurationGroupValues@2023-09-01' = {
  name: siteCgvName
  location: location
  properties: {
    configurationGroupSchemaResourceReference: {
      id: siteCgs.id
      idType: 'Open'
    }
    configurationType: 'Open'
    configurationValue: string(loadJsonContent('../jsons/Stratum_Site_CGV.json'))
  }
}

// Create SNS
// This will do the actual deploy of the application on the Site, which is the NFVIS (NAKS) cluster
// Refers to site created above, global and site configuration schemas  

resource sns 'Microsoft.HybridNetwork/sitenetworkservices@2023-09-01' = {
  name: snsName
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
   type: 'SystemAssigned'
  }
  properties: {
    siteReference: {
      id: site.id
    }
    networkServiceDesignVersionResourceReference: {
      id: nsdv.id
      idType: 'Open'
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
