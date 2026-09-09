@{
    RootModule            = 'PowerTools.psm1'
    ModuleVersion         = '2.0.0'
    CompatiblePSEditions  = @('Core')
    GUID                  = 'a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890'
    Author                = 'CriXDZ'
    CompanyName           = 'CriXDZ'
    Copyright             = '(c) CriXDZ. Todos los derechos reservados.'
    Description           = 'Suite de alta productividad para PowerShell.'
    PowerShellVersion     = '7.0'

    FunctionsToExport     = @(
        'New-PTProject',
        'Invoke-PTNavigate',
        'Set-PTBookmarkShortcut',
        'Remove-PTBookmarkShortcut',
        'Get-PTHistory',
        'Invoke-PTCleanup',
        'Show-PTHelp',
        'Search-PTWeb',
        'Start-PTMusic'
    )

    CmdletsToExport       = @()

    VariablesToExport     = @()

    AliasesToExport       = @(
        'pt-new',
        'ptn',
        'pt-go',
        'ptg',
        'pt-mark',
        'ptm',
        'pt-unmark',
        'ptum',
        'pt-hist',
        'pth',
        'pt-clean',
        'ptc',
        'pt-help',
        'phlp',
        'pt-search',
        'pts',
        'pt-music',
        'ptmu'
    )

    PrivateData           = @{
        PSData = @{
            Tags = @('Productivity', 'ADHD', 'CLI', 'Navigation', 'DeveloperTools', 'PowerShell')
        }
    }
}
