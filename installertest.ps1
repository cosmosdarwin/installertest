#######################################
# Step 1 - Download the ISO if needed #
#######################################

$preexistingISO = Get-Item "C:\*" | Where-Object Name -Eq "ubuntu.iso"
if (!$preexistingISO) {
    $isoUrl = "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
    $outputPath = "C:\ubuntu.iso"
    Invoke-WebRequest -Uri $isoUrl -OutFile $outputPath
}

Write-Host -ForegroundColor Green "[Step 1] [Success] The .iso image is saved locally"

#####################################
# Step 2 - Enable Hyper-V if needed #
#####################################

if (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | Where-Object { $_.State -eq 'Enabled' }) {
    Write-Host -ForegroundColor Green "[Step 2] [Success] Hyper-V feature is enabled"
} else {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    Write-Host "[Step 2] [Pending] Restart required to finish enabling Hyper-V, please restart and then run this script again"
    exit
}

#######################################
# Step 3 - Create VM Switch if needed #
#######################################

$externalSwitch = Get-VMSwitch | Where-Object SwitchType -Eq External
if (!$externalSwitch) {
    $netAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    New-VMSwitch -Name "External" -NetAdapterName $netAdapter.Name -AllowManagementOS $true
}

Write-Host -ForegroundColor Green "[Step 3] [Success] Virtual switch of type External created"

################################
# Step 4 - Create VM if needed #
################################

$preexistingVM = Get-VM | Where-Object Name -Eq "InstallerScriptDemo"
if (!$preexistingVM) {
    New-VM -Name "InstallerScriptDemo" -MemoryStartupBytes 8GB -Generation 2 -SwitchName "External" > $Null
}
Write-Host -ForegroundColor Green "[Step 4] [Success] Virtual machine created"

#########################################
# Step 5 - Mount ISO and set boot order #
#########################################

$preexistingDvdDrive = Get-VMDvdDrive -VMName "InstallerScriptDemo"
if (!$preexistingDvdDrive) {
    Add-VMDvdDrive -VMName "InstallerScriptDemo" -Path "C:\ubuntu.iso"
    Set-VMFirmware -VMName "InstallerScriptDemo" -FirstBootDevice (Get-VMDvdDrive -VMName "InstallerScriptDemo" | Select-Object -First 1)
    Set-VMFirmware -VMName "InstallerScriptDemo" -SecureBootTemplate "MicrosoftUEFICertificateAuthority"
}

Write-Host -ForegroundColor Green "[Step 5] [Success] Set boot order to .iso first"

####################################
# Step 6 - Start and connect to VM #
####################################

Start-VM "InstallerScriptDemo" > $Null
Start-Process "vmconnect.exe" -ArgumentList "$env:COMPUTERNAME", "InstallerScriptDemo"

Write-Host -ForegroundColor Green "[Step 6] [Success] Started VM"