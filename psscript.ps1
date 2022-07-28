Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,

    [string]
    $AzurePassword,

    [string]
    $AzureTenantID,

    [string]
    $AzureSubscriptionID,

    [string]
    $ODLID,

    [string]
    $DeploymentID,

    [string]
    $InstallCloudLabsShadow
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 


#Download git repository
New-Item -ItemType directory -Path C:\AllFiles
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://codeload.github.com/MSUSSolutionAccelerators/Smart-Spaces-Sustainability-Solution-Accelerator/zip/refs/heads/main","C:\AllFiles\AllFiles.zip")

#unziping folder
function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}
Expand-ZIPFile -File "C:\AllFiles\AllFiles.zip" -Destination "C:\AllFiles\"


Function InstallAzPowerShellModule
{
    <#Install-PackageProvider NuGet -Force
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module Az -Repository PSGallery -Force -AllowClobber#>

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")
    sleep 5
    Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose 

}
InstallAzPowerShellModule

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon

CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID



#Import creds

. C:\LabFiles\AzureCreds.ps1

$AzureUserName 
$AzurePassword 
$passwd = ConvertTo-SecureString $AzurePassword -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureUserName, $passwd


Connect-AzAccount -Credential $cred | Out-Null

$RG=Get-AzResourceGroup 
$RGName=$RG.ResourceGroupName

Install-Module AzureAD -Force
Connect-AzureAD -Credential $cred
$ObjId = (Get-AzureADUser -Filter "UserPrincipalName eq '$AzureUserName'").ObjectId


$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/chakri42/Smart-spaces/main/deploy-02.json","C:\LabFiles\deploy-02.json")
$WebClient.DownloadFile("https://raw.githubusercontent.com/chakri42/Smart-spaces/main/deploy-02.parameters.json","C:\LabFiles\deploy-02.parameters.json")



(Get-Content -Path "C:\LabFiles\deploy-02.parameters.json") | ForEach-Object {$_ -Replace "None", "$ObjId"} | Set-Content -Path "C:\LabFiles\deploy-02.parameters.json"

#deploy armtemplate

Import-Module Az
Connect-AzAccount -Credential $cred
Select-AzSubscription -SubscriptionId $AzureSubscriptionID
New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile C:\LabFiles\deploy-02.json -TemplateParameterFile C:\LabFiles\deploy-02.parameters.json


#Download LogonTask
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/many-models/covid-19-vaccine-proof/scripts/logon.ps1","C:\LabFiles\logon.ps1")


#Enable Auto-Logon
#$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
#Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String
#Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String
#Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "Password.1!!" -type String
#Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord



# Scheduled Task
#$Trigger= New-ScheduledTaskTrigger -AtLogOn
#$User= "$($env:ComputerName)\demouser"
#$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File C:\LabFiles\logon.ps1"
#Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
#Set-ExecutionPolicy -ExecutionPolicy bypass -Force


#Function4 Install Chocolatey
Function InstallChocolatey
{   
    #[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
    #[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
    $env:chocolateyUseWindowsCompression = 'true'
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -Verbose
    choco feature enable -n allowGlobalConfirmation
}


#Install SQl Server Management studio
Function InstallSQLSMS
{
    choco install sql-server-management-studio -y -force
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Microsoft SQL Server Management Studio 18.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    $Shortcut.Save()

}


#Install Postman
choco install postman





