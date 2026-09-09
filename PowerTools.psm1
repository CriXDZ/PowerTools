[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
param()

if (-not $script:PT) {
    $script:PT = @{}
}

$privateScripts = @(
    'UI\PT.Ansi.ps1',
    'UI\PT.Message.ps1',
    'UI\PT.Selector.ps1',
    'SY\PT.Config.ps1',
    'SY\PT.Environment.ps1',
    'SY\PT.KeyHandler.ps1',
    'SY\PT.PathFormatter.ps1',
    'SY\PT.Paths.ps1',
    'SY\PT.SearchProviders.ps1',
    'SY\PT.MusicProviders.ps1',
    'TL\PT.TemplateEngine.ps1',
    'TL\PT.Template.Default.ps1',
    'TL\PT.Template.HTML.ps1',
    'TL\PT.Template.Node.ps1',
    'TL\PT.Template.Python.ps1',
    'TL\PT.Template.Vite.ps1'
)

foreach ($scriptName in $privateScripts) {
    $scriptPath = Join-Path -Path "$PSScriptRoot\Private" -ChildPath $scriptName
    if (Test-Path -Path $scriptPath) {
        try {
            . $scriptPath
        }
        catch {
            Write-Error "Error critico al cargar componente privado '$scriptName': $_"
        }
    }
    else {
        Write-Warning "No se encontro el componente privado requerido: '$scriptPath'"
    }
}

$initCfg = $null
try {
    if (Get-Command -Name 'Read-PTConfig' -ErrorAction SilentlyContinue) {
        $initCfg = Read-PTConfig
    }
}
catch {
    $initCfg = $null
}

$script:PT.Config = $initCfg

$publicScripts = @(
    'PT.Builder.ps1',
    'PT.Navigate.ps1',
    'PT.Tools.ps1',
    'PT.Help.ps1',
    'PT.Search.ps1',
    'PT.Music.ps1'
)

foreach ($scriptName in $publicScripts) {
    $scriptPath = Join-Path -Path "$PSScriptRoot\Public" -ChildPath $scriptName
    if (Test-Path -Path $scriptPath) {
        try {
            . $scriptPath
        }
        catch {
            Write-Error "Error critico al cargar componente publico '$scriptName': $_"
        }
    }
    else {
        Write-Warning "No se encontro el componente publico requerido: '$scriptPath'"
    }
}

Export-ModuleMember -Function * -Alias *
