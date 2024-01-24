source ./env.rc
az deployment group create --resource-group ${resourceGroup} --template-file EneaToolingVMOperator.bicep --parameters EneaToolingVMOperator.parameters.json 
