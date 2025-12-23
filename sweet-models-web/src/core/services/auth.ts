/**
 * ============================================================================
 * Authentication Service
 * Handles all API calls to the Rust backend for auth operations
 * ============================================================================
 */

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://sweet-models-enterprise-production.up.railway.app';

/**
 * Login with email and password
 * Returns requiresTwoFA: true if 2FA is enabled
 */
export async function loginWithCredentials(email: string, password: string) {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/login`, {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'X-Requested-With': 'XMLHttpRequest',
  //     },
  //     credentials: 'include',
  //     body: JSON.stringify({ email, password }),
  //   });

  //   if (!response.ok) {
  //     const error = await response.json();
  //     throw new Error(error.message || 'Login failed');
  //   }

  //   return await response.json();
  // } catch (error) {
  //   console.error('Login error:', error);
  //   throw error;
  // }

  // Placeholder
  return {
    success: true,
    requiresTwoFA: true,
    sessionToken: 'temp-session-token',
  };
}

/**
 * Verify 2FA code
 * Returns JWT token if successful
 */
export async function verify2FACode(email: string, code: string, sessionToken: string) {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/verify-2fa`, {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'X-Requested-With': 'XMLHttpRequest',
  //       'Authorization': `Bearer ${sessionToken}`,
  //     },
  //     credentials: 'include',
  //     body: JSON.stringify({ email, code }),
  //   });

  //   if (!response.ok) {
  //     const error = await response.json();
  //     throw new Error(error.message || '2FA verification failed');
  //   }

  //   const data = await response.json();
  //   if (data.token) {
  //     localStorage.setItem('authToken', data.token);
  //   }
  //   return data;
  // } catch (error) {
  //   console.error('2FA verification error:', error);
  //   throw error;
  // }

  // Placeholder
  return {
    success: true,
    token: 'mock-jwt-token-' + Date.now(),
    user: { email },
  };
}

/**
 * Register new user
 */
export async function registerUser(
  email: string,
  password: string,
  confirmPassword: string,
  agreeToTerms: boolean
) {
  // TODO: Uncomment when backend endpoint is ready
  // if (password !== confirmPassword) {
  //   throw new Error('Passwords do not match');
  // }

  // try {
  //   const response = await fetch(`${API_URL}/api/auth/register`, {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'X-Requested-With': 'XMLHttpRequest',
  //     },
  //     credentials: 'include',
  //     body: JSON.stringify({ email, password, agreeToTerms }),
  //   });

  //   if (!response.ok) {
  //     const error = await response.json();
  //     throw new Error(error.message || 'Registration failed');
  //   }

  //   return await response.json();
  // } catch (error) {
  //   console.error('Registration error:', error);
  //   throw error;
  // }

  // Placeholder
  return {
    success: true,
    message: 'Registration successful. Please check your email.',
  };
}

/**
 * Logout current user
 */
export async function logout() {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/logout`, {
  //     method: 'POST',
  //     headers: {
  //       'X-Requested-With': 'XMLHttpRequest',
  //     },
  //     credentials: 'include',
  //   });

  //   if (response.ok) {
  //     localStorage.removeItem('authToken');
  //     return { success: true };
  //   }
  // } catch (error) {
  //   console.error('Logout error:', error);
  // }

  localStorage.removeItem('authToken');
  return { success: true };
}

/**
 * Validate JWT token
 */
export async function validateToken(token: string) {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/validate`, {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': `Bearer ${token}`,
  //     },
  //   });

  //   if (!response.ok) {
  //     return { valid: false };
  //   }

  //   return { valid: true, ...(await response.json()) };
  // } catch (error) {
  //   console.error('Token validation error:', error);
  //   return { valid: false };
  // }

  // Placeholder
  return { valid: true };
}

/**
 * Refresh JWT token
 */
export async function refreshToken() {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/refresh`, {
  //     method: 'POST',
  //     credentials: 'include',
  //   });

  //   if (!response.ok) {
  //     throw new Error('Token refresh failed');
  //   }

  //   const data = await response.json();
  //   if (data.token) {
  //     localStorage.setItem('authToken', data.token);
  //   }
  //   return data;
  // } catch (error) {
  //   console.error('Token refresh error:', error);
  //   throw error;
  // }

  // Placeholder
  return {
    token: 'mock-jwt-token-' + Date.now(),
  };
}

/**
 * Get current user info
 */
export async function getCurrentUser(token: string) {
  // TODO: Uncomment when backend endpoint is ready
  // try {
  //   const response = await fetch(`${API_URL}/api/auth/me`, {
  //     method: 'GET',
  //     headers: {
  //       'Authorization': `Bearer ${token}`,
  //     },
  //   });

  //   if (!response.ok) {
  //     return null;
  //   }

  //   return await response.json();
  // } catch (error) {
  //   console.error('Get user error:', error);
  //   return null;
  // }

  // Placeholder
  return {
    id: 'user-123',
    email: 'user@example.com',
    role: 'admin',
  };
}
