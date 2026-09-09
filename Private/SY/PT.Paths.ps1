function Get-PTRootPath {

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [ValidateSet('Projects', 'Documents', 'Desktop', 'Home', 'Downloads')]
        [string] $Location = 'Projects'
    )

    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($HOME) { $HOME } else { [Environment]::GetFolderPath('UserProfile') }

    switch ($Location) {
        'Home' {
            return $homeDir
        }
        'Desktop' {
            $desk = [Environment]::GetFolderPath('Desktop')
            if (-not $desk) { $desk = Join-Path -Path $homeDir -ChildPath 'Desktop' }
            return $desk
        }
        'Documents' {
            $docs = [Environment]::GetFolderPath('MyDocuments')
            if (-not $docs) { $docs = Join-Path -Path $homeDir -ChildPath 'Documents' }
            return $docs
        }
        'Projects' {
            $docs = [Environment]::GetFolderPath('MyDocuments')
            if (-not $docs) { $docs = Join-Path -Path $homeDir -ChildPath 'Documents' }
            return (Join-Path -Path $docs -ChildPath 'Projects')
        }
        'Downloads' {
            return (Join-Path -Path $homeDir -ChildPath 'Downloads')
        }
    }
}

function Get-PTSystemBookmark {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()

    $homeDir = Get-PTRootPath -Location Home
    $desk    = Get-PTRootPath -Location Desktop
    $docs    = Get-PTRootPath -Location Documents
    $proj    = Get-PTDefaultProjectPath
    $down    = Get-PTRootPath -Location Downloads

    return [ordered]@{
        'home'      = $homeDir
        'user'      = $homeDir
        'desk'      = $desk
        'desktop'   = $desk
        'docs'      = $docs
        'documents' = $docs
        'down'      = $down
        'downloads' = $down
        'proj'      = $proj
        'projects'  = $proj
    }
}

function Resolve-PTWorkspacePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $PWD.ProviderPath
    }

    $trimmed = $Path.Trim()

    if ($trimmed -eq '~') {
        return (Get-PTRootPath -Location Home)
    }
    if ($trimmed.StartsWith('~/') -or $trimmed.StartsWith('~\')) {
        $homeDir = Get-PTRootPath -Location Home
        $subPath = $trimmed.Substring(2)
        return (Join-Path -Path $homeDir -ChildPath $subPath)
    }

    try {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($trimmed)
    }
    catch {
        return [System.IO.Path]::GetFullPath($trimmed)
    }
}

function Get-PTDefaultProjectPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $configured = if (Get-Command -Name 'Get-PTConfigProperty' -ErrorAction SilentlyContinue) {
        Get-PTConfigProperty -Key 'projects'
    } else { $null }

    if ($configured -and [string]::IsNullOrWhiteSpace([string]$configured) -eq $false) {
        return (Resolve-PTWorkspacePath -Path ([string]$configured))
    }

    $cfg = if (Get-Command -Name 'Read-PTConfig' -ErrorAction SilentlyContinue) { Read-PTConfig } else { $null }
    if ($cfg -and $cfg.SystemPaths -and $cfg.SystemPaths.projects) {
        return (Resolve-PTWorkspacePath -Path $cfg.SystemPaths.projects)
    }

    return (Get-PTRootPath -Location Projects)
}
