Describe 'PT.Ansi - Tema ANSI de Consola' {
    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/UI/PT.Ansi.ps1')
    }

    Context 'Get-PTAnsiTheme - Contrato de Colores' {
        It 'Debe retornar un hashtable con las claves de estilo requeridas' {
            $theme = Get-PTAnsiTheme
            $theme | Should -Not -BeNullOrEmpty
            $theme.ContainsKey('Reset') | Should -Be $true
            $theme.ContainsKey('Accent') | Should -Be $true
            $theme.ContainsKey('SuccessIcon') | Should -Be $true
            $theme.ContainsKey('ItemActiveSymbol') | Should -Be $true
        }

        It 'Debe incluir secuencias de escape ANSI validas' {
            $theme = Get-PTAnsiTheme
            $theme.Reset | Should -Be "`e[0m"
            $theme.Bold | Should -Be "`e[1m"
            $theme.Accent | Should -Match '^\x1b\['
        }
    }
}
