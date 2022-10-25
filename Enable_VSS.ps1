#Requires -RunAsAdministrator
# =======================================================
#
# NAME: Enable_VSS.ps1
# AUTHOR: GAMBART Louis
# DATE: 25/10/2022
# VERSION 1.4
#
# =======================================================
#
# CHANGELOG
#
# 1.0: Initial version
# 1.1: Change to work on all Windows versions (not only on windows server)
# 1.2: Add mail notification if VSS couldn't be enabled
# 1.3: Add begin, process and end blocks to the functions
# 1.3.1: Add try/catch for the mail sending
# 1.3.2: Add datetime to the mail body and console output
# 1.4: Add function to write clean logs in the console
#
# =======================================================



# ====================== VARIABLES ======================


# clear error variable
$error.clear()

# get the name of the host
$hostname = $env:COMPUTERNAME

# the disk to enable VSS on
$diskName = "C:\"

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
    The VSS service couldn't be activated on the server $hostname.
    The test was done on the disk $diskName.
    Do not reply to this email, it is automatically generated.
    Cordially,
    The Windows monitoring team."
    SmtpServer = 'smtp server'
    ErrorAction = 'Stop'
}

# mail encoding
$emailingEncoding = [System.Text.Encoding]::UTF8


# ====================== FUNCTIONS ======================


function Get-Datetime {
    <#
    .SYNOPSIS
    Get the current date and time
    .DESCRIPTION
    Get the current date and time
    .INPUTS
    None
    .OUTPUTS
    System.DateTime: The current date and time
    .EXAMPLE
    Get-Datetime | Out-String
    2022-10-24 10:00:00
    #>
    [CmdletBinding()]
    param()
    begin {}
    process { return [DateTime]::Now }
    end {}
}


function Write-Log {
    <#
    .SYNOPSIS
    Write log message in the console
    .DESCRIPTION
    Write log message in the console
    .INPUTS
    System.String: The message to write
    System.String: The log level
    .OUTPUTS
    None
    .EXAMPLE
    Write-Log "Hello world" "Verbose"
    VERBOSE: Hello world
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$LogLevel = 'Information'
    )
    begin {}
    process {
        switch ($LogLevel) {
            'Error' { Write-Error $Message -ErrorAction Stop }
            'Warning' { Write-Warning $Message -WarningAction Continue }
            'Information' { Write-Information $Message -InformationAction Continue }
            'Verbose' { Write-Verbose $Message -Verbose }
            'Debug' { Write-Debug $Message -Debug Continue }
            default { throw "Invalid log level: $_" }
        }
    }
    end {}
}

function Get-VSS-Status {
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
    Get-VSS-Status -DiskName "C:\"
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


function Enable-VSS {
    <#
    .SYNOPSIS
    Enable VSS on the host
    .DESCRIPTION
    Enable VSS on the host through WMI Shadow Copy Object
    .INPUTS
    System.String: DiskName
    .OUTPUTS
    None.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$DiskName
    )
    $VssWmi = Get-WmiObject -List Win32_ShadowCopy
    $VssWmi.Create($DiskName, "ClientAccessible")
}


# ======================== SCRIPT =======================

Write-Log "Starting script on $hostname at $(Get-Datetime)" 'Verbose'

if (Get-VSS-Status -DiskName $diskName.Substring(0,1)) { Write-Log "VSS is already enabled on $diskName" 'Information' }
else {
    Write-Log "VSS is not enabled on $diskName" 'Information'
    Write-Log "Trying to enable VSS on $diskName" 'Verbose'
    Enable-VSS -DiskName $diskName
    if (Get-VSS-Status -DiskName $diskName.Substring(0,1)) { Write-Log "VSS is now enabled on $diskName" 'Information' }
    else {
        Write-Log "VSS couldn't be enabled on $diskName" 'Warning'
        try { Send-MailMessage @mail -Encoding $emailingEncoding }
        catch { Write-Log "Error while sending mail: $_" 'Error' }
        if (!$error) { Write-Log "Mail sent" 'Verbose' }
    }
}


# ====================== END SCRIPT =====================