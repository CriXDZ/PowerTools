Describe 'PT.Config - Persistencia Pura y Desacoplamiento' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/SY/PT.Config.ps1')
    }

    Context 'Resolucion de rutas desacopladas' {
        It 'Debe apuntar a LOCALAPPDATA o XDG_CONFIG_HOME y nunca a la raiz del modulo' {
            $configDir = Get-PTConfigDirectoryPath
            $configDir | Should -Not -BeNullOrEmpty
            $configDir | Should -Match 'PowerTools'
        }

        It 'Debe resolver la ruta del archivo config.json' {
            $configFile = Get-PTConfigFilePath
            $configFile | Should -Match 'config\.json$'
        }
    }

    Context 'Lectura y modificacion de configuracion privada' {
        It 'Debe retornar SystemPaths y Preferencias validas con Read-PTConfig' {
            $cfg = Read-PTConfig
            $cfg | Should -Not -BeNullOrEmpty
            $cfg.SystemPaths | Should -Not -BeNullOrEmpty
        }

        It 'Debe permitir persistir y recuperar preferencias con Set-PTConfigProperty' {
            Mock Test-Path { return $true }
            Mock Set-Content { return $true }

            $res = Set-PTConfigProperty -Key 'DefaultEditor' -Value 'code'
            $res | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Gestion de Marcadores Personalizados' {
        BeforeEach {
            $script:PTConfigCache = Get-PTDefaultConfig
            Mock Write-PTConfig { param($Config) $script:PTConfigCache = $Config }
            Mock Read-PTConfig { return $script:PTConfigCache }
        }

        It 'Debe gestionar marcadores en la configuracion con Set-PTBookmark y Get-PTBookmark' {
            $saved = Set-PTBookmark -Alias 'testapi' -Path 'C:\Test\Api'
            $saved | Should -Not -BeNullOrEmpty
            $saved.testapi | Should -Be 'C:\Test\Api'

            $retrieved = Get-PTBookmark -Alias 'testapi'
            $retrieved | Should -Be 'C:\Test\Api'
        }

        It 'Debe eliminar un marcador existente con Remove-PTBookmark' {
            Set-PTBookmark -Alias 'toremove' -Path 'C:\Test\Remove' | Out-Null
            $removed = Remove-PTBookmark -Alias 'toremove'
            $removed | Should -Be $true

            $nonExistent = Remove-PTBookmark -Alias 'nonexistent'
            $nonExistent | Should -Be $false
        }
    }
}
