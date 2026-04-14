import { useEffect, useState } from 'react';
import { View, Text, ActivityIndicator, StyleSheet } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { supabase } from '@/lib/supabase';

const PURPLE = '#1B4FA8';
const BG = '#EFF6FF';

export default function AuthCallback() {
  const router = useRouter();
  const { code } = useLocalSearchParams<{ code: string }>();
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!code) {
      router.replace('/(auth)/login');
      return;
    }
    supabase.auth.exchangeCodeForSession(code as string).then(({ error }) => {
      if (error) {
        setError(true);
        setTimeout(() => router.replace('/(auth)/login'), 2500);
      }
      // Success → onAuthStateChange in AuthContext handles routing automatically
    });
  }, [code]);

  return (
    <View style={styles.container}>
      {error ? (
        <Text style={styles.errorText}>
          El enlace expiró o ya fue usado.{'\n'}Redirigiendo al inicio de sesión...
        </Text>
      ) : (
        <>
          <ActivityIndicator size="large" color={PURPLE} />
          <Text style={styles.text}>Verificando tu correo...</Text>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: BG, gap: 16 },
  text: { fontSize: 16, color: PURPLE, fontWeight: '600' },
  errorText: { fontSize: 15, color: '#EF4444', textAlign: 'center', paddingHorizontal: 32, lineHeight: 24 },
});
