function New-HTMLProject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $indexContent = @"
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$ProjectName</title>
    <link rel="stylesheet" href="css/styles.css" />
    <link rel="preconnect" href="https://fonts.googleapis.com  " />
    <link rel="preconnect" href="https://fonts.gstatic.com  " crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
  </head>
  <body>
    <header class="header">
      <div class="container nav-container">
        <h1 class="logo">PowerTools</h1>
        <nav>
          <ul>
            <li><a href="#">Inicio</a></li>
            <li><a href="#">Características</a></li>
            <li><a href="#">Contacto</a></li>
          </ul>
        </nav>
      </div>
    </header>

    <main>
      <section class="hero">
        <div class="container">
          <h2>Impulsa tu desarrollo web con esta solución profesional</h2>
          <p>
            Esta plantilla de alto rendimiento está optimizada para proyectos frontend modernos. Combina arquitectura
            escalable, diseño intuitivo y tecnologías contemporáneas para resultados excepcionales.
          </p>
          <div class="cta-buttons">
            <a href="#" class="btn primary">Comenzar ahora</a>
            <a href="#" class="btn secondary">Explorar funcionalidades</a>
          </div>
        </div>
      </section>

      <section class="features">
        <div class="container">
          <h3>Desarrollado para profesionales</h3>
          <div class="feature-grid">
            <div class="feature-card">
              <h4>Arquitectura profesional</h4>
              <p>
                Estructura modular y escalable, diseñada para facilitar el mantenimiento y la expansión de proyectos
                empresariales.
              </p>
            </div>
            <div class="feature-card">
              <h4>Diseño adaptativo avanzado</h4>
              <p>
                Experiencia de usuario consistente en todos los dispositivos, con layout optimizado y rendimiento
                superior.
              </p>
            </div>
            <div class="feature-card">
              <h4>Estética contemporánea</h4>
              <p>
                Diseño visual sofisticado con tipografía profesional, paleta de colores equilibrada y enfoque centrado
                en UX.
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>

    <footer class="footer">
      <div class="container">
        <p>&copy; $(Get-Date -Format yyyy) PowerTools. Implementado con tecnologías avanzadas.</p>
      </div>
    </footer>

    <script src="js/main.js"></script>
  </body>
</html>
"@

    $stylesContent = @"
:root {
  --color-bg: #ffffff;
  --color-text: #1a1a1a;
  --color-accent: #2563eb;
  --color-accent-light: #60a5fa;
  --color-muted: #6b7280;
  --color-footer: #0f172a;
  --radius: 12px;
  --transition: 0.25s ease;
  --font-main: 'Inter', system-ui, sans-serif;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: var(--font-main);
  background-color: var(--color-bg);
  color: var(--color-text);
  line-height: 1.6;
}

/* Containers */
.container {
  width: 90%;
  max-width: 1200px;
  margin: 0 auto;
}

/* Header */
.header {
  background-color: #ffffffcc;
  backdrop-filter: blur(10px);
  position: sticky;
  top: 0;
  z-index: 10;
  border-bottom: 1px solid #e5e7eb;
}

.nav-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0;
}

.logo {
  font-weight: 700;
  font-size: 1.5rem;
}

nav ul {
  display: flex;
  list-style: none;
  gap: 1rem;
}

nav a {
  text-decoration: none;
  color: var(--color-text);
  font-weight: 500;
  transition: color var(--transition);
}

nav a:hover {
  color: var(--color-accent);
}

/* Hero section */
.hero {
  text-align: center;
  padding: 6rem 1rem;
  background: linear-gradient(120deg, var(--color-accent) 0%, var(--color-accent-light) 100%);
  color: #fff;
}

.hero h2 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
}

.hero p {
  font-size: 1.1rem;
  margin-bottom: 2rem;
  color: #e0e7ff;
}

.cta-buttons {
  display: flex;
  justify-content: center;
  gap: 1rem;
}

.btn {
  padding: 0.8rem 1.8rem;
  border-radius: var(--radius);
  text-decoration: none;
  font-weight: 600;
  transition: background var(--transition), transform var(--transition);
}

.btn.primary {
  background: #fff;
  color: var(--color-accent);
}

.btn.primary:hover {
  background: #f8fafc;
  transform: translateY(-2px);
}

.btn.secondary {
  background: transparent;
  color: #fff;
  border: 1px solid #fff;
}

.btn.secondary:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

/* Features */
.features {
  padding: 5rem 1rem;
  background-color: #f9fafb;
  text-align: center;
}

.features h3 {
  font-size: 2rem;
  margin-bottom: 3rem;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

.feature-card {
  background: #fff;
  padding: 2rem;
  border-radius: var(--radius);
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  transition: transform var(--transition);
}

.feature-card:hover {
  transform: translateY(-5px);
}

.feature-card h4 {
  color: var(--color-accent);
  margin-bottom: 0.5rem;
}

/* Footer */
.footer {
  background-color: var(--color-footer);
  color: #e2e8f0;
  padding: 1.5rem 0;
  text-align: center;
  font-size: 0.9rem;
  margin-top: 3rem;
}

/* Responsive */
@media (max-width: 768px) {
  .hero h2 {
    font-size: 2rem;
  }
  .cta-buttons {
    flex-direction: column;
  }
}
"@

    $treeFiles = @{
        'index.html'     = $indexContent
        'css/styles.css' = $stylesContent
        'js/main.js'     = $mainJsContent
        'README.md'      = $readmeContent
    }

    Invoke-PTScaffoldTree -BasePath $ProjectPath -Directories @('css', 'js', 'img') -Files $treeFiles
}
