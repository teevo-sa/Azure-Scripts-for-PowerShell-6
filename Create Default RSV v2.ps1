####################################################################
#
# .Description
#   Script used for deplou a defalult Recovery Service Vault.
#
####################################################################
# .Author:  Alexandre E. Knorst
####################################################################

###### User definition ######
$CUSTOMER_FULL = "FINOTOC"

##### Preparing variables ##########################################
$LOCATION = "East US 2"
$RSV_NAME = "RSV-" + $CUSTOMER_FULL
$RSG_BACKUP = "GRPRD-" + $CUSTOMER_FULL + "-BACKUP"
$PLAN_NAME = "PLAN-BKP-" + $CUSTOMER_FULL +"-Default"
####################################################################

#### Validating Resource Group ####
$RSG = Get-AzResourceGroup -Name $RSG_BACKUP -Location $LOCATION

if (!$?) {
    $RSG = New-AzResourceGroup -Name $RSG_BACKUP -Location $LOCATION
}

#### Creating Recovery Services Vault 
$RSV =  New-AzRecoveryServicesVault -Name $RSV_NAME  -ResourceGroupName $RSG.ResourceGroupName  -Location $LOCATION
Set-AzRecoveryServicesBackupProperties -Vault $RSV -BackupStorageRedundancy LocallyRedundant

#### Preparing next backup time
$TODAY = Get-Date
$KIND = new-object System.DateTimeKind
$KIND.value__ = 1 # UTC
$DATE = New-Object system.datetime($TODAY.Year,$TODAY.Month,$TODAY.Day,22,00,00,$KIND)

$SCHED 		= Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM -BackupManagementType AzureVM
$SCHED.ScheduleRunTimes[0] = $DATE

#### Setting retentions
$RETENTION 	= Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM -BackupManagementType AzureVM
$RETENTION.IsYearlyScheduleEnabled = $false
$RETENTION.DailySchedule.DurationCountInDays = 15
$RETENTION.WeeklySchedule.DurationCountInWeeks = 5
$RETENTION.MonthlySchedule.DurationCountInMonths = 6
$RETENTION.MonthlySchedule.RetentionScheduleFormatType = 'Daily'
$RETENTION.MonthlySchedule.RetentionScheduleDaily[0].DaysOfTheMonth[0].Date = 0
$RETENTION.MonthlySchedule.RetentionScheduleDaily[0].DaysOfTheMonth[0].isLast = $true

#### Creating default backup policy
New-AzRecoveryServicesBackupProtectionPolicy -Name $PLAN_NAME -WorkloadType AzureVM -BackupManagementType AzureVM -RetentionPolicy $RETENTION -SchedulePolicy $SCHED -VaultId $RSV.ID
