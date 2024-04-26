source ./env.rc
az resource delete --verbose --resource-group ${resourceGroup} --resource-type  Microsoft.HybridNetwork/siteNetworkServices --name StratumSNS
az resource delete --verbose  --resource-group ${resourceGroup} --resource-type Microsoft.HybridNetwork/sites --name StratumSite
az resource delete --verbose  --resource-group ${resourceGroup} --resource-type Microsoft.HybridNetwork/configurationGroupValues --name StratumSiteCGV
az resource delete --verbose  --resource-group ${resourceGroup} --resource-type Microsoft.HybridNetwork/configurationGroupValues --name StratumGlobalCGV
az deployment group cancel  --resource-group ${resourceGroup} --name stratum_operator_aosm   # in case was still running 
az deployment group delete  --resource-group ${resourceGroup} --name stratum_operator_aosm
kubectl delete pvc --all 
