/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - LOGIN PAGE
 * Dark Mode Enterprise | Glassmorphism | Professional UI
 * ============================================================================
 */

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Lock, Eye, EyeOff, AlertCircle, CheckCircle } from 'lucide-react';
import { login } from '@/core/services/auth.service';

// Note: Metadata must be exported from server component
// This is a client component for interactivity
// Metadata is handled in layout.tsx

/**
 * LoginPage Component
 * Features:
 * - Glassmorphism design
 * - Animated inputs with icons
 * - 2FA code input ready
 * - Error/success feedback
 * - Dark mode enterprise aesthetic
 */
export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [twoFACode, setTwoFACode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [show2FA, setShow2FA] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [step, setStep] = useState<'credentials' | '2fa'>('credentials');

  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(e.target.value);
    setError(null);
  };

  const handlePasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(e.target.value);
    setError(null);
  };

  const handleTwoFAChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, 6);
    setTwoFACode(value);
    setError(null);
  };

  const handleSubmitCredentials = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    if (!email || !password) {
      setError('Por favor completa todos los campos');
      setIsLoading(false);
      return;
    }

    try {
      const result = await login(email, password);

      // Guardar token temporalmente
      if (result.token) {
        localStorage.setItem('authToken', result.token);
        console.log('Token recibido:', result.token);
      }

      setSuccess(true);
      setIsLoading(false);
      router.push('/panel');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al iniciar sesión';
      setError(message);
      setIsLoading(false);
    }
  };

  const handleSubmit2FA = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // TODO: Validar 2FA con backend
    // const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/verify-2fa`, {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ email, twoFACode }),
    // });

    // Simulación
    setTimeout(() => {
      if (twoFACode.length === 6) {
        setSuccess(true);
        setIsLoading(false);
        // Redirigir al dashboard
        // router.push('/dashboard/panel');
      } else {
        setError('Código 2FA inválido (debe tener 6 dígitos)');
        setIsLoading(false);
      }
    }, 1000);
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center p-4">
        <div className="w-full max-w-md">
          <div className="text-center space-y-6 animate-fade-in">
            <div className="flex justify-center">
              <div className="p-4 bg-green-900/20 border border-green-700/50 rounded-full">
                <CheckCircle className="w-12 h-12 text-green-400" />
              </div>
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white mb-2">¡Bienvenido!</h2>
              <p className="text-gray-400">Tu sesión se ha iniciado correctamente. Redirigiendo...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center p-4 relative overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-600/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-pink-600/10 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>

      {/* Main Container */}
      <div className="w-full max-w-md relative z-10">
        {/* Glassmorphism Card */}
        <div className="backdrop-blur-xl bg-gray-900/40 border border-gray-800/50 rounded-2xl shadow-2xl p-8 space-y-8 animate-fade-in">
          {/* Logo Section */}
          <div className="text-center space-y-3">
            <div className="flex justify-center mb-4">
              <div className="p-3 bg-gradient-to-r from-pink-500/20 to-purple-500/20 rounded-lg border border-pink-500/30">
                <div className="w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-500 rounded-lg"></div>
              </div>
            </div>
            <h1 className="text-3xl font-bold text-white">Sweet Models</h1>
            <p className="text-gray-400 text-sm">Enterprise Secure Portal</p>
          </div>

          {/* Form Steps */}
          {step === 'credentials' ? (
            <form onSubmit={handleSubmitCredentials} className="space-y-5">
              {/* Email Input */}
              <div className="relative group">
                <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                  Email Corporativo
                </label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500 pointer-events-none" />
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={handleEmailChange}
                    placeholder="tu@empresa.com"
                    required
                    className="w-full pl-12 pr-4 py-3 bg-gray-800/50 border border-gray-700/50 rounded-lg focus:outline-none focus:border-pink-500/50 focus:bg-gray-800 transition duration-300 text-white placeholder-gray-500 backdrop-blur-sm"
                  />
                </div>
              </div>

              {/* Password Input */}
              <div className="relative group">
                <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-2">
                  Contraseña Segura
                </label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500 pointer-events-none" />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={handlePasswordChange}
                    placeholder="••••••••"
                    required
                    className="w-full pl-12 pr-12 py-3 bg-gray-800/50 border border-gray-700/50 rounded-lg focus:outline-none focus:border-pink-500/50 focus:bg-gray-800 transition duration-300 text-white placeholder-gray-500 backdrop-blur-sm"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-400 transition"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Remember Me & Forgot Password */}
              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="w-4 h-4 rounded bg-gray-700 border border-gray-600 cursor-pointer accent-pink-500"
                  />
                  <span className="text-gray-400 hover:text-gray-300 transition">Recuérdame</span>
                </label>
                <a
                  href="/forgot-password"
                  className="text-pink-500 hover:text-pink-400 transition font-medium"
                >
                  ¿Olvidaste tu contraseña?
                </a>
              </div>

              {/* Error Message */}
              {error && (
                <div className="flex items-center gap-3 p-4 bg-red-900/20 border border-red-700/50 rounded-lg animate-slide-in">
                  <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                  <p className="text-sm text-red-300">{error}</p>
                </div>
              )}

              {/* Submit Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-semibold text-white shadow-lg hover:shadow-purple-500/50 transition duration-300 flex items-center justify-center gap-2"
              >
                {isLoading ? (
                  <>
                    <div className="w-5 h-5 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                    Validando...
                  </>
                ) : (
                  'Acceder a Panel Seguro'
                )}
              </button>
            </form>
          ) : (
            <form onSubmit={handleSubmit2FA} className="space-y-5">
              <div className="text-center space-y-2 mb-6">
                <h2 className="text-xl font-bold text-white">Verificación de Dos Factores</h2>
                <p className="text-gray-400 text-sm">Ingresa el código de 6 dígitos de tu aplicación autenticadora</p>
              </div>

              {/* 2FA Code Input */}
              <div className="relative group">
                <label htmlFor="2fa" className="block text-sm font-medium text-gray-300 mb-2">
                  Código 2FA
                </label>
                <input
                  id="2fa"
                  type="text"
                  value={twoFACode}
                  onChange={handleTwoFAChange}
                  placeholder="000000"
                  inputMode="numeric"
                  maxLength={6}
                  required
                  className="w-full px-4 py-3 bg-gray-800/50 border border-gray-700/50 rounded-lg focus:outline-none focus:border-pink-500/50 focus:bg-gray-800 transition duration-300 text-white placeholder-gray-500 backdrop-blur-sm text-center text-2xl tracking-widest font-mono"
                />
              </div>

              {/* Error Message */}
              {error && (
                <div className="flex items-center gap-3 p-4 bg-red-900/20 border border-red-700/50 rounded-lg animate-slide-in">
                  <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0" />
                  <p className="text-sm text-red-300">{error}</p>
                </div>
              )}

              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setStep('credentials');
                    setTwoFACode('');
                    setError(null);
                  }}
                  className="flex-1 py-3 bg-gray-800/50 hover:bg-gray-800 border border-gray-700/50 rounded-lg font-semibold text-white transition duration-300"
                >
                  Volver
                </button>
                <button
                  type="submit"
                  disabled={isLoading || twoFACode.length !== 6}
                  className="flex-1 py-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-semibold text-white shadow-lg hover:shadow-purple-500/50 transition duration-300"
                >
                  {isLoading ? 'Verificando...' : 'Verificar'}
                </button>
              </div>
            </form>
          )}

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-700/50"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-gray-900/40 text-gray-500">¿Necesitas ayuda?</span>
            </div>
          </div>

          {/* Footer Links */}
          <div className="space-y-3 text-center text-sm text-gray-400">
            {step === 'credentials' && (
              <p>
                ¿No tienes cuenta?{' '}
                <a href="/register" className="text-pink-500 hover:text-pink-400 transition font-semibold">
                  Crear una
                </a>
              </p>
            )}
            <div className="flex items-center justify-center gap-4 pt-2 border-t border-gray-700/50">
              <a href="#" className="hover:text-gray-300 transition">
                Soporte
              </a>
              <span className="text-gray-700">•</span>
              <a href="#" className="hover:text-gray-300 transition">
                Privacidad
              </a>
              <span className="text-gray-700">•</span>
              <a href="#" className="hover:text-gray-300 transition">
                Términos
              </a>
            </div>
          </div>
        </div>

        {/* Security Badge */}
        <div className="mt-6 text-center text-xs text-gray-500 flex items-center justify-center gap-2">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span>Conexión segura | Paranoid Mode Enabled 🔒</span>
        </div>
      </div>
    </div>
  );
}
