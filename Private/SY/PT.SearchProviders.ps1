function Get-PTSearchProviders {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([object[]], [psobject[]])]
    param()

    return @(
        [pscustomobject]@{
            Id          = 'google'
            Prefix      = 'g'
            Label       = 'Google'
            Description = 'Motor de busqueda general'
            UrlPattern  = 'https://www.google.com/search?q={0}'
        },
        [pscustomobject]@{
            Id          = 'duckduckgo'
            Prefix      = 'd'
            Label       = 'DuckDuckGo'
            Description = 'Busqueda orientada a la privacidad'
            UrlPattern  = 'https://duckduckgo.com/?q={0}'
        },
        [pscustomobject]@{
            Id          = 'youtube'
            Prefix      = 'yt'
            Label       = 'YouTube'
            Description = 'Directo a resultados sin feed de distraccion'
            UrlPattern  = 'https://www.youtube.com/results?search_query={0}'
        },
        [pscustomobject]@{
            Id          = 'github'
            Prefix      = 'gh'
            Label       = 'GitHub'
            Description = 'Repositorios, codigo y herramientas de desarrollo'
            UrlPattern  = 'https://github.com/search?q={0}&type=repositories'
        },
        [pscustomobject]@{
            Id          = 'stackoverflow'
            Prefix      = 'so'
            Label       = 'StackOverflow'
            Description = 'Preguntas y soluciones tecnicas de programacion'
            UrlPattern  = 'https://stackoverflow.com/search?q={0}'
        },
        [pscustomobject]@{
            Id          = 'devdocs'
            Prefix      = 'dev'
            Label       = 'DevDocs'
            Description = 'Documentacion tecnica unificada para desarrolladores'
            UrlPattern  = 'https://devdocs.io/#q={0}'
        },
        [pscustomobject]@{
            Id          = 'mdn'
            Prefix      = 'mdn'
            Label       = 'MDN Web Docs'
            Description = 'Referencia tecnica de JavaScript, CSS y HTML'
            UrlPattern  = 'https://developer.mozilla.org/es/search?q={0}'
        },
        [pscustomobject]@{
            Id          = 'perplexity'
            Prefix      = 'ai'
            Label       = 'Perplexity AI'
            Description = 'Respuestas de inteligencia artificial con fuentes directas'
            UrlPattern  = 'https://www.perplexity.ai/search?q={0}'
        }
    )
}

function Get-PTSearchUrl {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Provider,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Query
    )

    if ([string]::IsNullOrWhiteSpace($Query)) {
        return [string]::Empty
    }

    $providers = Get-PTSearchProviders
    $target = $null

    $normProvider = $Provider.Trim().ToLowerInvariant()
    foreach ($p in $providers) {
        if ($p.Id.ToLowerInvariant() -eq $normProvider -or $p.Prefix.ToLowerInvariant() -eq $normProvider) {
            $target = $p
            break
        }
    }

    if (-not $target) {
        $target = $providers[0]
    }

    $escapedQuery = [System.Uri]::EscapeDataString($Query.Trim())
    return [string]::Format($target.UrlPattern, $escapedQuery)
}
