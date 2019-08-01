## 
# Criando VM Windows com discos Gerenciados.
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
$DISK_SIZE = 128  # Tamanho em GB 

# Configuração da VNET (Validar com a que existe no portal)
$VNET =  "VNET-DINAMIZE"
$SUBNET = "default"
$IP = "172.21.32.50"

# Credencias de Acesso
$ADMIN_USER = "dnmz_admin"
$ADMIN_PASSWORD = 'tJb3N$hN76@Gd#qrh4zjY*v75!AH+DdfedsGh23v7Fy%5AsE48'

##### 
#  Preparing variables .. 
#####

# Windows Version
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

# Configurando a NIC # 
$SUB = Get-Subnet
$IPconfig = New-AzNetworkInterfaceIpConfig  -Name ("IPconfig-"+$VMNAME) -PrivateIpAddressVersion IPv4 -PrivateIpAddress $IP -Subnet $SUB
$NIC = New-AzNetworkInterface -Name ($VMNAME + "-NIC") -ResourceGroupName $RSG.ResourceGroupName -Location $LOCATION -IpConfiguration $IPconfig

#  Criando credencias de acesso
$SecurePassword = ConvertTo-SecureString $ADMIN_PASSWORD -AsPlainText -Force
$CRED = New-Object System.Management.Automation.PSCredential ($ADMIN_USER, $SecurePassword)

# Criando VM
$VM = New-AzVMConfig -VMName $VMNAME -VMSize $VMSIZE 
$VM = Set-AzVMOperatingSystem -VM $VM -Windows -ComputerName $VMNAME -Credential $CRED
$VM = Set-AzVMSourceImage -VM $VM -PublisherName $PUBLISHER -Offer $OFFER -Skus $SKU -Version $VERSION
$VM = Set-AzVMOSDisk -VM $VM -Name ($VMNAME + "-OSDisk") -CreateOption fromImage -Windows -DiskSizeInGB $DISK_SIZE -StorageAccountType $STG_KIND
$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id

New-AzVM -VM $VM -ResourceGroupName $RSG.ResourceGroupName -Location $LOCATION -Verbose
