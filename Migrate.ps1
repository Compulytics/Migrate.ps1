function CopyFiles{
	param([string]$Src, [string]$Folder)
	if (!(Test-Path -Path $Dest\$Usr\$Folder)){
		New-Item $Dest\$Usr\$Folder -ItemType Directory | Out-Null
	}
	Get-ChildItem $Src -Recurse -Force | Sort-Object -Property FullName -Descending | ForEach-Object {
		if ($_.Directory){
			$StrDir = [string]$_.Directory
			$SubDirs = $StrDir.replace($Src,"")
			if (!(Test-Path -Path $DestSub$SubDirs)){
				$FullPath = "$DestSub$SubDirs"
				$DirectoryArray = $FullPath.split("\")
				$DirectoryBuffer = ""
				$DirectoryArray | ForEach-Object {
					$DirectoryBuffer += "$_\"
					if (!(Test-Path $DirectoryBuffer)){
						New-Item $DirectoryBuffer -ItemType Directory -Force | Out-Null
					}
				}
			}
		}
		$File = $_.FullName
		$DSTFileName = $File.Replace($Src,"")
		if (!(Test-Path $DestSub$DSTFileName)){
			Copy-Item "$File" -Destination "$DestSub$DSTFileName" -Force
		}
	}
}
function PasteFiles{
	param([string]$Repo, [string]$Folder)
	Copy-Item $Repo\$Usr\$Folder $SystemDrive\Users\$DestProfile -Recurse -Force -ErrorAction SilentlyContinue
}
function TakeProfile($Usr, $Dest){
	if (!($CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
		if (!($Usr -eq $Env:UserName)){
			Write-Host "ERROR: No Administrator access. Can only copy other profiles when run as Administrator!"
			sleep 5
			exit
		}
	}
	$FoldersToCopy = @("Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
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
	Write-Host "Copying Home Folder Contents"
	Get-ChildItem $SystemDrive\Users\$Usr\ | Foreach-Object{
		if($_.Directory){
			Copy-Item "$SystemDrive\Users\$Usr\$_" -Destination "$Dest\$Usr\"
		}
		else{
			if (!(Test-Path $Dest\$Usr\RootFolders)){
				New-Item $Dest\$Usr\RootFolders -ItemType Directory | Out-Null
			}
			if ([string]$_ -ne "Contacts" -and [string]$_ -ne "Desktop" -and [string]$_ -ne "Documents" -and [string]$_ -ne "Downloads" -and [string]$_ -ne "Favorites" -and [string]$_ -ne "Music" -and [string]$_ -ne "Pictures" -and [string]$_ -ne "Videos" -and [string]$_ -ne "3D Objects" -and [string]$_ -ne "Links" -and [string]$_ -ne "OneDrive" -and [string]$_ -ne "Saved Games" -and [string]$_ -ne "Searches"){
				Copy-Item "$SystemDrive\Users\$Usr\$_" -Recurse -Destination "$Dest\$Usr\RootFolders"
			}
		}
	}
	$FoldersToCopy | Foreach-Object{
		Write-Host "Copying $_ Folder"
		$DestSub = "$Dest\$Usr\$_"
		CopyFiles "$SystemDrive\Users\$Usr\$_" "$_"
	}
	if ($Usr -eq $Env:UserName){
		Stop-Process -Name chrome -ErrorAction SilentlyContinue
		Stop-Process -Name msedge -ErrorAction SilentlyContinue
		Stop-Process -Name firefox -ErrorAction SilentlyContinue
	}
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
function PutProfile($Usr, $Repo, $DestProfile){
	$ValidPasteProfiles = @()
	$FoldersToPaste = @("RootFolders\*","Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
	if (Test-Path $Repo){
		if (Test-Path $Repo\$Usr){
			Write-Host "Pasting Home Folder Contents"
			Get-ChildItem $Repo\$Usr | Foreach-Object{
				if($_.Directory){
					Copy-Item "$Repo\$Usr\$_" -Destination "$SystemDrive\Users\$DestProfile\"
				}
			}
			$FoldersTopaste | Foreach-Object{
				if ([string]$_ -eq "RootFolders\*"){
					Write-Host "Pasting Home Folder Folders"
				}
				else{
					Write-Host "Pasting $_ Folder"
				}
				PasteFiles "$Repo" "$_"
			}
			Stop-Process -Name chrome -ErrorAction SilentlyContinue
			Stop-Process -Name msedge -ErrorAction SilentlyContinue
			Stop-Process -Name firefox -ErrorAction SilentlyContinue

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
#START HERE
$SystemDrive = (Get-WmiObject Win32_OperatingSystem).SystemDrive
$CurrentUserPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ([string]$args[0] -eq "-c"){
	$Usr = $Env:UserName
	$Mode = "c"
}
elseif ([string]$args[0] -eq "-p"){
	$Mode = "p"
}
elseif ([string]$args[0] -eq "-h"){
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
	$Mode = Read-Host "Would you like to copy, copy other, or paste profile? (c,p)"
}
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
