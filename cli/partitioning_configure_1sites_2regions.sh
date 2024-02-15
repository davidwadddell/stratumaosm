#!/usr/bin/bash

# This script is used to configure the SDMCE system. It is intended to be run on the SDMCE system itself.
# The script assumes that the SDMCE system is already installed and running.

ems_version=$(ls /opt/opwv/oam)
OAMCLI="/opt/opwv/oam/${ems_version}/bin/OamCommandLine -u rest -p restpass -h localhost -s SdmceSystem -d opwvconfig -c"

# Partitioning

# Schema And Type Configuration

$OAMCLI 'deleteCfg Complex//Partitioning/SchemaTypeConfiguration/[CFG_GROUP_ID=1]'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/SchemaTypeConfiguration/CFG_GROUP_ID:1:SchemaName:Nudr_DataRepository%3Aactive'
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/SchemaTypeConfiguration/1/RecordTypes/CFG_GROUP_ID:1:RecordType:subscription-data_TS29505_Subscription_Data:Redundancy:profile100sync-partitioned:Key:ueId'
$OAMCLI 'addList Complex//Partitioning/SchemaTypeConfiguration/1/RecordTypes/1/ForwardingIndexes/servingPlmnId%2FprovisionedData%2FamData%2Fgpsis'

# UDR Sites

$OAMCLI 'deleteCfg Complex//Partitioning/GeoRegions/[CFG_GROUP_ID=1]'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/GeoRegions/CFG_GROUP_ID:1:GeoRegion:EAST'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/GeoRegions/1/UDRSites/CFG_GROUP_ID:1:UDRSiteId:site1'
$OAMCLI 'addList Complex//Partitioning/GeoRegions/1/UDRSites/1/StratumRegions/region1'
$OAMCLI 'addList Complex//Partitioning/GeoRegions/1/UDRSites/1/StratumRegions/region2'

# SUPI Ranges

# Delete old ones
$OAMCLI 'deleteCfg Complex//Partitioning/SupiRanges/[CFG_GROUP_ID=1]'

# Input new ones
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/SupiRanges/CFG_GROUP_ID:1:VirtualPartitionId:0'
$OAMCLI 'addList Complex//Partitioning/SupiRanges/1/SupiRanges/%5Eimsi-%5B0-9%5D%7B15%7D%24'

# Partition Groups

# Delete existing
$OAMCLI "deleteCfg Complex//Partitioning/PartitionGroups/[CFG_GROUP_ID=1]"

# Group 1
$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/PartitionGroups/CFG_GROUP_ID:1:PartitionGroupId:site1'

$OAMCLI 'addGroupOnlyIfNotExists [CFG_GROUP_ID=1] Complex//Partitioning/PartitionGroups/1/Partitions/CFG_GROUP_ID:1:PartitionId:1:UDRSiteId:site1:StratumRegion:region1'
$OAMCLI 'addList Complex//Partitioning/PartitionGroups/1/Partitions/1/VirtualPartitions/0'


