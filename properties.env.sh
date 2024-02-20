#!/bin/bash

echo "Exporting environment variables for use in properties.py file"

export ems_rw_ip=ems01
export ems_ro_ip=ems02
export notification_fe_ip_list=''
export build_user=opwv
export loadgen_expected_rfr=0
export loadgen_session_max_resp_time=0
export loadgen_vnfstate_max_resp_time=0
export loadgen_subscriber_max_resp_time=0
export loadgen_config_max_resp_time=0
export ems_product_version=4.1
export sudo_user=opwv
export ssh_user=root
export ssh_key_file=/spare/id_rsa
export region1_ssh_key_file=/spare/id_rsa

export ems_username=cli
export ems_password=*F2Uasf2HDeRiZY^
export linux_username=root
export cloud_ssh_user=cloud-user
export sudo_user=opwv
export linux_password=secret
export container_install=True
export path_to_tools=/opt/opwv/sdmCD/4.1/ldif/tools/Stratum

export docstore_bind_dn="cn=doc.test"
export docstore_bind_passwd=docsecret
export docstore_stratum_bind_dn="cn=doc.stratumtest"
export docstore_stratum_bind_passwd=docsecret
export docstore_schema_name=docstore
export docstore_stratum_schema_name=docstore-stratum-test
export docstore_schema_version=4712
export docstore_kpi_bind_dn=cn=doc.test_kpi
export docstore_kpi_bind_passwd=docsecret
export docstore_kpi_indexing_bind_dn=cn=doc.test_kpi_indexing
export docstore_kpi_indexing_bind_passwd=docsecret
export docstore_kpi_schema_name=docstore-kpi-test
export docstore_replication_schema_name=docstore-replication-profile-test
export docstore_admin_kpi_bind_dn=cn=doc.test_kpi_admin
export docstore_admin_kpi_bind_passwd=docsecret
export docstore_kpi_backup_dn=cn=doc.test_kpi_backup
export docstore_kpi_backup_passwd=docsecret
export docstore_kpi_backup_schema_name=docstore-kpi-test-backup
export docstore_data_repair_schema_name=docstore-data-repair-test
export docstore_kpi_ntfncore_bind_dn=cn=doc.test_kpi_ntfn_core
export docstore_kpi_ntfncore_bind_passwd=docsecret
export docstore_kpi_ntfnview_bind_dn=cn=doc.test_kpi_ntfn_view
export docstore_kpi_ntfnview_bind_passwd=docsecret
export docstore_kpi_ntfn_view_schema_name=docstore-kpi-test-notifications-view.yaml

export ldap_port=389
export secure_sbi_port=443
export sbi_port=443
export secure_udsf_port=443

export mysql_db_username=root
export mysql_db_password=ch4ngeme
export mysql_db_name=ordb

export r1_lba_vip_ip=__ENEA_ILD_SVC_IP__
export lba_vip_list=__ENEA_ILD_SVC_IP__

export r11_lba_vip=__ENEA_ILD_SVC_IP__
export r12_lba_vip=192.168.120.146
export r21_lba_vip=192.168.120.151
export r22_lba_vip=192.168.120.156
export lw1_pod_vip=192.168.120.160
export lw2_pod_vip=192.168.120.166
export le1_pod_vip=192.168.120.170
export le2_pod_vip=192.168.120.176


export test_ldap_bind_dn=cn=Stratum-Test-User,ou=Users,ou=Administration,o=EneaOrg
export test_ldap_bind_password=stratumtest

export ldap_bind_dn=cn=Stratum-Test-User,ou=Users,ou=Administration,o=EneaOrg
export ldap_password=stratumtest

export admin_bind_dn=cn=Stratum-Admin-Schema,ou=Users,ou=Administration,o=EneaOrg
export admin_bind_passwd=passwd

export indexing_bind_dn=cn=doc.test_kpi_indexing
export indexing_bind_passwd=docsecret

export indexing_virtual_user_bind_dn=cn=Indexing-Test-Virtual-User,ou=Users,ou=Administration,o=EneaOrg
export indexing_virtual_user_bind_passwd=stratumtest

export virtual_user_1_bind_dn=cn=Stratum-Test-Virtual-1-User,ou=Users,ou=Administration,o=EneaOrg
export virtual_user_2_bind_dn=cn=Stratum-Test-Virtual-2-User,ou=Users,ou=Administration,o=EneaOrg
export virtual_user_bind_passwd=stratumtest

export num_of_followers=2
export num_of_hashslots=128
export num_of_replicas=2

export is_multi_region=false

export enable_yaml_schema=True

# NBI parameters
export nbi_ip=$(hostname)
export nbi_port=30000
export ems_primary_host_internal=$(getent hosts ems01 | awk '{ print $1 }')
echo "ems_primary_host_internal=$ems_primary_host_internal"

export stratum_product_version=4
echo "stratum_product_version=$stratum_product_version"

export install_type=site
echo "install_type=$install_type"

export sbi_ntfn_ip=$(hostname)
export sbi_ntfn_port=8082
export container_host=10.20.163.15

export prometheus_port=9090

export config_update_wait=25

echo "Export completed"
