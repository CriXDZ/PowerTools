Describe 'PT.Paths - Gestor Puro de Rutas del Sistema y Workspace' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/SY/PT.Config.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.Paths.ps1')
    }

    Context 'Get-PTRootPath - Resolucion Agnostica de Ubicaciones Base' {
        It 'Debe resolver correctamente la ruta Home' {
            $homePath = Get-PTRootPath -Location 'Home'
            $homePath | Should -Not -BeNullOrEmpty
            Test-Path $homePath | Should -Be $true
        }

        It 'Debe resolver las rutas estandar Desktop, Documents, Projects y Downloads' {
            foreach ($target in @('Desktop', 'Documents', 'Projects', 'Downloads')) {
                $path = Get-PTRootPath -Location $target
                $path | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-PTSystemBookmark - Resolucion Agnostica de Marcadores del Sistema' {
        It 'Debe retornar un diccionario ordenado con los alias clave home, desk, docs, down y proj' {
            $bookmarks = Get-PTSystemBookmark
            $bookmarks | Should -Not -BeNullOrEmpty
            $bookmarks.Contains('home') | Should -Be $true
            $bookmarks.Contains('desk') | Should -Be $true
            $bookmarks.Contains('docs') | Should -Be $true
            $bookmarks.Contains('down') | Should -Be $true
            $bookmarks.Contains('proj') | Should -Be $true
        }
    }

    Context 'Resolve-PTWorkspacePath - Normalizacion y Resolucion de Rutas' {
        It 'Debe resolver la tilde (~) como la ruta Home del usuario' {
            $homeBase = Get-PTRootPath -Location Home
            $resolved = Resolve-PTWorkspacePath -Path '~'
            $resolved | Should -Be $homeBase
        }

        It 'Debe resolver rutas con tilde y subdirectorios (~/Proyectos)' {
            $homeBase = Get-PTRootPath -Location Home
            $expected = Join-Path $homeBase 'Proyectos'
            $resolved = Resolve-PTWorkspacePath -Path '~/Proyectos'
            $resolved | Should -Be $expected
        }

        It 'Debe retornar la ruta actual ($PWD) si se recibe entrada vacia o nula' {
            $resolved = Resolve-PTWorkspacePath -Path ''
            $resolved | Should -Be $PWD.ProviderPath
        }

        It 'Debe normalizar correctamente rutas absolutas y relativas' {
            $resolved = Resolve-PTWorkspacePath -Path '.\MiCarpeta'
            $resolved | Should -Match 'MiCarpeta$'
        }
    }

    Context 'Get-PTDefaultProjectPath' {
        It 'Debe retornar la ruta por defecto de proyectos cuando no hay configuracion previa' {
            Mock Read-PTConfig { return @{} }
            Mock Get-PTConfigProperty { return $null }
            $defaultPath = Get-PTDefaultProjectPath
            $defaultPath | Should -Not -BeNullOrEmpty
        }

        It 'Debe retornar la ruta configurada en PT.Config si existe' {
            Mock Get-PTConfigProperty { return 'C:\ProyectosCustom' }
            $path = Get-PTDefaultProjectPath
            $path | Should -Be 'C:\ProyectosCustom'
        }
    }
}

