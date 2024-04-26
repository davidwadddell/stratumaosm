source ./env.rc
az deployment group create --resource-group ${resourceGroup} --template-file ./bicep/stratum_publisher_aosm_part2.bicep --parameters @parameters/stratum.aosm.publisher.part2.parameters.json
