<#
.SYNOPSIS
    Navegacion rapida por marcadores deterministas y selector interactivo TUI.
.DESCRIPTION
    Permite saltar instantaneamente a carpetas clave del sistema o marcadores
    personalizados, gestionar marcadores persistentes o desplegar una interfaz TUI.
.PARAMETER Alias
    Nombre del marcador al que se desea navegar.
.PARAMETER List
    Emite todos los marcadores registrados como objetos estructurados al pipeline.
.PARAMETER Set
    Guarda un nuevo marcador personalizado con el alias indicado.
.PARAMETER Remove
    Elimina un marcador personalizado existente.
.PARAMETER Path
    Ruta a asociar al marcador al usar el parametro -Set (por defecto el directorio actual).
.EXAMPLE
    pt-go docs
.EXAMPLE
    pt-go -Set api ~/Projects/MyApi
.EXAMPLE
    pt-go -List
.EXAMPLE
    pt-go
#>
function Invoke-PTNavigate {
    [CmdletBinding(DefaultParameterSetName = 'Navigate', SupportsShouldProcess = $true)]
    [OutputType([System.Collections.Generic.List[PSCustomObject]], ParameterSetName = 'List')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Navigate')]
        [string] $Alias,

        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [switch] $List,

        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [string] $Set,

        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [string] $Remove,

        [Parameter(ParameterSetName = 'Set')]
        [string] $Path
    )

    if ($List) {
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()

        $sys = Get-PTSystemBookmark
        $uniqueSysKeys = @('home', 'desk', 'docs', 'down', 'proj')
        foreach ($k in $uniqueSysKeys) {
            if ($sys.Contains($k)) {
                $p = $sys[$k]
                $results.Add([PSCustomObject]@{
                    Alias       = $k
                    Path        = $p
                    DisplayPath = (Format-PTBreadcrumb -Path $p)
                    Type        = 'System'
                    Exists      = (Test-Path -Path $p)
                })
            }
        }

        $custom = Get-PTBookmark
        if ($custom -and $custom.PSObject.Properties) {
            foreach ($prop in $custom.PSObject.Properties) {
                $p = [string]$prop.Value
                $results.Add([PSCustomObject]@{
                    Alias       = $prop.Name
                    Path        = $p
                    DisplayPath = (Format-PTBreadcrumb -Path $p)
                    Type        = 'Custom'
                    Exists      = (Test-Path -Path $p)
                })
            }
        }

        return $results
    }

    if ($PSCmdlet.ParameterSetName -eq 'Set') {
        $targetPath = if ([string]::IsNullOrWhiteSpace($Path)) { $PWD.ProviderPath } else { (Resolve-PTWorkspacePath -Path $Path) }

        if (-not (Test-Path -Path $targetPath)) {
            Write-PTMessage -Level Warn -Message "La ruta especificada no existe: $targetPath"
            return
        }

        if ($PSCmdlet.ShouldProcess($Set, "Registrar marcador para '$targetPath'")) {
            Set-PTBookmark -Alias $Set -Path $targetPath | Out-Null
            $bc = Format-PTBreadcrumb -Path $targetPath
            Write-PTMessage -Level Success -Message "Marcador '$Set' registrado -> $bc"
        }
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Remove') {
        if ($PSCmdlet.ShouldProcess($Remove, "Eliminar marcador")) {
            $removed = Remove-PTBookmark -Alias $Remove
            if ($removed) {
                Write-PTMessage -Level Success -Message "Marcador '$Remove' eliminado."
            }
            else {
                Write-PTMessage -Level Warn -Message "No se encontro el marcador personalizado '$Remove'."
            }
        }
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($Alias)) {
        $targetPath = $null

        $sys = Get-PTSystemBookmark
        if ($sys.Contains($Alias.ToLowerInvariant())) {
            $targetPath = $sys[$Alias.ToLowerInvariant()]
        }
        else {
            $customPath = Get-PTBookmark -Alias $Alias
            if ($customPath) {
                $targetPath = $customPath
            }
        }

        if (-not $targetPath) {
            Write-PTMessage -Level Warn -Message "Marcador '$Alias' no reconocido. Usa 'pt-go' sin parametros para ver el catalogo."
            return
        }

        if (-not (Test-Path -Path $targetPath)) {
            Write-PTMessage -Level Error -Message "La ruta asociada al marcador no existe: $targetPath"
            return
        }

        Set-Location -Path $targetPath
        $bc = Format-PTBreadcrumb -Path $targetPath
        Write-PTMessage -Level Info -Message "Ubicacion: $bc"
        return
    }

    $options = [System.Collections.Generic.List[hashtable]]::new()

    $sys = Get-PTSystemBookmark
    $uniqueSysKeys = @('home', 'desk', 'docs', 'down', 'proj')
    foreach ($k in $uniqueSysKeys) {
        if ($sys.Contains($k)) {
            $p = $sys[$k]
            $bc = Format-PTBreadcrumb -Path $p
            $options.Add(@{
                Label       = $k
                Value       = $p
                Description = "[SYSTEM] $bc"
            })
        }
    }

    $custom = Get-PTBookmark
    if ($custom -and $custom.PSObject.Properties) {
        foreach ($prop in $custom.PSObject.Properties) {
            $p = [string]$prop.Value
            $bc = Format-PTBreadcrumb -Path $p
            $options.Add(@{
                Label       = $prop.Name
                Value       = $p
                Description = "[CUSTOM] $bc"
            })
        }
    }

    if ($options.Count -eq 0) {
        Write-PTMessage -Level Info -Message "No hay marcadores disponibles."
        return
    }

    $selected = Invoke-PTSelector -Title "Navegacion por Marcadores" -Options $options -AllowFilter

    if ($selected) {
        $targetPath = if ($selected -is [psobject] -and $selected.PSObject.Properties['Value']) { $selected.Value } else { [string]$selected }
        if (Test-Path -Path $targetPath) {
            Set-Location -Path $targetPath
            $bc = Format-PTBreadcrumb -Path $targetPath
            Write-PTMessage -Level Info -Message "Ubicacion: $bc"
        }
        else {
            Write-PTMessage -Level Error -Message "La ruta seleccionada no existe: $targetPath"
        }
    }
}

function Set-PTBookmarkShortcut {
    <#
    .SYNOPSIS
        Guarda el directorio actual o especificado como un marcador personalizado.
    .DESCRIPTION
        Registra un alias persistente en la configuracion del modulo PowerTools para saltos rapidos con pt-go.
    .PARAMETER Alias
        Nombre del marcador.
    .PARAMETER Path
        Ruta del directorio a guardar (por defecto el directorio actual).
    .EXAMPLE
        pt-mark api
    .EXAMPLE
        pt-mark docs ~/Documents/Notes
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Alias,

        [Parameter(Position = 1)]
        [string] $Path
    )

    $targetPath = if ([string]::IsNullOrWhiteSpace($Path)) { $PWD.ProviderPath } else { $Path }
    if ($PSCmdlet.ShouldProcess($Alias, "Guardar marcador para '$targetPath'")) {
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Invoke-PTNavigate -Set $Alias
        }
        else {
            Invoke-PTNavigate -Set $Alias -Path $Path
        }
    }
}

function Remove-PTBookmarkShortcut {
    <#
    .SYNOPSIS
        Elimina un marcador personalizado de PowerTools.
    .DESCRIPTION
        Remueve un alias de la configuracion persistente de marcadores.
    .PARAMETER Alias
        Nombre del marcador a eliminar.
    .EXAMPLE
        pt-unmark api
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Alias
    )

    if ($PSCmdlet.ShouldProcess($Alias, "Eliminar marcador")) {
        Invoke-PTNavigate -Remove $Alias
    }
}

New-Alias -Name 'pt-go'     -Value Invoke-PTNavigate         -Force
New-Alias -Name 'ptg'       -Value Invoke-PTNavigate         -Force
New-Alias -Name 'pt-mark'   -Value Set-PTBookmarkShortcut    -Force
New-Alias -Name 'ptm'       -Value Set-PTBookmarkShortcut    -Force
New-Alias -Name 'pt-unmark' -Value Remove-PTBookmarkShortcut -Force
New-Alias -Name 'ptum'      -Value Remove-PTBookmarkShortcut -Force

if (Get-Command -Name 'Register-ArgumentCompleter' -ErrorAction SilentlyContinue) {
    $navCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $parameterName; $null = $commandAst; $null = $fakeBoundParameters

        $completions = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

        if ($commandName -in @('pt-go', 'ptg', 'Invoke-PTNavigate')) {
            $sysBookmarks = Get-PTSystemBookmark
            foreach ($key in $sysBookmarks.Keys) {
                if ($key -like "$wordToComplete*") {
                    $path = $sysBookmarks[$key]
                    $completions.Add([System.Management.Automation.CompletionResult]::new($key, $key, [System.Management.Automation.CompletionResultType]::ParameterValue, "[SYSTEM] $path"))
                }
            }
        }

        $customBookmarks = Get-PTBookmark
        if ($customBookmarks -and $customBookmarks.PSObject.Properties) {
            foreach ($prop in $customBookmarks.PSObject.Properties) {
                $key = $prop.Name
                if ($key -like "$wordToComplete*") {
                    $path = [string]$prop.Value
                    $completions.Add([System.Management.Automation.CompletionResult]::new($key, $key, [System.Management.Automation.CompletionResultType]::ParameterValue, "[CUSTOM] $path"))
                }
            }
        }

        return $completions
    }

    Register-ArgumentCompleter -CommandName @('pt-go', 'ptg', 'Invoke-PTNavigate', 'pt-unmark', 'ptum', 'Remove-PTBookmarkShortcut') -ParameterName 'Alias' -ScriptBlock $navCompleter
}
