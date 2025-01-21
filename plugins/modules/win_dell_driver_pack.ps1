#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        catalog_temp_path = @{
            type = 'path'
            required = $true
        }
        download_path = @{
            type = 'path'
            required = $true
        }
        catalog_url = @{
            type = 'str'
            required = $false
            default = 'http://downloads.dell.com/catalog/DriverPackCatalog.cab'
        }
        os = @{
            type = 'str'
            required = $true
            choices = @(
                'winpe_11',
                'winpe_10',
                'win_11',
                'win_10'
            )
        }
        model = @{
            type = 'str'
            required = $false
        }
        create_version_subdirectory = @{
            type = 'bool'
            required = $false
            default = $true
        }
        disambiguation_method = @{
            type = 'str'
            required = $false
            default = 'newest'
            choices = @(
                'newest',
                'oldest'
            )
        }
    }
    required_if = @(
        @('os', 'win_11', @('model')),
        @('os', 'win_10', @('model'))
    )
    supports_check_mode = $false
}

$osToDellOsCode = @{
    winpe_11='winpe11x'
    winpe_10='winpe10x'
    win_11='Windows11'
    win_10='Windows10'
}
  
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$catalogTempPath = $module.Params['catalog_temp_path']
$downloadPath = $module.Params['download_path']
$catalogUrl = $module.Params['catalog_url']
$os = $module.Params['os']
$createVersionSubdirectory = $module.Params['create_version_subdirectory']
$disambiguationMethod = $module.Params['disambiguation_method']

$catalogTempPath = $catalogTempPath.TrimEnd("\")
$downloadPath = $downloadPath.TrimEnd("\")

if ([System.Uri]::IsWellFormedUriString($catalogUrl, [System.UriKind]::Absolute) -eq $false)
{
    $module.FailJson("Catalog URL '$catalogUrl' is not a valid URL.")
}

if (-not (Test-Path $catalogTempPath))
{
    $module.FailJson("Catalog temp directory '$catalogTempPath' does not exist or cannot be accessed.")
}

if (-not (Test-Path $downloadPath))
{
    $module.FailJson("Download directory '$downloadPath' does not exist or cannot be accessed.")
}

$catalogCabTempPath = Join-Path -Path $catalogTempPath -ChildPath 'DriverPackCatalog.cab'
$catalogXmlTempPath = Join-Path -Path $catalogTempPath -ChildPath 'DriverPackCatalog.xml'

if (Test-Path $catalogCabTempPath)
{
    try {
        Remove-Item -Path $catalogCabTempPath -Force | Out-Null
    }
    catch {
        $module.FailJson("Failed to remove existing catalog CAB file '$catalogCabTempPath'. Error: $_")
    }
}

if (Test-Path $catalogXmlTempPath)
{
    try {
        Remove-Item -Path $catalogXmlTempPath -Force | Out-Null
    }
    catch {
        $module.FailJson("Failed to remove existing catalog XML file '$catalogXmlTempPath'. Error: $_")
    }
}

$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($catalogUrl, $catalogCabTempPath)

if (-not (Test-Path $catalogCabTempPath))
{
    $module.FailJson("Failed to download catalog CAB file from '$catalogUrl'.")
}

try
{
    Start-Process "C:\Windows\System32\expand.exe" -ArgumentList @("""$($catalogCabTempPath)""", """$($catalogXmlTempPath)""") -Wait
}
catch
{
    $module.FailJson("Failed to extract catalog CAB file '$catalogCabTempPath'. Error: $_")
}

try
{
    [XML]$catalogData = Get-Content -Path $catalogXmlTempPath
}
catch
{
    $module.FailJson("Failed to parse the catalog file '$catalogXmlTempPath'. Error: $_")
}

$catalogVersion = $catalogData.DriverPackManifest.version    
$catalogBaseURL = "http://$($catalogData.DriverPackManifest.baseLocation)"
[array]$driverPacks = $catalogData.DriverPackManifest.DriverPackage

$isWinPE = $os -like 'winpe*'
$dellOsCode = $osToDellOsCode[$os]

$matchingDriverPacks = New-Object System.Collections.Generic.List[System.Xml.XmlElement]

foreach ($driverPack in $driverPacks)
{
    if (-not $isWinPE)
    {
        if (-not $driverPack.SupportedSystems)
        {
            continue
        }

        $supportedSystems = [Array]$driverPack.SupportedSystems

        $isSystemSupported = $false

        foreach ($supportedSystem in $supportedSystems)
        {
            if ($supportedSystem.Brand.Model.name -ieq $module.Params['model'])
            {
                $isSystemSupported = $true
                break
            }
        }

        if (-not $isSystemSupported)
        {
            continue
        }
    }

    if (-not $driverPack.SupportedOperatingSystems)
    {
        continue
    }

    $supportedOSes = [Array]$driverPack.SupportedOperatingSystems

    foreach ($supportedOS in $supportedOSes)
    {
        if ($supportedOS.OperatingSystem.osCode -eq $dellOsCode -and $supportedOS.OperatingSystem.osArch -eq 'x64')
        {
            $matchingDriverPacks.Add($driverPack)
            break
        }
    }
}

if ($matchingDriverPacks.Count -eq 0)
{
    if ($isWinPE)
    {
        $module.FailJson("No driver packs found for the specified OS '$os'.")
    }

    $module.FailJson("No driver packs found for the specified OS '$os' and model '$($module.Params['model'])'.")
}

if ($matchingDriverPacks.Count -gt 1)
{
    if ($disambiguationMethod -eq 'newest')
    {
        $selectedDateTime = [System.DateTime]::MinValue
    }
    else
    {
        $selectedDateTime = [System.DateTime]::MaxValue
    }

    $driverPack = $matchingDriverPacks[0]

    foreach ($matchingDriverPack in $matchingDriverPacks)
    {
        $driverPackDateTime = [System.DateTime]::Parse($matchingDriverPack.dateTime)

        if ($driverPackDateTime -gt $selectedDateTime -and $disambiguationMethod -eq 'newest')
        {
            $selectedDateTime = $driverPackDateTime
            $driverPack = $matchingDriverPack
        }

        if ($driverPackDateTime -lt $selectedDateTime -and $disambiguationMethod -eq 'oldest')
        {
            $selectedDateTime = $driverPackDateTime
            $driverPack = $matchingDriverPack
        }
    }
}
else
{
    $driverPack = $matchingDriverPacks[0]
}

$driverPackVersion = $driverPack.dellVersion
$driverPackURL = "$catalogBaseURL/$($driverPack.path)"
$driverPackFileName = [System.IO.Path]::GetFileName($driverPack.path)
$driverPackFormat = $driverPack.format

$downloadFinalPath = $downloadPath

if ($createVersionSubdirectory)
{
    $downloadFinalPath = Join-Path -Path $downloadPath -ChildPath $driverPackVersion
}

if (-not (Test-Path $downloadFinalPath))
{
    try
    {
        New-Item -Path $downloadFinalPath -ItemType Directory -Force | Out-Null
    }
    catch
    {
        $module.FailJson("Failed to create download directory '$downloadFinalPath'. Error: $_")
    }
}

$downloadFilePath = Join-Path -Path $downloadFinalPath -ChildPath $driverPackFileName

if ($driverPackFormat -eq 'exe')
{
    $downloadFilePath = $downloadFilePath -replace '\.exe$', '.zip'
}

$changed = $false
$module.Result["catalog_version"] = $catalogVersion
$module.Result["driver_pack_version"] = $driverPackVersion
$module.Result["driver_pack_path"] = $downloadFilePath
$module.Result["driver_format"] = $driverPackFormat

if (-not (Test-Path $downloadFilePath))
{
    $changed = $true
}
else
{
    $existingFileHash = Get-FileHash -Path $downloadFilePath -Algorithm MD5

    if ($existingFileHash.Hash -ine $driverPack.hashMD5)
    {
        $changed = $true
    }
}

if (-not $changed)
{
    $module.Result["changed"] = $false

    $module.ExitJson()
}

$webClient.DownloadFile($driverPackURL, $downloadFilePath)

$module.Result["changed"] = $true

$module.ExitJson()
