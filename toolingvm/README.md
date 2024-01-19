

# assumes publisher and artifact store already exist

# step1 - create artifact manifest and nsdg/nfdg
 az deployment group create --name EneaToolingVMPubPart1Deployment --resource-group rg-precert-ENEA-001 --template-file EneaToolingVMPu
blishPart1.bicep --parameters EneaToolingVMPublishPart1.parameters.json

