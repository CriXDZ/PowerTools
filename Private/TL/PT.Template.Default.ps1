function New-DefaultProject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $readmeContent = @"
# $ProjectName

Proyecto genérico con estructura base para desarrollo ágil.

## Estructura
- `src/`      - Código fuente principal
- `docs/`     - Documentación del proyecto

Generado con PowerTools.
"@

    $srcExampleContent = @"
/**
 * Punto de entrada principal para $ProjectName
 *
 * Este archivo sirve como base para el desarrollo.
 * Reemplázalo o extiéndelo según los requisitos del proyecto.
 */

console.log('$ProjectName inicializado.');
"@

    $gitignoreContent = @"
# Sistema
.DS_Store
Thumbs.db

# Editores
.vscode/
.idea/

# Entornos y dependencias
node_modules/
venv/
.env

# Salidas de compilación
dist/
build/
out/
"@

    $treeFiles = @{
        'README.md'     = $readmeContent
        'src/index.js'  = $srcExampleContent
        '.gitignore'    = $gitignoreContent
    }

    Invoke-PTScaffoldTree -BasePath $ProjectPath -Directories @('src', 'docs') -Files $treeFiles
}
