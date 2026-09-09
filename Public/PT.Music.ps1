function Start-PTMusic {
    <#
    .SYNOPSIS
        Inicia entornos acusticos y musica para enfoque, concentracion y sesiones de trabajo.
    .DESCRIPTION
        Proporciona acceso instantaneo a frecuencias de concentracion profunda (ruido marron,
        lo-fi beats, synthwave, ondas alfa) y estaciones personalizadas en YouTube Music (predeterminado),
        Spotify o flujos web, reduciendo la friccion y facilitando sesiones de trabajo productivas.
    .PARAMETER Station
        Identificador de la estacion a reproducir (ej. brown, lofi, synth, binaural)
        o nombre de una estacion personalizada. Si se omite, despliega el selector interactivo.
    .PARAMETER Provider
        Fuerza el proveedor de reproduccion ('YouTubeMusic', 'Spotify', 'WebStream'). Por defecto: YouTubeMusic.
    .PARAMETER Web
        Fuerza la apertura en navegador web en lugar de la aplicacion de escritorio cuando se usa Spotify.
    .PARAMETER List
        Lista todas las estaciones predefinidas y personalizadas registradas en el sistema.
    .PARAMETER Add
        Registra una nueva estacion personalizada en la configuracion del usuario.
    .PARAMETER Remove
        Elimina una estacion personalizada registrada previamente.
    .PARAMETER Url
        URL o URI de la estacion personalizada al utilizar -Add.
    .EXAMPLE
        ptmu brown
    .EXAMPLE
        ptmu lofi
    .EXAMPLE
        pt-music synth -Provider YouTubeMusic
    .EXAMPLE
        ptmu -Add -Station chill -Url "https://open.spotify.com/playlist/..."
    .EXAMPLE
        ptmu -List
    .EXAMPLE
        ptmu
    .OUTPUTS
        None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', DefaultParameterSetName = 'Play')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Play')]
        [string] $Station,

        [Parameter(ParameterSetName = 'Play')]
        [ValidateSet('YouTubeMusic', 'Spotify', 'Ambient', 'WebStream', 'Auto')]
        [string] $Provider,

        [Parameter(ParameterSetName = 'Play')]
        [switch] $Web,

        [Parameter(Mandatory = $true, ParameterSetName = 'List')]
        [switch] $List,

        [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
        [switch] $Add,

        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [switch] $Remove,

        [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
        [string] $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
        [string] $Url
    )

    begin {
        $e = [string][char]0x1B
        $theme = if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
            Get-PTAnsiTheme
        } else {
            @{
                Reset       = "$e[0m"
                Bold        = "$e[1m"
                Accent      = "$e[38;2;0;210;255m"
                Connector   = "$e[38;2;120;120;120m"
                HeaderIcon  = "$e[38;2;0;210;255m"
                FaintGray   = "$e[38;2;140;140;140m"
                Success     = "$e[38;2;46;204;113m"
                Warn        = "$e[38;2;241;196;15m"
            }
        }

        $sDiamond = [string][char]0x25C7
        $sPipe    = [string][char]0x2502
        $sCorner  = [string][char]0x2514
    }

    process {
        if ($List) {
            $catalog = Get-PTMusicCatalog
            Write-Host ""
            Write-Host "$($theme.HeaderIcon)$sDiamond$($theme.Reset)  $($theme.Bold)Catalogo de Audio y Enfoque$($theme.Reset)"
            Write-Host "$($theme.Connector)$sPipe$($theme.Reset)"

            foreach ($st in $catalog) {
                $customTag = if ($st.IsCustom) { " [Custom]" } else { "" }
                $idPad = "ptmu $($st.Id)$customTag".PadRight(22)
                Write-Host "$($theme.Connector)$sPipe$($theme.Reset)  $($theme.Success)$idPad$($theme.Reset)  $($theme.FaintGray)$($st.Description)$($theme.Reset)"
            }

            Write-Host "$($theme.Connector)$sPipe$($theme.Reset)"
            Write-Host "$($theme.Connector)$sCorner$($theme.Reset)  $($theme.FaintGray)Tip: Usa 'ptmu <estacion>' para iniciar reproduccion directa.$($theme.Reset)"
            Write-Host ""
            return
        }

        if ($Add) {
            $targetName = if (-not [string]::IsNullOrWhiteSpace($Name)) { $Name } else { $Station }
            if ([string]::IsNullOrWhiteSpace($targetName) -or [string]::IsNullOrWhiteSpace($Url)) {
                Write-Error "Debe especificar un nombre (-Name o -Station) y una URL (-Url) para registrar la estacion."
                return
            }

            $prov = if (-not [string]::IsNullOrWhiteSpace($Provider)) { $Provider } else { 'Auto' }
            Set-PTMusicStation -Name $targetName -Url $Url -Provider $prov
            if (Get-Command -Name 'Write-PTMessage' -ErrorAction SilentlyContinue) {
                Write-PTMessage -Level Success -Message "Estacion '$targetName' registrada exitosamente."
            }
            else {
                Write-Host "Estacion '$targetName' registrada exitosamente."
            }
            return
        }

        if ($Remove) {
            $targetName = if (-not [string]::IsNullOrWhiteSpace($Name)) { $Name } else { $Station }
            if ([string]::IsNullOrWhiteSpace($targetName)) {
                Write-Error "Debe especificar el nombre de la estacion a eliminar."
                return
            }

            $removed = Remove-PTMusicStation -Name $targetName
            if ($removed) {
                if (Get-Command -Name 'Write-PTMessage' -ErrorAction SilentlyContinue) {
                    Write-PTMessage -Level Success -Message "Estacion '$targetName' eliminada de la configuracion."
                }
                else {
                    Write-Host "Estacion '$targetName' eliminada de la configuracion."
                }
            }
            else {
                Write-Warning "No se encontro ninguna estacion personalizada con el nombre '$targetName'."
            }
            return
        }

        $catalog = Get-PTMusicCatalog
        $targetStationId = $Station

        if ([string]::IsNullOrWhiteSpace($targetStationId)) {
            if (Get-Command -Name 'Invoke-PTSelector' -ErrorAction SilentlyContinue) {
                $options = @($catalog | ForEach-Object {
                    [PSCustomObject]@{
                        Label       = $_.Label
                        Value       = $_.Id
                        Description = "[$($_.Category)] $($_.Description)"
                    }
                })

                $chosen = Invoke-PTSelector -Title "Seleccione una estacion de enfoque:" -Options $options -PageSize 8
                if ([string]::IsNullOrWhiteSpace($chosen)) {
                    return
                }

                $targetStationId = $chosen
            }
            else {
                Write-Warning "El selector interactivo no esta disponible."
                return
            }
        }

        $cleanTargetId = $targetStationId.Trim().ToLowerInvariant()
        $matchedStation = $null
        foreach ($st in $catalog) {
            if ($st.Id.ToLowerInvariant() -eq $cleanTargetId) {
                $matchedStation = $st
                break
            }
        }

        if (-not $matchedStation) {
            Write-Error "La estacion de audio '$targetStationId' no esta registrada en el catalogo."
            return
        }

        $preferProto = -not $Web.IsPresent
        $resolvedUri = Resolve-PTMusicUri -Station $matchedStation -ForceProvider $Provider -PreferProtocol:$preferProto

        if ([string]::IsNullOrWhiteSpace($resolvedUri)) {
            Write-Error "No fue posible resolver la URI de reproduccion para '$($matchedStation.Label)'."
            return
        }

        $actionDesc = "Reproducir estacion acustica '$($matchedStation.Label)'"
        if ($PSCmdlet.ShouldProcess($resolvedUri, $actionDesc)) {
            Start-Process -FilePath $resolvedUri
            if (Get-Command -Name 'Write-PTMessage' -ErrorAction SilentlyContinue) {
                Write-PTMessage -Level Info -Message "Iniciando audio de enfoque ($($matchedStation.Label)): $resolvedUri"
            }
        }
    }
}

New-Alias -Name 'pt-music' -Value Start-PTMusic -Force
New-Alias -Name 'ptmu'     -Value Start-PTMusic -Force

if (Get-Command -Name 'Register-ArgumentCompleter' -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName @('Start-PTMusic', 'pt-music', 'ptmu') -ParameterName 'Station' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $commandName; $null = $parameterName; $null = $commandAst; $null = $fakeBoundParameters

        $catalog = if (Get-Command -Name 'Get-PTMusicCatalog' -ErrorAction SilentlyContinue) {
            Get-PTMusicCatalog
        } else { @() }

        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        foreach ($st in $catalog) {
            if ($st.Id -like "$wordToComplete*") {
                $results.Add([System.Management.Automation.CompletionResult]::new($st.Id, $st.Id, [System.Management.Automation.CompletionResultType]::ParameterValue, "$($st.Label) - $($st.Description)"))
            }
        }
        return $results
    }
}
