#
# ServiceFabricUpdater.ps1
#

[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

<#
this function upserts an environmental variable for region to the manifest
#>
function Upsert-RegionEnvironmentVariable()
{
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [XML]$xml,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Region)

        Write-Output (Get-VstsLocString -Key 'PS_SvcManifestRegion' -ArgumentList $Region)

        $newEnv = $xml.CreateElement("EnvironmentVariable", "http://schemas.microsoft.com/2011/01/fabric")
        
        $newNameAttr = $xml.CreateAttribute("Name")
        $newNameAttr.Value = "DEPLOYMENT_REGION"
        
        $newValueAttr = $xml.CreateAttribute("Value")
        $newValueAttr.Value = $Region

        $newEnv.Attributes.Append($newNameAttr)
        $newEnv.Attributes.Append($newValueAttr)

        #insert or replace

        $envVar = $xml.ServiceManifest.CodePackage.EnvironmentVariables 

        if(!$envVar)
        {
            $newEnvVars = $xml.CreateElement("EnvironmentVariables", "http://schemas.microsoft.com/2011/01/fabric")
            $newEnvVars.AppendChild($newEnv)
            $xml.ServiceManifest.CodePackage.AppendChild($newEnvVars)
        }
        else
        {
            $oldEnv = $xml.ServiceManifest.CodePackage.EnvironmentVariables.EnvironmentVariable | ? {$_.Name -eq 'DEPLOYMENT_REGION'}
            if ($oldEnv)
            {
				$xml.ServiceManifest.CodePackage.EnvironmentVariables.ReplaceChild($newEnv, $oldEnv)
            }
            else
            {            
				$xml.ServiceManifest.CodePackage.EnvironmentVariables.AppendChild($newEnv)    
            }
        }

        Write-Output (Get-VstsLocString -Key 'PS_SvcManifestRegionSuccess' -ArgumentList $Region)     
}

try {
    Import-VstsLocStrings "$PSScriptRoot\task.json"

    # Get inputs.
    $input_errorActionPreference = Get-VstsInput -Name 'errorActionPreference' -Default 'Stop'
    switch ($input_errorActionPreference.ToUpperInvariant()) {
        'STOP' { }
        'CONTINUE' { }
        'SILENTLYCONTINUE' { }
        default {
            Write-Error (Get-VstsLocString -Key 'PS_InvalidErrorActionPreference' -ArgumentList $input_errorActionPreference)
        }
    }

    $input_AppManifestPath = Get-VstsInput -Name 'AppManifestPath' -Require
    $input_Version = Get-VstsInput -Name 'Version' -Require
    $input_VersionType = Get-VstsInput -Name 'VersionType' -Require
    $input_Port = Get-VstsInput -Name 'Port'
    $input_AppParametersPath = Get-VstsInput -Name 'AppParametersPath'
    $input_Tenant = Get-VstsInput -Name 'Tenant'
    $input_Environment = Get-VstsInput -Name 'Environment'    
    $input_Region = Get-VstsInput -Name 'Region'

    Write-Output "Inputs..."
    Write-Output "Applcation manifest path: $input_AppManifestPath"
    Write-Output "Version: $input_Version"
    Write-Output "Version type: $input_VersionType"
    Write-Output "Port: $input_Port"
    Write-Output "Application parameters path: $input_AppParametersPath"
    Write-Output "Tenant: $input_Tenant"
    Write-Output "Environment: $input_Environment"
    Write-Output "Region: $input_Region"

    #Guard against wrong files being passed in
    try {
        Assert-VstsPath -LiteralPath $input_AppManifestPath -PathType Leaf
    } catch {
        Write-Error (Get-VstsLocString -Key 'PS_InvalidFilePath' -ArgumentList $input_AppManifestPath)
    }
    
    if (!$input_AppManifestPath.ToUpperInvariant().EndsWith('APPLICATIONMANIFEST.XML')) {
        Write-Error (Get-VstsLocString -Key 'PS_InvalidFilePath' -ArgumentList $input_AppManifestPath)
    }

    #Update the AppManifest file
    $applicationManifestXml = [XML](Get-Content -Path $input_AppManifestPath)

    #Add a tenant code to the application name if one has been supplied
    if($input_Tenant){
        $newApplicationName = $applicationManifestXml.ApplicationManifest.ApplicationTypeName + "-$input_Tenant".ToUpperInvariant()
        $applicationManifestXml.ApplicationManifest.ApplicationTypeName = $newApplicationName
    }else {
        Write-Output (Get-VstsLocString -Key 'PS_NoTenant')
    }

    #Add an environment qualifier to the application name if one has been supplied
    if(($input_Environment -ne "empty") -and ($input_Environment -ne "")){
        $newApplicationName = $applicationManifestXml.ApplicationManifest.ApplicationTypeName + "-$input_Environment".ToUpperInvariant()
        $applicationManifestXml.ApplicationManifest.ApplicationTypeName = $newApplicationName
    }else {
        Write-Output (Get-VstsLocString -Key 'PS_NoEnvironment')
    }

    #Update the full version or just add a revision
    if($input_VersionType -eq "version") {
        $applicationManifestXml.ApplicationManifest.ApplicationTypeVersion = $input_Version
        $applicationManifestXml.ApplicationManifest.ServiceManifestImport | % { $_.ServiceManifestRef.ServiceManifestVersion = $input_Version }
    }
    else {        
        $newVersion = $applicationManifestXml.ApplicationManifest.ApplicationTypeVersion + "." + $input_Version
        $applicationManifestXml.ApplicationManifest.ApplicationTypeVersion = $newVersion
        $applicationManifestXml.ApplicationManifest.ServiceManifestImport | % { $_.ServiceManifestRef.ServiceManifestVersion = $newVersion }  
    }

    $applicationManifestXml.Save($input_AppManifestPath)

    Write-Output (Get-VstsLocString -Key 'PS_AppManifestUpdated' -ArgumentList $input_AppManifestPath)

    #Update the application name in the application parameters file
    if($input_AppParametersPath){
        Write-Output (Get-VstsLocString -Key 'PS_UpdatingAppParameters' -ArgumentList $input_AppParametersPath)
        $appParametersXml = [XML](Get-Content -Path $input_AppParametersPath)

        if($input_Tenant -ne "") {
            $newName = $appParametersXml.Application.Name + "-$input_Tenant"
        }

        if(($input_Environment -ne "" -and $input_Environment -ne "empty") -and $input_Tenant -ne "") {
            $newName = $newName + "-$input_Environment"
        }elseif(($input_Environment -ne "" -and $input_Environment -ne "empty")) {
            $newName = $appParametersXml.Application.Name + "-$input_Environment"
        }
            
        $appParametersXml.Application.Name = $newName   
            
        $appParametersXml.Save($input_AppParametersPath)         
    }

    #Find and update any ServiceManifests
    $path = (Get-Item $input_AppManifestPath).Directory.FullName

    $svcManifests = Get-ChildItem -Path $path -Include "ServiceManifest.xml" -Recurse

    $svcManifests | % {
        $serviceManifestPath = $_.FullName
        Write-Output (Get-VstsLocString -Key 'PS_UpdatingManifest' -ArgumentList $serviceManifestPath)
        $serviceManifestXml = [XML](Get-Content -Path $serviceManifestPath)    

        #Update the full version or just add a revision
        if($input_VersionType -eq "version") {
            $serviceManifestXml.ServiceManifest.Version = $input_Version
            $serviceManifestXml.ServiceManifest.CodePackage.Version = $input_Version
            $serviceManifestXml.ServiceManifest.ConfigPackage.Version = $input_Version
        }
        else {  
            $newVersion = $serviceManifestXml.ServiceManifest.Version + "." + $input_Version
            $serviceManifestXml.ServiceManifest.Version = $newVersion
            $serviceManifestXml.ServiceManifest.CodePackage.Version = $newVersion
            $serviceManifestXml.ServiceManifest.ConfigPackage.Version = $newVersion     
        }

        #Update the port number
        if($input_Port){
            $serviceManifestXml.ServiceManifest.Resources.Endpoints.Endpoint | % {
            $endPoint = $_
            
            if($endPoint.GetAttribute("Port")){
                $endPoint.Port = $input_Port
                $input_Port += 1
            }else {
                Write-Output (Get-VstsLocString -Key 'PS_MissingPortAttribute' -ArgumentList $endPoint.Name, $serviceManifestPath)
            }
        }
        }else {
            Write-Output (Get-VstsLocString -Key 'PS_NoPort')
        }
		
        #upsert region
        Upsert-RegionEnvironmentVariable $serviceManifestXml $input_Region

        $serviceManifestXml.Save($_.FullName)  

		Write-Output (Get-VstsLocString -Key 'PS_SvcManifestUpdated' -ArgumentList $_.FullName)        
    }
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
