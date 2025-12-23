/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true, // Esto acelera la carga
  poweredByHeader: false,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'sweet-models-s3.s3.amazonaws.com',
      },
    ],
  },
  async headers() {
    // Si estamos en desarrollo (tu PC), relajamos la seguridad.
    // Si estamos en producción (Railway), la activamos a tope.
    const isDev = process.env.NODE_ENV === 'development';

    const cspScriptSrc = isDev
      ? "'self' 'unsafe-eval' 'unsafe-inline'"
      : "'self'";

    const cspHeader = `default-src 'self'; script-src ${cspScriptSrc}; style-src 'self' 'unsafe-inline'; img-src 'self' blob: data: https://sweet-models-s3.s3.amazonaws.com; font-src 'self'; connect-src 'self' https://sweet-models-enterprise-production.up.railway.app ws://localhost:*;`;

    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Content-Security-Policy', value: cspHeader },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
    ];
  },
};

export default nextConfig;