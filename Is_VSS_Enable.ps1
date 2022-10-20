# =======================================================
#
# NAME: is_VSS_Enable.ps1
# AUTHOR: GAMBART Louis
# DATE: 20/10/2022
# VERSION 1.5
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
# 1.1: Add the mail sending function
# 1.2: Add the language check function to check if it is in english or french
# 1.3: Refactor code, add try/catch for the MailMessage sending
# 1.3.1: Add exit code when error is catched during the mail sending
# 1.3.2: Add print of the maximum space that can be used by VSS
# 1.4: Change language check verification
# 1.5: Remove exit code for Centreon (this script already send mail and don't will be use with Centreon)
#
# =======================================================



# ====================== VARIABLES ======================


# clear $error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# cmdlet to execute
$vss = cmd.exe /c "vssadmin list ShadowStorage"

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

# ====================== FUNCTIONS ======================


function Get-System-Language {
    <#
    .SYNOPSIS
    Get the local system language
    .DESCRIPTION
    The Get-System-Language enables you to get the current local system language
    .INPUTS
    None.
    .OUTPUTS
    System.String: return the system language
    #>
    [CmdletBinding()]
    $systemLanguage = (Get-WinSystemLocale).Name
    return $systemLanguage
}


function Get-VSS-Status {
    <#
    .SYNOPSIS
    Check if VSS service is enable on a host
    .DESCRIPTION
    The Get-VSS-Status function enable to know if the VSS service is enable on a host.
    .INPUTS
    vssadmin cmdlet query reply
    .OUTPUTS
    System.Int32: return 0 or 1 according to the status of the service
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $vss
    )
    if (Get-System-Language -eq "fr-FR") {
        $vssMatch = "^(Il n'existe aucun )"
    }
    else {
        $vssMatch = "No shadow copies are configured"
    }

    if ($vss -match $vssMatch) {
        Write-Host "VSS is not enable"
        return 1
    }
    else {
        foreach ($line in $vss) {
            if ($line -match "For volume: \((?<letter>[A-Z]):\)\\\\\?\\Volume{(?<volume>[a-z0-9-]+)}\\") {
                $drive = $matches.letter
                $volume = $matches.volume
            }
            if ($line -match "Used Shadow Copy Storage space: (.*) GB") { $used = $matches[1] }
            if ($line -match "Allocated Shadow Copy Storage space: (.*) GB") { $allocated = $matches[1] }
            if ($line -match "Maximum Shadow Copy Storage space: (.*) GB") { $maximum = $matches[1]}
        }
        Write-Host "VSS is enable on $drive drive and volume $volume"
        Write-Host "Used space: $used GB"
        Write-Host "Allocated space: $allocated GB"
        Write-Host "Maximum space usable by VSS: $maximum"
        return 0
    }
}


# ======================== SCRIPT =======================


Write-Host "Starting script for $hostname"
$result = Get-VSS-Status -vss $vss


# ====================== END SCRIPT =====================



# ========================= MAIL ========================


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

# ======================= END MAIL ======================