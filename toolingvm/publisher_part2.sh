source ./env.rc
az deployment group create --resource-group ${resourceGroup} --template-file EneaToolingVMPublishPart2.bicep --parameters EneaToolingVMPublishPart2.parameters.json
