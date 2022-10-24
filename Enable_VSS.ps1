#Requires -RunAsAdministrator
# =======================================================
#
# NAME: Enable_VSS.ps1
# AUTHOR: GAMBART Louis
# DATE: 24/10/2022
# VERSION 1.1
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
# 1.1: Change to work on all Windows versions (not only on windows server)
#
# =======================================================



# ====================== VARIABLES ======================


# clear error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# the disk to enable VSS on
$diskName = "C:\"


# ====================== FUNCTIONS ======================


function Get-VSS-Status {
    <#
    .SYNOPSIS
    Check if VSS is enabled on the host
    .DESCRIPTION
    Check if VSS is enabled on the host through WMI Shadow Copy Object
    .INPUTS
    VSS (cmdlet query)
    DiskName (string)
    .OUTPUTS
    Boolean: return true if VSS is enabled on the host
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $VSS,
        [String]$DiskName
    )
    if ($PSUICulture -eq "fr_FR") {
        if ($vss -match "^(Il n'existe aucun )") {
            return $false
        }
        else {
            foreach ($line in $vss) {
                if ($line -match "Pour le volume : \(?(C):\)\\\\\?\\Volume{(?<volume>[a-z0-9-]+)}\\") {
                    return $true
                    break
                }
            }
            return $false
        }
    }
    else {
        if ($vss -match "No shadow copies are configured") {
            return $false
        }
        else {
            foreach ($line in $vss) {
                if ($line -match "For volume: \(?(C):\)\\\\\?\\Volume{(?<volume>[a-z0-9-]+)}\\") {
                    return $true
                    break
                }
            }
            return $false
        }
    }
}


function Enable-VSS {
    <#
    .SYNOPSIS
    Enable VSS on the host
    .DESCRIPTION
    Enable VSS on the host through WMI Shadow Copy Object
    .INPUTS
    DiskName (string)
    .OUTPUTS
    None.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$DiskName
    )
    $VssWmi = Get-WmiObject -List Win32_ShadowCopy
    $VssWmi.Create($DiskName, "ClientAccessible")
}


# ======================== SCRIPT =======================


Write-Host "Starting script on $hostname"
$vss = cmd.exe /c 'vssadmin list ShadowStorage'
if (Get-VSS-Status -VSS $vss -DiskName $diskName.Substring(0,2)) {
    Write-Host "VSS is already enable on $diskName"
}
else {
    Write-Host "VSS is not enable on $diskName"
    Write-Host "Enabling VSS on $diskName"
    Enable-VSS -DiskName $diskName
    $vss = cmd.exe /c 'vssadmin list ShadowStorage'
    if (Get-VSS-Status -VSS $vss -DiskName $diskName.Substring(0,2)) {
        Write-Host "VSS is now enable on $diskName"
    }
    else {
        Write-Host "VSS can't be enable on $diskName"
    }
}


# ====================== END SCRIPT =====================