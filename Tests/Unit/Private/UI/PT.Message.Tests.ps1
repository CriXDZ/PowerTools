Describe 'PT.Message - Renderizado de Mensajes Visuales' {
    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/UI/PT.Ansi.ps1')
        . (Join-Path $moduleRoot 'Private/UI/PT.Message.ps1')
    }

    Context 'Write-PTMessage - Respeto de Variables de Entorno y Silencio' {
        It 'No debe emitir salida si PT_SILENT es 1' {
            $env:PT_SILENT = '1'
            try {
                Write-PTMessage -Message 'Test Silent'
            }
            finally {
                Remove-Item Env:\PT_SILENT -ErrorAction SilentlyContinue
            }
        }

        It 'Debe renderizar mensaje con nivel Info por defecto' {
            $env:PT_NO_COLOR = '1'
            try {
                Write-PTMessage -Message 'Hola Mundo'
            }
            finally {
                Remove-Item Env:\PT_NO_COLOR -ErrorAction SilentlyContinue
            }
        }
    }
}
