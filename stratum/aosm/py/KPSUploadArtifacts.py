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

# Read parameters files
params = os.path.join(os.getcwd(), 'parameters/kps.aosm.publisher.part1.parameters.json')
with open(params, 'r') as file:
    content = json.load(file)
    names = content['parameters']
    artifactManifest = names['artifactManifestName']['value']
    artifactStore = names['artifactStore']['value']
    publisher = names['publisherName']['value']
    armTemplateName = names['armTemplateName']['value']
    armTemplateVersion = names['armTemplateVersion']['value']    

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
url = f"https://management.azure.com/subscriptions/{subscription}/resourceGroups/{rg}/providers/Microsoft.Hybridnetwork/publishers/{publisher}/artifactStores/{artifactStore}/artifactManifests/{artifactManifest}/listcredential?api-version=2023-09-01"
print ("URL: " + url + "\n")

# Get credentials
acr_cred = get_credentials(url)

if sys.argv[1] == "all" or sys.argv[1] == "helm":

    # Load helm charts data    
    with open(os.path.join(os.getcwd(), 'parameters/kps-helm-charts.json'), 'r') as file:
        hcharts = json.load(file)

    # Login to helm registry
    command = [
        "helm", "registry", "login",
        acr_cred["acrServerUrl"].replace("https://", ""), "--username", acr_cred["username"], "--password",
        acr_cred["acrToken"]
    ]
    output = subprocess.check_output(command)
    print(output.decode("utf-8"))
    
    # Generate oci url
    oci = "oci" + acr_cred["acrServerUrl"].replace("https", "")
    print(oci)

    # Push helm charts
    for hchart in hcharts["charts"]:
        helm_tgz = hchart["chartFile"]
        command_push = ["helm", "push", helm_tgz, oci]
        output = subprocess.check_output(command_push)
        print(output.decode("utf-8"))

    # Login to docker registry
    docker_login_command = [
        "docker", "login",
        acr_cred["acrServerUrl"].replace("https://", ""), "--username", acr_cred["username"], "--password",
        acr_cred["acrToken"]
    ]
    output = subprocess.check_output(docker_login_command)
    print(output.decode("utf-8"))

    # Load images data from parameters file
    with open(os.path.join(os.getcwd(), 'parameters/kps-images.json'), 'r') as file:
        images = json.load(file)
    
    # Push images
    for image in images["images"]:

        # Tag image
        imagetag = image["name"] + ":" + image["version"]
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
    
