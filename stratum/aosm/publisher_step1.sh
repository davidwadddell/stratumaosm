source ./env.rc
az deployment group create --resource-group ${resourceGroup} --template-file ./bicep/stratum_publisher_aosm_part1.bicep --parameters @parameters/stratum.aosm.publisher.part1.parameters.json
