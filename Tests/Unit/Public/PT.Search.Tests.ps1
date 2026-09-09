Describe 'PT.Search - Busqueda Web Rapida y Asistencia Anti-Distraccion' -Tag 'Unit', 'Search' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path -Path $moduleRoot -ChildPath 'Private\UI\PT.Ansi.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Private\UI\PT.Message.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Private\SY\PT.SearchProviders.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Public\PT.Search.ps1')
    }

    Context 'Get-PTSearchProviders - Catalogo de Motores Especializados' {
        It 'Debe registrar los 8 motores tecnicos requeridos' {
            $providers = Get-PTSearchProviders
            $providers.Count | Should -Be 8

            $ids = @($providers | ForEach-Object { $_.Id })
            $ids -contains 'google'        | Should -Be $true
            $ids -contains 'duckduckgo'    | Should -Be $true
            $ids -contains 'youtube'       | Should -Be $true
            $ids -contains 'github'        | Should -Be $true
            $ids -contains 'stackoverflow' | Should -Be $true
            $ids -contains 'devdocs'       | Should -Be $true
            $ids -contains 'mdn'           | Should -Be $true
            $ids -contains 'perplexity'    | Should -Be $true
        }

        It 'Cada proveedor debe tener Id, Prefix, Label, Description y UrlPattern validos' {
            $providers = Get-PTSearchProviders
            foreach ($p in $providers) {
                $p.Id | Should -Not -BeNullOrEmpty
                $p.Prefix | Should -Not -BeNullOrEmpty
                $p.Label | Should -Not -BeNullOrEmpty
                $p.Description | Should -Not -BeNullOrEmpty
                $p.UrlPattern | Should -Match '\{0\}'
            }
        }
    }

    Context 'Get-PTSearchUrl - Sanitizacion y Construccion de URLs' {
        It 'Debe retornar vacio si la consulta esta en blanco o es nula' {
            Get-PTSearchUrl -Provider 'google' -Query ''      | Should -Be ''
            Get-PTSearchUrl -Provider 'google' -Query '   '   | Should -Be ''
        }

        It 'Debe escapar caracteres especiales conforme a RFC 3986' {
            $urlCSharp = Get-PTSearchUrl -Provider 'google' -Query 'C#'
            $urlCSharp | Should -Match 'q=C%23'

            $urlAmpersand = Get-PTSearchUrl -Provider 'google' -Query 'foo & bar'
            $urlAmpersand | Should -Match 'foo%20%26%20bar'

            $urlPlus = Get-PTSearchUrl -Provider 'google' -Query 'react+vite'
            $urlPlus | Should -Match 'react%2Bvite'

            $urlAccent = Get-PTSearchUrl -Provider 'google' -Query 'diseño web'
            $urlAccent | Should -Match 'dise%C3%B1o%20web'
        }

        It 'Debe enrutar tanto por Id como por Prefix' {
            $urlById = Get-PTSearchUrl -Provider 'github' -Query 'powertools'
            $urlByPrefix = Get-PTSearchUrl -Provider 'gh' -Query 'powertools'

            $urlById | Should -Be $urlByPrefix
            $urlById | Should -Match '^https://github.com/search\?q=powertools'
        }

        It 'Anti-distraccion YouTube: debe apuntar exclusivamente a /results?search_query=' {
            $ytUrl = Get-PTSearchUrl -Provider 'yt' -Query 'clean code'
            $ytUrl | Should -Match '^https://www.youtube.com/results\?search_query=clean%20code$'
        }

        It 'Debe usar fallback a Google ante un proveedor desconocido' {
            $fallbackUrl = Get-PTSearchUrl -Provider 'inexistente_xyz' -Query 'test query'
            $fallbackUrl | Should -Match '^https://www.google.com/search\?q=test%20query$'
        }
    }

    Context 'Search-PTWeb - Enrutamiento y Guardarrailes de Ejecucion' {
        BeforeEach {
            Mock Start-Process { }
            Mock Write-PTMessage { }
        }

        It 'Debe detectar prefijo directo yt y abrir la URL correspondiente' {
            Mock Start-Process { } -ParameterFilter { $FilePath -match 'youtube\.com/results\?search_query=clean%20architecture' }

            Search-PTWeb -Query @('yt', 'clean', 'architecture')

            Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
        }

        It 'Debe detectar prefijo directo gh y abrir la URL de GitHub' {
            Mock Start-Process { } -ParameterFilter { $FilePath -match 'github\.com/search\?q=ripgrep' }

            Search-PTWeb -Query @('gh', 'ripgrep')

            Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
        }

        It 'Debe usar el motor predeterminado si no hay prefijo registrado' {
            Mock Start-Process { } -ParameterFilter { $FilePath -match 'google\.com/search\?q=react%20router%20error' }

            Search-PTWeb -Query @('react', 'router', 'error')

            Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
        }

        It 'Debe respetar el parametro explicito -Provider' {
            Mock Start-Process { } -ParameterFilter { $FilePath -match 'stackoverflow\.com/search\?q=powershell%20pester' }

            Search-PTWeb -Provider 'so' -Query @('powershell', 'pester')

            Assert-MockCalled Start-Process -Times 1 -Exactly -Scope It
        }

        It 'Guardarrail WhatIf: bajo -WhatIf no debe invocar Start-Process' {
            Search-PTWeb -Query @('yt', 'test') -WhatIf

            Assert-MockCalled Start-Process -Times 0 -Exactly -Scope It
        }
    }

    Context 'Exportacion de Alias de Busqueda Web' {
        It 'Debe exportar pt-search y pts apuntando a Search-PTWeb' {
            Import-Module (Join-Path $moduleRoot 'PowerTools.psd1') -Force

            foreach ($aliasName in @('pt-search', 'pts')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Search-PTWeb'
            }

            $func = Get-Command -Name 'Search-PTWeb' -ErrorAction SilentlyContinue
            $func | Should -Not -BeNullOrEmpty
            $func.CommandType | Should -Be 'Function'
        }
    }
}
