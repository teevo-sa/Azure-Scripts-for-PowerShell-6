## 
#
# Criando VM Linux 
#
##

# Local
$LOCATION = "East US 2"

# Grupo de Recurso
$RSG_NAME = "GRPRD-CUSTOMER-SERVICO"

# VM Name (nao pode ser maior que 15 caracteres)
$VMNAME = "VMW-DNMZ-W01"

# VM Size
$VMSIZE = "Standard_B2MS"

# Disk kind
$STG_KIND = "Standard_LRS" 

# Configuração da VNET (Validar com a que existe no portal)
$VNET =  "VNET-DINAMIZE"
$SUBNET = "default"

$IP = "172.21.32.50"

$ADMIN_PASSWORD = 'tJb3N$hN76@Gd#qrh4zjY*v75!AH+Gh23v7Fy%5AsE48'
$ADMIN_USER = "dnmz_admin"

##### 
#  Preparing variables .. 
#####

# Storage Account_Name 
$STGNAME = "stg" + ($VMNAME.Replace("-", "")).ToLower()

# Linux Version
$PUBLISHER= "MicrosoftWindowsServer"
$OFFER = "WindowsServer"
$SKU = "2016-Datacenter"
$VERSION = "latest"

#####

function Get-Subnet () {
    $RETURN_SUBNET = ""    
    $VNETs = Get-AzVirtualNetwork
    foreach ($VN in $VNETs) { 
        if ($VN.Name -eq $VNET) {
            $SUBNETs = $VN | Get-AzVirtualNetworkSubnetConfig
            foreach ($SUB in $SUBNETs) {
                if ($SUB.Name -eq $SUBNET) {
                    $RETURN_SUBNET = $SUB                    
                }                 
            }
        }
    }
    $RETURN_SUBNET
}

#### Validating Resource Group ####
$RSG = Get-AzResourceGroup -Name $RSG_NAME -Location $LOCATION

if (!$?) {
    $RSG = New-AzResourceGroup -Name $RSG_NAME -Location $LOCATION
}

#### Validating Storage Account ####
$STG = Get-AzStorageAccount -ResourceGroupName $RSG.ResourceGroupName -Name $STGNAME
if (!$?) {
    $STG = New-AzStorageAccount -ResourceGroupName $RSG.ResourceGroupName -Name $STGNAME -SkuName $STG_KIND -Location $LOCATION -Kind StorageV2 -AccessTier Hot
}

# Criando container
$STG_CONTAINER = Get-AzStorageContainer -Context $STG.Context -Name "vhds" 
if (!$?) {
    $STG_CONTAINER = New-AzStorageContainer -Context $STG.Context -PublicAccess Blob -Name "vhds"
}

# Configurando a NIC # 
$SUB = Get-Subnet
$IPconfig = New-AzNetworkInterfaceIpConfig  -Name ("IPconfig-"+$VMNAME) -PrivateIpAddressVersion IPv4 -PrivateIpAddress $IP -Subnet $SUB
$NIC = New-AzNetworkInterface -Name ($VMNAME + "-NIC") -ResourceGroupName $RSG.ResourceGroupName -Location $LOCATION -IpConfiguration $IPconfig

# Criando o disco
$OSDisk = $STG.PrimaryEndpoints.Blob.ToString() + "vhds/" + $VMNAME + "-OSDISK.vhd"

#  Criando credencias de acesso
$SecurePassword = ConvertTo-SecureString $ADMIN_PASSWORD -AsPlainText -Force
$CRED = New-Object System.Management.Automation.PSCredential ($ADMIN_USER, $SecurePassword)

# Criando VM
$VM = New-AzVMConfig -VMName $VMNAME -VMSize $VMSIZE 
$VM = Set-AzVMOperatingSystem -VM $VM -Windows -ComputerName $VMNAME -Credential $CRED
$VM = Set-AzVMSourceImage -VM $VM -PublisherName $PUBLISHER -Offer $OFFER -Skus $SKU -Version $VERSION
$VM = Set-AzVMOSDisk -VM $VM -Name ($VMNAME + "-OSDISK") -VhdUri $OSDisk -Caching ReadOnly -CreateOption fromImage -DiskSizeInGB $DISK_SIZE
$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id

New-AzVM -VM $VM -ResourceGroupName $RSG.ResourceGroupName -Location $LOCATION -Verbose
