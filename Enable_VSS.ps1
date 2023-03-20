#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$diskName
)
#==========================================================================================
#
# SCRIPT NAME        :     Enable_VSS.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.11.18
# RELEASE            :     v2.4.0
# USAGE SYNTAX       :     .\Enable_VSS.ps1 -diskName "C:\"
#
# SCRIPT DESCRIPTION :     This script check if VSS is enable and try to enable it if it's not the case
#
#==========================================================================================

#                 - RELEASE NOTES -
# v1.0.0  2022.10.21 - Louis GAMBART - Initial version
# v1.1.0  2022.10.24 - Louis GAMBART - Change to work on all Windows versions (not only on windows server)
# v1.2.0  2022.10.24 - Louis GAMBART - Add mail notification if VSS couldn't be enabled
# v1.3.0  2022.10.25 - Louis GAMBART - Add begin, process and end blocks to the functions
# v1.3.1  2022.10.25 - Louis GAMBART - Add try/catch for the mail sending
# v1.3.2  2022.10.25 - Louis GAMBART - Add datetime to the mail body and console output
# v1.4.0  2022.10.25 - Louis GAMBART - Add function to write clean logs in the console
# v1.5.0  2022.10.25 - Louis GAMBART - Add control on the drive letter
# v1.5.1  2022.10.25 - Louis GAMBART - Pass the drive letter to the script
# v1.5.2  2022.10.26 - Louis GAMBART - Rename function Get-VSS-Status to Test-VSS
# v1.6.0  2022.10.26 - Louis GAMBART - Add system type check (workstation or server)
# v1.6.1  2022.10.26 - Louis GAMBART - Change error message on diskname parameter control
# v1.7.0  2022.10.26 - Louis GAMBART - change mail body and subject
# v1.7.1  2022.10.26 - Louis GAMBART - Change order of script execution
# v1.7.2  2022.10.26 - Louis GAMBART - Modify get system type function
# v1.8.0  2022.10.26 - Louis GAMBART - Add volume resize action when enabling VSS
# v1.9.0  2022.10.27 - Louis GAMBART - Adapt Get-SystemType for french and english
# v2.0.0  2022.10.27 - Louis GAMBART - Add creation of scheduled task to run shadow copy on the volume created
# v2.1.0  2022.10.27 - Louis GAMBART - Change Enable-VSS to get the output of WMI command to retrieve the volume ID
# v2.2.0  2022.10.28 - Louis GAMBART - Add function type in variables declaration
# v2.2.1  2022.10.28 - Louis GAMBART - Use approved verbs in function name
# v2.3.0  2022.10.31 - Louis GAMBART - Change script header and commentary blocks
# v2.3.1  2022.10.31 - Louis GAMBART - Add variable type for $emailingEncoding
# v2.4.0  2022.11.18 - Louis GAMBART - Rework file to fix warnings/informations given by PSScriptAnalyzer
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# clear error variable
$error.clear()

# get the name of the host
[String] $hostname = $env:COMPUTERNAME

# max VSS volume size
[String] $maxVSSVolumeSize = "500000MB"

# mail variables
[String] $emailingTo = ""
[String] $emailingCc = ""
[String] $emailingFrom = ""
[String] $emailingSMTPServer = ""
[UTF8Encoding] $emailingEncoding = [System.Text.Encoding]::UTF8


####################
#                  #
#  II - FUNCTIONS  #
#                  #
####################

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
    [OutputType([System.DateTime])]
    param()
    begin {}
    process { return [DateTime]::Now }
    end {}
}


function Get-SystemType {
    <#
    .SYNOPSIS
    Get the system type
    .DESCRIPTION
    Get the system type
    .INPUTS
    None
    .OUTPUTS
    System.String: The system type
    .EXAMPLE
    Get-SystemType
    Server
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param()
    begin {}
    process {
        if ($PSUICulture.Name -eq "fr-FR") {
            $info = systeminfo /fo csv | ConvertFrom-Csv | Select-Object Nom*
            if ($info."Nom de l'hÃ´te" -match "^(Microsoft Windows ?(Server))") { return 'Server' }
            elseif ($info."Nom de l'hÃ´te" -match "^(Microsoft Windows ?([0-9]{1,2}))") { return 'Workstation' }
            else { return 'Unknow' }
        }
        else {
            $info = systeminfo /fo csv | ConvertFrom-Csv | Select-Object OS*
            if ($info.'OS Name' -match "^(Microsoft Windows ?(Server))") { return 'Server' }
            elseif ($info.'OS Name' -match "^(Microsoft Windows ?([0-9]{1,2}))") { return 'Workstation' }
            else { return 'Unknow' }
        }
    }
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


function Enable-VSS {
    <#
    .SYNOPSIS
    Enable VSS on the host
    .DESCRIPTION
    Enable VSS on the host through WMI Shadow Copy Object
    .INPUTS
    System.String: DiskName
    System.String: maxVSSSize
    .OUTPUTS
    None.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$DiskName,
        [Parameter(Mandatory=$true, Position=1)]
        [String]$MaximumSize
    )
    begin { $VssWmi = Get-CimClass -ClassName Win32_ShadowCopy }
    process {
        $out = $VssWmi.Create($DiskName, "ClientAccessible")
        cmd.exe /c "vssadmin resize shadowstorage /for=$($DiskName.Substring(0,2)) /on=$($DiskName.Substring(0,2)) /maxsize=$MaximumSize"
    }
    end { return $out }
}


function Add-VSS-Scheduled-Task {
    <#
    .SYNOPSIS
    Create a scheduled task
    .DESCRIPTION
    Create a scheduled task to run VSS on the host
    .INPUTS
    System.String: DiskName
    System.String: MaximumSize
    .OUTPUTS
    None.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$ShadowCopyVolumeID
    )
    begin {
        $TaskName = "ShadowCopyVolume" + $ShadowCopyVolumeID }
    process {
        $scheduledAction = New-ScheduledTaskAction -Execute 'C:\Windows\system32\vssadmin.exe' -Argument "Create Shadow /AutoRetry=15 /For\\?\Volume$ShadowCopyVolumeID" -WorkingDirectory 'C:\Windows\system32'
        $scheduledTriggers = @(
            New-ScheduledTaskTrigger -Daily -At 7:00AM
            New-ScheduledTaskTrigger -Daily -At 00:00PM
        )
        $scheduledTask = New-ScheduledTask -Action $scheduledAction -Trigger $scheduledTriggers -Description "Run Shadow Copy on $($ShadowCopyVolumeID)"
        Register-ScheduledTask -TaskName $TaskName -TaskPath "\" -InputObject $scheduledTask -User "SYSTEM"
    }
    end {}
}


#####################
#                   #
#  III - MAIL ARGS  #
#                   #
#####################


# mail attributes
$emailingArgs = @{
    To = $emailingTo
    Cc = $emailingCc
    From = $emailingFrom
    Subject = "[VSS Monitoring] $hostname - $(Get-Datetime)"
    Body = "Hello,
        The VSS service couldn't be activated on the $(Get-SystemType) $hostname at $(Get-Datetime).
        The test was done on the disk $diskName.
        Do not reply to this email, it is automatically generated.
        Cordially,
        The Windows monitoring team."
    SmtpServer = $emailingSMTPServer
    ErrorAction = 'Stop'
}


###########################
#                         #
#  IV - SCRIPT EXECUTION  #
#                         #
###########################

Write-Log "Starting script on $hostname ($(Get-SystemType)) at $(Get-Datetime)" 'Verbose'

if ($diskName -notmatch "^([a-zA-Z]:\\)$") { Write-Log "The disk name is not valid: please enter it like C:\" 'Error' }

if (!(Test-Path $diskName)) { Write-Log "The disk $diskName doesn't exist on the host $hostname" 'Error' }

if (Test-VSS -DiskName $diskName.Substring(0,1)) { Write-Log "VSS is already enabled on $diskName" 'Information' }
else {
    Write-Log "VSS is not enabled on $diskName" 'Information'
    Write-Log "Trying to enable VSS on $diskName" 'Verbose'
    $volumeID = (Enable-VSS -DiskName $diskName -MaximumSize $maxVSSVolumeSize).ShadowID | Out-String
    if (Test-VSS -DiskName $diskName.Substring(0,1)) {
        Write-Log "VSS is now enabled on $diskName" 'Information'
        Add-VSS-Scheduled-Task -ShadowCopyVolumeID $volumeID.Replace("`n","").replace("`r","")
        Write-Log "VSS scheduled task created on $diskName" 'Information'
    }
    else {
        Write-Log "VSS couldn't be enabled on $diskName" 'Warning'
        try { Send-MailMessage @emailingArgs -Encoding $emailingEncoding }
        catch { Write-Log "Error while sending mail: $_" 'Error' }
        if (!$error) { Write-Log "Mail sent" 'Verbose' }
    }
}


#####################
#                   #
#  IV - SCRIPT END  #
#                   #
#####################
