Describe 'PT.Help - Menu Interactivo y Catalogo de Ayuda Vercel CLI' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        Import-Module (Join-Path $moduleRoot 'PowerTools.psd1') -Force
    }

    Context 'Show-PTHelp - Renderizado y Filtrado de Categorias' {
        It 'Debe ejecutarse silenciosamente sin errores bajo PT_SILENT con categorias canonicas' {
            $env:PT_SILENT = '1'
            try {
                Show-PTHelp -Categoria All
                Show-PTHelp -Categoria Desarrollo
                Show-PTHelp -Categoria Navegacion
                Show-PTHelp -Categoria Web
                Show-PTHelp -Categoria Enfoque
                Show-PTHelp -Categoria Sistema
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }

        It 'Debe resolver sinonimos de categoria comunes sin arrojar excepciones' {
            $env:PT_SILENT = '1'
            try {
                Show-PTHelp -Target 'audio'
                Show-PTHelp -Target 'focus'
                Show-PTHelp -Target 'dev'
                Show-PTHelp -Target 'nav'
                Show-PTHelp -Target 'sys'
                Show-PTHelp -Target 'web'
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Show-PTHelp - Inspeccion Detallada de Comandos y Micro-Alias' {
        It 'Debe inspeccionar comandos oficiales principales sin error' {
            $env:PT_SILENT = '1'
            try {
                Show-PTHelp -Target 'pt-music'
                Show-PTHelp -Target 'pt-new'
                Show-PTHelp -Target 'pt-go'
                Show-PTHelp -Target 'pt-mark'
                Show-PTHelp -Target 'pt-unmark'
                Show-PTHelp -Target 'pt-search'
                Show-PTHelp -Target 'pt-hist'
                Show-PTHelp -Target 'pt-clean'
                Show-PTHelp -Target 'pt-help'
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }

        It 'Debe resolver inspeccion a traves de micro-alias' {
            $env:PT_SILENT = '1'
            try {
                Show-PTHelp -Target 'ptmu'
                Show-PTHelp -Target 'ptn'
                Show-PTHelp -Target 'ptg'
                Show-PTHelp -Target 'ptm'
                Show-PTHelp -Target 'ptum'
                Show-PTHelp -Target 'pts'
                Show-PTHelp -Target 'pth'
                Show-PTHelp -Target 'ptc'
                Show-PTHelp -Target 'phlp'
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }

        It 'Debe resolver inspeccion mediante el nombre de funcion canonica' {
            $env:PT_SILENT = '1'
            try {
                Show-PTHelp -Target 'Start-PTMusic'
                Show-PTHelp -Target 'New-PTProject'
                Show-PTHelp -Target 'Search-PTWeb'
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }

        It 'Debe manejar terminos inexistentes sin lanzar errores ni excepciones' {
            $env:PT_SILENT = '1'
            try {
                { Show-PTHelp -Target 'comando_inexistente_xyz' } | Should -Not -Throw
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Exportacion de Alias de Ayuda' {
        It 'Debe exportar pt-help y phlp apuntando a Show-PTHelp' {
            foreach ($aliasName in @('pt-help', 'phlp')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'Show-PTHelp'
            }
        }
    }
}
