Describe 'PT.Environment - Deteccion de Entorno y Comandos' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/SY/PT.Environment.ps1')
    }

    Context 'Test-CommandAvailability' {
        It 'Debe retornar $true para comandos existentes en el sistema' {
            Test-CommandAvailability -CommandName 'Get-Command' | Should -Be $true
        }

        It 'Debe retornar $false para comandos inexistentes' {
            Test-CommandAvailability -CommandName 'NonExistentCommand_9999' | Should -Be $false
        }
    }

    Context 'Get-PTAvailableEditor' {
        It 'Debe retornar el editor preferido si esta disponible' {
            Mock Get-Command { return [PSCustomObject]@{ Source = 'C:\bin\code.exe' } } -ParameterFilter { $Name -eq 'custom-editor' }
            $editor = Get-PTAvailableEditor -Preferred 'custom-editor'
            $editor | Should -Be 'C:\bin\code.exe'
        }

        It 'Debe retornar notepad como fallback seguro si no hay ningun editor instalado' {
            Mock Get-Command { return $null }
            Mock Test-Path { return $false }
            $editor = Get-PTAvailableEditor
            $editor | Should -Be 'notepad'
        }
    }
}
