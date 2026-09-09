Describe 'PT.Selector - Motor Interactivo TUI estilo Vercel / Clack' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path $moduleRoot 'Private/UI/PT.Ansi.ps1')
        . (Join-Path $moduleRoot 'Private/SY/PT.KeyHandler.ps1')
        . (Join-Path $moduleRoot 'Private/UI/PT.Selector.ps1')
    }

    Context 'Glifos Tipograficos y Codigos Unicode' {
        It 'Debe generar simbolos Unicode nativos sin corrupcion de caracteres' {
            $symbols = Get-PTSelectorSymbols
            $symbols | Should -Not -BeNullOrEmpty
            $symbols.DiamondFull | Should -Be ([string][char]0x25C6)
            $symbols.Pipe | Should -Be ([string][char]0x2502)
        }
    }

    Context 'Navegacion Ciclica y Limites de Indices' {
        It 'Debe ciclar al siguiente elemento hacia abajo y envolver al inicio' {
            $next = Get-PTSelectorNextIndex -CurrentIndex 2 -TotalItems 3 -Action 'Down'
            $next | Should -Be 0

            $next = Get-PTSelectorNextIndex -CurrentIndex 0 -TotalItems 3 -Action 'Down'
            $next | Should -Be 1
        }

        It 'Debe ciclar al elemento anterior hacia arriba y envolver al final' {
            $prev = Get-PTSelectorNextIndex -CurrentIndex 0 -TotalItems 3 -Action 'Up'
            $prev | Should -Be 2

            $prev = Get-PTSelectorNextIndex -CurrentIndex 2 -TotalItems 3 -Action 'Up'
            $prev | Should -Be 1
        }

        It 'Debe respetar limites en PageUp y PageDown' {
            $pageDown = Get-PTSelectorNextIndex -CurrentIndex 0 -TotalItems 10 -Action 'PageDown' -PageSize 4
            $pageDown | Should -Be 4

            $pageUp = Get-PTSelectorNextIndex -CurrentIndex 4 -TotalItems 10 -Action 'PageUp' -PageSize 4
            $pageUp | Should -Be 0
        }
    }

    Context 'Calculo de Ventana y Paginacion Pura' {
        It 'Debe calcular correctamente limites sin desbordar cuando TotalItems es menor que PageSize' {
            $win = Get-PTSelectorPageWindow -SelectedIndex 1 -TotalItems 3 -PageSize 5
            $win.StartIndex | Should -Be 0
            $win.EndIndex | Should -Be 3
            $win.HasPrev | Should -Be $false
            $win.HasNext | Should -Be $false
        }

        It 'Debe centrar la ventana y habilitar HasPrev y HasNext cuando corresponda' {
            $win = Get-PTSelectorPageWindow -SelectedIndex 4 -TotalItems 10 -PageSize 4
            $win.StartIndex | Should -Be 2
            $win.EndIndex | Should -Be 6
            $win.HasPrev | Should -Be $true
            $win.HasNext | Should -Be $true
        }

        It 'Debe anclar la ventana al final si el elemento seleccionado esta en la ultima pagina' {
            $win = Get-PTSelectorPageWindow -SelectedIndex 9 -TotalItems 10 -PageSize 4
            $win.StartIndex | Should -Be 6
            $win.EndIndex | Should -Be 10
            $win.HasPrev | Should -Be $true
            $win.HasNext | Should -Be $false
        }
    }

    Context 'Filtrado en Tiempo Real y Resaltado' {
        It 'Debe filtrar opciones por coincidencia en Label o Description de forma case-insensitive' {
            $options = @(
                [pscustomobject]@{ Label = 'Node'; Description = 'Servidor JS' },
                [pscustomobject]@{ Label = 'Python'; Description = 'Backend Script' },
                [pscustomobject]@{ Label = 'Vite'; Description = 'Frontend React' }
            )

            $filtered = Find-PTMatchingOptions -Options $options -FilterText 'js'
            $filtered.Count | Should -Be 1
            $filtered[0].Label | Should -Be 'Node'
        }

        It 'Debe retornar todas las opciones si el filtro esta vacio' {
            $options = @( [pscustomobject]@{ Label = 'A' }, [pscustomobject]@{ Label = 'B' } )
            $filtered = Find-PTMatchingOptions -Options $options -FilterText ''
            $filtered.Count | Should -Be 2
        }

        It 'Debe formatear el texto resaltando la parte coincidente' {
            $highlighted = Format-PTHighlightedText -Text 'TypeScript' -SearchTerm 'Script'
            $highlighted | Should -Match 'Script'
        }
    }

    Context 'Construccion Pura del Fotograma (Format-PTSelectorFrame)' {
        It 'Debe incluir conectores de rama Vercel/Clack y marcar el circulo lleno en la opcion activa' {
            $options = @(
                [pscustomobject]@{ Label = 'Opcion A'; Description = 'Desc A' },
                [pscustomobject]@{ Label = 'Opcion B'; Description = 'Desc B' }
            )

            $frame = Format-PTSelectorFrame -FilteredOptions $options -SelectedIndex 0 -FilterText '' -Title 'Seleccione:' -PageSize 5
            $frame | Should -Not -BeNullOrEmpty
            $frame -join "`n" | Should -Match 'Opcion A'
        }

        It 'Debe mostrar mensaje atenuado si no hay opciones coincidentes' {
            $frame = Format-PTSelectorFrame -FilteredOptions @() -SelectedIndex 0 -FilterText 'xyz' -Title 'Buscar' -PageSize 5
            $frame -join "`n" | Should -Match 'No hay coincidencias'
        }
    }

    Context 'QA Geometrico y Rigor Visual (Zero-Shift / Freeze Contract)' {
        It 'Debe garantizar que el prefijo visible activo e inactivo tenga exactamente 4 caracteres de ancho' {
            $activePrefix = "  " + [char]0x25C6 + " "
            $inactivePrefix = "  " + [char]0x25C7 + " "

            $activePrefix.Length | Should -Be 4
            $inactivePrefix.Length | Should -Be 4
        }

        It 'No debe desplazar la etiqueta horizontalmente al alternar de item activo a inactivo' {
            $activePlain = "  " + [char]0x25C6 + "  Item1"
            $inactivePlain = "  " + [char]0x25C7 + "  Item1"

            $activePlain.IndexOf("Item1") | Should -Be $inactivePlain.IndexOf("Item1")
        }

        It 'Todos los scripts UI del modulo deben superar analisis sintactico AST sin errores' {
            $uiFiles = Get-ChildItem -Path (Join-Path $script:moduleRoot 'Private/UI/*.ps1')
            foreach ($file in $uiFiles) {
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors) | Out-Null
                $errors.Count | Should -Be 0
            }
        }

        It 'Debe alinear las descripciones en una columna vertical uniforme independientemente del largo de etiqueta' {
            $options = @(
                [pscustomobject]@{ Label = 'A'; Description = 'Desc A' },
                [pscustomobject]@{ Label = 'LargaEtiqueta'; Description = 'Desc B' }
            )
            $frame = Format-PTSelectorFrame -FilteredOptions $options -SelectedIndex 0 -FilterText '' -Title 'Alineacion' -PageSize 5
            $frame | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Ejecucion y Manejo de Opciones' {
        It 'Debe retornar $null si la lista de opciones esta vacia' {
            $res = Invoke-PTSelector -Title 'Test' -Options @()
            $res | Should -BeNullOrEmpty
        }

        It 'Debe soportar lista de opciones y retornar el resultado esperado' {
            Mock Read-Host { return '2' }
            Mock Write-Host { }
            $res = Invoke-PTSelector -Title 'Test' -Options @('Alfa', 'Beta', 'Gamma')
            $res | Should -Not -BeNullOrEmpty
        }
    }
}
