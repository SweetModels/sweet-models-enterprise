/**
 * Authentication Service (frontend)
 * Connects Next.js client with Rust backend.
 */

export interface LoginSuccess {
  token: string;
  requiresTwoFA?: boolean;
}

export async function login(email: string, password: string): Promise<LoginSuccess> {
  const baseUrl = process.env.NEXT_PUBLIC_API_URL;
  if (!baseUrl) {
    throw new Error('NEXT_PUBLIC_API_URL no está configurada');
  }

  const url = `${baseUrl}/auth/login`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      let errorMessage = 'Error al iniciar sesión';
      if (response.status === 401) {
        errorMessage = 'Credenciales inválidas';
      } else if (response.status >= 500) {
        errorMessage = 'Servidor no disponible';
      }

      try {
        const errorBody = await response.json();
        if (errorBody?.message) {
          errorMessage = errorBody.message;
        }
      } catch (err) {
        // ignore json parse
      }

      throw new Error(errorMessage);
    }

    const data = (await response.json()) as { token?: string; requiresTwoFA?: boolean };

    if (!data?.token) {
      throw new Error('Respuesta sin token. Verifique el backend.');
    }

    return { token: data.token, requiresTwoFA: data.requiresTwoFA };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error desconocido al iniciar sesión';
    throw new Error(message);
  }
}
