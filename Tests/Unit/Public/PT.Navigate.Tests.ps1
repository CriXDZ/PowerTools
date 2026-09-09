Describe 'PT.Navigate - Orquestador de Marcadores y Navegacion Rapida' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/UI/PT.Ansi.ps1')
        . (Join-Path $moduleRoot 'Private/UI/PT.Message.ps1')
        . (Join-Path $moduleRoot 'Private/UI/PT.Selector.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.Config.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.Environment.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.PathFormatter.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.Paths.ps1')
        . (Join-Path $moduleRoot 'Public/PT.Navigate.ps1')
    }

    Context 'Invoke-PTNavigate -List' {
        It 'Debe retornar una coleccion estructurada de marcadores del sistema y de usuario' {
            $list = Invoke-PTNavigate -List
            $list | Should -Not -BeNullOrEmpty
            $list[0].PSObject.Properties['Alias'] | Should -Not -BeNullOrEmpty
            $list[0].PSObject.Properties['Path'] | Should -Not -BeNullOrEmpty
            $list[0].PSObject.Properties['DisplayPath'] | Should -Not -BeNullOrEmpty
            $list[0].PSObject.Properties['Type'] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-PTNavigate -Set y -Remove' {
        It 'Debe registrar un marcador personalizado con -Set' {
            Mock Write-PTConfig { }
            Mock Test-Path { return $true }
            Mock Write-PTMessage { }

            Invoke-PTNavigate -Set 'mywork' -Path 'C:\Projects\Work'
            $res = Get-PTBookmark -Alias 'mywork'
            $res | Should -Be 'C:\Projects\Work'
        }

        It 'Debe remover un marcador personalizado con -Remove' {
            Mock Write-PTConfig { }
            Mock Write-PTMessage { }

            Set-PTBookmark -Alias 'todelete' -Path 'C:\Projects\Delete' | Out-Null
            Invoke-PTNavigate -Remove 'todelete'
            $res = Get-PTBookmark -Alias 'todelete'
            $res | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-PTNavigate con Alias directo' {
        It 'Debe resolver marcadores del sistema y ejecutar Set-Location' {
            Mock Set-Location { }
            Mock Write-PTMessage { }
            Mock Test-Path { return $true }

            Invoke-PTNavigate -Alias 'docs'
            Assert-MockCalled Set-Location -Times 1 -Exactly -Scope It
        }

        It 'Debe alertar si el marcador no existe' {
            Mock Set-Location { }
            Mock Write-PTMessage { }

            Invoke-PTNavigate -Alias 'non_existing_bookmark_xyz'
            Assert-MockCalled Set-Location -Times 0 -Exactly -Scope It
            Assert-MockCalled Write-PTMessage -Times 1 -Exactly -Scope It
        }
    }

    Context 'Shortcuts y Aliases pt-mark / pt-unmark' {
        It 'Set-PTBookmarkShortcut debe delegar a Invoke-PTNavigate -Set' {
            Mock Invoke-PTNavigate { }
            Set-PTBookmarkShortcut -Alias 'quickmark' -Path 'C:\Quick'
            Assert-MockCalled Invoke-PTNavigate -Times 1 -Exactly -Scope It
        }

        It 'Remove-PTBookmarkShortcut debe delegar a Invoke-PTNavigate -Remove' {
            Mock Invoke-PTNavigate { }
            Remove-PTBookmarkShortcut -Alias 'quickmark'
            Assert-MockCalled Invoke-PTNavigate -Times 1 -Exactly -Scope It
        }
    }

    Context 'Invoke-PTNavigate interactivo TUI' {
        It 'Debe invocar Invoke-PTSelector con AllowFilter y navegar con ruta directa en string' {
            Mock Invoke-PTSelector { return 'C:\Test\DirectStringDocs' }
            Mock Set-Location { }
            Mock Test-Path { return $true }
            Mock Write-PTMessage { }

            Invoke-PTNavigate
            Assert-MockCalled Invoke-PTSelector -Times 1 -Exactly -Scope It
            Assert-MockCalled Set-Location -Times 1 -Exactly -Scope It
        }

        It 'Debe navegar correctamente cuando Invoke-PTSelector retorna un objeto con propiedad Value' {
            Mock Invoke-PTSelector { return [pscustomobject]@{ Label = 'docs'; Value = 'C:\Test\DocsObj' } }
            Mock Set-Location { }
            Mock Test-Path { return $true }
            Mock Write-PTMessage { }

            Invoke-PTNavigate
            Assert-MockCalled Invoke-PTSelector -Times 1 -Exactly -Scope It
            Assert-MockCalled Set-Location -Times 1 -Exactly -Scope It
        }

        It 'No debe navegar si el usuario cancela la seleccion en el selector TUI' {
            Mock Invoke-PTSelector { return $null }
            Mock Set-Location { }
            Mock Write-PTMessage { }

            Invoke-PTNavigate
            Assert-MockCalled Invoke-PTSelector -Times 1 -Exactly -Scope It
            Assert-MockCalled Set-Location -Times 0 -Exactly -Scope It
        }
    }

    Context 'Exportacion de Alias y Funciones del Modulo' {
        It 'Debe exportar los comandos y alias pt-go, ptg, pt-mark, ptm, pt-unmark y ptum al importar el modulo' {
            Import-Module (Join-Path $moduleRoot 'PowerTools.psd1') -Force

            foreach ($aliasName in @('pt-go', 'ptg')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Invoke-PTNavigate'
            }

            foreach ($aliasName in @('pt-mark', 'ptm')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Set-PTBookmarkShortcut'
            }

            foreach ($aliasName in @('pt-unmark', 'ptum')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Remove-PTBookmarkShortcut'
            }

            $funcNav = Get-Command -Name 'Invoke-PTNavigate' -ErrorAction SilentlyContinue
            $funcNav | Should -Not -BeNullOrEmpty
            $funcNav.CommandType | Should -Be 'Function'
        }
    }
}
