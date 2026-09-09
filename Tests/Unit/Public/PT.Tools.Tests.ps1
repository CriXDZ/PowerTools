Describe 'PT.Tools - Historial y Asistente de Limpieza Intuitivo' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        Import-Module (Join-Path $moduleRoot 'PowerTools.psd1') -Force
    }

    Context 'Get-PTHistory - Consulta y Optimizacion de Historial PSReadLine' {
        It 'Debe retornar lineas de historial filtradas por Search y Unique' {
            Mock Test-Path { return $true } -ModuleName PowerTools
            Mock Get-Content { return @('git status', 'git commit', 'npm start', 'git pull') } -ModuleName PowerTools

            $hist = Get-PTHistory -Search 'git' -Unique
            $hist | Should -Not -BeNullOrEmpty
            $hist.Count | Should -Be 3
        }

        It 'Debe respetar el limite de Count en la salida' {
            Mock Test-Path { return $true } -ModuleName PowerTools
            Mock Get-Content { return @('linea1', 'linea2', 'linea3', 'linea4', 'linea5') } -ModuleName PowerTools

            $hist = Get-PTHistory -Count 2
            $hist.Count | Should -Be 2
            $hist[0] | Should -Be 'linea4'
        }

        It 'Debe soportar la optimizacion y deduplicacion del archivo de historial con -Deduplicate' {
            Mock Test-Path { return $true } -ModuleName PowerTools
            Mock Get-Content { return @('git status', 'git status', 'npm test') } -ModuleName PowerTools
            Mock Set-Content { } -ModuleName PowerTools

            Get-PTHistory -Deduplicate -WhatIf
        }

        It 'Debe soportar la purga limpia del historial con -Clear' {
            Mock Test-Path { return $true } -ModuleName PowerTools
            Mock Clear-Content { } -ModuleName PowerTools

            Get-PTHistory -Clear -WhatIf
        }
    }

    Context 'Invoke-PTCleanup - Limpieza de Temporales con Scopes' {
        It 'Debe ejecutar la evaluacion de scopes sin alterar el disco real' {
            Mock Test-Path { return $true } -ModuleName PowerTools
            Mock Remove-Item { } -ModuleName PowerTools

            Invoke-PTCleanup -Scope User -WhatIf
            Invoke-PTCleanup -Scope Dev -WhatIf
            Invoke-PTCleanup -Scope System -WhatIf
            Invoke-PTCleanup -Scope Full -WhatIf
        }
    }

    Context 'Exportacion de Alias de Herramientas y Mantenimiento' {
        It 'Debe exportar pt-hist y pth apuntando a Get-PTHistory' {
            foreach ($aliasName in @('pt-hist', 'pth')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Get-PTHistory'
            }
        }

        It 'Debe exportar pt-clean y ptc apuntando a Invoke-PTCleanup' {
            foreach ($aliasName in @('pt-clean', 'ptc')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Invoke-PTCleanup'
            }
        }
    }
}
