source ./env.rc
set -x
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.HybridNetwork/publishers/EneaPublisher/networkFunctionDefinitionGroups/StratumNFDG
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Hybridnetwork/publishers/EneaPublisher/networkServiceDesignGroups/StratumNSDG
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.HybridNetwork/publishers/EneaPublisher/networkFunctionDefinitionGroups/StratumNFDG
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Hybridnetwork/publishers/EneaPublisher/artifactStores/EneaArtifactStore/artifactManifests/StratumManifest
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.HybridNetwork/publishers/EneaPublisher/artifactStores/EneaArtifactStore 
az resource delete --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.HybridNetwork/publishers/EneaPublisher
az deployment group delete --resource-group ${resourceGroup} --name stratum_publisher_aosm_part1
