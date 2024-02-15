#!/usr/bin/bash

set -e

alias kubectl='sudo kubectl'

# Copy schema files from the pytest client

pytestclient=$(kubectl get pod -l name=stratum-pytest-client -o jsonpath="{.items[0].metadata.name}")
toolsdir=/opt/opwv/sdmCD/4.1/ldif/tools/Stratum

echo "Removing existing schema files from /var/tmp"
rm -f /var/tmp/docstore*.yaml

echo "Copying schema files from the pytest client to /var/tmp"
kubectl cp ${pytestclient}:${toolsdir}/docstore-test.yaml /var/tmp/docstore-test.yaml
kubectl cp ${pytestclient}:${toolsdir}/docstore-Nudr-DataRepository-att.yaml /var/tmp/docstore-Nudr-DataRepository-att.yaml
kubectl cp ${pytestclient}:${toolsdir}/docstore-Nudsf-DataRepository.yaml /var/tmp/docstore-Nudsf-DataRepository.yaml
kubectl cp ${pytestclient}:${toolsdir}/docstore-Builtin-DataRepository.yaml /var/tmp/docstore-Builtin-DataRepository.yaml
#cp docstore-Builtin-DataRepository.yaml /var/tmp/docstore-Builtin-DataRepository.yaml

echo "Changing ownership of schema files"
sudo chown azureuser:azureuser /var/tmp/docstore*.yaml

# Update the replication profile within the schema files
# (Full command needs to be in single quotes as the sed command contains a colon)
echo "Updating the replication profile within the schema files"
for file in "/var/tmp/docstore*.yaml"; do sed -i "s/redundancy: .*/redundancy: profile100sync/g" $file; done

# Get EMS pod name
echo "Getting EMS pod name"
ems01=$(kubectl get pod -l name=ems01 -o jsonpath="{.items[0].metadata.name}")
echo "ems01 is $ems01"

# Copy updated YAML files to EMS
echo "Copying updated YAML files to EMS"
kubectl cp /var/tmp/docstore-test.yaml $ems01:/tmp/docstore-test.yaml
kubectl cp /var/tmp/docstore-Nudr-DataRepository-att.yaml $ems01:/tmp/docstore-Nudr-DataRepository-att.yaml
kubectl cp /var/tmp/docstore-Nudsf-DataRepository.yaml $ems01:/tmp/docstore-Nudsf-DataRepository.yaml
kubectl cp /var/tmp/docstore-Builtin-DataRepository.yaml $ems01:/tmp/docstore-Builtin-DataRepository.yaml

# Copy required scripts to ems01
echo "Copying required scripts to ems01"
kubectl cp /var/tmp/site_configure_no_partitioning.sh $ems01:/var/tmp/site_configure_no_partitioning.sh
kubectl cp /var/tmp/partitioning_configure_1sites_2regions.sh $ems01:/var/tmp/partitioning_configure_1sites_2regions.sh

# Execute the configuration script on the ems01
echo "Executing the configuration script on the ems01"
kubectl exec -it $ems01 -- bash -c "chmod +x /var/tmp/site_configure_no_partitioning.sh; /var/tmp/site_configure_no_partitioning.sh site1region1 site1region2 region1 region2 1 2"

# Execute the partitioning configuration script on the ems01
echo "Executing the partitioning configuration script on the ems01"
kubectl exec -it $ems01 -- bash -c "chmod +x /var/tmp/partitioning_configure_1sites_2regions.sh; /var/tmp/partitioning_configure_1sites_2regions.sh"    

# Restart processes
echo "Restarting processes"
adms=$(kubectl get pods | grep adm | awk '{print $1}')
ilds=$(kubectl get pods | grep ild | awk '{print $1}')
csms=$(kubectl get pods | grep csm | awk '{print $1}')

echo "Killing adm_server process on $adms"
for adm in $adms; do kubectl exec $adm -c adm -- bin/sh -c 'kill $(pidof adm_server)'; done

echo "Killing ild_server process on $ilds"    
for ild in $ilds; do kubectl exec $ild -c ild -- /bin/sh -c 'kill $(pidof ild_server)'; done

echo "Killing csm_server process on $csms"    
for csm in $csms; do kubectl exec $csm -c csm -- /bin/sh -c 'kill $(pidof csm_server)'; done

# Wait until processes restart
echo "Sleeping"
sleep 240

echo "Completed"
