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
						New-Item $DirectoryBuffer -ItemType Directory | Out-Null
					}
				}
			}
		}
		$File = $_.FullName
		$DSTFileName = $File.Replace($Src,"")
		if (!(Test-Path $DestSub$DSTFileName)){
			Copy-Item "$File" -Destination "$DestSub$DSTFileName"
		}
	}
}
function PasteFiles{
	param([string]$Repo, [string]$Folder)
	Copy-Item $Repo\$Usr\$Folder $Home -Recurse -Force -ErrorAction SilentlyContinue
}
function TakeProfile{
	param([parameter(Mandatory=$false)][string]$Dest)
	$FoldersToCopy = @("Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
	if ($Dest.Length -eq 0){
		$Dest = Read-Host "Enter Destination Path"
	}
	else{
		$Overwrite = "y"
	}
	if (Test-Path -Path $Dest\$Usr){
		if ($Overwrite){
			Write-Host "User ID Already Exists - Overwriting"
			remove-item $Dest\$Usr -Force -Recurse
		}
		else{
			Write-Host "User ID Already Exists"
			$Overwrite = Read-Host "Overwrite existing data? (y,n)"
			if ($Overwrite -eq "y"){
				remove-item $Dest\$Usr -Force -Recurse
			}
			else{
				exit
			}
		}
	}
	else{
		New-Item $Dest\$Usr -ItemType Directory | Out-Null
	}

	Write-Host "Copying Home Folder Contents"
	Get-ChildItem $Home | Foreach-Object{
		if($_.Directory){
			Copy-Item "$Home\$_" -Destination "$Dest\$Usr\"
		}
		else{
			if (!(Test-Path $Dest\$Usr\RootFolders)){
				New-Item $Dest\$Usr\RootFolders -ItemType Directory | Out-Null
			}
			if ([string]$_ -ne "Contacts" -and [string]$_ -ne "Desktop" -and [string]$_ -ne "Documents" -and [string]$_ -ne "Downloads" -and [string]$_ -ne "Favorites" -and [string]$_ -ne "Music" -and [string]$_ -ne "Music" -and [string]$_ -ne "Pictures" -and [string]$_ -ne "Videos" -and [string]$_ -ne "3D Objects" -and [string]$_ -ne "Links" -and [string]$_ -ne "OneDrive" -and [string]$_ -ne "Saved Games" -and [string]$_ -ne "Searches"){
				Copy-Item "$Home\$_" -Recurse -Destination "$Dest\$Usr\RootFolders"
			}
		}
	}
	$FoldersToCopy | Foreach-Object{
		Write-Host "Copying $_ Folder"
		$DestSub = "$Dest\$Usr\$_"
		CopyFiles "$HOME\$_" "$_"
	}
	Stop-Process -Name chrome -ErrorAction SilentlyContinue
	Stop-Process -Name msedge -ErrorAction SilentlyContinue
	Stop-Process -Name firefox -ErrorAction SilentlyContinue
	if (Test-Path "$Home\AppData\Local\Google\Chrome\User Data\Default"){
		Write-Host "Copying Chrome Data"
		Copy-Item "$Home\AppData\Local\Google\Chrome\User Data\Default" -Destination $Dest\$Usr\ChromeData\Default -Recurse
	}
	Write-Host "Copying Edge Data"
	Copy-Item "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Destination $Dest\$Usr\EdgeData\Default -Recurse
	if (Test-Path "$Home\AppData\Roaming\Mozilla\Firefox\Profiles"){
		Write-Host "Copying Firefox Data"
		Copy-Item "$Home\AppData\Roaming\Mozilla\Firefox\Profiles" -Destination $Dest\$Usr\FirefoxData\Profiles -Recurse
		Copy-Item "$Home\AppData\Roaming\Mozilla\Firefox\profiles.ini" -Destination $Dest\$Usr\FirefoxData\profiles.ini
	}
}
function PutProfile{
	param([parameter(Mandatory=$false)][string]$Repo)
	$ValidProfiles = @()
	$FoldersToPaste = @("RootFolders\*","Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
	if ($Repo.Length -eq 0){
		$Repo = Read-Host "Enter Destination Path"
	}
	if ($Usr.Length -eq 0){
		Write-Host "================================="
		Get-Childitem $Repo | Foreach-Object{if(!($_.directory)){Write-Host $_;$ValidProfiles += $_}}
		Write-Host "================================="
		$Usr = Read-Host "Which profile would you like to paste?"
		if (!($Usr.Contains($ValidProfiles))){
			Write-Host "Invalid Selection!"
			exit
		}
	}
	if (Test-Path $Repo){
		if (Test-Path $Repo\$Usr){
			Write-Host "Pasting Home Folder Contents"
			Get-ChildItem $Repo\$Usr | Foreach-Object{
				if($_.Directory){
					Copy-Item "$Repo\$Usr\$_" -Destination "$Home\"
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
				if (Test-Path "$Home\AppData\Local\Google\Chrome\User Data\Default"){
					remove-item "$Home\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
				}
				Copy-Item $Repo\$Usr\ChromeData\Default "$Home\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
			}

			Write-Host "Pasting Edge Data Folder"
			if (Test-Path "$Home\AppData\Local\Microsoft\Edge\User Data\Default"){
				remove-item "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
			}
			Copy-Item $Repo\$Usr\EdgeData\Default "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
			if (Test-Path $Repo\$Usr\FirefoxData\Profiles){
				Write-Host "Pasting Firefox Data Folder"
				if (Test-Path "$Home\AppData\Roaming\Mozilla\Firefox\Profiles"){
					remove-item "$Home\AppData\Roaming\Mozilla\Firefox\Profiles" -Force -Recurse
					remove-item "$Home\AppData\Roaming\Mozilla\Firefox\profiles.ini" -Force
				}
				Copy-Item $Repo\$Usr\FirefoxData\Profiles "$Home\AppData\Roaming\Mozilla\Firefox\Profiles" -Force -Recurse
				Copy-Item $Repo\$Usr\FirefoxData\profiles.ini  "$Home\AppData\Roaming\Mozilla\Firefox\profiles.ini"
			}
		}
		else{
			Write-Host "User Profile Not Found!"
			exit
		}
	}
	else{
		Write-Host "Invalid Source Path!"
		exit
	}
}
if ([string]$args[0] -eq "-c"){
	$Usr = $Env:UserName
	$Mode = "c"
}
elseif ([string]$args[0] -eq "-p"){
	$Mode = "p"
}
elseif ([string]$args[0] -eq "-h"){
	Write-Host "Usage:"
	Write-Host ".\ThisProgram.ps1 [OPTIONS] <PROFILE REPOSITORY PATH> [OPTIONS 2] <PROFILE NAME>"
	Write-Host "======================================================================="
	Write-Host "|| OPTIONS:                                                          ||"
	Write-Host "======================================================================="
	Write-Host "|| -c                                                   Copy Profile ||"
	Write-Host "|| -p                                                  Paste Profile ||"
	Write-Host "|| -h                                                Print This Page ||"
	Write-Host "======================================================================="
	Write-Host "|| OPTIONS 2:                                                        ||"
	Write-Host "======================================================================="
	Write-Host "|| -u                                           Paste <PROFILE NAME> ||"
	Write-Host "|| -a                       Assume (Automatically gets profile name) ||"
	Write-Host "======================================================================="
	Write-Host "||                                NOTE                               ||"
	Write-Host "======================================================================="
	Write-Host "|| OPTIONS 2 and PROFILE NAME are only valid when -p option selected ||"
	Write-Host "======================================================================="
	exit
}
else{
	$Mode = Read-Host "Would you like to copy or paste profile? (c,p)"
}
if ($Mode -eq "c"){
	$Usr = $Env:UserName
	if ([string]$args[1]){
		TakeProfile $args[1]
	}
	else{
		TakeProfile
	}
}
elseif ($Mode -eq "p"){
	if ([string]$args[1]){
		if ([string]$args[2]){
			if ([string]$args[2] -eq "-u"){
				if ([string]$args[3]){
					$Usr = [string]$args[3]
				}
			}
			elseif ([string]$args[2] -eq "-a"){
				$Usr = $Env:UserName
			}
		}
		PutProfile $args[1]
	}
	else{
		PutProfile
	}
}
else{
	Write-Host "Invalid Selection!"
	exit
}
Write-Host "Done"
