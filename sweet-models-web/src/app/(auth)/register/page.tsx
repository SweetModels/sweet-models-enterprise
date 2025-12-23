/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - REGISTER PAGE
 * Dark Mode Enterprise | Glassmorphism | Professional UI
 * ============================================================================
 */

'use client';

import { useState } from 'react';
import { Mail, Lock, CheckCircle2, Eye, EyeOff, AlertCircle } from 'lucide-react';

/**
 * RegisterPage Component
 * Features:
 * - Glassmorphism design matching login page
 * - Real-time password strength indicator
 * - Terms agreement checkbox
 * - Error/success feedback
 * - Animated inputs with icons
 */
export default function RegisterPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [agreeToTerms, setAgreeToTerms] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const getPasswordStrength = () => {
    if (!password) return { level: 0, label: '', color: '' };
    let strength = 0;
    const checks = [
      password.length >= 8,
      /[A-Z]/.test(password),
      /[0-9]/.test(password),
      /[^A-Za-z0-9]/.test(password),
    ];
    strength = checks.filter(Boolean).length;

    const levels = [
      { level: 0, label: '', color: '' },
      { level: 1, label: 'Débil', color: 'bg-red-500' },
      { level: 2, label: 'Media', color: 'bg-yellow-500' },
      { level: 3, label: 'Fuerte', color: 'bg-blue-500' },
      { level: 4, label: 'Muy Fuerte', color: 'bg-green-500' },
    ];
    return levels[strength];
  };

  const passwordStrength = getPasswordStrength();
  const isPasswordValid = password.length >= 8;
  const passwordsMatch = password === confirmPassword && password.length > 0;

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // Validation
    if (!email || !password || !confirmPassword) {
      setError('Por favor completa todos los campos');
      setIsLoading(false);
      return;
    }

    if (!isPasswordValid) {
      setError('La contraseña debe tener al menos 8 caracteres');
      setIsLoading(false);
      return;
    }

    if (!passwordsMatch) {
      setError('Las contraseñas no coinciden');
      setIsLoading(false);
      return;
    }

    if (!agreeToTerms) {
      setError('Debes aceptar los términos de servicio');
      setIsLoading(false);
      return;
    }

    // TODO: Integrar con API de Rust
    // try {
    //   const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/register`, {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify({ email, password, agreeToTerms }),
    //   });
    //   const data = await response.json();
    // }

    // Simulación
    setTimeout(() => {
      setSuccess(true);
      setIsLoading(false);
    }, 1500);
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950 flex items-center justify-center p-4">
        <div className="w-full max-w-md">
          <div className="text-center space-y-6 animate-fade-in">
            <div className="flex justify-center">
              <div className="p-4 bg-green-900/20 border border-green-700/50 rounded-full">
                <CheckCircle2 className="w-12 h-12 text-green-400" />
              </div>
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white mb-2">¡Cuenta Creada!</h2>
              <p className="text-gray-400 mb-6">
                Hemos enviado un email de confirmación a <br />
                <span className="text-pink-400 font-semibold">{email}</span>
              </p>
              <a
                href="/login"
                className="inline-block px-6 py-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 rounded-lg font-semibold text-white transition"
              >
                Ir a Iniciar Sesión
              </a>
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
        <div className="backdrop-blur-xl bg-gray-900/40 border border-gray-800/50 rounded-2xl shadow-2xl p-8 space-y-6 animate-fade-in">
          {/* Logo Section */}
          <div className="text-center space-y-3">
            <div className="flex justify-center mb-4">
              <div className="p-3 bg-gradient-to-r from-pink-500/20 to-purple-500/20 rounded-lg border border-pink-500/30">
                <div className="w-8 h-8 bg-gradient-to-r from-pink-500 to-purple-500 rounded-lg"></div>
              </div>
            </div>
            <h1 className="text-3xl font-bold text-white">Sweet Models</h1>
            <p className="text-gray-400 text-sm">Crear Nueva Cuenta</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
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
                  onChange={(e) => {
                    setEmail(e.target.value);
                    setError(null);
                  }}
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
                  onChange={(e) => {
                    setPassword(e.target.value);
                    setError(null);
                  }}
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

              {/* Password Strength Indicator */}
              {password && (
                <div className="mt-2 space-y-2">
                  <div className="h-1 bg-gray-700 rounded-full overflow-hidden">
                    <div
                      className={`h-full transition-all duration-300 ${passwordStrength.color}`}
                      style={{ width: `${(passwordStrength.level / 4) * 100}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-gray-400">
                    Fortaleza: <span className={`font-semibold ${passwordStrength.color.replace('bg-', 'text-')}`}>{passwordStrength.label}</span>
                  </p>
                </div>
              )}
            </div>

            {/* Confirm Password Input */}
            <div className="relative group">
              <label htmlFor="confirm" className="block text-sm font-medium text-gray-300 mb-2">
                Confirmar Contraseña
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500 pointer-events-none" />
                <input
                  id="confirm"
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => {
                    setConfirmPassword(e.target.value);
                    setError(null);
                  }}
                  placeholder="••••••••"
                  required
                  className="w-full pl-12 pr-12 py-3 bg-gray-800/50 border border-gray-700/50 rounded-lg focus:outline-none focus:border-pink-500/50 focus:bg-gray-800 transition duration-300 text-white placeholder-gray-500 backdrop-blur-sm"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-400 transition"
                >
                  {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {confirmPassword && passwordsMatch && (
                <p className="text-xs text-green-400 mt-2">✓ Las contraseñas coinciden</p>
              )}
            </div>

            {/* Terms Checkbox */}
            <label className="flex items-start gap-3 cursor-pointer p-3 rounded-lg hover:bg-gray-800/30 transition">
              <input
                type="checkbox"
                checked={agreeToTerms}
                onChange={(e) => {
                  setAgreeToTerms(e.target.checked);
                  setError(null);
                }}
                className="w-4 h-4 rounded mt-0.5 bg-gray-700 border border-gray-600 cursor-pointer accent-pink-500"
              />
              <span className="text-sm text-gray-400">
                Acepto los{' '}
                <a href="/terms" className="text-pink-500 hover:text-pink-400 transition font-semibold">
                  Términos de Servicio
                </a>{' '}
                y la{' '}
                <a href="/privacy" className="text-pink-500 hover:text-pink-400 transition font-semibold">
                  Política de Privacidad
                </a>
              </span>
            </label>

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
              disabled={isLoading || !agreeToTerms}
              className="w-full py-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-semibold text-white shadow-lg hover:shadow-purple-500/50 transition duration-300 flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <div className="w-5 h-5 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                  Creando cuenta...
                </>
              ) : (
                'Crear Cuenta Segura'
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-700/50"></div>
            </div>
          </div>

          {/* Footer Links */}
          <div className="space-y-3 text-center text-sm text-gray-400">
            <p>
              ¿Ya tienes cuenta?{' '}
              <a href="/login" className="text-pink-500 hover:text-pink-400 transition font-semibold">
                Inicia sesión
              </a>
            </p>
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
          <span>Conexión segura | Enterprise Grade 🔒</span>
        </div>
      </div>
    </div>
  );
}
