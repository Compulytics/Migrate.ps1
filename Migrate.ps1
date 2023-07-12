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
	$FoldersToCopy = @("Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
	$Dest = Read-Host "Enter Destination Path"
	if (Test-Path -Path $Dest\$Usr){
		Write-Host "User ID Already Exists"
		$Overwrite = Read-Host "Overwrite existing data? (y,n)"
		if ($Overwrite -eq "y"){
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
	Get-ChildItem $Home | Foreach-Object{
		if($_.Directory){
			Copy-Item "$Home\$_" -Destination "$Dest\$Usr\"
		}
	}
	$FoldersToCopy | Foreach-Object{
		Write-Host "Copying $_ Folder"
		$DestSub = "$Dest\$Usr\$_"
		CopyFiles "$HOME\$_" "$_"
	}
	Stop-Process -Name chrome -ErrorAction SilentlyContinue
	Stop-Process -Name msedge -ErrorAction SilentlyContinue
	Write-Host "Copying Chrome Data"
	Copy-Item "$Home\AppData\Local\Google\Chrome\User Data\Default" -Destination $Dest\$Usr\ChromeData\Default -Recurse
	Write-Host "Copying Edge Data"
	Copy-Item "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Destination $Dest\$Usr\EdgeData\Default -Recurse
}
function PutProfile{
	$FoldersToPaste = @("Contacts","Desktop","Documents","Downloads","Favorites","Music","Pictures","Videos")
	$Repo = Read-Host "Enter Profile Source Path"
	if (Test-Path $Repo){
		if (Test-Path $Repo\$Usr){
			Write-Host "Pasting Home Folder Contents"
			Get-ChildItem $Repo\$Usr | Foreach-Object{
				if($_.Directory){
					Copy-Item "$Repo\$Usr\$_" -Destination "$Home\"
				}
			}
			$FoldersTopaste | Foreach-Object{
				Write-Host "Pasting $_ Folder"
				PasteFiles "$Repo" "$_"
			}
			Stop-Process -Name chrome -ErrorAction SilentlyContinue
			Stop-Process -Name msedge -ErrorAction SilentlyContinue
			Write-Host "Pasting Chrome Data Folder"
			if (Test-Path "$Home\AppData\Local\Google\Chrome\User Data\Default"){
				remove-item "$Home\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
			}
			Copy-Item $Repo\$Usr\ChromeData\Default "$Home\AppData\Local\Google\Chrome\User Data\Default" -Force -Recurse
			Write-Host "Pasting Edge Data Folder"
			if (Test-Path "$Home\AppData\Local\Microsoft\Edge\User Data\Default"){
				remove-item "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
			}
			Copy-Item $Repo\$Usr\EdgeData\Default "$Home\AppData\Local\Microsoft\Edge\User Data\Default" -Force -Recurse
		}
		else{
			Write-Host "User Profile Not Found! (Username different at source and destination?)"
			exit
		}
	}
	else{
		Write-Host "Invalid Source Path!"
		exit
	}
}
$Usr = $Env:UserName
$Mode = Read-Host "Would you like to copy or paste profile? (c,p)"
if ($Mode -eq "c"){
	TakeProfile
}
elseif ($Mode -eq "p"){
	PutProfile
}
else{
	Write-Host "Invalid Selection!"
	exit
}
Write-Host "Done"