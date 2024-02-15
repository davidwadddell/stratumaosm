param publisherName string = 'TestPublisher'
param nfdgroupName string = 'TestNFDGroup'
param nfdversion string = '1.0.0'
param location string = resourceGroup().location
param nfvId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/aosm-demo/providers/microsoft.extendedlocation/customlocations/aosmcluster-custom-location'
param nfdvId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/aosm-demo/providers/microsoft.hybridnetwork/publishers/{publisherName}/networkFunctionDefinitionGroups/{nfdg}/networkFunctionDefinitionVersions/{nfdv}'
param charts array
param cnfName string

// Create a copy of the charts array with the Values property converted to a string
// The Values property is an object, and the deploymentValues property of the CNF resource requires a string
//
var charts2 = [for item in charts: {Values: string(item.Values), Version: item.Version}]

// The deploymentValues property of the CNF resource requires a string
// This array defines the values for the deploymentValues property, which is an array of objects, one per subcharts which is being deployed
//
var vals = {
  charts: charts2
}

// Create the CNF resource
// This is the ARM template
// The deploymentValues property is an array of objects, one per subchart which is being deployed
// This allows the Helm chats to be deployed with different values
//
resource cnf 'Microsoft.HybridNetwork/networkFunctions@2023-09-01' = {
  name: cnfName
  location: location
  identity: {
   type: 'SystemAssigned'
  }
  properties: {
    configurationType: 'Open'
    networkFunctionDefinitionVersionResourceReference: {
      id: nfdvId
      idType: 'Open'
    }
    nfviType: 'AzureArcKubernetes'
    nfviId:nfvId 
    allowSoftwareUpdate: true
    deploymentValues: string(vals)
  }
}
