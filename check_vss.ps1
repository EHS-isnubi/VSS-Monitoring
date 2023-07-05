#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory, Position=0)]
    [string]$diskName
)
#==========================================================================================
#
# SCRIPT NAME        :     is_VSS_Enable_Centreon.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.10.21
# RELEASE            :     v2.4.0
# USAGE SYNTAX       :     .\check_vss.ps1 -diskName "C"
#
# SCRIPT DESCRIPTION :     This script check if VSS is enable and send exit code and output to Centreon
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# v1.0.0  2022.10.21 - Louis GAMBART - Initial version
# v2.0.0  2022.10.27 - Louis GAMBART - Rework to follow Enable_VSS script
# v2.1.0  2022.10.31 - Louis GAMBART - Rework script header and commentary blocks
# v2.1.1  2022.10.31 - Louis GAMBART - Remove useless cmdlet variable (usage of begin block in function)
# v2.1.2  2022.10.31 - Louis GAMBART - Standardization of commentary blocks
# v2.2.0  2023.07.04 - Louis GAMBART - Add Get-Datetime function
# v2.2.1  2023.07.04 - Louis GAMBART - Add Write-Log function
# v2.2.2  2023.07.04 - Louis GAMBART - Add error handler
# v2.3.0  2023.07.04 - Louis GAMBART - Add output for Centreon
# v2.3.1  2023.07.05 - Louis GAMBART - Change invalid disk name from error to unknown
# v2.4.0  2023.07.05 - Louis GAMBART - Remove useless function
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# clear $error variable
$error.clear()

# host name
[String] $hostname = $env:COMPUTERNAME

# centreon output string
[String] $output = ""

# centreon exit code
# 0 = OK
# 1 = WARNING
# 2 = CRITICAL
# 3 = UNKNOWN


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
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$DiskName
    )
    begin { $vss = cmd.exe /c 'vssadmin list ShadowStorage' }
    process {
        if ($PSUICulture -eq "fr-FR") {
            if ($vss -match "^(Il n'existe aucun )") {
                return $false
            }
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
            if ($vss -match "No shadow copies are configured") {
                return $false
            }
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


#########################
#                       #
#  III - ERROR HANDLER  #
#                       #
#########################

# trap errors
trap {
    Write-Output "ERROR: An error has occured and the script can't run: $_"
    exit 2
}


###########################
#                         #
#  IV - SCRIPT EXECUTION  #
#                         #
###########################

if ($diskName -match "^([a-zA-Z])$") {
    if (Test-Path -Path $diskName":\") {
        if (Test-VSS -DiskName $diskName) {
            $output += "OK: VSS is enable"
            $output += "<b>\n"
            $output += "\nVSS is enable on $hostname for disk $diskName"
            Write-Output $output
            exit 0
        }
        else {
            $output += "WARNING: VSS is disable"
            $output += "<b>\n"
            $output += "\nVSS is disable on $hostname for disk $diskName"
            Write-Output $output
            exit 1
        }
    }
    else {
        $output += "CRITICAL: Disk $diskName does not exist"
        $output += "<b>\n"
        $output += "\nDisk $diskName does not exist on $hostname"
        Write-Output $output
        exit 2
    }
}
else {
    $output += "UNKNOW: Disk $diskName is not a valid disk name"
    $output += "<b>\n"
    $output += "\nDisk $diskName is not a valid disk name on $hostname, enter it just as a letter, like C or E"
    Write-Output $output
    exit 3
}