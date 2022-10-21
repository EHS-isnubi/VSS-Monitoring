# =======================================================
#
# NAME: Enable_VSS.ps1
# AUTHOR: GAMBART Louis
# DATE: 21/10/2022
# VERSION 1.0
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
#
# =======================================================



# ====================== VARIABLES ======================


# clear error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME


# variable for the cmdlet
$task = "C:\Windows\System32\vssadmin.exe"
$workingDir = "%systemroot%\system32"
$taskName = "Enable VSS on host"


# ====================== FUNCTIONS ======================


function Get-Device-ID {
    <#
    .SYNOPSIS
    Get the device ID of the disk
    .DESCRIPTION
    Get the device ID of the disk
    .INPUTS
    diskname (string)
    .OUTPUTS
    deviceID (string)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DiskName
    )
    $volumeWMI = Get-WmiObject Win32_Volume -Namespace root/cimv2 | ?{ $_.Name -eq $DiskName }
    $deviceID = $volumeWMI.DeviceID.toUpper().Replace("\\?\Volume", "").Replace("\", "")
    return $deviceID
}


function Enable-VSS {
    <#
    .SYNOPSIS
    Enable VSS on the host
    .DESCRIPTION
    Enable VSS on the host through scheduled task and vssadmin cmdlet
    .INPUTS
    TaskName (string)
    Task (string)
    WorkingDir (string)
    Arguments (string)
    .OUTPUTS
    None.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Task,
        [String]$WorkingDirectory,
        [String]$Arguments,
        [String]$TaskName
    )
    $scheduledAction = New-ScheduledTaskAction -Execute $Task -Argument $Arguments `
    -WorkingDirectory $WorkingDirectory
    $scheduledTrigger = New-ScheduledTaskTrigger -AtLogOn
    $scheduledSettings = New-ScheduledTaskSettingsSet -Compatibility V1 -DontStopOnIdleEnd -ExecutionTimeLimit `
    (New-TimeSpan -Minutes 30) -Priority 5
    $scheduledTask = New-ScheduledTask -Action $scheduledAction -Trigger $scheduledTrigger `
    -Settings $scheduledSettings
    Register-ScheduledTask $TaskName -InputObject $scheduledTask -User "NT AUTHORITY\SYSTEM"
}


# ======================== SCRIPT =======================


Write-Host "Starting script on $hostname"
$deviceID = Get-Device-ID -diskName "C:\"
$taskFor = "\\?\Volume" + $deviceID  + "\"
$taskArgument = "create shadowstorage /autoretry=15 /for=$taskFor"
Enable-VSS -Task $task -WorkingDirectory $workingDir -Arguments $taskArgument -TaskName $taskName


# ====================== END SCRIPT =====================