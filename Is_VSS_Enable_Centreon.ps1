#Requires -RunAsAdministrator
param(
[Parameter(Mandatory=$true, Position=0)]
[string]$diskName
)
#==========================================================================================
#
# SCRIPT NAME        :     is_VSS_Enable_Centreon.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.10.21
# RELEASE            :     v2.0.0
# USAGE SYNTAX       :     .\is_VSS_Enable_Centreon.ps1 -diskName "C"
#
# SCRIPT DESCRIPTION :     This script check if VSS is enable and send exit code to Centreon
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# 1.0.0  2022.10.21 - Louis GAMBART - Initial version
# 2.0.0  2022.10.27 - Louis GAMBART - Rework to follow Enable_VSS script
# 2.1.0  2022.10.31 - Louis GAMBART - Rework script header and commentary blocks
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# clear $error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# cmdlet to execute
$vss = cmd.exe /c "vssadmin list ShadowStorage"


####################
#                  #
#  II - FUNCTIONS  #
#                  #
####################

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


############################
#                          #
#  III - SCRIPT EXECUTION  #
#                          #
############################

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


################
#              #
#  SCRIPT END  #
#              #
################

##############
#            #
#  CENTREON  #
#            #
##############

# 0 = OK
# 1 = WARNING
# 2 = CRITICAL