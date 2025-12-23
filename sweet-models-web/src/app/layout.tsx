/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - ROOT LAYOUT
 * Global styles, fonts, metadata, providers
 * ============================================================================
 */

import type { Metadata } from 'next';
import { Noto_Sans } from 'next/font/google';
import './globals.css';

/**
 * Load Noto Sans font family
 * Supports latin, cyrillic, greek, etc.
 */
const notoSans = Noto_Sans({
  subsets: ['latin', 'latin-ext'],
  weight: ['400', '500', '600', '700', '800'],
  display: 'swap',
  preload: true,
});

/**
 * Metadata for SEO and social media
 */
export const metadata: Metadata = {
  title: {
    default: 'Sweet Models Enterprise',
    template: '%s | Sweet Models Enterprise',
  },
  description:
    'Premium talent management platform for content creators. Secure, scalable, enterprise-grade.',
  keywords: [
    'talent management',
    'content creators',
    'models',
    'enterprise',
    'secure platform',
  ],
  authors: [
    {
      name: 'Sweet Models Team',
      url: 'https://sweet-models-enterprise.com',
    },
  ],
  creator: 'Sweet Models Enterprise',
  publisher: 'Sweet Models Enterprise',
  robots: {
    index: true,
    follow: true,
    'max-image-preview': 'large',
    'max-snippet': -1,
    'max-video-preview': -1,
    googleBot: 'snippet, max-image-preview:large, max-video-preview:-1',
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://sweet-models-enterprise.com',
    siteName: 'Sweet Models Enterprise',
    title: 'Sweet Models Enterprise',
    description: 'Premium talent management platform for content creators',
    images: [
      {
        url: 'https://sweet-models-s3.s3.amazonaws.com/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Sweet Models Enterprise',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@sweetmodels',
    creator: '@sweetmodels',
    title: 'Sweet Models Enterprise',
    description: 'Premium talent management platform',
    images: 'https://sweet-models-s3.s3.amazonaws.com/twitter-image.png',
  },
  manifest: '/manifest.json',
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },
  metadataBase: new URL('https://sweet-models-enterprise.com'),
  alternates: {
    canonical: 'https://sweet-models-enterprise.com',
  },
};

/**
 * Root Layout Component
 * Wraps entire app with global styles and providers
 */
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={notoSans.className}
    >
      <head>
        {/* Preconnect to external resources */}
        <link rel="preconnect" href="https://sweet-models-s3.s3.amazonaws.com" />
        <link rel="preconnect" href="https://sweet-models-enterprise-production.up.railway.app" />
        <link rel="dns-prefetch" href="https://sweet-models-s3.s3.amazonaws.com" />

        {/* Security: Content Security Policy */}
        <meta
          httpEquiv="Content-Security-Policy"
          content="default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://sweet-models-s3.s3.amazonaws.com; font-src 'self' data:;"
        />

        {/* Security: X-UA-Compatible */}
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />

        {/* Viewport */}
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />

        {/* Theme color */}
        <meta name="theme-color" content="#000000" />

        {/* Apple mobile web app */}
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Sweet Models" />
      </head>

      <body className="bg-black text-white antialiased">
        {/* Main content container */}
        <div className="min-h-screen flex flex-col">
          {/* Header/Navigation (future) */}
          <header className="border-b border-gray-800">
            <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
              <div className="flex items-center justify-between">
                <div className="text-xl font-bold bg-gradient-to-r from-pink-500 to-purple-500 bg-clip-text text-transparent">
                  Sweet Models
                </div>
                <div className="text-sm text-gray-400">Enterprise Portal</div>
              </div>
            </nav>
          </header>

          {/* Main content */}
          <main className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-12">
            {children}
          </main>

          {/* Footer */}
          <footer className="border-t border-gray-800 mt-12">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
              <div className="grid grid-cols-4 gap-8 mb-8 text-sm">
                <div>
                  <h3 className="font-semibold text-white mb-4">Product</h3>
                  <ul className="space-y-2 text-gray-400">
                    <li><a href="#" className="hover:text-white transition">Features</a></li>
                    <li><a href="#" className="hover:text-white transition">Pricing</a></li>
                    <li><a href="#" className="hover:text-white transition">Security</a></li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-4">Company</h3>
                  <ul className="space-y-2 text-gray-400">
                    <li><a href="#" className="hover:text-white transition">About</a></li>
                    <li><a href="#" className="hover:text-white transition">Blog</a></li>
                    <li><a href="#" className="hover:text-white transition">Careers</a></li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-4">Legal</h3>
                  <ul className="space-y-2 text-gray-400">
                    <li><a href="#" className="hover:text-white transition">Privacy</a></li>
                    <li><a href="#" className="hover:text-white transition">Terms</a></li>
                    <li><a href="#" className="hover:text-white transition">Cookies</a></li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-4">Connect</h3>
                  <ul className="space-y-2 text-gray-400">
                    <li><a href="#" className="hover:text-white transition">Twitter</a></li>
                    <li><a href="#" className="hover:text-white transition">GitHub</a></li>
                    <li><a href="#" className="hover:text-white transition">LinkedIn</a></li>
                  </ul>
                </div>
              </div>
              <div className="border-t border-gray-800 pt-8 text-center text-sm text-gray-500">
                <p>&copy; 2024 Sweet Models Enterprise. All rights reserved. | Paranoid Mode Security 🔒</p>
              </div>
            </div>
          </footer>
        </div>
      </body>
    </html>
  );
}
