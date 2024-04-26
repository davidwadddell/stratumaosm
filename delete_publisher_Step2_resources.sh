source ./env.rc

az resource delete --verbose --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.HybridNetwork/publishers/EneaPublisher/networkfunctiondefinitiongroups/StratumNFDG/networkfunctiondefinitionversions/1.0.0
az resource delete --verbose --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Hybridnetwork/publishers/EneaPublisher/networkservicedesigngroups/StratumNSDG/networkservicedesignversions/1.0.0
az resource delete --verbose --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Hybridnetwork/publishers/EneaPublisher/configurationGroupSchemas/StratumGlobalConfiguration
az resource delete --verbose --ids /subscriptions/${subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Hybridnetwork/publishers/EneaPublisher/configurationGroupSchemas/StratumSiteConfiguration
