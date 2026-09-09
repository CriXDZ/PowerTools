Describe 'PT.Builder - Motor Unificado de Plantillas y Orquestador Clean CLI' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        Import-Module (Join-Path $moduleRoot 'PowerTools.psd1') -Force
    }

    Context 'Catalogo Declarativo de Plantillas (Get-PTProjectTemplate)' {
        It 'Debe registrar las 5 plantillas principales del sistema' {
            InModuleScope 'PowerTools' {
                $templates = Get-PTProjectTemplate
                $templates.Count | Should -Be 5

                $ids = @($templates | ForEach-Object { $_.Id })
                ($ids -contains 'Node')    | Should -Be $true
                ($ids -contains 'Python')  | Should -Be $true
                ($ids -contains 'Vite')    | Should -Be $true
                ($ids -contains 'HTML')    | Should -Be $true
                ($ids -contains 'Default') | Should -Be $true
            }
        }

        It 'Cada plantilla debe cumplir el contrato estandar de datos y accion' {
            InModuleScope 'PowerTools' {
                $templates = Get-PTProjectTemplate
                foreach ($t in $templates) {
                    $t.Id | Should -Not -BeNullOrEmpty
                    $t.Label | Should -Not -BeNullOrEmpty
                    $t.Description | Should -Not -BeNullOrEmpty
                    $t.Build | Should -Not -BeNullOrEmpty
                    ($t.Build -is [ScriptBlock]) | Should -Be $true
                }
            }
        }

        It 'Debe recuperar una plantilla individual por su Id o Value' {
            InModuleScope 'PowerTools' {
                $tplNode = Get-PTProjectTemplate -Id 'Node'
                $tplNode | Should -Not -BeNullOrEmpty
                $tplNode.Id | Should -Be 'Node'
            }
        }
    }

    Context 'Bateria Extrema de Pruebas Unitarias TDD para New-PTProject' {
        It 'Test 1 (Validacion de Input): Falla controlada si el nombre contiene caracteres prohibidos o reservados' {
            $invalidName = "Proyecto/Invalido*"
            New-PTProject -Name $invalidName -Type Node -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            $reservedName = "CON"
            New-PTProject -Name $reservedName -Type Node -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Test 2 (WhatIf Guardrail): Bajo -WhatIf, ningun archivo o carpeta se crea y el motor de plantillas no se dispara' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pt_whatif_" + [Guid]::NewGuid().ToString().Substring(0,8))
            $projName = "WhatIfTest"

            try {
                New-PTProject -Name $projName -Type Node -Path $tempDir -WhatIf | Should -BeNullOrEmpty
                Test-Path (Join-Path $tempDir $projName) | Should -Be $false
            }
            finally {
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }

        It 'Test 3 (Salida Estructurada): Emite un objeto fuertemente tipado [PSCustomObject] al pipeline con la metadata del proyecto creado' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pt_struct_" + [Guid]::NewGuid().ToString().Substring(0,8))
            $projName = "StructTest"

            try {
                Mock Format-PTBreadcrumb { return '~/StructTest' } -ModuleName PowerTools

                $res = New-PTProject -Name $projName -Type Python -Path $tempDir -PassThru
                $res | Should -Not -BeNullOrEmpty
                $res.Name | Should -Be $projName
                $res.Type | Should -Be 'Python'
            }
            finally {
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    Context 'Exportacion de Alias de Scaffolding' {
        It 'Debe exportar pt-new y ptn apuntando a New-PTProject' {
            foreach ($aliasName in @('pt-new', 'ptn')) {
                $cmd = Get-Command -Name $aliasName -ErrorAction SilentlyContinue
                $cmd | Should -Not -BeNullOrEmpty
                $cmd.CommandType | Should -Be 'Alias'
                $cmd.Definition | Should -Be 'New-PTProject'
            }
        }
    }
}
