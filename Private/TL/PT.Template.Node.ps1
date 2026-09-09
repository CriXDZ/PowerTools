function New-NodeProject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $indexContent = @"
/**
 * $ProjectName - Aplicación principal
 */
const express = require('express');
const path = require('path');

// Inicializar Express
const app = express();

// Configuración básica
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Rutas
app.get('/', (req, res) => {
  res.send('¡Bienvenido a $ProjectName!');
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor iniciado en http://localhost:\${PORT}`);
});

module.exports = app;
"@

    $packageSeed = @{
        name        = $ProjectName.ToLower()
        version     = "1.0.0"
        description = "Aplicacion Node.js"
        main        = "src/index.js"
        scripts     = @{
            start = "node src/index.js"
            dev   = "nodemon src/index.js"
        }
    }
    $packageJsonContent = $packageSeed | ConvertTo-Json -Depth 10

    $treeFiles = @{
        'src/index.js'      = $indexContent
        '.env'              = $envContent
        'public/index.html' = $htmlContent
        'README.md'         = $readmeContent
        'package.json'      = $packageJsonContent
        '.gitignore'        = $gitignoreContent
    }

    Invoke-PTScaffoldTree -BasePath $ProjectPath -Directories @('src', 'public') -Files $treeFiles
}
