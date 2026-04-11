import React, { createContext, useContext, useEffect, useState } from 'react';
import { Session, User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

type AuthContextType = {
  session: Session | null;
  user: User | null;
  isLoading: boolean;
  hasProfile: boolean;
  refreshProfile: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType>({
  session: null,
  user: null,
  isLoading: true,
  hasProfile: false,
  refreshProfile: async () => {},
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasProfile, setHasProfile] = useState(false);

  async function checkProfile(uid: string) {
    const { data } = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_uid', uid)
      .maybeSingle();
    setHasProfile(!!data);
  }

  async function refreshProfile() {
    if (user) await checkProfile(user.id);
  }

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        await checkProfile(session.user.id);
      }
      setIsLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      // TOKEN_REFRESHED is a silent background operation — ignore it completely.
      // getSession() already handles startup correctly.
      if (event === 'TOKEN_REFRESHED') return;

      // Set isLoading=true BEFORE updating session/user state.
      // This prevents the router from seeing session=user + hasProfile=false
      // (which would flash the onboarding screen) while checkProfile is pending.
      setIsLoading(true);
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        await checkProfile(session.user.id);
      } else {
        setHasProfile(false);
      }
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ session, user, isLoading, hasProfile, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
