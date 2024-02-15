#!/usr/bin/bash

# This script is used to configure the SDMCE system. It is intended to be run on the SDMCE system itself.
# The script assumes that the SDMCE system is already installed and running.

if [ "$#" -ne 6 ]; then
    echo "No region1 or region2 or localsite1 or localsite2 or number of sites or number of regions given"
    exit
fi

region1=$1
region2=$2
localsite1=$3
localsite2=$4
sites=$5
regions=$6

ems_version=$(ls /opt/opwv/oam)
OAMCLI="/opt/opwv/oam/${ems_version}/bin/OamCommandLine -u rest -p restpass -h localhost -s SdmceSystem -d opwvconfig -c"

# Onboarded regions
command="addList Complex//SDMCE/OnBoardedRegions/${region1}"
$OAMCLI "${command}"
command="addList Complex//SDMCE/OnBoardedRegions/${region2}"
$OAMCLI "${command}"

# Replication Topology

command="addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//ReplicationTopology/RegionToSiteMappings/CFG_GROUP_ID:1:RegionName:${region1}:LocalSiteName:${localsite1}"
$OAMCLI "${command}"

command="addGroupOnlyIfNotExists [CFG_GROUP_ID=2] Complex//ReplicationTopology/RegionToSiteMappings/CFG_GROUP_ID:2:RegionName:${region2}:LocalSiteName:${localsite2}"
$OAMCLI "${command}"

# Replication Profiles

$OAMCLI "deleteCfg Complex//ReplicationTopology/ReplicationProfiles/[CFG_GROUP_ID=profile100sync]"

command="addGroupOnlyIfNotExists [CFG_GROUP_ID=profile100sync] Complex//ReplicationTopology/ReplicationProfiles/CFG_GROUP_ID:profile100sync:ProfileName:profile100sync:CacheId::ProfileDescription:profile100sync:ProfileSpecification:%5B+${localsite1}+%2C+${localsite2}+%5D:LeadershipMode:SoftLeader:AllowLocalRead:false"

$OAMCLI "${command}"

# CSM
# Add the CSM endpoints for all sites

for site in $(seq 1 $sites)
do
    for region in $(seq 1 $regions)
    do    
        command="deleteCfg Complex//CSM/Inter-siteReplication/CSMEndpoints/[CFG_GROUP_ID=site${site}region${region}]"
        echo "${command}"
        $OAMCLI "${command}"        
    done
done

for site in $(seq 1 $sites)
do
    for region in $(seq 1 $regions)
    do
        region_name="site${site}region${region}"

        command="addGroupOnlyIfNotExists [CFG_GROUP_ID=${region_name}] Complex//CSM/Inter-siteReplication/CSMEndpoints/CFG_GROUP_ID:${region_name}:RegionName:${region_name}"
        echo "${command}"
        $OAMCLI "${command}"

        command="addList Complex//CSM/Inter-siteReplication/CSMEndpoints/${region_name}/CSMEndpointAddresses/site${site}-region${region}-stratum-csm-0.stratum-nodes.stratum.svc.cluster.local"
        echo "${command}"
        $OAMCLI "${command}"      
    done
done

# LDAP Clients

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:1:Enabled:true:Name:Standard:Description:StandardClient+Prio+3:Login:cn%3Ddoc.test:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:true:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=2] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:2:Enabled:true:Name:Standard_profile:Description:StandardClient_profile+Prio+3:Login:cn%3Ddoc.test_profile:Password:docsecret:AppGroup::SchemaName:Profile%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:true:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=3] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:3:Enabled:true:Name:Standard_app1:Description:StandardClient_app1+Prio+3:Login:cn%3Ddoc.test_app1:Password:docsecret:AppGroup::SchemaName:app1%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=4] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:4:Enabled:true:Name:StandardNoTableScan:Description:StandardClient+No+Table-Scan:Login:cn%3Ddoc.testNoTableScan:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=5] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:5:Enabled:true:Name:SchemaMissing:Description:StandardClient+missing+Schema:Login:cn%3Ddoc.testMissingSchema:Password:docsecret:AppGroup::SchemaName:docstoreWRONG%3A4712:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=6] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:6:Enabled:true:Name:SchemaWithoutVersion:Description:StandardClient+Broken+Schema:Login:cn%3Ddoc.testSchemaBroken:Password:docsecret:AppGroup::SchemaName:docstore:Priority:1:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=7] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:7:Enabled:true:Name:StandardPrio1:Description:StandardClient+Prio+1:Login:cn%3Ddoc.testPrio1:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=8] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:8:Enabled:true:Name:StandardPrio2:Description:StandardClient+Prio+2:Login:cn%3Ddoc.testPrio2:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:2:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=9] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:9:Enabled:false:Name:StandardNotEnabled:Description:StandardClient+Not+Enabled:Login:cn%3Ddoc.testNotEnabled:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:2:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=10] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:10:Enabled:true:Name:ClientDocstore:Description:ClientDocstoreStratumTest:Login:cn%3Ddoc.stratumtest:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=11] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:11:Enabled:true:Name:ClientDocstoreKpi:Description:ClientDocstoreKpiTest:Login:cn%3Ddoc.test_kpi:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=12] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:12:Enabled:true:Name:ClientDocstoreNtfnViewKpi:Description:ClientDocstoreKpiNtfnViewTest:Login:cn%3Ddoc.test_kpi_ntfn_view:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-notifications-view.yaml:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=13] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:13:Enabled:true:Name:ClientDocstoreNtfnCoreKpi:Description:ClientDocstoreKpiNtfnCoreTest:Login:cn%3Ddoc.test_kpi_ntfn_core:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-notifications-core:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=14] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:14:Enabled:true:Name:ClientDocstoreKpiBackup:Description:ClientDocstoreKpiTestBackup:Login:cn%3Ddoc.test_kpi_backup:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-backup:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=15] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:15:Enabled:true:Name:ClientDocstoreHighPrioKpi:Description:ClientDocstoreHighPrioKpiTest:Login:cn%3Ddoc.test_kpi_high_priority:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:2:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=16] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:16:Enabled:true:Name:ClientDocstoreMediumPrioKpi:Description:ClientDocstoreMediumPrioKpiTest:Login:cn%3Ddoc.test_kpi_medium_priority:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:4:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=17] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:17:Enabled:true:Name:ClientDocstoreAdminPrioKpi:Description:ClientDocstoreAdminPrioKpiTest:Login:cn%3Ddoc.test_kpi_admin_priority:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:true:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=18] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:18:Enabled:true:Name:ClientDocstoreAdminKpi:Description:ClientDocstoreAdminKpiTest:Login:cn%3Ddoc.test_kpi_admin:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=19] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:19:Enabled:true:Name:LdapOverloadAdminPriorityClient:Description:TestLdapOverloadAdminPriorityClient:Login:cn%3Ddoc.ldap_overload_admin_priority:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=20] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:20:Enabled:true:Name:LdapOverloadHighPriorityClient:Description:TestLdapOverloadHighPriorityClient:Login:cn%3Ddoc.ldap_overload_high_priority:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:2:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=21] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:21:Enabled:true:Name:LdapOverloadLowPriorityClient:Description:TestLdapOverloadLowPriorityClient:Login:cn%3Ddoc.ldap_overload_low_priority:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=22] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:22:Enabled:true:Name:LdapOverloadNoPriorityClient:Description:TestLdapOverloadNoPriorityClient:Login:cn%3Ddoc.ldap_overload_no_priority:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:1:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=23] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:23:Enabled:true:Name:ClientDocstoreKpiIndexing:Description:ClientDocstoreKpiIndexingTest:Login:cn%3Ddoc.test_kpi_indexing:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=24] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:24:Enabled:true:Name:DocstoreAdmin:Description:DocstoreAdmin:Login:cn%3Ddoc.test_admin:Password:docsecret:AppGroup::SchemaName:docstore%3A4712:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:true:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=25] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:25:Enabled:true:Name:ClientDocstoreReplication:Description:ClientDocstoreReplicationTest:Login:cn%3Ddoc.test_replication:Password:docsecret:AppGroup::SchemaName:docstore-replication-profile-test%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=26] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:26:Enabled:true:Name:ClientDocstoreReplicationIndexing:Description:ClientDocstoreReplicationIndexingTest:Login:cn%3Ddoc.test_rep_Indexing:Password:docsecret:AppGroup::SchemaName:docstore-replication-profile-test%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=27] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:27:Enabled:true:Name:ClientDocstoreIndexingTest:Description:Test+Client+for+DocStore+Indexing+Use+Case:Login:cn%3Ddoc.stratumtest_index:Password:docsecret:AppGroup::SchemaName:docstore-stratum-test%3A4712:Priority:1:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=28] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:28:Enabled:true:Name:ClientDocstoreNotificationTest:Description:Test+Client+for+DocStore+Notification+Use+Case:Login:cn%3Ddoc.test_notification:Password:docsecret:AppGroup::SchemaName:notification-app1%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=29] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:29:Enabled:true:Name:ClientDocstoreVoWiFiTest:Description:Test+Client+for+DocStore+VoWiFi+Use+Case:Login:cn%3Ddoc.test_vowifi:Password:docsecret:AppGroup::SchemaName:VoWiFi%3A5:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=30] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:30:Enabled:true:Name:ClientDocstoreCAAATest:Description:Test+Client+for+DocStore+cAAA+Use+Case:Login:cn%3Ddoc.test_caaa:Password:docsecret:AppGroup::SchemaName:mAAA-Core-Pilot%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=31] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:31:Enabled:true:Name:ClientDocstorecAAAView:Description:Client+for+DocStore+cAAA-Subscriber+View-User+Prio+3:Login:cn%3Ddoc.test_caaa_view_index:Password:docsecret:AppGroup::SchemaName:view-on-mAAA-Core-Pilot%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=32] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:32:Enabled:true:Name:ClientDocstoreUdNotificationTests:Description:Test+Client+for+DocStore+Ud+Notification+Use+Cases:Login:cn%3Ddoc.test_ud_notification:Password:docsecret:AppGroup::SchemaName:ud-notification-app1%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=33] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:33:Enabled:true:Name:ClientDocstoreKpiView:Description:ClientDocstoreKpiViewTest:Login:cn%3Ddoc.test_kpi_view:Password:docsecret:AppGroup::SchemaName:view-on-docstore-kpi-test:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=34] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:34:Enabled:true:Name:ClientDocstoreDataRepair:Description:ClientDocstoreDataRepairTest:Login:cn%3Ddoc.test_repair:Password:docsecret:AppGroup::SchemaName:docstore-data-repair-test%3A1:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=35] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:35:Enabled:true:Name:ClientDocstoreEntryAliasing:Description:ClientDocstoreEntryAliasingTest:Login:cn%3Ddoc.test_entry:Password:docsecret:AppGroup::SchemaName:docstore-entry%3A4715:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=36] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:36:Enabled:true:Name:ClientDocstoreLocalRead_preferred:Description:ClientDocstoreLocalRead_preferred:Login:cn%3Ddoc.test_localPreferred:Password:docsecret:AppGroup::SchemaName:docstore-local-read%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:preferred:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=37] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:37:Enabled:true:Name:ClientDocstoreLocalRead_never:Description:ClientDocstoreLocalRead_never:Login:cn%3Ddoc.test_localNever:Password:docsecret:AppGroup::SchemaName:docstore-local-read%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=38] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:38:Enabled:true:Name:ClientDocstoreLocalRead_byControl:Description:ClientDocstoreLocalRead_byControl:Login:cn%3Ddoc.test_byControl:Password:docsecret:AppGroup::SchemaName:docstore-local-read%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:bycontrol:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=39] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:39:Enabled:true:Name:ClientDocstoreAccessControl:Description:ClientDocstoreAccessControl:Login:cn%3Ddoc.test_kpi_access_view:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-access-control-view:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=40] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:40:Enabled:true:Name:ClientDocstoreAccessControlRestricted:Description:ClientDocstoreAccessControlRestricted:Login:cn%3Ddoc.test_kpi_access_view_restricted:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-access-control-view-restricted:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=41] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:41:Enabled:true:Name:ClientDocstoreEntryViewAliasing:Description:ClientDocstoreEntryViewAliasingTest:Login:cn%3Ddoc.test_entryView:Password:docsecret:AppGroup::SchemaName:view-on-docstore-entry%3A4715:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=42] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:42:Enabled:true:Name:ClientDocstoreIndexes:Description:ClientDocstoreIndexes:Login:cn%3Ddoc.test_kpi_indexes:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-indexes:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=43] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:43:Enabled:true:Name:ClientDocstoreKPILocalRead:Description:ClientDocstoreKPILocalRead:Login:cn%3Ddoc.test_kpi_localread:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-localread:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:preferred:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=44] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:44:Enabled:true:Name:ClientDocstoreKPIBackupLocalReadPersistence:Description:ClientDocstoreKPIBackupLocalReadPersistence:Login:cn%3Ddoc.test_kpi_backup_localread_persistence:Password:docsecret:AppGroup::SchemaName:docstore-kpi-test-backup-localread-persistence:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:preferred:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=45] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:45:Enabled:true:Name:ClientDocstoreSchemaManagement:Description:ClientDocstoreSchemaManagementTest:Login:cn%3Ddoc.test_schmgmt:Password:docsecret:AppGroup::SchemaName:docstore-schmgmt-test:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=46] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:46:Enabled:true:Name:ClientDocstoreSchemaManagementView:Description:ClientDocstoreSchemaManagementViewTest:Login:cn%3Ddoc.test_schmgmt_view:Password:docsecret:AppGroup::SchemaName:view-on-schmgmt-test:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=47] Complex//SDMCE/DocStoreClients/LDAP/DocStoreClientCfg/CFG_GROUP_ID:47:Enabled:true:Name:ClientDocstoreSchemaManagementViewPilot:Description:ClientDocstoreSchemaManagementViewPilotTest:Login:cn%3Ddoc.test_schmgmt_pilot:Password:docsecret:AppGroup::SchemaName:view-on-schmgmt-test%3A2:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:EraseStoreAllowed:false:AllowLocalRead:never:MetaInResponse:false'

# SBI Clients
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//SDMCE/DocStoreClients/SBI/DocStoreClientCfg/CFG_GROUP_ID:1:Enabled:true:Name:nudr-dr-v2:Description:ClientDocstoreSbiNudrTest:Login:nudr-dr-v2:Password:docsecret:AppGroup::SchemaName:Nudr_DataRepository%3A2.1.7:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:MetaInResponse:false'
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=2] Complex//SDMCE/DocStoreClients/SBI/DocStoreClientCfg/CFG_GROUP_ID:2:Enabled:true:Name:nudsf-dr-v1:Description:ClientDocstoreSbiNudsfTest:Login:nudsf-dr-v1:Password:docsecret:AppGroup::SchemaName:Nudsf_DataRepository%3A1.0.4:Priority:3:TableScanAllowed:true:SubtreeDelete:false:IgnoreCriticalLockRequest:false:MetaInResponse:false'
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=3] Complex//SDMCE/DocStoreClients/SBI/DocStoreClientCfg/CFG_GROUP_ID:3:Enabled:true:Name:builtin-v1:Description:ClientDocstoreSbiBuiltInTest:Login:builtin-v1:Password:docpass:AppGroup::SchemaName:Builtin_DataRepository%3A1:Priority:3:TableScanAllowed:false:SubtreeDelete:false:IgnoreCriticalLockRequest:false:MetaInResponse:false'

# Multi cache support
$OAMCLI 'update Complex//SDMCE/BackwardCompatibility/MinimumReleaseVersionCompatibility:4.3.0'

# CSM Redundancy
$OAMCLI 'update Complex//CSM/Inter-siteReplication/CsmRedundancy:1'

# Overload Protection
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=ADMIN_PRIORITY] Complex//Cluster/AdaptiveThrottling/OverloadThresholds/CFG_GROUP_ID:ADMIN_PRIORITY:Priority:1:ThresholdSensitivity:1.5:OverloadProbabilityThreshold:50:CPUThreshold:NONE'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=HIGH_PRIORITY] Complex//Cluster/AdaptiveThrottling/OverloadThresholds/CFG_GROUP_ID:HIGH_PRIORITY:Priority:2:ThresholdSensitivity:1.5:OverloadProbabilityThreshold:50:CPUThreshold:HIGH'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=LOW_PRIORITY] Complex//Cluster/AdaptiveThrottling/OverloadThresholds/CFG_GROUP_ID:LOW_PRIORITY:Priority:3:ThresholdSensitivity:1.5:OverloadProbabilityThreshold:50:CPUThreshold:LOW'

# ILD plugin startup time
$OAMCLI 'update Complex/ILDElement//ILDTrafficServer/plugin.startup_time:100'

# Trace logging

$OAMCLI 'update Complex//SDMCE/DocStoreLogging/EnableDocTraceLogging:true'
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=LOW_PRIORITY] Complex//SDMCE/DocStoreTracing/TraceProfiles/CFG_GROUP_ID:DEFAULT:TraceProfileName:default:TraceNotFound:true:TraceTimeout:true'

# Schemas

export EMS_USER=rest
export EMS_PASSWORD=restpass
export EMS_System_Name=SdmceSystem

cd /tmp
python3 /opt/opwv/oam/*/tools/schema/YAMLtoEMS.py -i ./docstore-test.yaml - -

$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/docstore/SchemaActive:4712'
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/docstore/SchemaEnabled:true'

python3 /opt/opwv/oam/*/tools/schema/YAMLtoEMS.py -i ./docstore-Nudr-DataRepository-att.yaml - -
python3 /opt/opwv/oam/*/tools/schema/YAMLtoEMS.py -i ./docstore-Nudsf-DataRepository.yaml - -

$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Nudr_DataRepository/SchemaActive:2.1.7'
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Nudr_DataRepository/SchemaEnabled:true'
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Nudsf_DataRepository/SchemaActive:1.0.4'
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Nudsf_DataRepository/SchemaEnabled:true'

python3 /opt/opwv/oam/*/tools/schema/YAMLtoEMS.py -i ./docstore-Builtin-DataRepository.yaml - -
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Builtin_DataRepository/SchemaActive:1'
$OAMCLI 'update Complex//SDMCE/SchemaManagement/SchemaEntriesCore/Builtin_DataRepository/SchemaEnabled:true'
