source ./env.rc
time az deployment group create -g ${resourceGroup}  --template-file ./bicep/stratum_operator_aosm.bicep  --parameters @parameters/stratum.aosm.operator.parameters.json
