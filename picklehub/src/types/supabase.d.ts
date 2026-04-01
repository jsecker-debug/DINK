import { SupabaseClient, User, AuthResponse as SupabaseAuthResponse } from '@supabase/supabase-js';

declare module '@/lib/supabaseClient' {
  export const supabase: SupabaseClient;
}

declare module '@/hooks/useAuth' {
  import { User } from '@supabase/supabase-js';

  export interface AuthResponse {
    data: {
      user: User | null;
      session: {
        access_token: string;
        refresh_token: string;
        expires_in: number;
        expires_at: number;
        token_type: string;
      } | null;
    } | null;
    error: Error | null;
  }

  export interface UseAuth {
    user: User | null;
    loading: boolean;
    signIn: (email: string, password: string) => Promise<AuthResponse>;
    signUp: (email: string, password: string) => Promise<AuthResponse>;
    signOut: () => Promise<{ error: Error | null }>;
  }

  export function useAuth(): UseAuth;
} 