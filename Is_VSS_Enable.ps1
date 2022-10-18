# =======================================================
#
# NAME: is_VSS_Enable.ps1
# AUTHOR: GAMBART Louis
# DATE: 18/10/2022
# VERSION 1.2
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
# 1.1: Add the mail sending function
# 1.2: Add the language check function to check if it is in english or french
#
# =======================================================



# ====================== VARIABLES ======================


# get the name of the host
$hostname = $env:COMPUTERNAME

# cmdlet to execute
$vss = cmd.exe /c "vssadmin list ShadowStorage"

# Mail variables
[String] $Emailing_SmtpServer = "smtp_server"
[String] $Emailing_Subject = '[VSS Monitoring]'
[String] $Emailing_From = 'sender mail'

# Test mail
[Array] $Emailing_To = 'test mail address'
[Array] $Emailing_Cc = 'copy test mail address'
# Prod mail
#[Array] $Emailing_To = 'prod mail address','prod mail address 2'
#[Array] $Emailing_CC = 'copy prod mail address'

# Mail body
$Emailing_Body = "
    Hello,

    The server $hostname don't have VSS enable.

    Do not reply to this email, it is automatically generated.
    Cordially,
    The Windows monitoring team."

# Mail encoding
$Emailing_Encoding = [System.Text.Encoding]::UTF8


# ====================== FUNCTIONS ======================


function checkSystemLanguage {
    $systemLanguage = (Get-WinSystemLocale).Name
    return $systemLanguage
}


function isVSSenable {
    param (
        [Parameter(Mandatory=$true)]
        $vss
    )
    if (checkSystemLanguage -eq "fr-FR") {
        $vssmatch = "^(Il n'existe aucun )"
    }
    elseif (checkSystemLanguage -eq "en-US") {
        $vssmatch = "No shadow copies are configured"
    }

    if ($vss -match $vssmatch) {
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
        }
        Write-Host "VSS is enable on $drive drive and volume $volume"
        Write-Host "Used space: $used GB"
        Write-Host "Allocated space: $allocated GB"
        return 0
    }
}


# ======================== SCRIPT =======================


Write-Host "Starting script for $hostname"
$result = isVSSenable -vss $vss


# ====================== END SCRIPT =====================



# ========================= MAIL ========================


# Send mail if VSS is not enable
if ($result -eq 1)
{
    Send-MailMessage -From $Emailing_From -To $Emailing_To -Cc $Emailing_Cc -SmtpServer $Emailing_SmtpServer -Subject $Emailing_Subject -Body $Emailing_Body -Encoding $Emailing_Encoding
    Write-Host "Mail sent"
    exit 1
}
else {
    exit 0
}


# ======================= END MAIL ======================


# ======================= CENTREON ======================

# 0: OK
# 1: WARNING
# 2: CRITICAL