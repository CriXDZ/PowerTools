Describe 'PT.TemplateEngine - Scaffolding Declarativo de Plantillas' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/TL/PT.TemplateEngine.ps1')
    }

    Context 'Get-PTProjectTemplate - Catalogo de Plantillas' {
        It 'Debe retornar las plantillas registradas en el sistema' {
            $templates = Get-PTProjectTemplate
            $templates | Should -Not -BeNullOrEmpty
            $templates.Count | Should -BeGreaterThan 0
        }

        It 'Debe recuperar una plantilla especifica por su Id' {
            $tpl = Get-PTProjectTemplate -Id 'Node'
            $tpl | Should -Not -BeNullOrEmpty
            $tpl.Id | Should -Be 'Node'
        }
    }

    Context 'Invoke-PTScaffoldTree - Creacion Declarativa de Arbol de Disco' {
        It 'Debe invocar New-Item y Set-Content al generar la estructura' {
            Mock Test-Path { return $false }
            Mock New-Item { return $true }
            Mock Set-Content { return $true }

            Invoke-PTScaffoldTree -BasePath 'TestDrive:\Demo' -Directories @('src', 'docs') -Files @{ 'README.md' = '# Demo' }
            Assert-MockCalled New-Item
            Assert-MockCalled Set-Content
        }
    }
}
