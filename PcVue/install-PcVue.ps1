	[CmdletBinding()]
	param(
	[string] $PcVueVersion = '15.0.2_PcVue_FullDVD.iso' # ISO drive to mount from the shared folder.
	)

###################################################################################################
#
# PowerShell configuration.
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Hide any progress bars, due to downloads and installs of remote components.
$ProgressPreference = "SilentlyContinue"

# Discard any collected errors from a previous execution.
$Error.Clear()

# Allow certian operations, like downloading files, to execute.
Set-ExecutionPolicy Bypass -Scope Process -Force

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe artifact failed to apply.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Functions used in this script.
#

## Mount the needed .iso file and return the letter of the drive when it is mounted.
function New-IsoFileMount
{
	param(
	  [string] $PcVueVersion
	)

	$imagePath= "Z:\"+ $PcVueVersion
	$null = @(
		Write-Host "Path of ISO image to be mounted: $($imagePath)"
	)

	$isoDrive = (Get-DiskImage -ImagePath $imagePath | Get-Volume).DriveLetter
	if (-not $isoDrive)
	{
		Mount-DiskImage -ImagePath $imagePath -StorageType ISO | Out-Null
	}
	$isoDrive = (Get-DiskImage -ImagePath $imagePath | Get-Volume).DriveLetter
	
	return $isoDrive
}

## Connect my file share in the SA to the VM (copied from the Portal).
function New-NetworkDriveMapping
{
	$result = Test-NetConnection -ComputerName apoclab505.file.core.windows.net -Port 445
	if ($result.TcpTestSucceeded)
	{
		# Save the password so the drive will persist on reboot
		cmd.exe /C "cmdkey /add:`"apoclab505.file.core.windows.net`" /user:`"AZURE\apoclab505`" /pass:`"MOqPM0BtWn8T3ZdtIvLFT07LkGC2kXRDPLHMWMnm3NCwpMtokYW7nZvrm0yJIqUeYaeYXdr6wQaxg9wTtWBPVg==`""
		# Mount the drive
		New-PSDrive -Name Z -PSProvider FileSystem -Root "\\apoclab505.file.core.windows.net\sharedfolder" -Persist
	}
	else
	{
		throw "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
	}
}

## Ensure the Log path exists.
function Test-LogPathExists
{
	param(
	  [string] $LogPath = 'C:\Log'
	)

	if (-not(Test-Path -Path $LogPath -PathType Leaf))
	{
		New-Item -ItemType directory -Path $LogPath -Force -ErrorAction Stop | Out-Null
	}

	Write-Host "Logs will be collected under path '$LogPath'"
}

###################################################################################################
#
# Main execution block.
#

try
{
    pushd $PSScriptRoot

	Write-Host "Starting installation of PcVue."
	
	#Write-Host "Mapping permanent network drive."
	#New-NetworkDriveMapping

	Write-Host "Mounting ISO file for version $PcVueVersion."
	$isoDrive = New-IsoFileMount -PcVueVersion $PcVueVersion
	Write-Host "ISO Drive is $ISODrive"

	#Write-Host "Ensuring location for logs exists."
	#Test-LogPathExists

	#Write-Host "Installing PrqCore components."
	#$prqCoreExe = $isoDrive + ":\Prerequisite\PrqCore.exe" 
	#& "$prqCoreExe" /quiet /norestart /NoPrompt SilentMode=1

	#Write-Host "Installing PrqWdt components."
	#$prqWdtExe = $isoDrive + ":\Prerequisite\PrqWdt.exe"
	#& "$prqWdtExe" /quiet /norestart /NoPrompt
	
	#Write-Host "Installing core components."
	#$coreSetupExe = $isoDrive + ":\Core\Setup.exe" 
	#& "$coreSetupExe" /clone_wait /L1036 /s /v"/quiet /norestart /l*v C:\Log\Install.log"

	#Write-Host "Installing Wdt components."
	#$wdtSetupExe = $isoDrive + ":\Wdt\Setup.exe"
	#& "$wdtSetupExe" /clone_wait /L1036 /s /v"/quiet /norestart /l*v C:\Log\Install.log"

    Write-Host "`nThe artifact was applied successfully.`n"
}
finally
{
    popd
}