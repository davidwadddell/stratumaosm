export auth_token=$(az account get-access-token | grep accessToken | sed 's#.*": "##g' | sed 's#",##g'  ) 
