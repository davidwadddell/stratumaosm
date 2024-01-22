source ./env.rc
export auth_token=$(az account get-access-token | grep accessToken | sed 's#.*": "##g' | sed 's#",##g'  )
python3 ./py/StratumUploadArtifacts.py all
