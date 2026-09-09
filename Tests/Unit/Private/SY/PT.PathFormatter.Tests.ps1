Describe 'PT.PathFormatter - Formateo Puro de UI' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/SY/PT.PathFormatter.ps1')
    }

    Context 'Format-PTBreadcrumb' {
        It 'Debe contraer la ruta de usuario a ~' {
            $homeDir = [Environment]::GetFolderPath('UserProfile')
            $testPath = Join-Path $homeDir 'Proyectos\Demo'
            $result = Format-PTBreadcrumb -Path $testPath
            $result | Should -Match '^\~'
        }

        It 'Debe truncar rutas largas preservando el primer y ultimo elemento' {
            $longPath = 'C:\Mock\Desarrollador\Documentos\SubCarpeta1\SubCarpeta2\ProyectoFinal'
            $result = Format-PTBreadcrumb -Path $longPath -MaxLength 25
            $result | Should -Match '\.\.\.'
        }

        It 'Debe manejar entradas vacias retornando ~' {
            $result = Format-PTBreadcrumb -Path ''
            $result | Should -Be '~'
        }
    }
}
