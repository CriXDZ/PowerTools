function Get-PTAvailableEditor {

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string] $Preferred
    )

    if ($Preferred -and $Preferred -ne 'auto') {
        $cmd = Get-Command -Name $Preferred -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
        if (Test-Path -Path $Preferred) {
            return $Preferred
        }
    }

    $candidates = @('antigravity-ide', 'antigravity', 'cursor', 'code', 'windsurf', 'zed', 'nvim', 'vim', 'subl', 'notepad', 'nano')

    foreach ($cand in $candidates) {
        $cmd = Get-Command -Name $cand -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    if ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core') {
        $localAppData = $env:LOCALAPPDATA
        $programFiles = $env:ProgramFiles
        $programFilesX86 = ${env:ProgramFiles(x86)}

        $standardPaths = @(
            (Join-Path $localAppData 'Programs\Antigravity IDE\bin\antigravity-ide.cmd'),
            (Join-Path $localAppData 'Programs\Antigravity IDE\Antigravity.exe'),
            (Join-Path $localAppData 'Programs\Antigravity\bin\antigravity.cmd'),
            (Join-Path $localAppData 'Programs\Antigravity\Antigravity.exe'),
            (Join-Path $localAppData 'Programs\cursor\Cursor.exe'),
            (Join-Path $localAppData 'Programs\Microsoft VS Code\Code.exe'),
            (Join-Path $programFiles 'Microsoft VS Code\Code.exe'),
            (Join-Path $programFilesX86 'Microsoft VS Code\Code.exe')
        )

        foreach ($exePath in $standardPaths) {
            if (Test-Path -Path $exePath) {
                return $exePath
            }
        }
    }

    if ($env:VISUAL -and (Get-Command -Name $env:VISUAL -ErrorAction SilentlyContinue)) {
        return $env:VISUAL
    }
    if ($env:EDITOR -and (Get-Command -Name $env:EDITOR -ErrorAction SilentlyContinue)) {
        return $env:EDITOR
    }

    return 'notepad'
}

function Invoke-PTEditor {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Path = (Get-Location).Path,

        [string] $Editor
    )

    $targetPath = if ([string]::IsNullOrWhiteSpace($Path)) {
        (Get-Location).Path
    } else {
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }

    $resolvedEditor = if ($Editor) {
        Get-PTAvailableEditor -Preferred $Editor
    }
    elseif ($script:PT -and $script:PT.Config -and $script:PT.Config.DefaultEditor) {
        Get-PTAvailableEditor -Preferred $script:PT.Config.DefaultEditor
    }
    else {
        Get-PTAvailableEditor
    }

    if (-not $resolvedEditor) {
        Write-PTMessage -Message "No se encontro un editor o IDE valido instalado en el sistema." -Level Error
        return
    }

    $editorName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedEditor).ToLowerInvariant()

    try {
        if ($editorName -in @('nvim', 'vim', 'nano', 'vi')) {
            & $resolvedEditor $targetPath
            return
        }

        if ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core') {
            if ($resolvedEditor -like "*.cmd" -or $resolvedEditor -like "*.bat") {
                $null = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$resolvedEditor`" `"$targetPath`"" -WindowStyle Hidden -ErrorAction Stop
                return
            }
        }

        $null = Start-Process -FilePath $resolvedEditor -ArgumentList $targetPath -ErrorAction Stop
        return
    }
    catch {
        try {
            $null = Start-Process -FilePath $resolvedEditor -ArgumentList $targetPath -UseShellExecute -ErrorAction Stop
            return
        }
        catch {
            Write-PTMessage -Message "No se pudo invocar el editor '$resolvedEditor': $_" -Level Error
            return
        }
    }
}

function Test-CommandAvailability {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $CommandName
    )

    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}
