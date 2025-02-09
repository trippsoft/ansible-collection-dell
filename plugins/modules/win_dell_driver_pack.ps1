#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        catalog_path = @{
            type = 'path'
            required = $true
        }
        download_path = @{
            type = 'path'
            required = $true
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
    winpe_11 = 'winpe11x'
    winpe_10 = 'winpe10x'
    win_11 = 'Windows11'
    win_10 = 'Windows10'
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$catalogPath = $module.Params['catalog_path']
$downloadPath = $module.Params['download_path']
$os = $module.Params['os']
$createVersionSubdirectory = $module.Params['create_version_subdirectory']
$disambiguationMethod = $module.Params['disambiguation_method']

$downloadPath = $downloadPath.TrimEnd("\")

if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    $module.FailJson("Catalog XML file '$catalogPath' does not exist or cannot be accessed.")
}

if (-not (Test-Path -LiteralPath $downloadPath -PathType Container)) {
    $module.FailJson("Download directory '$downloadPath' does not exist or cannot be accessed.")
}

[XML]$catalogData = Get-Content -LiteralPath $catalogPath

$catalogVersion = $catalogData.DriverPackManifest.version
$catalogBaseURL = "http://$($catalogData.DriverPackManifest.baseLocation)"
[Array]$driverPacks = $catalogData.DriverPackManifest.DriverPackage

$isWinPE = $os -like 'winpe*'
$dellOsCode = $osToDellOsCode[$os]

$matchingDriverPacks = New-Object System.Collections.Generic.List[System.Xml.XmlElement]

foreach ($driverPack in $driverPacks) {
    if (-not $isWinPE) {
        if (-not $driverPack.SupportedSystems) {
            continue
        }

        $supportedSystems = [Array]$driverPack.SupportedSystems

        $isSystemSupported = $false

        foreach ($supportedSystem in $supportedSystems) {
            if ($supportedSystem.Brand.Model.name -ieq $module.Params['model']) {
                $isSystemSupported = $true
                break
            }
        }

        if (-not $isSystemSupported) {
            continue
        }
    }

    if (-not $driverPack.SupportedOperatingSystems) {
        continue
    }

    $supportedOSes = [Array]$driverPack.SupportedOperatingSystems

    foreach ($supportedOS in $supportedOSes) {
        if ($supportedOS.OperatingSystem.osCode -eq $dellOsCode -and $supportedOS.OperatingSystem.osArch -eq 'x64') {
            $matchingDriverPacks.Add($driverPack) | Out-Null
            break
        }
    }
}

if ($matchingDriverPacks.Count -eq 0) {
    if ($isWinPE) {
        $module.FailJson("No driver packs found for the specified OS '$os'.")
    }

    $module.FailJson("No driver packs found for the specified OS '$os' and model '$($module.Params['model'])'.")
}

if ($matchingDriverPacks.Count -gt 1) {
    if ($disambiguationMethod -eq 'newest') {
        $selectedDateTime = [System.DateTime]::MinValue
    }
    else {
        $selectedDateTime = [System.DateTime]::MaxValue
    }

    $driverPack = $matchingDriverPacks[0]

    foreach ($matchingDriverPack in $matchingDriverPacks) {
        $driverPackDateTime = [System.DateTime]::Parse($matchingDriverPack.dateTime)

        if ($driverPackDateTime -gt $selectedDateTime -and $disambiguationMethod -eq 'newest') {
            $selectedDateTime = $driverPackDateTime
            $driverPack = $matchingDriverPack
        }

        if ($driverPackDateTime -lt $selectedDateTime -and $disambiguationMethod -eq 'oldest') {
            $selectedDateTime = $driverPackDateTime
            $driverPack = $matchingDriverPack
        }
    }
}
else {
    $driverPack = $matchingDriverPacks[0]
}

$driverPackVersion = $driverPack.dellVersion
$driverPackURL = "$catalogBaseURL/$($driverPack.path)"
$driverPackFileName = [System.IO.Path]::GetFileName($driverPack.path)
$driverPackFormat = $driverPack.format

$downloadFinalPath = $downloadPath

if ($createVersionSubdirectory) {
    $downloadFinalPath = Join-Path -Path $downloadPath -ChildPath $driverPackVersion
}

if (-not (Test-Path -LiteralPath $downloadFinalPath)) {
    New-Item -Path $downloadFinalPath -ItemType Directory -Force | Out-Null
}

$downloadFilePath = Join-Path -Path $downloadFinalPath -ChildPath $driverPackFileName

$changed = $false
$module.Result["catalog_version"] = $catalogVersion
$module.Result["driver_pack_version"] = $driverPackVersion
$module.Result["driver_pack_path"] = $downloadFilePath
$module.Result["driver_format"] = $driverPackFormat

if (-not (Test-Path -LiteralPath $downloadFilePath)) {
    $changed = $true
}
else {
    $existingFileHash = Get-FileHash -LiteralPath $downloadFilePath -Algorithm MD5

    if ($existingFileHash.Hash -ine $driverPack.hashMD5) {
        $changed = $true
    }
}

if (-not $changed) {
    $module.Result["changed"] = $false

    $module.ExitJson()
}

$webClient = New-Object System.Net.WebClient

$webClient.DownloadFile($driverPackURL, $downloadFilePath)

$module.Result["changed"] = $true

$module.ExitJson()
