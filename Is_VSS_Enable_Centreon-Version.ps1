#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$diskName
)
# =======================================================
#
# NAME: is_VSS_Enable_Centreon-Version.ps1
# AUTHOR: GAMBART Louis
# DATE: 27/10/2022
# VERSION 2.0
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
# 2.0: Rework to follow Enable_VSS script
#
# =======================================================



# ====================== VARIABLES ======================


# clear $error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# cmdlet to execute
$vss = cmd.exe /c "vssadmin list ShadowStorage"


# ====================== FUNCTIONS ======================


function Test-VSS {
    <#
    .SYNOPSIS
    Check if VSS is enabled on the host
    .DESCRIPTION
    Check if VSS is enabled on the host through WMI Shadow Copy Object
    .INPUTS
    System.String: DiskName
    .OUTPUTS
    System.Boolean: return true if VSS is enabled on the host
    .EXAMPLE
    Test-VSS -DiskName "C"
    True
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$DiskName
    )
    begin { $vss = cmd.exe /c 'vssadmin list ShadowStorage' }
    process {
        if ($PSUICulture -eq "fr-FR") {
            if ($vss -match "^(Il n'existe aucun )") { return $false }
            else {
                foreach ($line in $vss) {
                    if ($line -match "Pour le volume : \(?($DiskName):\)\\\\\?\\Volume{(?<volume>[a-z0-9-]+)}\\") {
                        return $true
                        break
                    }
                }
                return $false
            }
        }
        else {
            if ($vss -match "No shadow copies are configured") { return $false }
            else {
                foreach ($line in $vss) {
                    if ($line -match "For volume: \(?($DiskName):\)\\\\\?\\Volume{(?<volume>[a-z0-9-]+)}\\") {
                        return $true
                        break
                    }
                }
                return $false
            }
        }
    }
    end {}
}


# ======================== SCRIPT =======================

if ($diskName -match "^([a-zA-Z])$") {
    if (Test-Path -Path $diskName":\")
    {
        Write-Host "Starting script for $hostname"
        if (Test-VSS -DiskName $diskName) {
            Write-Host "VSS is enable on this host"
            exit 0
        }
        else {
            Write-Host "VSS is not enable on this host"
            exit 1
        }
    }
    else { Write-Host "Disk $diskName does not exist on $hostname" }
}
else { Write-Host "Disk $diskName is not a valid disk name, enter it just as a letter, like C or E" }


# ====================== END SCRIPT =====================


# ======================= CENTREON ======================

# 0 = OK
# 1 = WARNING
# 2 = CRITICAL