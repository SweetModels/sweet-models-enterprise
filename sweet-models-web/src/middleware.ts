/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - MIDDLEWARE
 * Defense-First | Token Validation | Security Verification
 * ============================================================================
 * Intercepta TODAS las rutas excepto /_next y /static
 * Verifica headers de seguridad y prepara validación JWT
 */

import { NextRequest, NextResponse } from 'next/server';

// ============================================================================
// RUTAS PÚBLICAS (No requieren autenticación)
// ============================================================================
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/health',
  '/_next',
  '/static',
  '/api/health',
];

// ============================================================================
// RUTAS PROTEGIDAS (Requieren autenticación)
// ============================================================================
const PROTECTED_ROUTES = [
  '/dashboard',
  '/admin',
  '/api/admin',
  '/api/models',
  '/settings',
];

/**
 * Middleware defensivo de seguridad
 * @param {NextRequest} request - Request HTTP
 * @returns {NextResponse} Response con headers de seguridad
 */
export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // 🚫 Ignora rutas de Next.js y estáticas
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/static') ||
    pathname.startsWith('/favicon.ico') ||
    pathname.startsWith('/robots.txt')
  ) {
    return NextResponse.next();
  }

  // ============================================================================
  // 🔍 VALIDACIÓN DE SEGURIDAD EN HEADERS
  // ============================================================================
  const response = NextResponse.next();

  // 1️⃣ Verificar origen (CSRF Protection)
  const origin = request.headers.get('origin');
  const referer = request.headers.get('referer');
  const allowedOrigins = [
    'https://sweet-models-enterprise.com',
    'https://sweet-models-web.vercel.app',
    'http://localhost:3000', // Desarrollo local
  ];

  if (origin && !allowedOrigins.includes(origin)) {
    console.warn(`⚠️ CSRF Alert: Origin rechazado: ${origin}`);
    // Permitir pero loguear para investigación
  }

  // 2️⃣ Verificar User-Agent (Bot Detection)
  const userAgent = request.headers.get('user-agent') || '';
  const suspiciousBots = ['curl', 'wget', 'python', 'sqlmap', 'nikto'];
  const isSuspicious = suspiciousBots.some((bot) => userAgent.toLowerCase().includes(bot));

  if (isSuspicious) {
    console.warn(`⚠️ Security Alert: User-Agent sospechoso detectado: ${userAgent}`);
  }

  // 3️⃣ Inyectar headers de respuesta defensivos
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-XSS-Protection', '1; mode=block');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');

  // ============================================================================
  // 🔐 VALIDACIÓN DE TOKEN JWT (TODO: IMPLEMENTAR VALIDACIÓN COMPLETA)
  // ============================================================================
  if (isProtectedRoute(pathname)) {
    // TODO: Extraer token de cookies/headers
    const token = extractToken(request);

    if (!token) {
      // Redirigir a login si no hay token
      console.warn(`🔐 Token ausente en ruta protegida: ${pathname}`);
      return NextResponse.redirect(new URL('/login', request.url));
    }

    // TODO: Validar JWT signature
    // const isValidToken = await validateJWT(token);
    // if (!isValidToken) {
    //   console.warn(`🔐 Token inválido/expirado en ruta: ${pathname}`);
    //   return NextResponse.redirect(new URL('/login', request.url));
    // }

    // TODO: Verificar permisos según rol
    // const userRole = decodeTokenRole(token);
    // if (!hasPermission(userRole, pathname)) {
    //   return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    // }
  }

  // ============================================================================
  // 📊 LOGGING DE SEGURIDAD
  // ============================================================================
  const method = request.method;
  const timestamp = new Date().toISOString();
  const ip = request.headers.get('x-forwarded-for') || 'unknown';

  console.log(`[${timestamp}] ${method} ${pathname} | IP: ${ip}`);

  return response;
}

/**
 * Verifica si una ruta requiere autenticación
 */
function isProtectedRoute(pathname: string): boolean {
  return PROTECTED_ROUTES.some((route) => pathname.startsWith(route));
}

/**
 * Extrae el token JWT de la request
 * Busca en: Authorization header > cookies
 */
function extractToken(request: NextRequest): string | null {
  // 1️⃣ Buscar en Authorization header (Bearer token)
  const authHeader = request.headers.get('authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7);
  }

  // 2️⃣ Buscar en cookies
  const token = request.cookies.get('access_token')?.value;
  if (token) {
    return token;
  }

  return null;
}

/**
 * Configuración de qué rutas ejecutan el middleware
 */
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
