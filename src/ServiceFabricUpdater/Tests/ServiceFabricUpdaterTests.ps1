#
# ServiceFabricUpdaterTests.ps1
#

Import-Module ..\ps_modules\VstsTaskSdk

$applicationManifest = Get-ChildItem -Path . -Filter ApplicationManifest.xml
$serviceManifest = Get-ChildItem -Path . -Filter ServiceManifest.xml

$env:input_errorActionPreference = "CONTINUE"
$env:input_AppManifestPath = $applicationManifest.FullName
$env:input_Version = "4.8.1"
$env:input_VersionType = "version"
$env:input_Port = "9800"
$env:input_Environment = "SAND"
$env:input_Tenant = "TEST"
$env:input_Region ="West Europe"

Invoke-VstsTaskScript -ScriptBlock { . ..\ServiceFabricUpdater\ServiceFabricUpdater.ps1 }