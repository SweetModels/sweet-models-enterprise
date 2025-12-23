/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - HOME PAGE
 * Landing page / Portal entry point
 * ============================================================================
 */

export default function Home() {
  return (
    <div className="space-y-12">
      {/* Hero Section */}
      <section className="text-center space-y-6">
        <h1 className="text-5xl md:text-7xl font-bold bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500 bg-clip-text text-transparent leading-tight">
          Welcome to Sweet Models Enterprise
        </h1>
        <p className="text-xl text-gray-400 max-w-2xl mx-auto">
          Premium talent management platform. Secure, scalable, and built for the modern creator economy.
        </p>
        <div className="flex gap-4 justify-center pt-6">
          <a
            href="/login"
            className="px-8 py-3 bg-gradient-to-r from-pink-500 to-purple-500 rounded-lg font-semibold hover:shadow-lg hover:shadow-pink-500/50 transition"
          >
            Sign In
          </a>
          <a
            href="/register"
            className="px-8 py-3 border border-gray-600 rounded-lg font-semibold hover:border-gray-400 transition"
          >
            Create Account
          </a>
        </div>
      </section>

      {/* Features Grid */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-8 py-12">
        <div className="p-6 border border-gray-800 rounded-lg hover:border-gray-700 transition">
          <div className="text-3xl mb-4">🔒</div>
          <h3 className="text-lg font-semibold mb-2">Paranoid Mode Security</h3>
          <p className="text-gray-400">
            Military-grade encryption, zero-trust architecture, and continuous security monitoring.
          </p>
        </div>
        <div className="p-6 border border-gray-800 rounded-lg hover:border-gray-700 transition">
          <div className="text-3xl mb-4">⚡</div>
          <h3 className="text-lg font-semibold mb-2">Lightning Fast</h3>
          <p className="text-gray-400">
            Built on Rust and Next.js. Sub-100ms API responses. Optimized for scale.
          </p>
        </div>
        <div className="p-6 border border-gray-800 rounded-lg hover:border-gray-700 transition">
          <div className="text-3xl mb-4">📊</div>
          <h3 className="text-lg font-semibold mb-2">Real-Time Analytics</h3>
          <p className="text-gray-400">
            Monitor performance, earnings, and engagement in real-time with comprehensive dashboards.
          </p>
        </div>
      </section>

      {/* Status Indicator */}
      <section className="p-6 bg-gradient-to-r from-gray-900/50 to-gray-800/50 border border-gray-800 rounded-lg">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-semibold text-lg mb-1">System Status</h3>
            <p className="text-gray-400">All systems operational. Last check: just now</p>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
            <span className="text-green-400 font-semibold">Operational</span>
          </div>
        </div>
      </section>
    </div>
  );
}
