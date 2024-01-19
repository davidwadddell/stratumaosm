import requests
import os
import shutil 
import subprocess
import sys
import json

# This script uploads artifacts to the artifact store
# It requires the following environment variables to be set:
# auth_token - the auth token to use for the upload
# subscription - the subscription to use
# resourceGroup - the resource group to use
# artifactManifestName - the name of the artifact manifest
# artifactStore - the name of the artifact store
# publisherName - the name of the publisher
# It also requires the following files to be present:
# parameters/aosm.names.parameters.json - the parameters file for the artifact manifest
# parameters/helm-charts.json - the helm charts to upload
# parameters/images.json - the images to upload
# bicep/arm_cnf_template.bicep - the bicep template to upload
# bicep/arm_cnf_template.json - the bicep template to upload

# Example usage:
# python3 StratumUploadArtifacts.py all

# Read environment variables
auth_token = os.environ["auth_token"]
subscription = os.environ["subscription"]
rg = os.environ["resourceGroup"]

# Read parameters file
params = os.path.join(os.getcwd(), 'EneaToolingVMPublishPart1.parameters.json')
with open(params, 'r') as file:
    content = json.load(file)
    names = content['parameters']
    artifactManifest = names['artifactManifestName']['value']
    artifactStore = names['artifactStoreName']['value']
    publisher = names['publisherName']['value']
    vmTemplateName = names['vmTemplateName']['value']
    vmTemplateVersion = names['vmTemplateVersion']['value']
    nfTemplateName = names['nfTemplateName']['value']
    nfTemplateVersion = names['nfTemplateVersion']['value']

# Check if auth_token is null
if (auth_token == None):
    print("auth_token is null")
    print(
        "Please run 'az login' and then 'az account get-access-token' to get the auth_token then export auth_token."
    )
    os._exit()

# Check if subscription is null 
if len(sys.argv) != 2:
    print(
        "Usage: UploadArtifacts.py [all|helm|oras]"
    )
    os._exit()

# Function to get credentials
def get_credentials(url):
    credentials={}
    headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {auth_token}"
    }

    # Get credentials
    response = requests.post(url, headers=headers, data={})

    # Check if response is 200
    if (response.status_code != 200):
        print("Error getting credentials")
        print(response.json())
        os._exit()

    # Get credentials from response
    credentials["username"] = response.json()["username"]
    credentials["acrToken"] = response.json()["acrToken"]
    credentials["acrServerUrl"] = response.json()["acrServerUrl"]
    credentials["repositories"] = response.json()["repositories"]
    return credentials

# URL to get credentials
url = f"https://management.azure.com/subscriptions/{subscription}/resourceGroups/{rg}/providers/Microsoft.Hybridnetwork/publishers/{publisher}/artifactStores/{artifactStore}/artifactManifests/{artifactManifest}/listcredential?api-version=2023-04-01-preview"
print ("URL: " + url + "\n")

# Get credentials
acr_cred = get_credentials(url)
    
if sys.argv[1] == "all" or sys.argv[1] == "oras":

    # Login to docker registry
    docker_login_command = [
        "docker", "login",
        acr_cred["acrServerUrl"].replace("https://", ""), "--username", acr_cred["username"], "--password",
        acr_cred["acrToken"]
    ]
    output = subprocess.check_output(docker_login_command)
    print(output.decode("utf-8"))

    imagetag = "eneatoolingvmimage:1.0.0"
    docker_image = acr_cred["acrServerUrl"].replace("https://", "") + "/" + imagetag

    print ('\nTagging image ', imagetag, ' as ', docker_image)
    docker_tag_command = ["docker", "tag", imagetag, docker_image]
    output = subprocess.check_output(docker_tag_command)
    print(output.decode("utf-8"))
    print ('Tagged image ', imagetag, ' as ', docker_image)

    # Push image
    print ('\nPushing image ', docker_image, '...')
    docker_push_command = [ "docker", "push",  docker_image ]
    output = subprocess.check_output(docker_push_command)
    print(output.decode("utf-8"))
    print ('Pushed image ', docker_image)

    # Login to oras registry
    oras_login_command = ["oras", "login",  acr_cred["acrServerUrl"].replace("https://", ""), "--username", acr_cred["username"], "--password",
        acr_cred["acrToken"]]
    output = subprocess.check_output(oras_login_command)
    print(output.decode("utf-8"))

    # Push the VM template to oras
    command_oras_push = ["oras", "push", acr_cred["acrServerUrl"].replace("https://", "") + "/" + vmTemplateName + ":" + vmTemplateVersion, "./nf/template/vmTemplate.json"]
    output = subprocess.check_output(command_oras_push)
    print(output.decode("utf-8"))

    # Push the ARM template to oras
    command_oras_push = ["oras", "push", acr_cred["acrServerUrl"].replace("https://", "") + "/" + nfTemplateName + ":" + nfTemplateVersion, "./nsd/template/nfTemplate.json"]
    output = subprocess.check_output(command_oras_push)
    print(output.decode("utf-8"))
