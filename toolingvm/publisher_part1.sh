#!/bin/bash
source ./env.rc
az deployment group create --resource-group ${resourceGroup} --template-file EneaToolingVMPublishPart1.bicep --parameters EneaToolingVMPublishPart1.parameters.json 
