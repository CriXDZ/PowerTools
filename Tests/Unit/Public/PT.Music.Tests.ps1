Describe 'PT.Music - Entornos Acusticos y Enfoque Cognitivo' -Tag 'Unit', 'Music' {

    BeforeAll {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path (Join-Path $dir 'PowerTools.psd1')) -eq $false) {
            $dir = Split-Path $dir -Parent
        }
        $moduleRoot = $dir; $script:moduleRoot = $dir

        . (Join-Path -Path $moduleRoot -ChildPath 'Private\UI\PT.Ansi.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Private\UI\PT.Message.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Private\SY\PT.Config.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Private\SY\PT.MusicProviders.ps1')
        . (Join-Path -Path $moduleRoot -ChildPath 'Public\PT.Music.ps1')
    }

    Context 'Catalogo Base y Metadatos (Get-PTBaseMusicStations)' {
        It 'Debe registrar las 5 estaciones base de enfoque y sonido ambiente' {
            $stations = Get-PTBaseMusicStations
            $stations.Count | Should -Be 5

            $ids = $stations.Id
            $ids -contains 'rain' | Should -Be $true
            $ids -contains 'brown' | Should -Be $true
            $ids -contains 'lofi' | Should -Be $true
            $ids -contains 'synth' | Should -Be $true
            $ids -contains 'binaural' | Should -Be $true
        }

        It 'Cada estacion base debe cumplir el contrato de propiedades' {
            $stations = Get-PTBaseMusicStations
            foreach ($st in $stations) {
                $st.Id | Should -Not -BeNullOrEmpty
                $st.Label | Should -Not -BeNullOrEmpty
                $st.Category | Should -Not -BeNullOrEmpty
                $st.Description | Should -Not -BeNullOrEmpty
                $st.DefaultProvider | Should -Not -BeNullOrEmpty
                $st.WebUrl | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Resolucion de URIs y Protocolos (Resolve-PTMusicUri)' {
        BeforeAll {
            $Script:BaseStations = Get-PTBaseMusicStations
            $Script:Rain = $Script:BaseStations | Where-Object { $_.Id -eq 'rain' }
            $Script:Brown = $Script:BaseStations | Where-Object { $_.Id -eq 'brown' }
            $Script:Lofi = $Script:BaseStations | Where-Object { $_.Id -eq 'lofi' }
        }

        It 'Debe resolver a YouTube Music en modo reproductor activo por defecto' {
            $uri = Resolve-PTMusicUri -Station $Script:Brown
            $uri | Should -BeLike 'https://music.youtube.com/watch*'
        }

        It 'Debe resolver estacion rain al proveedor ambiental dedicado bajo ForceProvider Ambient' {
            $uri = Resolve-PTMusicUri -Station $Script:Rain -ForceProvider 'Ambient'
            $uri | Should -Be 'https://rainymood.com/'
        }

        It 'Debe resolver URI de protocolo de Spotify cuando se especifica explicitamente con PreferProtocol' {
            $uri = Resolve-PTMusicUri -Station $Script:Brown -ForceProvider 'Spotify' -PreferProtocol
            $uri | Should -BeLike 'spotify:playlist:*'
        }

        It 'Debe resolver URL web de Spotify cuando se especifica explicitamente sin preferir protocolo' {
            $uri = Resolve-PTMusicUri -Station $Script:Brown -ForceProvider 'Spotify' -PreferProtocol:$false
            $uri | Should -BeLike 'https://open.spotify.com/playlist/*'
        }

        It 'Autoplay Guardrail: debe convertir /playlist?list= a /watch?list= para iniciar reproduccion directa' {
            $playlistSt = [pscustomobject]@{
                Id                 = 'custom-list'
                Label              = 'Custom List'
                YouTubeMusicUrl    = 'https://music.youtube.com/playlist?list=PL123456789'
                DefaultProvider    = 'YouTubeMusic'
            }

            $uri = Resolve-PTMusicUri -Station $playlistSt
            $uri | Should -Be 'https://music.youtube.com/watch?list=PL123456789'
        }

        It 'Debe transformar URLs web de Spotify a protocolo spotify: cuando se solicita PreferProtocol en estacion personalizada' {
            $customSt = [pscustomobject]@{
                Id              = 'mi-focus'
                Label           = 'Mi Focus'
                RawUrl          = 'https://open.spotify.com/playlist/37i9dQZF1DX4wta20PHgwo'
                DefaultProvider = 'Spotify'
                IsCustom        = $true
            }

            $uri = Resolve-PTMusicUri -Station $customSt -PreferProtocol
            $uri | Should -Be 'spotify:playlist:37i9dQZF1DX4wta20PHgwo'
        }
    }

    Context 'Gestion de Configuracion Persistente (Get/Set/Remove-PTMusicStation)' {
        BeforeEach {
            $mockConfig = [pscustomobject]@{
                MusicStations = [pscustomobject]@{}
            }
            Mock Read-PTConfig { return $mockConfig }
            Mock Write-PTConfig { }
        }

        It 'Debe guardar una estacion personalizada' {
            Set-PTMusicStation -Name 'chill' -Url 'https://open.spotify.com/playlist/test1234' -Provider 'Spotify'

            $res = Get-PTMusicStation -Name 'chill'
            $res | Should -Not -BeNullOrEmpty
            $res.Url | Should -Be 'https://open.spotify.com/playlist/test1234'
            $res.Provider | Should -Be 'Spotify'
        }

        It 'Debe eliminar una estacion personalizada existente' {
            Set-PTMusicStation -Name 'eliminar' -Url 'https://test.com/stream'
            $deleted = Remove-PTMusicStation -Name 'eliminar'
            $deleted | Should -Be $true

            $res = Get-PTMusicStation -Name 'eliminar'
            $res | Should -BeNullOrEmpty
        }

        It 'Debe retornar $false al intentar eliminar una estacion inexistente' {
            $deleted = Remove-PTMusicStation -Name 'no_existe_xyz'
            $deleted | Should -Be $false
        }
    }

    Context 'Start-PTMusic - Orquestador y Guardarrailes de Ejecucion' {
        It 'Guardarrail WhatIf: bajo -WhatIf ningun proceso del sistema es lanzado' {
            Mock Start-Process { }
            Start-PTMusic -Station 'brown' -WhatIf
            Assert-MockCalled Start-Process -Times 0 -Scope It
        }

        It 'Debe invocar Start-Process con YouTube Music por defecto' {
            Mock Start-Process { }
            Mock Write-PTMessage { }

            Start-PTMusic -Station 'lofi'
            Assert-MockCalled Start-Process -Times 1 -ParameterFilter {
                $FilePath -like 'https://music.youtube.com/*'
            } -Scope It
        }

        It 'Debe invocar Start-Process con Spotify cuando se especifica explicitamente' {
            Mock Start-Process { }
            Mock Write-PTMessage { }

            Start-PTMusic -Station 'lofi' -Provider 'Spotify' -Web
            Assert-MockCalled Start-Process -Times 1 -ParameterFilter {
                $FilePath -like 'https://open.spotify.com/*'
            } -Scope It
        }

        It 'Debe emitir error controlado si la estacion especificada no existe' {
            Mock Start-Process { }
            $errorOutput = $null

            Start-PTMusic -Station 'estacion_fantasma_404' -ErrorVariable errorOutput -ErrorAction SilentlyContinue
            Assert-MockCalled Start-Process -Times 0 -Scope It
            $errorOutput | Should -Not -BeNullOrEmpty
        }

        It 'Debe listar el catalogo bajo el switch -List sin lanzar errores' {
            { Start-PTMusic -List } | Should -Not -Throw
        }
    }

    Context 'Exportacion de Alias de Audio y Paridad de 2 Comandos' {
        It 'Debe exportar pt-music y ptmu apuntando a Start-PTMusic' {
            $manifestPath = Join-Path -Path $moduleRoot -ChildPath 'PowerTools.psd1'
            $manifest = Import-PowerShellDataFile -Path $manifestPath

            $manifest.FunctionsToExport -contains 'Start-PTMusic' | Should -Be $true
            $manifest.AliasesToExport -contains 'pt-music' | Should -Be $true
            $manifest.AliasesToExport -contains 'ptmu' | Should -Be $true

            $aliasMusic = Get-Alias -Name 'pt-music' -ErrorAction SilentlyContinue
            $aliasMu    = Get-Alias -Name 'ptmu' -ErrorAction SilentlyContinue

            $aliasMusic.Definition | Should -Be 'Start-PTMusic'
            $aliasMu.Definition    | Should -Be 'Start-PTMusic'
        }
    }
}
