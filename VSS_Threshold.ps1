#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$Threshold
)
#==========================================================================================
#
# SCRIPT NAME        :     VSS_Threshold.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.10.17
# RELEASE            :     v2.1.0
# USAGE SYNTAX       :     .\VSS_Threshold
#
# SCRIPT DESCRIPTION :     This script check the usage of VSS and print warning if it exceed threshold
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# 1.0.0  2022.10.17 - Louis GAMBART - Initial version
# 2.0.0  2022.10.31 - Louis GAMBART - Rework to follow Enable_VSS script
# 2.1.0  2022.10.31 - Louis GAMBART - Fix mistake in unit of threshold, add snapshot size in output
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# get the name of the host
$hostname = $env:COMPUTERNAME


####################
#                  #
#  II - FUNCTIONS  #
#                  #
####################

function getVSSusage {
    <#
    .SYNOPSIS
    Get the usage of VSS on the host
    .DESCRIPTION
    Get the usage of VSS on the host through WMI Shadow Copy Object
    .INPUTS
    System.String: Threshold
    .OUTPUTS
    None
    .EXAMPLE
    getVSSusage -Threshold "80"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Threshold
    )
    $DiskSpaceUsed = Get-CimInstance -ClassName Win32_ShadowStorage | Select-Object @{n = "Used (GB)"; e = { [math]::Round([double]$_.UsedSpace / 1GB, 3) } }, @{n = "Max (GB)"; e = { [math]::Round([double]$_.MAxSpace / 1GB, 3) } }, *
    $HealthState = foreach ($Disks in $DiskSpaceUsed) {
        $Volume = Get-Volume -UniqueId $DiskSpaceUsed.Volume.DeviceID
        $DiskSize = [math]::Round([double]$volume.Size / 1GB, 3)
        $diskremaining = [math]::Round([double]$volume.SizeRemaining / 1GB, 3)
        if ($Disks.'Used (GB)' -gt $Threshold) {
            Write-Host "Disk $($Volume.DriveLetter) snapshot size is higher than $Threshold. The disk size is $($diskSize) and it has $($diskremaining) remaining space. The max snapshot size is $($Disks.'Max (GB)')"
            Write-Host "The snapshot size is $($Disks.'Used (GB)')"
        }
    }
    if (!$HealthState) {
        Write-Host "All disks are healthy"
    }
    else {
        Write-Host $HealthState
    }
}


############################
#                          #
#  III - SCRIPT EXECUTION  #
#                          #
############################

if ($Threshold -notmatch "^[0-9]+$") { Write-Host "Please enter a valid threshold number, in GB" }
else {
    Write-Host "Starting script for $hostname"
    getVSSusage -Threshold $Threshold
}