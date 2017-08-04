<#	
.NOTES
===========================================================================
 Created on:   	8/3/2017 9:01 PM
 Created by:   	Anthony Clendenen
 Organization: 	AnthonyOnAzure
 Filename:     	ASRAutomatedSetup.ps1
===========================================================================
.DESCRIPTION
	This PowerShell script will build out Azure Site Recovery.  
	It builds a new resource group, storage account, Vnet and subnet and
	Recovery Services Vault.  It then creates the replication and reovery
	policy while enabling them.  This is intended for protecting VMware and 
	physical servers but can be modfied easily for VMM, Hyper-V and Azure.
#>

$Location = 'westus'
$RgName = "asr-tst-002"
$StorAcctName = "asrstor002"
$Directory = "C:\Temp\"

if (!(Test-Path $Directory -PathType Container))
{
	New-Item -ItemType Directory -Force -Path $Directory
}

Login-AzureRmAccount -Credential (get-credential -Credential username@email.com)

# New Resource Group
$AsrRG = New-AzureRmResourceGroup -Name $RgName -Location $Location

# New Storage account
$AsrStor = New-AzureRmStorageAccount -ResourceGroupName $RgName -Name $StorAcctName -Location $Location -SkuName Standard_LRS

# Create Recovery Vnet and subnet 
$RecoverySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name RecoverySubnet -AddressPrefix "172.16.1.0/24"
$RecoveryVnet = New-AzureRmVirtualNetwork -ResourceGroupName $RgName -Name 'RecoveryVnet' -AddressPrefix '172.16.0.0/21' -Location $Location -Subnet $RecoverySubnet

# Create New Recovery Services Vault
$Vault = New-AzureRmRecoveryServicesVault -Name $RgName -ResourceGroupName $RgName -Location $Location

# Build Vault Key - Path is local to PowerShell execution
Get-AzureRmRecoveryServicesVaultSettingsFile -Vault $Vault -Path $Directory

# Find the file name of the vault credentials
$VaultCredentials = Get-childitem $Directory *.VaultCredentials
# Join the Path and Filename
$ImportPath = Join-path -Path $Directory -ChildPath $VaultCredentials.Name

# Import the vault settings
Import-AzureRmSiteRecoveryVaultSettingsFile -Path $ImportPath

<#
Download Config server http://aka.ms/unifiedsetup

Extract Config server install files on VMware VM to c:\Temp\Extracted
c:\temp\MicrosoftAzureSiteRecoveryUnifiedSetup.exe /q /xC:\Temp
cd C:\Temp\Extracted
#>
<# 
Before creating credentials file for MySql change the "Password" for the MySQL root and user by updating the Add-Content command.

Without changing the Add-Content cmd this would be the output of the New-Item and Add-Content cmds

MySQLCredentialsfile.txt

[MySQLCredentials]
MySQLRootPassword = "Password"
MySQLUserPassword = "Password"
#>
<#
# Create MySql Credentials text file
New-Item c:\Temp\MySQLCredentialsfile.txt -type file -force -value "[MySQLCredentials]"
Add-Content c:\Temp\MySQLCredentialsfile.txt "`nMySQLRootPassword = `"Password`"`rMySQLUserPassword = `"Password`""

# Installing and registering a Configuration Server using Command line
# UNIFIEDSETUP.EXE /AcceptThirdpartyEULA /servermode "CS" /InstallLocation "I:\" /MySQLCredsFilePath "C:\Temp\MySQLCredentialsfile.txt" /VaultCredsFilePath "c:\temp\asr\asr-test-001_2017-08-01T17-15-01.VaultCredentials" /EnvType "VMWare"

# Install Mobility Service on VMware VMs from a command prompt
# https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-vmware-to-azure-install-mob-svc#install-mobility-service-manually-at-a-command-prompt
# Download and install the agent on the Hyper-V host(s) from this URL: https://aka.ms/downloaddra
#>

# Enable replication for vault
$ReplicationFreq = "300"
$PolicyName = $RgName
$RecoveryPoints = 1

# Create Site Recovery and Replication Policy 
$SiteRecoveryPolicy = New-AzureRmSiteRecoveryPolicy -Name $PolicyName -ReplicationFrequencyInSeconds $ReplicationFreq -RecoveryPoints $RecoveryPoints -ReplicationProvider HyperVReplicaAzure -ApplicationConsistentSnapshotFrequencyInHours 1

# Get the Protection Container
$ProtectionContainer = Get-AzureRmSiteRecoveryProtectionContainer

$Policy = Get-AzureRmSiteRecoveryPolicy -FriendlyName $PolicyName

# Create the Container Mapping
$ContainerMapping = New-AzureRmSiteRecoveryProtectionContainerMapping -Name $RgName -Policy $Policy -PrimaryProtectionContainer $ProtectionContainer
