# =======================================================
#
# NAME: is_VSS_Enable_Centreon-Version.ps1
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


# clear $error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# cmdlet to execute
$vss = cmd.exe /c "vssadmin list ShadowStorage"


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
    exit 1
}
else {
    exit 0
}

# ======================= END MAIL ======================


# ======================= CENTREON ======================

# 0 = OK
# 1 = WARNING
# 2 = CRITICAL