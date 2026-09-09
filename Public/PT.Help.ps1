function Show-PTHelp {
    <#
    .SYNOPSIS
        Muestra el catalogo completo de comandos o la ficha tecnica de un comando o categoria en PowerTools.
    .DESCRIPTION
        Despliega la guia contextual moderna estilo Vercel CLI con los atajos del modulo,
        soporte para filtrado por categorias (incluyendo sinonimos como 'audio', 'focus', 'dev')
        e inspeccion tecnica detallada de comandos y micro-alias (ej. 'pt-music', 'ptmu', 'ptm').
    .PARAMETER Target
        Nombre de categoria, sinonimo de categoria, comando publico o micro-alias a inspeccionar.
        Por defecto es 'All' para desplegar el catalogo completo.
    .EXAMPLE
        pt-help
    .EXAMPLE
        pt-help Enfoque
    .EXAMPLE
        pt-help audio
    .EXAMPLE
        pt-help pt-music
    .EXAMPLE
        phlp ptm
    .OUTPUTS
        None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Categoria')]
        [string] $Target = 'All'
    )

    $t = if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
        Get-PTAnsiTheme
    } else {
        $e = [string][char]0x1B
        @{
            Reset       = "$e[0m"
            Bold        = "$e[1m"
            Accent      = "$e[38;2;0;210;255m"
            Connector   = "$e[38;2;120;120;120m"
            HeaderIcon  = "$e[38;2;0;210;255m"
            FaintGray   = "$e[38;2;140;140;140m"
            Success     = "$e[1;32m"
            Warn        = "$e[1;33m"
        }
    }

    $symDiamond = [string][char]0x25C7
    $symPipe    = [string][char]0x2502
    $symCorner  = [string][char]0x2514
    $symLine    = [string][char]0x2500
    $symCross   = [string][char]0x2716

    $catalogo = [ordered]@{
        'Desarrollo' = @{
            Tag      = '[DEV]'
            Title    = 'Desarrollo y Scaffolding'
            Commands = @(
                @{ Cmd = 'pt-new, ptn [nombre]'; Desc = 'Inicializa un nuevo proyecto mediante scaffolding e integracion con IDE' }
            )
        }
        'Navegacion' = @{
            Tag      = '[NAV]'
            Title    = 'Navegacion y Marcadores'
            Commands = @(
                @{ Cmd = 'pt-go, ptg [marcador]';   Desc = 'Navegacion rapida por marcadores y selector interactivo' }
                @{ Cmd = 'pt-mark, ptm <alias>';    Desc = 'Guarda el directorio actual como marcador personalizado' }
                @{ Cmd = 'pt-unmark, ptum <alias>'; Desc = 'Elimina un marcador personalizado de la configuracion' }
            )
        }
        'Web' = @{
            Tag      = '[WEB]'
            Title    = 'Busqueda Web y Documentacion'
            Commands = @(
                @{ Cmd = 'pt-search, pts [p] <q>'; Desc = 'Busqueda web asistida (Google, YT, GitHub, SO, MDN, Perplexity)' }
            )
        }
        'Enfoque' = @{
            Tag      = '[FOCUS]'
            Title    = 'Audio y Enfoque'
            Commands = @(
                @{ Cmd = 'pt-music, ptmu [estacion]'; Desc = 'Entornos sonoros para concentracion profunda (rain, brown, lofi, synth, binaural)' }
            )
        }
        'Sistema' = @{
            Tag      = '[SYS]'
            Title    = 'Sistema y Mantenimiento'
            Commands = @(
                @{ Cmd = 'pt-hist, pth [filtro]'; Desc = 'Hub interactivo de historial, edicion de perfil y mantenimiento' }
                @{ Cmd = 'pt-clean, ptc [-Scope]'; Desc = 'Asistente de mantenimiento seguro de temporales y caches (User/Dev/System/Full)' }
            )
        }
    }

    $commandMap = [ordered]@{
        'New-PTProject' = @{
            Canonical   = 'New-PTProject'
            Aliases     = @('pt-new', 'ptn')
            Category    = 'Desarrollo'
            Tag         = '[DEV]'
            Synopsis    = 'Inicializa un nuevo proyecto mediante scaffolding declarativo e integracion con IDE.'
            Syntax      = 'pt-new [-ProjectName] <String> [[-Template] <String>] [-WithGit] [-OpenWith <String>]'
            Examples    = @(
                @{ Code = 'pt-new MiApp -Template node -WithGit'; Desc = 'Crea proyecto Node.js e inicializa Git' }
                @{ Code = 'ptn Backend -Template go -OpenWith code'; Desc = 'Crea proyecto Go y lo abre en VS Code' }
                @{ Code = 'ptn'; Desc = 'Abre el selector interactivo TUI de plantillas' }
            )
        }
        'Invoke-PTNavigate' = @{
            Canonical   = 'Invoke-PTNavigate'
            Aliases     = @('pt-go', 'ptg')
            Category    = 'Navegacion'
            Tag         = '[NAV]'
            Synopsis    = 'Navegacion rapida por marcadores de rutas y selector interactivo TUI.'
            Syntax      = 'pt-go [[-Target] <String>] [-Interactive]'
            Examples    = @(
                @{ Code = 'pt-go work'; Desc = 'Cambia directamente a la ruta del marcador work' }
                @{ Code = 'ptg'; Desc = 'Abre el selector interactivo TUI de marcadores guardados' }
            )
        }
        'Set-PTBookmarkShortcut' = @{
            Canonical   = 'Set-PTBookmarkShortcut'
            Aliases     = @('pt-mark', 'ptm')
            Category    = 'Navegacion'
            Tag         = '[NAV]'
            Synopsis    = 'Guarda el directorio actual o especificado como marcador rapido persistente.'
            Syntax      = 'pt-mark [-Alias] <String> [[-Path] <String>]'
            Examples    = @(
                @{ Code = 'pt-mark api'; Desc = 'Guarda el directorio actual con el alias api' }
                @{ Code = 'ptm docs C:\Proyectos\Docs'; Desc = 'Guarda una ruta especifica como marcador' }
            )
        }
        'Remove-PTBookmarkShortcut' = @{
            Canonical   = 'Remove-PTBookmarkShortcut'
            Aliases     = @('pt-unmark', 'ptum')
            Category    = 'Navegacion'
            Tag         = '[NAV]'
            Synopsis    = 'Elimina un marcador guardado de la configuracion persistente.'
            Syntax      = 'pt-unmark [-Alias] <String>'
            Examples    = @(
                @{ Code = 'pt-unmark api'; Desc = 'Elimina el marcador api' }
                @{ Code = 'ptum temp'; Desc = 'Elimina el marcador temp usando micro-alias' }
            )
        }
        'Search-PTWeb' = @{
            Canonical   = 'Search-PTWeb'
            Aliases     = @('pt-search', 'pts')
            Category    = 'Web'
            Tag         = '[WEB]'
            Synopsis    = 'Busqueda web asistida con enrutamiento por prefijos tecnicos y selector interactivo.'
            Syntax      = 'pt-search [[-Query] <String[]>] [-Provider <String>]'
            Examples    = @(
                @{ Code = 'pts yt clean code'; Desc = 'Busqueda directa de videos tecnicos en YouTube' }
                @{ Code = 'pts gh ripgrep'; Desc = 'Busqueda de repositorios en GitHub' }
                @{ Code = 'pts'; Desc = 'Abre el selector interactivo TUI de motores de busqueda' }
            )
        }
        'Start-PTMusic' = @{
            Canonical   = 'Start-PTMusic'
            Aliases     = @('pt-music', 'ptmu')
            Category    = 'Enfoque'
            Tag         = '[FOCUS]'
            Synopsis    = 'Inicia entornos acusticos y musica para concentracion profunda y sesiones de trabajo.'
            Syntax      = 'pt-music [[-Station] <String>] [-Provider <String>] [-List] [-PreferProtocol]'
            Examples    = @(
                @{ Code = 'pt-music rain'; Desc = 'Inicia lluvia suave y tormenta para aislamiento sonoro' }
                @{ Code = 'ptmu lofi'; Desc = 'Inicia Lo-Fi beats en YouTube Music en modo directo' }
                @{ Code = 'ptmu synth -Provider Spotify'; Desc = 'Inicia Synthwave directamente en Spotify Web' }
                @{ Code = 'ptmu'; Desc = 'Abre el selector interactivo TUI de entornos sonoros' }
            )
        }
        'Get-PTHistory' = @{
            Canonical   = 'Get-PTHistory'
            Aliases     = @('pt-hist', 'pth')
            Category    = 'Sistema'
            Tag         = '[SYS]'
            Synopsis    = 'Hub interactivo de historial de comandos, deduplicacion y busqueda rapida.'
            Syntax      = 'pt-hist [[-Filter] <String>] [-Deduplicate] [-Interactive]'
            Examples    = @(
                @{ Code = 'pt-hist git'; Desc = 'Filtra comandos ejecutados que contengan git' }
                @{ Code = 'pth -Deduplicate'; Desc = 'Elimina lineas duplicadas conservando la cronologia' }
                @{ Code = 'pth'; Desc = 'Abre el selector interactivo TUI para re-ejecutar comandos' }
            )
        }
        'Invoke-PTCleanup' = @{
            Canonical   = 'Invoke-PTCleanup'
            Aliases     = @('pt-clean', 'ptc')
            Category    = 'Sistema'
            Tag         = '[SYS]'
            Synopsis    = 'Asistente de mantenimiento seguro de temporales obsoletos y caches de desarrollo.'
            Syntax      = 'pt-clean [[-Scope] <String>] [-DryRun]'
            Examples    = @(
                @{ Code = 'pt-clean'; Desc = 'Inicia el asistente guiado de mantenimiento' }
                @{ Code = 'ptc -Scope Dev'; Desc = 'Limpia caches de desarrollo (npm, pip, dotnet)' }
                @{ Code = 'ptc -Scope Full -DryRun'; Desc = 'Simula limpieza completa sin eliminar ningun archivo' }
            )
        }
        'Show-PTHelp' = @{
            Canonical   = 'Show-PTHelp'
            Aliases     = @('pt-help', 'phlp')
            Category    = 'Sistema'
            Tag         = '[SYS]'
            Synopsis    = 'Muestra el catalogo completo o la ficha tecnica de un comando o categoria.'
            Syntax      = 'pt-help [[-Target] <String>]'
            Examples    = @(
                @{ Code = 'pt-help'; Desc = 'Muestra el catalogo general con todos los comandos' }
                @{ Code = 'pt-help Enfoque'; Desc = 'Muestra solo los comandos de una categoria (o pt-help audio)' }
                @{ Code = 'pt-help pt-music'; Desc = 'Muestra la ficha tecnica detallada de un comando' }
                @{ Code = 'phlp ptm'; Desc = 'Consulta la ficha tecnica usando el micro-alias del comando' }
            )
        }
    }

    $categorySynonyms = @{
        'all'           = 'All'
        'todo'          = 'All'
        'todos'         = 'All'

        'desarrollo'    = 'Desarrollo'
        'dev'           = 'Desarrollo'
        'scaffold'      = 'Desarrollo'
        'scaffolding'   = 'Desarrollo'
        '[dev]'         = 'Desarrollo'

        'navegacion'    = 'Navegacion'
        'nav'           = 'Navegacion'
        'marcador'      = 'Navegacion'
        'marcadores'    = 'Navegacion'
        'bookmark'      = 'Navegacion'
        'bookmarks'     = 'Navegacion'
        '[nav]'         = 'Navegacion'

        'web'           = 'Web'
        'busqueda'      = 'Web'
        'search'        = 'Web'
        'doc'           = 'Web'
        'docs'          = 'Web'
        '[web]'         = 'Web'

        'enfoque'       = 'Enfoque'
        'focus'         = 'Enfoque'
        'audio'         = 'Enfoque'
        'musica'        = 'Enfoque'
        'music'         = 'Enfoque'
        'sound'         = 'Enfoque'
        '[focus]'       = 'Enfoque'

        'sistema'       = 'Sistema'
        'sys'           = 'Sistema'
        'system'        = 'Sistema'
        'mantenimiento' = 'Sistema'
        'clean'         = 'Sistema'
        'hist'          = 'Sistema'
        'historial'     = 'Sistema'
        '[sys]'         = 'Sistema'
    }

    if ($env:PT_SILENT -eq '1') {
        return
    }

    $rawTarget = if ([string]::IsNullOrWhiteSpace($Target)) { 'All' } else { $Target.Trim() }
    $lowerTarget = $rawTarget.ToLowerInvariant()

    # 1. Inspeccion de Comando o Micro-Alias
    $matchedCmd = $null
    foreach ($k in $commandMap.Keys) {
        $c = $commandMap[$k]
        if ($k.ToLowerInvariant() -eq $lowerTarget) {
            $matchedCmd = $c
            break
        }
        foreach ($al in $c.Aliases) {
            if ($al.ToLowerInvariant() -eq $lowerTarget) {
                $matchedCmd = $c
                break
            }
        }
        if ($matchedCmd) { break }
    }

    if ($matchedCmd) {
        try { Clear-Host } catch { $null = $_ }
        Write-Host ""
        Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Bold + "PowerTools v2.0.0" + $t.Reset + "  " + $t.Connector + $symLine + $t.Reset + "  " + $t.FaintGray + "Ficha de Comando: " + $t.Reset + $t.Bold + $matchedCmd.Canonical + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Warn + $matchedCmd.Tag + $t.Reset + "  " + $t.Bold + $matchedCmd.Category + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        $aliasLine = ($matchedCmd.Aliases -join ', ')
        Write-Host ($t.Connector + $symPipe + $t.Reset + "  " + $t.Bold + "Alias:" + $t.Reset + "      " + $t.Success + $aliasLine + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset + "  " + $t.Bold + "Sinopsis:" + $t.Reset + "   " + $t.FaintGray + $matchedCmd.Synopsis + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset + "  " + $t.Bold + "Sintaxis:" + $t.Reset + "   " + $t.Accent + $matchedCmd.Syntax + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Bold + "Ejemplos de Uso" + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        foreach ($ex in $matchedCmd.Examples) {
            $codeStr = $ex.Code.PadRight(34)
            Write-Host ($t.Connector + $symPipe + $t.Reset + "  " + $t.Success + $codeStr + $t.Reset + "  " + $t.FaintGray + $ex.Desc + $t.Reset)
        }
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        Write-Host ($t.Connector + $symCorner + $t.Reset + "  " + $t.FaintGray + "Tip: Usa 'Get-Help $($matchedCmd.Canonical) -Full' para documentacion exhaustiva." + $t.Reset)
        Write-Host ""
        return
    }

    # 2. Filtrado de Categorias (Canonica o Sinonimo)
    $resolvedCategory = if ($categorySynonyms.ContainsKey($lowerTarget)) {
        $categorySynonyms[$lowerTarget]
    } elseif ($catalogo.Contains($rawTarget)) {
        $rawTarget
    } else {
        $null
    }

    if ($null -eq $resolvedCategory) {
        try { Clear-Host } catch { $null = $_ }
        Write-Host ""
        Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Bold + "PowerTools v2.0.0" + $t.Reset + "  " + $t.Connector + $symLine + $t.Reset + "  " + $t.FaintGray + "Ayuda y Catalogo" + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)
        Write-Host ($t.Warn + $symCross + $t.Reset + "  No se encontro ninguna categoria o comando para '$rawTarget'.")
        Write-Host ($t.Connector + $symPipe + $t.Reset)
        Write-Host ($t.Connector + $symCorner + $t.Reset + "  " + $t.FaintGray + "Tip: Usa 'pt-help' para el catalogo completo o 'pt-help <comando>' (ej: pt-help pt-music, pt-help audio)." + $t.Reset)
        Write-Host ""
        return
    }

    # 3. Renderizado del Catalogo General o Filtrado
    try { Clear-Host } catch { $null = $_ }
    Write-Host ""
    Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Bold + "PowerTools v2.0.0" + $t.Reset + "  " + $t.Connector + $symLine + $t.Reset + "  " + $t.FaintGray + "Catalogo de Comandos y Atajos" + $t.Reset)
    Write-Host ($t.Connector + $symPipe + $t.Reset)

    $catsToShow = if ($resolvedCategory -eq 'All') {
        @('Desarrollo', 'Navegacion', 'Web', 'Enfoque', 'Sistema')
    } else {
        @($resolvedCategory)
    }

    foreach ($catKey in $catsToShow) {
        if (-not $catalogo.Contains($catKey)) { continue }
        $c = $catalogo[$catKey]

        Write-Host ($t.HeaderIcon + $symDiamond + $t.Reset + "  " + $t.Warn + $c.Tag + $t.Reset + "  " + $t.Bold + $c.Title + $t.Reset)
        Write-Host ($t.Connector + $symPipe + $t.Reset)

        foreach ($item in $c.Commands) {
            $cmdStr = $item.Cmd.PadRight(26)
            Write-Host ($t.Connector + $symPipe + $t.Reset + "  " + $t.Success + $cmdStr + $t.Reset + "  " + $t.FaintGray + $item.Desc + $t.Reset)
        }
        Write-Host ($t.Connector + $symPipe + $t.Reset)
    }

    Write-Host ($t.Connector + $symCorner + $t.Reset + "  " + $t.FaintGray + "Tip: Usa 'pt-help <Categoria|Comando>' para inspeccionar. Ej: pt-help audio, pt-help pt-music" + $t.Reset)
    Write-Host ""
}

New-Alias -Name 'pt-help' -Value Show-PTHelp -Force
New-Alias -Name 'phlp'    -Value Show-PTHelp -Force

if (Get-Command -Name 'Register-ArgumentCompleter' -ErrorAction SilentlyContinue) {
    $scriptCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $null = $commandName; $null = $parameterName; $null = $commandAst; $null = $fakeBoundParameters

        $completions = @(
            @{ Value = 'All';        Tip = 'Mostrar catalogo completo' },
            @{ Value = 'Desarrollo'; Tip = 'Comandos de scaffolding y creacion de proyectos' },
            @{ Value = 'Navegacion'; Tip = 'Marcadores y navegacion rapida entre rutas' },
            @{ Value = 'Web';        Tip = 'Busqueda web asistida por motores tecnicos' },
            @{ Value = 'Enfoque';    Tip = 'Entornos sonoros y concentracion acustica' },
            @{ Value = 'Sistema';    Tip = 'Historial, perfil y mantenimiento seguro' },
            @{ Value = 'audio';      Tip = 'Sinonimo de Enfoque' },
            @{ Value = 'focus';      Tip = 'Sinonimo de Enfoque' },
            @{ Value = 'dev';        Tip = 'Sinonimo de Desarrollo' },
            @{ Value = 'nav';        Tip = 'Sinonimo de Navegacion' },
            @{ Value = 'web';        Tip = 'Sinonimo de Web' },
            @{ Value = 'sys';        Tip = 'Sinonimo de Sistema' },
            @{ Value = 'pt-new';     Tip = 'Nuevo proyecto (ptn)' },
            @{ Value = 'ptn';        Tip = 'Micro-alias de pt-new' },
            @{ Value = 'pt-go';      Tip = 'Navegar a marcador (ptg)' },
            @{ Value = 'ptg';        Tip = 'Micro-alias de pt-go' },
            @{ Value = 'pt-mark';    Tip = 'Crear marcador (ptm)' },
            @{ Value = 'ptm';        Tip = 'Micro-alias de pt-mark' },
            @{ Value = 'pt-unmark';  Tip = 'Eliminar marcador (ptum)' },
            @{ Value = 'ptum';       Tip = 'Micro-alias de pt-unmark' },
            @{ Value = 'pt-search';  Tip = 'Busqueda web asistida (pts)' },
            @{ Value = 'pts';        Tip = 'Micro-alias de pt-search' },
            @{ Value = 'pt-music';   Tip = 'Entornos sonoros de enfoque (ptmu)' },
            @{ Value = 'ptmu';       Tip = 'Micro-alias de pt-music' },
            @{ Value = 'pt-hist';    Tip = 'Historial de comandos (pth)' },
            @{ Value = 'pth';        Tip = 'Micro-alias de pt-hist' },
            @{ Value = 'pt-clean';   Tip = 'Mantenimiento seguro de temporales (ptc)' },
            @{ Value = 'ptc';        Tip = 'Micro-alias de pt-clean' },
            @{ Value = 'pt-help';    Tip = 'Catalogo y ayuda contextual (phlp)' },
            @{ Value = 'phlp';       Tip = 'Micro-alias de pt-help' }
        )

        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        foreach ($c in $completions) {
            if ($c.Value -like "$wordToComplete*") {
                $results.Add([System.Management.Automation.CompletionResult]::new($c.Value, $c.Value, [System.Management.Automation.CompletionResultType]::ParameterValue, $c.Tip))
            }
        }
        return $results
    }

    Register-ArgumentCompleter -CommandName @('Show-PTHelp', 'pt-help', 'phlp') -ParameterName 'Target' -ScriptBlock $scriptCompleter
    Register-ArgumentCompleter -CommandName @('Show-PTHelp', 'pt-help', 'phlp') -ParameterName 'Categoria' -ScriptBlock $scriptCompleter
}
