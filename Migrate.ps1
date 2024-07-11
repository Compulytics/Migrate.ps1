# This script performs backup and restore operations for Windows user profiles, including browser data for Chrome, Edge, and Firefox.

# Function to copy files from the source directory to the destination directory
function CopyFiles{
	param([string]$Src, [string]$Folder)

	# Check if the destination path exists, if not create it
	if (!(Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

	# Use Robocopy to copy the files and folders
    $DestinationPath = "$Dest\$Usr\$Folder"
    $LogDir = "$Dest\Logs\$Usr"
    $LogFile = "$LogDir\robocopy_log_$Folder.txt"
    
    # Ensure robocopy log directory exists
    if (!(Test-Path -Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

    # Execute robocopy
    Start-Process robocopy -ArgumentList "$Src $DestinationPath /MIR /LOG:$LogFile /NFL /NDL /NP /R:3 /W:5" -NoNewWindow -Wait
}

# Function to paste files from the repository to the destination user profile
function PasteFiles{
	param([string]$Repo, [string]$Folder)

    # Use Robocopy to copy the files and folders
    $SourcePath = "$Repo\$Usr\$Folder"
    $DestinationPath = "$SystemDrive\Users\$DestProfile\$Folder"
    $LogDir = "$Repo\Logs\$Usr"
    $LogFile = "$LogDir\robocopy_log_$Folder.txt"

    # Ensure log directory exists
    if (!(Test-Path -Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

	if ($Folder -eq "RootFolders") {
		# Copy each subfolder in RootFolders individually
		Get-ChildItem -Directory $SourcePath | ForEach-Object {
			$SubFolder = $_.Name
			$SubSourcePath = "$SourcePath\$SubFolder"
			$SubDestinationPath = "$DestinationPath\$SubFolder"
			$SubLogFile = "$LogDir\robocopy_log_RootFolders_$SubFolder.txt"
			
			# Execute robocopy for each subfolder
			Start-Process robocopy -ArgumentList "$SubSourcePath $SubDestinationPath /E /LOG:$SubLogFile /NFL /NDL /NP /R:3 /W:5" -NoNewWindow -Wait
		}
	} else {
		# Execute robocopy for each subfolder
		Start-Process robocopy -ArgumentList "$SourcePath $DestinationPath /E /LOG:$LogFile /NFL /NDL /NP /R:3 /W:5" -NoNewWindow -Wait
	}
}

# Function to take (backup) a user profile
function TakeProfile($Usr, $Dest){

	# Check if the script is running with administrative privileges
	if (!($CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
		if (!($Usr -eq $Env:UserName)){
			Write-Host "ERROR: No Administrator access. Can only copy other profiles when run as Administrator!"
			sleep 5
			exit
		}
	}

	# List of folders to copy from the user profile
	$FoldersToCopy = @("Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")

	# Check if the destination path for the user profile already exists
	if (Test-Path -Path $Dest\$Usr){
		Write-Host "User ID Already Exists"
		$Overwrite = Read-Host "Overwrite existing data? (y,n)"
		if ($Overwrite -eq "y"){
			Write-Host "Overwriting..."
			remove-item $Dest\$Usr -Force -Recurse
		}
		else{
			exit
		}
	}
	else{
		New-Item $Dest\$Usr -ItemType Directory | Out-Null
	}

	# Copy home folder contents
	Write-Host "Copying Home Folder Contents"
	Get-ChildItem $SystemDrive\Users\$Usr\ | Foreach-Object{
		if($_.Directory){
			Copy-Item "$SystemDrive\Users\$Usr\$_" -Destination "$Dest\$Usr\"
		}
		else{
			if (!(Test-Path $Dest\$Usr\RootFolders)){
				New-Item $Dest\$Usr\RootFolders -ItemType Directory | Out-Null
			}
			if ([string]$_ -ne "Contacts" -and [string]$_ -ne "Desktop" -and [string]$_ -ne "Documents" -and [string]$_ -ne "Downloads" -and [string]$_ -ne "Favorites" -and [string]$_ -ne "Music" -and [string]$_ -ne "Pictures" -and [string]$_ -ne "Videos" -and [string]$_ -ne "3D Objects" -and [string]$_ -ne "Links" -and [string]$_ -ne "Saved Games" -and [string]$_ -ne "Searches" -and !($_ -match "OneDrive")){
				Copy-Item "$SystemDrive\Users\$Usr\$_" -Recurse -Destination "$Dest\$Usr\RootFolders"
			}
		}
	}

	# Copy predefined folders
	$FoldersToCopy | Foreach-Object{
		Write-Host "Copying $_ Folder"
		$DestSub = "$Dest\$Usr\$_"
		CopyFiles "$SystemDrive\Users\$Usr\$_" "$_"
	}

	# Terminate any running browser processes to ensure data integrity
	$CurrentProcesses = $((get-wmiobject win32_process -computername $((hostname)) | Select-Object ProcessName))
	if ($CurrentProcesses.ProcessName.Contains("chrome.exe") -or $CurrentProcesses.ProcessName.Contains("msedge.exe") -or $CurrentProcesses.ProcessName.Contains("firefox")){
		Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process -Force
		Get-Process -Name msedge -ErrorAction SilentlyContinue | Stop-Process -Force
		Get-Process -Name firefox -ErrorAction SilentlyContinue | Stop-Process -Force
	}

	# Copy browser data
	if (Test-Path "$SystemDrive\Users\$Usr\AppData\Local\Google\Chrome\User Data\Default"){
		Write-Host "Copying Chrome Data"
		Copy-Item "$SystemDrive\Users\$Usr\AppData\Local\Google\Chrome\User Data\Default" -Destination $Dest\$Usr\ChromeData\Default -Recurse
	}
	Write-Host "Copying Edge Data"
	Copy-Item "$SystemDrive\Users\$Usr\AppData\Local\Microsoft\Edge\User Data\Default" -Destination $Dest\$Usr\EdgeData\Default -Recurse
	if (Test-Path "$SystemDrive\Users\$Usr\AppData\Roaming\Mozilla\Firefox\Profiles"){
		Write-Host "Copying Firefox Data"
		Copy-Item "$SystemDrive\Users\$Usr\AppData\Roaming\Mozilla\Firefox\Profiles" -Destination $Dest\$Usr\FirefoxData\Profiles -Recurse
		Copy-Item "$SystemDrive\Users\$Usr\AppData\Roaming\Mozilla\Firefox\profiles.ini" -Destination $Dest\$Usr\FirefoxData\profiles.ini
	}
}

# Function to put (restore) a user profile
function PutProfile($Usr, $Repo, $DestProfile){
	$ValidPasteProfiles = @()

	# List of folders to paste back to the user profile
	$FoldersToPaste = @("RootFolders\*","Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")

	# Check if the repository path exists
	if (Test-Path $Repo){
		if (Test-Path $Repo\$Usr){
			Write-Host "Pasting Home Folder Contents"
			Get-ChildItem $Repo\$Usr | Foreach-Object{
				if($_.Directory){
					Copy-Item "$Repo\$Usr\$_" -Destination "$SystemDrive\Users\$DestProfile\"
				}
			}

			# Paste each folder back to the destination user profile
			$FoldersTopaste | Foreach-Object{
				if ([string]$_ -eq "RootFolders\*"){
					Write-Host "Pasting Home Folder Folders"
				}
				else{
					Write-Host "Pasting $_ Folder"
				}
				PasteFiles "$Repo" "$_"
			}

			# Terminate any running browser processes to ensure data integrity
			$CurrentProcesses = $((get-wmiobject win32_process -computername $((hostname)) | Select-Object ProcessName))
			if ($CurrentProcesses.ProcessName.Contains("chrome.exe") -or $CurrentProcesses.ProcessName.Contains("msedge.exe") -or $CurrentProcesses.ProcessName.Contains("firefox")){
				Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process -Force
				Get-Process -Name msedge -ErrorAction SilentlyContinue | Stop-Process -Force
				Get-Process -Name firefox -ErrorAction SilentlyContinue | Stop-Process -Force
			}

			# Paste browser data
			if (Test-Path $Repo\$Usr\ChromeData\Default){
				Write-Host "Pasting Chrome Data Folder"
				if (Test-Path "$SystemDrive\Users\$DestProfile\AppData\Local\Google\Chrome\User Data\Default"){
					remove-item "$SystemDrive\Users\$DestProfile\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
				}
				Copy-Item $Repo\$Usr\ChromeData\Default "$SystemDrive\Users\$DestProfile\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
			}

			Write-Host "Pasting Edge Data Folder"
			if (Test-Path "$SystemDrive\Users\$DestProfile\AppData\Local\Microsoft\Edge\User Data\Default"){
				remove-item "$SystemDrive\Users\$DestProfile\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
			}
			Copy-Item $Repo\$Usr\EdgeData\Default "$SystemDrive\Users\$DestProfile\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
			if (Test-Path $Repo\$Usr\FirefoxData\Profiles){
				Write-Host "Pasting Firefox Data Folder"
				if (Test-Path "$SystemDrive\Users\$DestProfile\AppData\Roaming\Mozilla\Firefox\Profiles"){
					remove-item "$SystemDrive\Users\$DestProfile\AppData\Roaming\Mozilla\Firefox\Profiles" -Force -Recurse
					remove-item "$SystemDrive\Users\$DestProfile\AppData\Roaming\Mozilla\Firefox\profiles.ini" -Force
				}
				Copy-Item $Repo\$Usr\FirefoxData\Profiles "$SystemDrive\Users\$DestProfile\AppData\Roaming\Mozilla\Firefox\Profiles" -Force -Recurse
				Copy-Item $Repo\$Usr\FirefoxData\profiles.ini  "$SystemDrive\Users\$DestProfile\AppData\Roaming\Mozilla\Firefox\profiles.ini"
			}
		}
		else{
			Write-Host "User Profile Not Found!"
			sleep 5
			exit
		}
	}
	else{
		Write-Host "Invalid Source Path!"
		sleep 5
		exit
	}
}

# Main script execution starts here

# Get the system drive and current user principal
$SystemDrive = (Get-WmiObject Win32_OperatingSystem).SystemDrive
$CurrentUserPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Process command-line arguments
if ([string]$args[0] -eq "-c"){
	$Usr = $Env:UserName
	$Mode = "c"
}
elseif ([string]$args[0] -eq "-p"){
	$Mode = "p"
}
elseif ([string]$args[0] -eq "-h"){
	# Display help menu
	Write-Host "Usage:"
	Write-Host ".\ThisProgram.ps1 [OPTIONS] <Profile to Copy or Paste from> <Source or Destination Path> <Profile to Paste to>"
	Write-Host "======================================================================="
	Write-Host "|| OPTIONS:                                                          ||"
	Write-Host "======================================================================="
	Write-Host "|| -c                                                   Copy Profile ||"
	Write-Host "|| -p                                                  Paste Profile ||"
	Write-Host "|| -h                                                Print This Page ||"
	Write-Host "======================================================================="
	Write-Host "|| NOTE: <Profile to Paste to> is only valid in Paste mode!          ||"
	Write-Host "======================================================================="
	exit
}
else{
	# Ask the user if they want to copy or paste a profile
	$Mode = Read-Host "Would you like to copy or paste profile? (c,p)"
}

# Perform copy or paste operation based on the selected mode
if ($Mode -eq "c"){
	if ([string]$args[1]){
		if ([string]$args[2]){
			if (Test-Path $args[2]){
				$ValidSourceProfiles = @()
				Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){$ValidSourceProfiles += $_.ToString()}}
				if ($ValidSourceProfiles.Contains([string]$args[1])){
					TakeProfile $args[1] $args[2]
				}
				else{
					Write-Host "ERROR: Invalid source profile selected!"
					sleep 5
					exit
				}
			}
			else{
				New-Item -Path $args[2] -ItemType "Directory" | Out-Null
				Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){$ValidSourceProfiles += $_.ToString()}}}
				if ($ValidSourceProfiles.Contains($args[1])){
					TakeProfile $Usr $args[2]
				}
				else{
					Write-Host "ERROR: Invalid source profile selected!"
					sleep 5
					exit
				}
			}
		}
		else{
			$Repo = Read-Host "Enter the path of the repository where you will store your profile"
			if (Test-Path $Repo){
				$ValidSourceProfiles = @()
				Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){$ValidSourceProfiles += $_.ToString()}}
				if ($ValidSourceProfiles.Contains([string]$args[1])){
					TakeProfile $args[1] $Repo
				}
				else{
					Write-Host "ERROR: Invalid source profile selected!"
					sleep 5
					exit
				}
			}
			else{
				New-Item -Path $Repo -ItemType "Directory" | Out-Null
				Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){$ValidSourceProfiles += $_.ToString()}}}
				if ($ValidSourceProfiles.Contains($args[1])){
					TakeProfile $args[1] $Repo
				}
				else{
					Write-Host "ERROR: Invalid source profile selected!"
					sleep 5
					exit
				}
			}
		}
	}
	else{
		$Repo = Read-Host "Enter the path of the repository where you will store your profile"
		if (Test-Path $Repo){
			Write-Host "================================="
			Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){Write-Host $_;$ValidSourceProfiles += $_.ToString()}}}
			Write-Host "================================="
			$Usr = Read-Host "Which profile would you like to copy?"
			if ($ValidSourceProfiles.Contains($Usr)){
				TakeProfile $Usr $Repo
			}
			else{
				Write-Host "ERROR: Invalid source profile selected!"
				sleep 5
				exit
			}
		}
		else{
			New-Item -Path $Repo -ItemType "Directory" | Out-Null
			Write-Host "================================="
			Get-Childitem $SystemDrive\Users | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){Write-Host $_;$ValidSourceProfiles += $_.ToString()}}}
			Write-Host "================================="
			$Usr = Read-Host "Which profile would you like to copy?"
			if ($ValidSourceProfiles.Contains($Usr)){
				TakeProfile $Usr $Repo
			}
			else{
				Write-Host "ERROR: Invalid source profile selected!"
				sleep 5
				exit
			}
		}
	}
}
elseif ($Mode -eq "p"){
	if ([string]$args[1]){
		if ([string]$args[2]){
			if ([string]$args[3]){
				if (Test-Path $args[2]){
					$ValidSourceProfiles = @()
					Get-Childitem $args[2] | Foreach-Object{if(!($_.directory)){$ValidSourceProfiles += $_.ToString()}}
					if (!($ValidSourceProfiles.Contains([string]$args[1]))){
						Write-Host "ERROR: Invalid source profile selected!"
						sleep 5
						exit
					}
					$ValidDestProfiles = @()
					Get-Childitem $SystemDrive\Users\ | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){$ValidDestProfiles += $_.ToString()}}}
					if ($ValidDestProfiles.Contains($args[3])){
						PutProfile $args[1] $args[2] $args[3]
					}
					else{
						Write-Host "ERROR: Invalid destination profile selected!"
						sleep 5
						exit
					}
				}
				else{
					Write-Host "ERROR: Invalid source path!"
					sleep 5
					exit
				}
			}
			else{
				Write-Host $args[2]
				if (Test-Path $args[2]){
					$ValidSourceProfiles = @()
					Get-Childitem $args[2] | Foreach-Object{if(!($_.directory)){$ValidSourceProfiles += $_.ToString()}}
					if (!($ValidSourceProfiles.Contains([string]$args[1]))){
						Write-Host "ERROR: Invalid source profile selected."
						sleep 5
						exit
					}
				}
				else{
					Write-Host "ERROR: Invalid source path!"
					sleep 5
					exit
				}
				$ValidDestProfiles = @()
				Write-Host "================================="
				Get-Childitem $SystemDrive\Users\ | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){Write-Host $_;$ValidDestProfiles += $_.ToString()}}}
				Write-Host "================================="
				$UsrDest = Read-Host "Which profile would you like to paste to?"
				if ($ValidDestProfiles.Contains($UsrDest)){
					PutProfile $args[1] $args[2] $UsrDest
				}
			}
		}
		else{
			$Repo = Read-Host "Enter profile repository path"
			if (Test-Path $Repo){
				$ValidSourceProfiles = @()
				Get-Childitem $Repo | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){$ValidSourceProfiles += $_.ToString()}}}
				if (!($ValidSourceProfiles.Contains([string]$args[1]))){
					Write-Host "ERROR: Invalid profile source selected!"
					sleep 5
					exit
				}
				$ValidDestProfiles = @()
				Write-Host "================================="
				Get-Childitem $SystemDrive\Users\ | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){Write-Host $_;$ValidDestProfiles += $_.ToString()}}}
				Write-Host "================================="
				$UsrDest = Read-Host "Which profile would you like to paste to?"
				if ($ValidDestProfiles.Contains($UsrDest)){
					PutProfile $args[1] $Repo $UsrDest
				}
			}
		}
	}
	else{
		$Repo = Read-Host "Enter profile repository path"
		if (Test-Path $Repo){
			$ValidSourceProfiles = @()
			Write-Host "================================="
			Get-Childitem $Repo | Foreach-Object{if(!($_.directory)){Write-Host $_;$ValidSourceProfiles += $_.ToString()}}
			Write-Host "================================="
			$UsrSource = Read-Host "Which profile would you like to paste from?"
			if ($ValidSourceProfiles.Contains($UsrSource)){
				$ValidDestProfiles = @()
				Write-Host "================================="
				Get-Childitem $SystemDrive\Users\ | Foreach-Object{if(!($_.directory)){if ($_.Name -ne "Public"){Write-Host $_;$ValidDestProfiles += $_.ToString()}}}
				Write-Host "================================="
				$UsrDest = Read-Host "Which profile would you like to paste to?"
				if ($ValidDestProfiles.Contains($UsrDest)){
					PutProfile $UsrSource $Repo $UsrDest
				}
				else{
					Write-Host "Invalid Selection!"
					sleep 5
					exit
				}
			}
			else{
				Write-Host "Invalid Selection!"
				sleep 5
				exit
			}
		}
		else{
			Write-Host "Invalid profile repository path!"
			sleep 5
			exit
		}
	}
}
else{
	Write-Host "Invalid Selection!"
	sleep 5
	exit
}
Write-Host "Done"
#END HERE
