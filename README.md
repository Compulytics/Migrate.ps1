# Migrate.ps1

Migrate.ps1 is a PowerShell script designed to perform a basic migration of Windows user profiles, including user data for Google Chrome, Firefox, and Microsoft Edge. This script can be run from a portable hard drive, USB disk, or through an RMM (Remote Monitoring and Management) solution. Its primary purpose is to clone a Windows user profile along with the associated browser data.

## Features
- Backup and restore Windows user profiles.
- Includes user data for Google Chrome, Firefox, and Microsoft Edge.
- Designed for ease of use with portable storage devices and RMM solutions.

## Usage

### Help Menu
Display the help menu:
```powershell
.\Migrate.ps1 -h
```

### Backup User Profile
Backup a user profile to a specified directory:
```powershell
.\Migrate.ps1 -c <source_user> <destination_path>
```
Example:
```powershell
.\Migrate.ps1 -c user1 E:\Profiles
```
This command backs up the profile of `user1` to the directory `E:\Profiles`.

### Restore User Profile
Restore a user profile from a backup directory and overwrite an existing user profile:
```powershell
.\Migrate.ps1 -p <source_user> <backup_path> <destination_user>
```
Example:
```powershell
.\Migrate.ps1 -p user1 E:\Profiles user2
```
This command restores the profile of `user1` from the directory `E:\Profiles` and overwrites the profile of `user2`.

## Requirements
- PowerShell
- Administrator privileges

## Notes
- Ensure the script is executed with administrative privileges to access and modify user profiles.
- Verify the destination path exists or can be created by the script.
