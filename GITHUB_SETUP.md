# 📤 Guía para Subir a GitHub

## ✅ Estado Actual

- ✅ Repositorio Git inicializado
- ✅ Commit inicial creado (189 archivos)
- ✅ .gitignore configurado
- ✅ README actualizado

## 🚀 Pasos para Subir a GitHub

### 1. Crear Repositorio en GitHub

1. Ve a [GitHub](https://github.com) e inicia sesión
2. Click en el botón **"+"** (arriba derecha) → **"New repository"**
3. Configura el repositorio:
   - **Repository name**: `sweet-models-enterprise`
   - **Description**: "🚀 Plataforma empresarial completa - Backend Rust/Axum + Flutter Mobile con gamificación y sistema de moderación"
   - **Visibility**:
     - ✅ **Private** (recomendado para código empresarial)
     - o **Public** (si quieres que sea open source)
   - ⚠️ **NO marques**: "Add README", "Add .gitignore", "Choose a license" (ya los tienes)
4. Click **"Create repository"**

### 2. Conectar Repositorio Local con GitHub

GitHub te mostrará las instrucciones. Copia y ejecuta estos comandos en PowerShell:

```powershell
# Navegar al proyecto
cd "c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise"

# Configurar tu información (solo la primera vez)
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"

# Conectar con GitHub (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/TU_USUARIO/sweet-models-enterprise.git

# Verificar que se agregó correctamente
git remote -v

# Subir el código (primera vez)
git push -u origin master
```

### 3. Autenticación

GitHub te pedirá autenticación. Opciones:

#### Opción A: Personal Access Token (Recomendado)

1. Ve a GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Nombre: "Sweet Models Enterprise"
4. Scopes: Marca **repo** (acceso completo a repositorios)
5. Click "Generate token"
6. **COPIA EL TOKEN** (solo lo verás una vez)
7. Cuando Git pida contraseña, pega el token

#### Opción B: GitHub CLI (Más fácil)

```powershell
# Instalar GitHub CLI (si no lo tienes)
winget install --id GitHub.cli

# Autenticarte
gh auth login

# Luego puedes usar gh para push
gh repo create sweet-models-enterprise --private --source=. --push
```

## 📦 Estructura Subida

```text
sweet-models-enterprise/
├── .gitignore              ✅ Archivos ignorados
├── README.md               ✅ Documentación principal
├── docker-compose.yml      ✅ Orquestación Docker
├── backend_api/            ✅ Servidor Rust
│   ├── src/main.rs        ✅ API con JWT + Endpoints
│   ├── Cargo.toml         ✅ Dependencias Rust
│   ├── Dockerfile         ✅ Imagen Docker
│   └── migrations/        ✅ Migraciones SQL
└── mobile_app/             ✅ Aplicación Flutter
    ├── lib/               ✅ Código Dart
    ├── android/           ✅ Proyecto Android
    ├── ios/               ✅ Proyecto iOS
    ├── windows/           ✅ Proyecto Windows
    └── pubspec.yaml       ✅ Dependencias Flutter
```

## 🔒 Archivos NO Subidos (por .gitignore)

- ❌ `backend_api/target/` - Binarios compilados Rust
- ❌ `mobile_app/build/` - Builds de Flutter
- ❌ `.env` - Variables de entorno sensibles
- ❌ `*.log` - Logs temporales
- ❌ Scripts de desarrollo temporal

## 📝 Comandos Útiles Post-Push

```powershell
# Ver estado
git status

# Hacer cambios futuros
git add .
git commit -m "Descripción del cambio"
git push

# Ver historial
git log --oneline

# Crear rama nueva
git checkout -b feature/nueva-funcionalidad

# Ver ramas
git branch -a
```

## 🌐 URL del Repositorio

Después de crear el repo, tu URL será:

```text
https://github.com/TU_USUARIO/sweet-models-enterprise
```

## 🎯 Siguientes Pasos Recomendados

### 1. Configurar GitHub Actions (CI/CD)

Crea `.github/workflows/rust.yml`:

```yaml
name: Rust CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: cd backend_api && cargo build --verbose
      - name: Run tests
        run: cd backend_api && cargo test --verbose
```

### 2. Configurar GitHub Secrets

Para variables de entorno:

- Settings → Secrets and variables → Actions
- Add: `DATABASE_URL`, `JWT_SECRET`, etc.

### 3. Badges en README

Añade al README.md:

```markdown
![Rust](https://img.shields.io/badge/rust-1.75+-orange.svg)
![Flutter](https://img.shields.io/badge/flutter-3.24.5+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
```

## ⚠️ Importante: Seguridad

### Antes de hacer el repo público

- ✅ Verifica que no hay contraseñas hardcodeadas
- ✅ Revisa que `.gitignore` funciona
- ✅ Cambia `JWT_SECRET` en producción
- ✅ Usa variables de entorno para credenciales

### Archivos a revisar

```powershell
# Buscar posibles secrets
git grep -i "password"
git grep -i "secret"
git grep -i "token"
```

## 📞 Soporte

Si tienes problemas:

1. Revisa el status: `git status`
2. Revisa los remotos: `git remote -v`
3. Verifica autenticación: `gh auth status`

---

**¡Listo para GitHub!** 🚀

Ahora tu código está versionado localmente. Solo falta ejecutar los comandos de conexión con GitHub.
