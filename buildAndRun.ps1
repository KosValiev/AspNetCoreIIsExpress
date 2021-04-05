#build
dotnet build

#deploy
$CurrentDirectory = (Get-Location).tostring()
$Port = 44333
$SiteName = 'Test'
$HostName = 'localhost'
$IisExpressAdminCmd = 'C:\Program Files (x86)\IIS Express\IisExpressAdminCmd.exe'
$AppCmd = 'C:\Program Files (x86)\IIS Express\appcmd.exe'
$IisExpressCmd = 'C:\Program Files\IIS Express\iisexpress.exe'
$HostDirectory = Join-Path  $CurrentDirectory '.site'
$FirstSiteBuildDirectory = Join-Path  $CurrentDirectory 'src/AspNetCoreIIsExpress.Site1/bin/Debug/net5.0'
$SecondSiteBuildDirectory = Join-Path  $CurrentDirectory 'src/AspNetCoreIIsExpress.Site2/bin/Debug/net5.0'

#remove not default apppools
$AppPools = & $AppCmd list app /site.name:"$SiteName" | findstr /v "applicationPool:Clr4IntegratedAppPool" | SELECT-STRING  -Pattern '\(applicationPool:(.*?)\)'  -AllMatches | ForEach-Object { $_.Matches[0].Groups[1].Value }
foreach ($Pool in $AppPools){
    &$AppCmd delete apppool $Pool
}

# recreate site and set up certificate
&$AppCmd delete site "$SiteName"
&$AppCmd add site /name:"$SiteName" /bindings:http/*:${Port}:$HostName /physicalPath:"$HostDirectory"

# add neccessary asp.net core modules to iis if needed
$AspNetCoreModuleV2 =  &$AppCmd list modules /app.name:"$SiteName/" /name:'AspNetCoreModuleV2'
if ( $null -eq $AspNetCoreModuleV2 )
{
    &$AppCmd install module /name:AspNetCoreModuleV2 /image:"%IIS_BIN%\Asp.Net Core Module\V2\aspnetcorev2.dll"
}

$AspNetCoreModule =  &$AppCmd list modules /app.name:"$SiteName/" /name:'AspNetCoreModule'
if ( $null -eq $AspNetCoreModule )
{
    &$AppCmd install module /name:AspNetCoreModule /image:"%IIS_BIN%\aspnetcore.dll"
}

&$AppCmd set config "$SiteName" -section:system.webServer/aspNetCore

&$AppCmd add apppool /name:site1 /managedRuntimeVersion:""
&$AppCmd add app /site.name:"$SiteName" /path:/site1 /applicationPool:"site1" /physicalPath:"$FirstSiteBuildDirectory"

&$AppCmd add apppool /name:site2 /managedRuntimeVersion:""
&$AppCmd add app /site.name:"$SiteName" /path:/site2 /applicationPool:"site2" /physicalPath:"$SecondSiteBuildDirectory"

&$IisExpressCmd /site:$SiteName