function Search-PTWeb {
    <#
    .SYNOPSIS
        Busqueda web asistida con enrutamiento rapido por prefijos tecnicos y selector interactivo.
    .DESCRIPTION
        Ejecuta consultas directas en navegadores web enrutando por motores especializados
        (Google, DuckDuckGo, YouTube, GitHub, StackOverflow, DevDocs, MDN, Perplexity).
        Permite sintaxis directa por prefijo (ej. 'pts yt clean code') o interfaz interactiva TUI.
    .PARAMETER Query
        Terminos de la busqueda web. Si el primer termino coincide con un prefijo registrado
        (ej. yt, gh, so, mdn, dev, ai, g, d), la consulta se enruta a dicho proveedor.
    .PARAMETER Provider
        Fuerza explicitamente el proveedor o motor de busqueda deseado.
    .EXAMPLE
        Search-PTWeb "powershell 7 error handling"
    .EXAMPLE
        pts yt arquitectura de software
    .EXAMPLE
        pts gh ripgrep
    .EXAMPLE
        pts mdn array reduce
    .EXAMPLE
        pts
    .OUTPUTS
        None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]] $Query,

        [Parameter()]
        [string] $Provider
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
            }
        }

        $sDiamond = [string][char]0x25C7
        $sPipe    = [string][char]0x2502
        $sCorner  = [string][char]0x2514
    }

    process {
        $providers = Get-PTSearchProviders

        $selectedProvider = $null
        $searchTerms = $null

        if (-not $Query -or $Query.Count -eq 0) {
            if (Get-Command -Name 'Invoke-PTSelector' -ErrorAction SilentlyContinue) {
                $options = @($providers | ForEach-Object {
                    [PSCustomObject]@{
                        Label       = $_.Label
                        Value       = $_.Id
                        Description = "[$($_.Prefix)] $($_.Description)"
                    }
                })

                $chosenId = Invoke-PTSelector -Title "Seleccione el motor de busqueda:" -Options $options -PageSize 8
                if ([string]::IsNullOrWhiteSpace($chosenId)) {
                    return
                }

                $selectedProvider = $chosenId

                Write-Host ""
                Write-Host "$($theme.HeaderIcon)$sDiamond$($theme.Reset)  $($theme.Bold)Busqueda Web ($selectedProvider)$($theme.Reset)"
                Write-Host "$($theme.Connector)$sPipe$($theme.Reset)"
                Write-Host "$($theme.Connector)$sPipe$($theme.Reset)  $($theme.FaintGray)Ingrese los terminos de busqueda:$($theme.Reset) " -NoNewline
                $inputTerms = Read-Host
                if ([string]::IsNullOrWhiteSpace($inputTerms)) {
                    Write-Host "$($theme.Connector)$sCorner$($theme.Reset)  Busqueda cancelada." -ForegroundColor Yellow
                    return
                }
                $searchTerms = $inputTerms.Trim()
            }
            else {
                Write-Warning "El selector interactivo no esta disponible."
                return
            }
        }
        else {
            $firstToken = $Query[0].Trim().ToLowerInvariant()
            $matchingProvider = $null

            foreach ($p in $providers) {
                if ($p.Id.ToLowerInvariant() -eq $firstToken -or $p.Prefix.ToLowerInvariant() -eq $firstToken) {
                    $matchingProvider = $p
                    break
                }
            }

            if ($matchingProvider) {
                $selectedProvider = $matchingProvider.Id
                if ($Query.Count -gt 1) {
                    $searchTerms = ($Query[1..($Query.Count - 1)] -join ' ').Trim()
                }
                else {
                    Write-Host ""
                    Write-Host "$($theme.Connector)$sPipe$($theme.Reset)  $($theme.FaintGray)Ingrese terminos para $($matchingProvider.Label):$($theme.Reset) " -NoNewline
                    $inputTerms = Read-Host
                    if ([string]::IsNullOrWhiteSpace($inputTerms)) {
                        Write-Host "$($theme.Connector)$sCorner$($theme.Reset)  Busqueda cancelada." -ForegroundColor Yellow
                        return
                    }
                    $searchTerms = $inputTerms.Trim()
                }
            }
            else {
                $configuredDefault = if (Get-Command -Name 'Get-PTConfigProperty' -ErrorAction SilentlyContinue) {
                    Get-PTConfigProperty -Key 'DefaultSearchEngine'
                } else { $null }

                $selectedProvider = if (-not [string]::IsNullOrWhiteSpace($Provider)) {
                    $Provider
                } elseif (-not [string]::IsNullOrWhiteSpace($configuredDefault)) {
                    $configuredDefault
                } else {
                    'google'
                }

                $searchTerms = ($Query -join ' ').Trim()
            }
        }

        if ([string]::IsNullOrWhiteSpace($searchTerms)) {
            return
        }

        $url = Get-PTSearchUrl -Provider $selectedProvider -Query $searchTerms

        if ([string]::IsNullOrWhiteSpace($url)) {
            Write-Error "No fue posible generar la URL de busqueda para el proveedor '$selectedProvider'."
            return
        }

        $actionDesc = "Abrir busqueda web en navegador"
        if ($PSCmdlet.ShouldProcess($url, $actionDesc)) {
            Start-Process -FilePath $url
            if (Get-Command -Name 'Write-PTMessage' -ErrorAction SilentlyContinue) {
                Write-PTMessage -Level Info -Message "Abriendo busqueda ($selectedProvider): $searchTerms"
            }
        }
    }
}

New-Alias -Name 'pt-search' -Value Search-PTWeb -Force
New-Alias -Name 'pts'       -Value Search-PTWeb -Force

if (Get-Command -Name 'Register-ArgumentCompleter' -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName @('pt-search', 'pts', 'Search-PTWeb') -ParameterName 'Provider' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $commandName; $null = $parameterName; $null = $commandAst; $null = $fakeBoundParameters

        $providers = if (Get-Command -Name 'Get-PTSearchProviders' -ErrorAction SilentlyContinue) {
            Get-PTSearchProviders
        } else { @() }

        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        foreach ($p in $providers) {
            if ($p.Id -like "$wordToComplete*" -or $p.Prefix -like "$wordToComplete*") {
                $results.Add([System.Management.Automation.CompletionResult]::new($p.Id, $p.Id, [System.Management.Automation.CompletionResultType]::ParameterValue, "$($p.Label) - $($p.Description)"))
            }
        }
        return $results
    }
}
