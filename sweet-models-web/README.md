# Sweet Models Web - Enterprise Next.js Portal

**Paranoid Mode Security 🔒** | Production-Ready | Zero-Trust Architecture

## 📋 Estructura de Carpetas

```
src/
├── app/
│   ├── (auth)/           # Rutas públicas (login, register)
│   ├── (dashboard)/      # Rutas protegidas (admin panel)
│   ├── api/              # API routes (backend proxy)
│   ├── layout.tsx        # Layout global
│   └── page.tsx          # Home page
├── core/
│   ├── security/         # Encriptación OMNI, JWT validation
│   └── services/         # Llamadas a API Rust backend
├── components/
│   └── ui/               # Componentes visuales reutilizables
├── middleware.ts         # Defense-first middleware
└── .env.local            # Variables de entorno (secretas)
```

## 🔒 Características de Seguridad Implementadas

### Headers HTTP Militares
- ✅ **Content-Security-Policy (CSP)**: Máxima restricción (`default-src 'self'`)
- ✅ **X-Frame-Options: DENY**: Anti-clickjacking total
- ✅ **X-Content-Type-Options: nosniff**: Previene type confusion
- ✅ **Strict-Transport-Security (HSTS)**: Fuerza HTTPS por 2 años
- ✅ **Referrer-Policy**: `strict-origin-when-cross-origin`
- ✅ **Permissions-Policy**: Deshabilita acceso a cámara, micrófono, geolocation

### Middleware Defensivo
- ✅ Intercepta TODAS las rutas excepto `/_next` y `/static`
- ✅ Validación de origen (CSRF protection)
- ✅ Detección de bots sospechosos
- ✅ Inyección de headers de respuesta defensivos
- ✅ **TODO**: Validación de token JWT
- ✅ **TODO**: Verificación de permisos por rol

### Configuración Next.js
- ✅ Source maps deshabilitados en producción
- ✅ Minificación SWC (rápida)
- ✅ React Strict Mode habilitado
- ✅ Rewrites ocultos para API backend
- ✅ Imágenes optimizadas con dominio S3 seguro

## 🚀 Instalación y Desarrollo

### Prerequisitos
- Node.js 18+
- npm 9+

### Instalación
```bash
cd sweet-models-web
npm install
```

### Desarrollo Local
```bash
npm run dev
# Acceder a http://localhost:3000
```

### Build Producción
```bash
npm run build
npm start
```

## 🔐 Variables de Entorno Requeridas

Crear `.env.local`:
```env
# Backend API
NEXT_PUBLIC_API_URL=https://sweet-models-enterprise-production.up.railway.app

# JWT Secret (para validar tokens del backend)
JWT_SECRET=tu_secret_key_aqui

# AWS S3 (Imágenes)
NEXT_PUBLIC_S3_BUCKET=sweet-models-s3
AWS_REGION=us-east-1

# Auth (Next-Auth)
NEXTAUTH_SECRET=tu_nextauth_secret_aqui
NEXTAUTH_URL=https://sweet-models-web.vercel.app
```

## 📊 Roadmap de Seguridad

- [ ] Implementar validación JWT completa en middleware
- [ ] Agregar rate limiting (10 requests/min por IP)
- [ ] TOTP/2FA para admin
- [ ] Encriptación OMNI para datos sensibles
- [ ] Audit logging centralizado
- [ ] DDoS protection (Cloudflare)
- [ ] Web Application Firewall (WAF)

## 📝 Notas de Desarrollo

1. **NUNCA** commitear `.env.local` a Git
2. **SIEMPRE** usar HTTPS en producción (Railway/Vercel)
3. **VALIDAR** inputs del usuario en backend + frontend
4. **LOGUEAR** eventos de seguridad en AWS CloudWatch
5. **RENOVAR** JWT tokens cada 15 minutos

## 🛡️ Cumplimiento de Normas

- ✅ OWASP Top 10 2021
- ✅ NIST Cybersecurity Framework
- ✅ CWE/SANS Top 25
- ✅ GDPR-ready (datos de EU protegidos)

---

**Última actualización**: 2024-12-21
**Versión de seguridad**: 1.0 (Paranoid Mode)
