function Invoke-PTScaffoldTree {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $BasePath,

        [array] $Directories = @(),

        [hashtable] $Files = @{}
    )

    if (-not (Test-Path -Path $BasePath -PathType Container)) {
        $null = New-Item -Path $BasePath -ItemType Directory -Force
    }

    foreach ($dir in $Directories) {
        $targetDir = Join-Path -Path $BasePath -ChildPath $dir
        if (-not (Test-Path -Path $targetDir -PathType Container)) {
            $null = New-Item -Path $targetDir -ItemType Directory -Force
        }
    }

    foreach ($fileRelPath in $Files.Keys) {
        $targetFilePath = Join-Path -Path $BasePath -ChildPath $fileRelPath
        $parentDir = [System.IO.Path]::GetDirectoryName($targetFilePath)
        if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -Path $parentDir)) {
            $null = New-Item -Path $parentDir -ItemType Directory -Force
        }

        if (-not (Test-Path -Path $targetFilePath)) {
            Set-Content -Path $targetFilePath -Value $Files[$fileRelPath] -Encoding UTF8
        }
    }
}

function Get-PTProjectTemplate {

    [CmdletBinding()]
    [OutputType([object[]], [psobject])]
    param(
        [string] $Id
    )

    $catalog = @(
        [PSCustomObject]@{
            Id          = 'Node'
            Label       = 'Node'
            Value       = 'Node'
            Description = 'Backend JavaScript con npm'
            NextSteps   = @(
                'npm install'
                'npm run dev'
                'code . (o abrir en su editor)'
            )
            Build       = {
                param([string]$ProjectPath, [string]$ProjectName)
                if (Get-Command -Name 'New-NodeProject' -ErrorAction SilentlyContinue) {
                    New-NodeProject -ProjectPath $ProjectPath -ProjectName $ProjectName
                }
            }
        }
        [PSCustomObject]@{
            Id          = 'Python'
            Label       = 'Python'
            Value       = 'Python'
            Description = 'Backend o scripts con venv'
            NextSteps   = @(
                '.\venv\Scripts\Activate.ps1'
                'python src/main.py'
                'code .'
            )
            Build       = {
                param([string]$ProjectPath, [string]$ProjectName)
                if (Get-Command -Name 'New-PythonProject' -ErrorAction SilentlyContinue) {
                    New-PythonProject -ProjectPath $ProjectPath -ProjectName $ProjectName
                }
            }
        }
        [PSCustomObject]@{
            Id          = 'Vite'
            Label       = 'Vite'
            Value       = 'Vite'
            Description = 'App frontend moderna (React, Vue)'
            NextSteps   = @(
                'npm install'
                'npm run dev'
                'code .'
            )
            Build       = {
                param([string]$ProjectPath, [string]$ProjectName)
                if (Get-Command -Name 'New-ViteProject' -ErrorAction SilentlyContinue) {
                    New-ViteProject -ProjectPath $ProjectPath -ProjectName $ProjectName
                }
            }
        }
        [PSCustomObject]@{
            Id          = 'HTML'
            Label       = 'HTML'
            Value       = 'HTML'
            Description = 'Sitio web estatico clasico (HTML/CSS/JS)'
            NextSteps   = @(
                'code . (o abrir index.html en el navegador)'
            )
            Build       = {
                param([string]$ProjectPath, [string]$ProjectName)
                if (Get-Command -Name 'New-HTMLProject' -ErrorAction SilentlyContinue) {
                    New-HTMLProject -ProjectPath $ProjectPath -ProjectName $ProjectName
                }
            }
        }
        [PSCustomObject]@{
            Id          = 'Default'
            Label       = 'Default'
            Value       = 'Default'
            Description = 'Estructura base multiproposito'
            NextSteps   = @(
                'code .'
            )
            Build       = {
                param([string]$ProjectPath, [string]$ProjectName)
                if (Get-Command -Name 'New-DefaultProject' -ErrorAction SilentlyContinue) {
                    New-DefaultProject -ProjectPath $ProjectPath -ProjectName $ProjectName
                }
            }
        }
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        return $catalog
    }

    $found = $catalog | Where-Object { $_.Id -eq $Id -or $_.Value -eq $Id }
    return $found
}
