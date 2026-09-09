$script:PTConfigCache = $null

function Get-PTConfigDirectoryPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core') {
        $base = $env:LOCALAPPDATA
        if (-not $base) {
            $base = [Environment]::GetFolderPath('LocalApplicationData')
        }
        return (Join-Path -Path $base -ChildPath 'PowerTools')
    }
    else {
        $base = $env:XDG_CONFIG_HOME
        if (-not $base) {
            $base = Join-Path -Path $HOME -ChildPath '.config'
        }
        return (Join-Path -Path $base -ChildPath 'PowerTools')
    }
}

function Get-PTConfigFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return (Join-Path -Path (Get-PTConfigDirectoryPath) -ChildPath 'config.json')
}

function Get-PTDefaultSystemPaths {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $userProfile = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $desktop     = [Environment]::GetFolderPath('Desktop')
    $documents   = [Environment]::GetFolderPath('MyDocuments')

    if (-not $desktop)   { $desktop = Join-Path -Path $userProfile -ChildPath 'Desktop' }
    if (-not $documents) { $documents = Join-Path -Path $userProfile -ChildPath 'Documents' }

    return @{
        'home'     = $userProfile
        'desk'     = $desktop
        'docs'     = $documents
        'projects' = Join-Path -Path $documents -ChildPath 'Projects'
    }
}

function Get-PTDefaultConfig {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $defaultPaths = Get-PTDefaultSystemPaths
    return [pscustomobject]@{
        DefaultEditor = 'auto'
        SystemPaths   = $defaultPaths
        Preferences   = [pscustomobject]@{}
    }
}

function Read-PTConfig {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch] $ForceRefresh
    )

    if (-not $ForceRefresh -and $null -ne $script:PTConfigCache) {
        return $script:PTConfigCache
    }

    $configPath = Get-PTConfigFilePath
    if (-not (Test-Path -Path $configPath)) {
        $defaultConfig = Get-PTDefaultConfig
        $script:PTConfigCache = $defaultConfig
        return $defaultConfig
    }

    try {
        $raw = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        if (-not $obj) {
            $defaultConfig = Get-PTDefaultConfig
            $script:PTConfigCache = $defaultConfig
            return $defaultConfig
        }

        if (-not $obj.PSObject.Properties['SystemPaths'] -or -not $obj.SystemPaths) {
            $obj | Add-Member -NotePropertyName SystemPaths -NotePropertyValue (Get-PTDefaultSystemPaths) -Force
        }
        if (-not $obj.PSObject.Properties['Preferences']) {
            $obj | Add-Member -NotePropertyName Preferences -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        if (-not $obj.PSObject.Properties['DefaultEditor']) {
            $obj | Add-Member -NotePropertyName DefaultEditor -NotePropertyValue 'auto' -Force
        }

        $script:PTConfigCache = $obj
        return $obj
    }
    catch {
        $defaultConfig = Get-PTDefaultConfig
        $script:PTConfigCache = $defaultConfig
        return $defaultConfig
    }
}

function Write-PTConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    $dir = Get-PTConfigDirectoryPath
    if (-not [System.IO.Directory]::Exists($dir)) {
        $null = [System.IO.Directory]::CreateDirectory($dir)
    }

    $path = Get-PTConfigFilePath
    $json = $Config | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($path, $json, [System.Text.Encoding]::UTF8)
    $script:PTConfigCache = $Config
}

function Get-PTConfigProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key
    )

    $cfg = Read-PTConfig
    if ($cfg.PSObject.Properties[$Key]) {
        return $cfg.$Key
    }
    if ($cfg.Preferences -and $cfg.Preferences.PSObject.Properties[$Key]) {
        return $cfg.Preferences.$Key
    }
    if ($cfg.SystemPaths) {
        if ($cfg.SystemPaths -is [System.Collections.IDictionary] -and $cfg.SystemPaths.Contains($Key)) {
            return $cfg.SystemPaths[$Key]
        }
        if ($cfg.SystemPaths.PSObject.Properties[$Key]) {
            return $cfg.SystemPaths.$Key
        }
    }
    return $null
}

function Set-PTConfigProperty {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key,

        [Parameter()]
        [object] $Value
    )

    $cfg = Read-PTConfig -ForceRefresh

    if ($cfg.PSObject.Properties[$Key]) {
        $cfg.$Key = $Value
    }
    else {
        if (-not $cfg.Preferences -or -not ($cfg.Preferences -is [psobject])) {
            $cfg | Add-Member -NotePropertyName Preferences -NotePropertyValue ([pscustomobject]@{}) -Force
        }

        if ($cfg.Preferences.PSObject.Properties[$Key]) {
            $cfg.Preferences.$Key = $Value
        }
        else {
            $cfg.Preferences | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
        }
    }

    Write-PTConfig -Config $cfg
    return $cfg
}

function Get-PTBookmark {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [string] $Alias
    )

    $cfg = Read-PTConfig
    $bookmarks = if ($cfg.PSObject.Properties['Bookmarks'] -and $cfg.Bookmarks) {
        $cfg.Bookmarks
    } else {
        [pscustomobject]@{}
    }

    if ([string]::IsNullOrWhiteSpace($Alias)) {
        return $bookmarks
    }

    if ($bookmarks.PSObject.Properties[$Alias]) {
        return $bookmarks.$Alias
    }

    return $null
}

function Set-PTBookmark {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Alias,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $cfg = Read-PTConfig -ForceRefresh
    if (-not $cfg.PSObject.Properties['Bookmarks'] -or -not $cfg.Bookmarks) {
        $cfg | Add-Member -NotePropertyName Bookmarks -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    if ($cfg.Bookmarks.PSObject.Properties[$Alias]) {
        $cfg.Bookmarks.$Alias = $Path
    }
    else {
        $cfg.Bookmarks | Add-Member -NotePropertyName $Alias -NotePropertyValue $Path -Force
    }

    Write-PTConfig -Config $cfg
    return $cfg.Bookmarks
}

function Remove-PTBookmark {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Alias
    )

    $cfg = Read-PTConfig -ForceRefresh
    if (-not $cfg.PSObject.Properties['Bookmarks'] -or -not $cfg.Bookmarks) {
        return $false
    }

    if ($cfg.Bookmarks.PSObject.Properties[$Alias]) {
        $cfg.Bookmarks.PSObject.Properties.Remove($Alias)
        Write-PTConfig -Config $cfg
        return $true
    }

    return $false
}

function Get-PTMusicStation {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [string] $Name
    )

    $cfg = Read-PTConfig
    $stations = if ($cfg.PSObject.Properties['MusicStations'] -and $cfg.MusicStations) {
        $cfg.MusicStations
    } else {
        [pscustomobject]@{}
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $stations
    }

    if ($stations.PSObject.Properties[$Name]) {
        return $stations.$Name
    }

    return $null
}

function Set-PTMusicStation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Url,

        [string] $Provider = 'Auto'
    )

    $cfg = Read-PTConfig -ForceRefresh
    if (-not $cfg.PSObject.Properties['MusicStations'] -or -not $cfg.MusicStations) {
        $cfg | Add-Member -NotePropertyName MusicStations -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    $stationData = [pscustomobject]@{
        Url      = $Url
        Provider = $Provider
    }

    if ($cfg.MusicStations.PSObject.Properties[$Name]) {
        $cfg.MusicStations.$Name = $stationData
    }
    else {
        $cfg.MusicStations | Add-Member -NotePropertyName $Name -NotePropertyValue $stationData -Force
    }

    Write-PTConfig -Config $cfg
    return $cfg.MusicStations
}

function Remove-PTMusicStation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $cfg = Read-PTConfig -ForceRefresh
    if (-not $cfg.PSObject.Properties['MusicStations'] -or -not $cfg.MusicStations) {
        return $false
    }

    if ($cfg.MusicStations.PSObject.Properties[$Name]) {
        $cfg.MusicStations.PSObject.Properties.Remove($Name)
        Write-PTConfig -Config $cfg
        return $true
    }

    return $false
}

