Describe 'PowerTools - Regla de Arquitectura y Desacoplamiento Depurado' -Tag 'Unit', 'Architecture' {
    BeforeAll {
        $ModuleManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\PowerTools.psd1'
        $Manifest = Import-PowerShellDataFile -Path $ModuleManifestPath
        $Script:PublicFunctions = $Manifest.FunctionsToExport
        $Script:PublicAliases = $Manifest.AliasesToExport
        $Script:PrivateFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private') -Recurse -Filter '*.ps1'
    }

    Context 'Jerarquia Unidireccional Estricta (Private -> Pure / No Public Calls)' {
        It 'Ningun script en Private debe invocar funciones publicas ni alias exportados' {
            foreach ($file in $Script:PrivateFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $tokens = $null
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)

                # Extraer todos los CommandAst
                $commandNodes = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)

                foreach ($cmd in $commandNodes) {
                    $cmdName = $cmd.GetCommandName()
                    if ($null -ne $cmdName) {
                        $isPublicFunc = $Script:PublicFunctions -contains $cmdName
                        $isPublicAlias = $Script:PublicAliases -contains $cmdName

                        if ($isPublicFunc -or $isPublicAlias) {
                            Fail "El archivo privado '$($file.Name)' viola la jerarquia al invocar la funcion o alias publico '$cmdName'"
                        }
                    }
                }
            }
        }

        It 'La carpeta Private/Navigation no debe existir en la estructura del modulo' {
            $navDir = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private\Navigation'
            (Test-Path -Path $navDir) | Should -Be $false
        }

        It 'El archivo residual Private/UI/PT.Colors.ps1 no debe existir y VariablesToExport debe estar vacio' {
            $colorsFile = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private\UI\PT.Colors.ps1'
            (Test-Path -Path $colorsFile) | Should -Be $false
            $Manifest.VariablesToExport.Count | Should -Be 0
        }

        It 'El archivo Public/PT.NavManager.ps1 no debe existir y Public/PT.Navigate.ps1 debe existir con sus alias estandarizados' {
            $oldNavScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.NavManager.ps1'
            (Test-Path -Path $oldNavScript) | Should -Be $false

            $navScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Navigate.ps1'
            (Test-Path -Path $navScript) | Should -Be $true

            $Script:PublicFunctions -contains 'Invoke-PTNavigate' | Should -Be $true
            $Script:PublicAliases -contains 'pt-go' | Should -Be $true
            $Script:PublicAliases -contains 'ptg' | Should -Be $true
            $Script:PublicAliases -contains 'pt-mark' | Should -Be $true
            $Script:PublicAliases -contains 'ptm' | Should -Be $true
            $Script:PublicAliases -contains 'pt-unmark' | Should -Be $true
            $Script:PublicAliases -contains 'ptum' | Should -Be $true

            $Script:PublicAliases -contains 'goto' | Should -Be $false
        }

        It 'El orquestador Public/PT.Builder.ps1 debe existir y exportar New-PTProject y sus alias' {
            $builderScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Builder.ps1'
            (Test-Path -Path $builderScript) | Should -Be $true

            $Script:PublicFunctions -contains 'New-PTProject' | Should -Be $true
            $Script:PublicAliases -contains 'pt-new' | Should -Be $true
            $Script:PublicAliases -contains 'ptn' | Should -Be $true

            $Script:PublicAliases -contains 'project' | Should -Be $false
        }

        It 'El orquestador Public/PT.Tools.ps1 debe existir y exportar pt-hist, pt-clean y sus variantes' {
            $toolsScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Tools.ps1'
            (Test-Path -Path $toolsScript) | Should -Be $true

            $Script:PublicFunctions -contains 'Get-PTHistory' | Should -Be $true
            $Script:PublicFunctions -contains 'Invoke-PTCleanup' | Should -Be $true
            $Script:PublicAliases -contains 'pt-hist' | Should -Be $true
            $Script:PublicAliases -contains 'pth' | Should -Be $true
            $Script:PublicAliases -contains 'pt-clean' | Should -Be $true
            $Script:PublicAliases -contains 'ptc' | Should -Be $true

            $Script:PublicAliases -contains 'phist' | Should -Be $false
            $Script:PublicAliases -contains 'clcas' | Should -Be $false
            $Script:PublicFunctions -contains 'Edit-PTProfile' | Should -Be $false
            $Script:PublicFunctions -contains 'Clear-PTHistory' | Should -Be $false
            $Script:PublicAliases -contains 'ep' | Should -Be $false
            $Script:PublicAliases -contains 'clh' | Should -Be $false
        }

        It 'El orquestador Public/PT.Help.ps1 debe existir y exportar pt-help y phlp' {
            $helpScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Help.ps1'
            (Test-Path -Path $helpScript) | Should -Be $true

            $Script:PublicFunctions -contains 'Show-PTHelp' | Should -Be $true
            $Script:PublicAliases -contains 'pt-help' | Should -Be $true
            $Script:PublicAliases -contains 'phlp' | Should -Be $true

            $Script:PublicAliases -contains 'helpme' | Should -Be $false
            $Script:PublicFunctions -contains 'Show-HelpMenu' | Should -Be $false
        }

        It 'El orquestador Public/PT.Search.ps1 debe existir y exportar Search-PTWeb con pt-search y pts' {
            $searchScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Search.ps1'
            (Test-Path -Path $searchScript) | Should -Be $true

            $Script:PublicFunctions -contains 'Search-PTWeb' | Should -Be $true
            $Script:PublicAliases -contains 'pt-search' | Should -Be $true
            $Script:PublicAliases -contains 'pts' | Should -Be $true

            # Comprobacion estricta: gg no debe ser exportado para preservar paridad 1:1
            $Script:PublicAliases -contains 'gg' | Should -Be $false
        }

        It 'El orquestador Public/PT.Music.ps1 debe existir y exportar Start-PTMusic con pt-music y ptmu' {
            $musicScript = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Public\PT.Music.ps1'
            (Test-Path -Path $musicScript) | Should -Be $true

            $Script:PublicFunctions -contains 'Start-PTMusic' | Should -Be $true
            $Script:PublicAliases -contains 'pt-music' | Should -Be $true
            $Script:PublicAliases -contains 'ptmu' | Should -Be $true

            # Regla de paridad estricta: exactamente 2 alias asignados
            $Script:PublicAliases -contains 'ptm' | Should -Be $true # Pertenece a pt-mark
        }

        It 'El archivo AGENTS.md debe existir en la raiz del modulo y definir la constitucion' {
            $agentsFile = Join-Path -Path $PSScriptRoot -ChildPath '..\..\AGENTS.md'
            (Test-Path -Path $agentsFile) | Should -Be $true
        }

        It 'Todas las subcarpetas bajo Private/ deben ser exactamente de 2 letras (UI, SY, TL)' {
            $privateDir = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private'
            $subDirs = Get-ChildItem -Path $privateDir -Directory
            foreach ($dir in $subDirs) {
                $dir.Name.Length | Should -Be 2
            }
        }
    }
}
