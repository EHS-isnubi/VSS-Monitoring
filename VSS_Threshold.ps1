# =======================================================
#
# NAME: VSS_Threshold.ps1
# AUTHOR: GAMBART Louis
# DATE: 18/10/2022
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


# value of the threshold in Gb
$threshold = "0"

# get the name of the host
$hostname = $env:COMPUTERNAME


# ====================== FUNCTIONS ======================


function getVSSusage {
    $DiskSpaceUsed = Get-CimInstance -ClassName Win32_ShadowStorage | Select-Object @{n = "Used (GB)"; e = { [math]::Round([double]$_.UsedSpace / 1GB, 3) } }, @{n = "Max (GB)"; e = { [math]::Round([double]$_.MAxSpace / 1GB, 3) } }, *
    $HealthState = foreach ($Disks in $DiskSpaceUsed) {
        $Volume = Get-Volume -UniqueId $DiskSpaceUsed.Volume.DeviceID
        $DiskSize = [math]::Round([double]$volume.Size / 1GB, 3)
        $diskremaining = [math]::Round([double]$volume.SizeRemaining / 1GB, 3)
        if ($Disks.'Used (GB)' -gt $threshold) {
            "Disk $($Volume.DriveLetter) snapshot size is higher than $Threshold. The disk size is $($diskSize) and it has $($diskremaining) remaining space. The max snapshot size is $($Disks.'Max (GB)')"
        }
    }
    if (!$HealthState) {
        Write-Host "All disks are healthy"
    }
    else {
        Write-Host $HealthState
    }
}


# ======================== SCRIPT =======================


Write-Host "Starting script for $hostname"
getVSSusage


# ====================== END SCRIPT =====================
