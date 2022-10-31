#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$diskName
)
#==========================================================================================
#
# SCRIPT NAME        :     is_VSS_Enable.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.10.18
# RELEASE            :     v2.0.0
# USAGE SYNTAX       :     .\is_VSS_Enable.ps1 -diskName "C"
#
# SCRIPT DESCRIPTION :     This script check if VSS is enable and send mail if not
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# 1.0.0  2022.10.18 - Louis GAMBART - Initial version
# 1.1.0  2022.10.18 - Louis GAMBART - Add the mail sending function
# 1.2.0  2022.10.18 - Louis GAMBART - Add the language check function to check if it is in english or french
# 1.3.0  2022.10.19 - Louis GAMBART - Refactor code, add try/catch for the MailMessage sending
# 1.3.1  2022.10.19 - Louis GAMBART - Add exit code when error is catched during the mail sending
# 1.3.2  2022.10.19 - Louis GAMBART - Add print of the maximum space that can be used by VSS
# 1.4.0  2022.10.19 - Louis GAMBART - Change language check verification
# 1.5.0  2022.10.20 - Louis GAMBART - Remove exit code for Centreon (this script already send mail)
# 1.6.0  2022.10.24 - Louis GAMBART - Remove Get-System-Language function and replace it by $PSUICulture variable (function don't return the value wanted)
# 2.0.0  2022.10.31 - Louis GAMBART - Rework to follow Enable_VSS script
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
    if (Test-Path -Path $diskName":\") {
        Write-Host "Starting script for $hostname"
        if (Test-VSS -DiskName $diskName) {
            Write-Host "VSS is enable on this host"
            $result = "0"
        }
        else {
            Write-Host "VSS is not enable on this host"
            $result = "1"
        }
    }
    else { Write-Host "Disk $diskName does not exist on $hostname" }
}
else { Write-Host "Disk $diskName is not a valid disk name, enter it just as a letter, like C or E" }


######################
#                    #
# IV - MAIL SENDING  #
#                    #
######################

# mail attributes
$mail = @{
    # Test mail
    To = 'test mail'
    Cc = 'copy test mail'
    # Prod mail
    # To = 'prod mail', 'prod mail 2'
    # Cc = 'copy prod mail'
    From = 'sender mail'
    Subject = '[VSS Monitoring]'
    Body = "Hello,
        The server $hostname don't have VSS enable.
        Do not reply to this email, it is automatically generated.
        Cordially,
        The Windows monitoring team."
    SmtpServer = 'smtp server'
    ErrorAction = 'Stop'
}

# mail encoding
$emailingEncoding = [System.Text.Encoding]::UTF8

# Send mail if VSS is not enable
if ($result -eq 1)
{
    try {
        Send-MailMessage @mail -Encoding $emailingEncoding
    }
    catch {
        Write-Host $_ -ForegroundColor Red
    }
    if (!$error) {
        Write-Host "Mail sent"
    }
}