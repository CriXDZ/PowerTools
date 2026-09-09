function Get-PTBaseMusicStations {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([object[]], [psobject[]])]
    param()

    return @(
        [pscustomobject]@{
            Id              = 'rain'
            Label           = 'Ambient Rain'
            Category        = 'Ambiente'
            Description     = 'Lluvia suave y tormenta continua para aislamiento acustico y calma mental'
            DefaultProvider = 'YouTubeMusic'
            YouTubeMusicUrl = 'https://music.youtube.com/watch?v=13EL6Mgeocc&list=RDAMVM13EL6Mgeocc'
            AmbientUrl      = 'https://rainymood.com/'
            SpotifyUri      = 'spotify:playlist:37i9dQZF1DXbcPC6Vvqudd'
            WebUrl          = 'https://rainymood.com/'
            IsCustom        = $false
        },
        [pscustomobject]@{
            Id              = 'brown'
            Label           = 'Brown Noise'
            Category        = 'Enfoque'
            Description     = 'Frecuencias bajas continuas para mitigar distracciones y enfocar la mente'
            DefaultProvider = 'YouTubeMusic'
            YouTubeMusicUrl = 'https://music.youtube.com/watch?v=TKHjJnEaVrQ'
            SpotifyUri      = 'spotify:playlist:37i9dQZF1DX4wta20PHgwo'
            WebUrl          = 'https://open.spotify.com/playlist/37i9dQZF1DX4wta20PHgwo'
            IsCustom        = $false
        },
        [pscustomobject]@{
            Id              = 'lofi'
            Label           = 'Lo-Fi Beats'
            Category        = 'Enfoque'
            Description     = 'Ritmo suave de 70-90 BPM sin letra para trabajo continuo'
            DefaultProvider = 'YouTubeMusic'
            YouTubeMusicUrl = 'https://music.youtube.com/playlist?list=RDAO1-qMCYe8pGt51RoZyWxAYg'
            SpotifyUri      = 'spotify:playlist:37i9dQZF1DXdLEN7aqioXM'
            WebUrl          = 'https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM'
            IsCustom        = $false
        },
        [pscustomobject]@{
            Id              = 'synth'
            Label           = 'Synthwave / Retro'
            Category        = 'Sesion de Trabajo'
            Description     = 'Sintetizadores y ritmo electronico para programacion rapida'
            DefaultProvider = 'YouTubeMusic'
            YouTubeMusicUrl = 'https://music.youtube.com/watch?v=4xDzrJKXOOY'
            SpotifyUri      = 'spotify:playlist:37i9dQZF1DXd9rSDyQguIk'
            WebUrl          = 'https://open.spotify.com/playlist/37i9dQZF1DXd9rSDyQguIk'
            IsCustom        = $false
        },
        [pscustomobject]@{
            Id              = 'binaural'
            Label           = 'Alpha Waves'
            Category        = 'Sesion de Trabajo'
            Description     = 'Ondas continuas 10Hz y 432Hz para concentracion profunda y foco mental'
            DefaultProvider = 'YouTubeMusic'
            YouTubeMusicUrl = 'https://music.youtube.com/watch?v=lRckcZ4jRy0&list=RDAMVMlRckcZ4jRy0'
            SpotifyUri      = 'spotify:playlist:37i9dQZF1DX9uKNf5jGX6m'
            WebUrl          = 'https://open.spotify.com/playlist/37i9dQZF1DX9uKNf5jGX6m'
            IsCustom        = $false
        }
    )
}

function Get-PTMusicCatalog {
    [CmdletBinding()]
    [OutputType([object[]], [psobject[]])]
    param()

    $baseStations = Get-PTBaseMusicStations
    $catalog = [System.Collections.Generic.List[pscustomobject]]::new()

    foreach ($st in $baseStations) {
        $catalog.Add($st)
    }

    if (Get-Command -Name 'Get-PTMusicStation' -ErrorAction SilentlyContinue) {
        $customStations = Get-PTMusicStation
        if ($customStations -and $customStations -is [psobject]) {
            foreach ($prop in $customStations.PSObject.Properties) {
                $cName = $prop.Name
                $cData = $prop.Value
                $cUrl = if ($cData.Url) { $cData.Url } else { [string]$cData }
                $cProvider = if ($cData.Provider) { $cData.Provider } else { 'Auto' }

                $isSpotify = $cUrl -match '^spotify:' -or $cUrl -match 'spotify\.com'
                $isYtMusic = $cUrl -match 'music\.youtube\.com'

                $spotifyUri = if ($isSpotify -and $cUrl -match '^spotify:') { $cUrl } else { $null }
                $webUrl = if ($cUrl -match '^https?://') { $cUrl } else { $null }

                $existingIndex = -1
                for ($i = 0; $i -lt $catalog.Count; $i++) {
                    if ($catalog[$i].Id -eq $cName.ToLowerInvariant()) {
                        $existingIndex = $i
                        break
                    }
                }

                $customItem = [pscustomobject]@{
                    Id              = $cName.ToLowerInvariant()
                    Label           = $cName
                    Category        = 'Personalizada'
                    Description     = "Estacion personalizada ($cProvider)"
                    DefaultProvider = if ($cProvider -ne 'Auto') { $cProvider } elseif ($isSpotify) { 'Spotify' } elseif ($isYtMusic) { 'YouTubeMusic' } else { 'WebStream' }
                    SpotifyUri      = $spotifyUri
                    WebUrl          = $webUrl
                    YouTubeMusicUrl = if ($isYtMusic) { $cUrl } else { $null }
                    RawUrl          = $cUrl
                    IsCustom        = $true
                }

                if ($existingIndex -ge 0) {
                    $catalog[$existingIndex] = $customItem
                }
                else {
                    $catalog.Add($customItem)
                }
            }
        }
    }

    return @($catalog)
}

function Resolve-PTMusicUri {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Station,

        [string] $ForceProvider,

        [switch] $PreferProtocol
    )

    $provider = if (-not [string]::IsNullOrWhiteSpace($ForceProvider)) {
        $ForceProvider.Trim()
    }
    elseif ($Station.DefaultProvider) {
        $Station.DefaultProvider
    }
    else {
        'YouTubeMusic'
    }

    if ($Station.IsCustom -and $Station.RawUrl) {
        $raw = $Station.RawUrl.Trim()
        if ($provider -eq 'Spotify' -or ($provider -eq 'Auto' -and $raw -match 'spotify')) {
            if ($PreferProtocol -and $raw -match 'open\.spotify\.com/(playlist|album|track|artist)/([a-zA-Z0-9]+)') {
                $type = $Matches[1]
                $id   = $Matches[2]
                return "spotify:$($type):$($id)"
            }
            return $raw
        }
        return $raw
    }

    $targetUri = switch -Regex ($provider) {
        '^(ambient|rain|rainymood|amb)$' {
            if (-not [string]::IsNullOrWhiteSpace($Station.AmbientUrl)) {
                $Station.AmbientUrl
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Station.WebUrl)) {
                $Station.WebUrl
            }
            else {
                $Station.YouTubeMusicUrl
            }
            break
        }
        '^(spotify|sp)$' {
            if ($PreferProtocol -and -not [string]::IsNullOrWhiteSpace($Station.SpotifyUri)) {
                $Station.SpotifyUri
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Station.WebUrl)) {
                $Station.WebUrl
            }
            else {
                $Station.SpotifyUri
            }
            break
        }
        '^(youtubemusic|ytm|youtube|yt)$' {
            if (-not [string]::IsNullOrWhiteSpace($Station.YouTubeMusicUrl)) {
                $Station.YouTubeMusicUrl
            }
            break
        }
        default {
            if (-not [string]::IsNullOrWhiteSpace($Station.YouTubeMusicUrl)) {
                $Station.YouTubeMusicUrl
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Station.AmbientUrl)) {
                $Station.AmbientUrl
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Station.WebUrl)) {
                $Station.WebUrl
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Station.SpotifyUri)) {
                $Station.SpotifyUri
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($targetUri)) {
        if (-not [string]::IsNullOrWhiteSpace($Station.YouTubeMusicUrl)) {
            $targetUri = $Station.YouTubeMusicUrl
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Station.AmbientUrl)) {
            $targetUri = $Station.AmbientUrl
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Station.WebUrl)) {
            $targetUri = $Station.WebUrl
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Station.SpotifyUri)) {
            $targetUri = $Station.SpotifyUri
        }
    }

    if ($targetUri -match 'music\.youtube\.com/playlist\?list=([a-zA-Z0-9_-]+)') {
        $playlistId = $Matches[1]
        $targetUri = "https://music.youtube.com/watch?list=$playlistId"
    }

    return $targetUri
}
