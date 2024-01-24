source ./env.rc
az resource delete --verbose --resource-group ${resourceGroup} --resource-type  Microsoft.HybridNetwork/siteNetworkServices --name EneaToolingSNS
az resource delete --verbose  --resource-group ${resourceGroup} --resource-type Microsoft.HybridNetwork/sites --name EneaToolingSite
az resource delete --verbose  --resource-group ${resourceGroup} --resource-type Microsoft.HybridNetwork/configurationGroupValues --name EneaToolingCGV
az deployment group cancel  --resource-group ${resourceGroup} --name EneaToolingVMOperator   # in case was still running 
az deployment group delete  --resource-group ${resourceGroup} --name EneaToolingVMOperator
