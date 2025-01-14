#cheking admin rights
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$testadmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($testadmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}
Clear-Host

$Url = "https://github.com/technishroom/scripts/archive/refs/heads/main.zip"
$ExtractPath = "C:\Users\Public\Downloads\"
$DownloadZipFile = $ExtractPath + "Shroom.zip"
$NewFolderName = "Shroom Programs"
$DestinationPath = "$Home\AppData\Local\Shroom"

# Download zip file from url
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile

# Extract the zip file
$shell = New-Object -ComObject Shell.Application
$zipFolder = $shell.NameSpace($DownloadZipFile)
$destinationFolder = $shell.NameSpace($ExtractPath)
$destinationFolder.CopyHere($zipFolder.Items())

# Delete archive
Remove-Item $DownloadZipFile

# Rename the extracted folder
$extractedFolder = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
$renamedFolderPath = Join-Path -Path $ExtractPath -ChildPath $NewFolderName
Write-Host $renamedFolderPath
Move-Item -Path $extractedFolder.FullName -Destination $renamedFolderPath -Force

# Copy scripts to its destination
Copy-Item -path ($renamedFolderPath + "\Scripts") -Destination $DestinationPath -Recurse -Force
$FILE = Get-Item $DestinationPath -Force
$FILE.attributes = 'Hidden' 

$tasks = Get-ChildItem -Path ($renamedFolderPath + '\Tasks')
foreach ($task in $tasks) {
    $taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $task.Name }
    if ($taskExists) {
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
    }         
    Register-ScheduledTask -xml (Get-Content ($renamedFolderPath + '\Tasks\' + $task.Name ) | Out-String) -TaskPath "\Microsoft\Windows\" -TaskName $task.Name 
}

# Clean up
Remove-Item $renamedFolderPath -Force -Recurse
Clear-RecycleBin -Force