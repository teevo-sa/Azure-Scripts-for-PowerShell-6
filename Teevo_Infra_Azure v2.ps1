##########################################################################################
#
#  Cria Infra basica Azure
#  Alexandre E. Knorst {alexandre.knorst@teevo.com.br}
# 
##########################################################################################

##########################################################################################
#  Antes de executar o script é necessario se logar no Azure e setar a assinatura
#  Exemplo:
#     Login-AzAccount -Subscription "Azure - Cristalpet"
##########################################################################################


#############################################
###  Basic Configurations ###
#############################################

# Region (East US 2, Brazil South, West US 2, ... )
$LOCATION = "East US 2"

# Nome do cliente 
$CUSTOMER_FULL = "ECBAHIA"
$CUSTOMER_SHORT = "ECB"

#### Network ####
# Network Definitions
$NETWORK = "172.20.0.0/20"
$NETWORK_DEFAULT = "172.20.0.0/24"

# Management allowed full Network
$MGMT_NETWORK = "186.237.31.154 186.237.28.64/28"

#############################################
###  END::  Basic Configurations ###
#############################################


# Main Resource Group
$RSG_MAIN = "GRPRD-" + $CUSTOMER_FULL

# Parametros para VNET
$VNET_NAME = "VNET-" + $CUSTOMER_FULL

### Network Security Group
$NSG_MAIN = "NSG-" + $CUSTOMER_FULL

# Diagnostic Storage Account
$STG_DIAG = "stg" + $CUSTOMER_SHORT.ToLower() + "diag"

# Creating Main Resouce Group
$RSG = New-AzResourceGroup -Name $RSG_MAIN -Location $LOCATION

# Adding LOCK for Remove
New-AzResourceLock -LockName DONT_DELETE -LockLevel CanNotDelete -ResourceGroupName $RSG_MAIN -LockNotes "Dont allow remove Items" -Force

# Creating Virtual Network
$VNET_SUBNET = New-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix $NETWORK_DEFAULT
$VNET = New-AzVirtualNetwork -Name $VNET_NAME -ResourceGroupName $RSG_MAIN -AddressPrefix $NETWORK -Location $LOCATION -Subnet $VNET_SUBNET
 
# Creating Network Security Group
$NSG_GROUP = New-AzNetworkSecurityGroup -Location $LOCATION -Name $NSG_MAIN -ResourceGroupName $RSG_MAIN

$RULE = 1;
$MGMT_NETWORK.Split(" ") | foreach {
    $PRIORITY = 1000 + $RULE
    Add-AzNetworkSecurityRuleConfig -Name "Allow_MGMT_Teevo_$RULE" -NetworkSecurityGroup $NSG_GROUP -Access Allow -Description "Management Network - Teevo $_" -DestinationAddressPrefix * -DestinationPortRange * -Direction Inbound -Priority $PRIORITY -Protocol * -SourceAddressPrefix "$_" -SourcePortRange "*"
    $RULE++
}
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSG_GROUP

# Creating Diagnostic Storage
New-AzStorageAccount -ResourceGroupName $RSG_MAIN -Name $STG_DIAG -SkuName Standard_LRS -Location $LOCATION
