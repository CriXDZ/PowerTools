function Get-PTHistoryPath {

    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        if (Get-Command -Name 'Get-PSReadLineOption' -ErrorAction SilentlyContinue) {
            return (Get-PSReadLineOption).HistorySavePath
        }
    }
    catch { $null = $_ }

    if ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core') {
        return (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
    }
    else {
        $homeDir = if (Get-Command -Name 'Get-PTRootPath' -ErrorAction SilentlyContinue) {
            Get-PTRootPath -Location Home
        } else { $HOME }
        return (Join-Path $homeDir '.local/share/powershell/PSReadLine/ConsoleHost_history.txt')
    }
}

function Get-PTHistory {
    <#
    .SYNOPSIS
        Hub interactivo y gestor del historial de comandos de PSReadLine.
    .DESCRIPTION
        Permite consultar, optimizar duplicados, inspeccionar en bloc de notas o vaciar el historial de PSReadLine.
        Si se invoca sin parametros en sesion interactiva, despliega un menu TUI selector.
    .PARAMETER Search
        Texto o expresion a buscar en el historial.
    .PARAMETER Count
        Cantidad maxima de lineas a recuperar (ultimas N lineas). Por defecto: 50.
    .PARAMETER Unique
        Filtra comandos repetidos en la salida.
    .PARAMETER Deduplicate
        Remueve de forma permanente comandos duplicados del archivo de historial.
    .PARAMETER Clear
        Vacia de forma segura el archivo de historial de comandos.
    .PARAMETER Open
        Abre el archivo de historial en el Bloc de notas.
    .PARAMETER Interactive
        Fuerza la apertura del menu desplegable TUI interactivo.
    .EXAMPLE
        Get-PTHistory -Search "git"
    .EXAMPLE
        pt-hist
    .EXAMPLE
        pt-hist -Count 20 -Unique
    .OUTPUTS
        System.String
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([string[]])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string] $Search,

        [int] $Count = 50,

        [switch] $Unique,

        [switch] $Deduplicate,

        [switch] $Clear,

        [switch] $Open,

        [switch] $Interactive
    )

    process {

    $historyPath = Get-PTHistoryPath

    $shouldRunInteractive = $Interactive -or ($PSCmdlet.MyInvocation.BoundParameters.Count -eq 0 -and [Environment]::UserInteractive -and $env:PT_SILENT -ne '1')

    if ($shouldRunInteractive -and (Get-Command -Name 'Invoke-PTSelector' -ErrorAction SilentlyContinue)) {
        $options = @(
            [pscustomobject]@{ Label = '[1] Limpiar duplicados'; Description = 'Optimizar el archivo eliminando lineas repetidas'; Value = 'DEDUP' }
            [pscustomobject]@{ Label = '[2] Abrir en Bloc de notas'; Description = 'Inspeccionar el historial en el editor de texto'; Value = 'OPEN' }
            [pscustomobject]@{ Label = '[3] Vaciar historial completo'; Description = 'Limpiar completamente el archivo de historial'; Value = 'CLEAR' }
        )

        $choice = Invoke-PTSelector -Title "Hub de Historial de PSReadLine" -Options $options
        if (-not $choice) { return }

        switch ($choice) {
            'DEDUP' {
                return Get-PTHistory -Deduplicate
            }
            'OPEN' {
                return Get-PTHistory -Open
            }
            'CLEAR' {
                return Get-PTHistory -Clear
            }
        }
        return
    }

    if (-not (Test-Path -Path $historyPath)) {
        Write-PTMessage -Message "No se encontro el archivo de historial en: $historyPath" -Level Warn
        return
    }

    if ($Open) {
        $null = Invoke-PTEditor -Path $historyPath -Editor 'notepad'
        return
    }

    if ($Clear) {
        if ($PSCmdlet.ShouldProcess($historyPath, "Limpiar completamente el historial de comandos")) {
            try {
                Clear-Content -Path $historyPath -ErrorAction Stop
                Write-PTMessage -Message "Historial limpiado." -Level Success
            }
            catch {
                Write-PTMessage -Message "Error al limpiar el historial: $_" -Level Error
            }
        }
        return
    }

    if ($Deduplicate) {
        if ($PSCmdlet.ShouldProcess($historyPath, "Eliminar comandos duplicados del historial")) {
            try {
                $rawLines = Get-Content -Path $historyPath -ErrorAction Stop
                $cleanLines = $rawLines | Select-Object -Unique
                Set-Content -Path $historyPath -Value $cleanLines -Encoding UTF8 -Force
                $removedCount = $rawLines.Count - $cleanLines.Count
                if ($removedCount -gt 0) {
                    Write-PTMessage -Message "Historial optimizado (-$removedCount duplicados)." -Level Success
                }
                else {
                    Write-PTMessage -Message "Historial optimizado (sin duplicados)." -Level Success
                }
            }
            catch {
                Write-PTMessage -Message "Error al optimizar el historial: $_" -Level Error
            }
        }
        return
    }

    $lines = Get-Content -Path $historyPath -ErrorAction Stop

    if ($Search) {
        $lines = $lines | Where-Object { $_ -like "*$Search*" }
    }

    if ($Unique) {
        $lines = $lines | Select-Object -Unique
    }

    if ($Count -gt 0 -and $lines.Count -gt $Count) {
        $lines = $lines | Select-Object -Last $Count
    }

    return $lines
    }
}

function Invoke-PTCleanup {
    <#
    .SYNOPSIS
        Asistente inteligente de mantenimiento y limpieza (WinUtil Style).
    .DESCRIPTION
        Purga archivos temporales obsoletos (>24h), vacia la Papelera de Reciclaje y limpia caches de desarrollo/sistema con guardarrailes de seguridad.
    .PARAMETER Scope
        Alcance del mantenimiento: 'User', 'Dev', 'System' o 'Full'.
    .PARAMETER Interactive
        Fuerza la apertura del selector desplegable TUI interactivo.
    .EXAMPLE
        Invoke-PTCleanup -Scope User
    .EXAMPLE
        pt-clean -Scope Dev
    .EXAMPLE
        pt-clean -WhatIf
    .OUTPUTS
        None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [ValidateSet('User', 'Dev', 'System', 'Full')]
        [string] $Scope,

        [switch] $Interactive
    )

    $shouldRunInteractive = $Interactive -or (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Scope') -and [Environment]::UserInteractive -and $env:PT_SILENT -ne '1')

    if ($shouldRunInteractive -and (Get-Command -Name 'Invoke-PTSelector' -ErrorAction SilentlyContinue)) {
        $options = @(
            [pscustomobject]@{ Label = '[1] Temporales de Usuario'; Description = 'Purga de temporales >24h en %TEMP% y Papelera'; Value = 'User' }
            [pscustomobject]@{ Label = '[2] Caches de Desarrollo'; Description = 'Limpieza de caches de npm, pip y dotnet NuGet'; Value = 'Dev' }
            [pscustomobject]@{ Label = '[3] Caches del Sistema'; Description = 'Limpieza segura de temporales de Windows Update (Admin)'; Value = 'System' }
            [pscustomobject]@{ Label = '[4] Limpieza Completa'; Description = 'Ejecuta todas las tareas de mantenimiento disponibles'; Value = 'Full' }
        )

        $chosenScope = Invoke-PTSelector -Title "Asistente de Limpieza y Mantenimiento Seguros" -Options $options
        if (-not $chosenScope) { return }
        $Scope = $chosenScope
    }

    if (-not $Scope) {
        $Scope = 'User'
    }

    if (-not $PSCmdlet.ShouldProcess("Sistema ($Scope)", "Ejecutar mantenimiento y limpieza de temporales")) {
        return
    }

    if ($Scope -in @('User', 'Full')) {
        $userTemp = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
        if (Test-Path -Path $userTemp) {
            $threshold = (Get-Date).AddDays(-1)
            $oldItems = Get-ChildItem -Path $userTemp -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $threshold }
            foreach ($item in $oldItems) {
                try {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } catch { $null = $_ }
            }
        }

        if (Get-Command -Name 'Clear-RecycleBin' -ErrorAction SilentlyContinue) {
            try {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            } catch { $null = $_ }
        }
    }

    if ($Scope -in @('Dev', 'Full')) {
        if (Get-Command -Name 'npm' -ErrorAction SilentlyContinue) {
            try { & npm cache clean --force 2>$null } catch { $null = $_ }
        }
        if (Get-Command -Name 'pip' -ErrorAction SilentlyContinue) {
            try { & pip cache purge 2>$null } catch { $null = $_ }
        }
        if (Get-Command -Name 'dotnet' -ErrorAction SilentlyContinue) {
            try { & dotnet nuget locals all --clear 2>$null } catch { $null = $_ }
        }
    }

    if ($Scope -in @('System', 'Full') -and ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core')) {
        $systemTargets = @(
            "$env:windir\SoftwareDistribution\Download\*",
            "$env:SystemRoot\Temp\*"
        )

        foreach ($pattern in $systemTargets) {
            $baseDir = Split-Path -Parent $pattern
            if (Test-Path -Path $baseDir) {
                Remove-Item -Path $pattern -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-PTMessage -Message "Mantenimiento finalizado ($Scope)." -Level Success
}

New-Alias -Name 'pt-hist'  -Value Get-PTHistory    -Force
New-Alias -Name 'pth'      -Value Get-PTHistory    -Force
New-Alias -Name 'pt-clean' -Value Invoke-PTCleanup -Force
New-Alias -Name 'ptc'      -Value Invoke-PTCleanup -Force
