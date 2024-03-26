# Migrate.ps1
Does a basic migration of Windows user profiles including Chrome, Firefox, and Edge user data.
This program is designed to run off of a portable hard drive, USB disk, or through an RMM solution and its primary purpose is to clone a Windows user profile including user data for Google Chrome, Firefox, and Microsoft Edge.

Usage:
.\Migrate.ps1 -h..........................................Help Menu; 
.\Migrate.ps1 -c user1 E:\Profiles .......................Back-up user1's profile to E:\Profiles; 
.\Migrate.ps1 -p user1 E:\Profiles user2..................Overwrite user2's profile with the backup of user1's profile stored in E:\Profiles; 
