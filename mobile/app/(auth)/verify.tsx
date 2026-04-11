import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

export default function VerifyScreen() {
  const { email } = useLocalSearchParams<{ email: string }>();
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const router = useRouter();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  async function verify() {
    const otp = code.trim();
    if (otp.length < 6) {
      Alert.alert('Código incompleto', 'Ingresa el código que llegó al correo');
      return;
    }
    setLoading(true);
    const { error } = await supabase.auth.verifyOtp({
      email: email as string,
      token: otp,
      type: 'signup',
    });
    setLoading(false);
    if (error) {
      Alert.alert('Código incorrecto', 'El código no es válido o ya expiró. Solicita uno nuevo.');
      setCode('');
    }
    // On success → onAuthStateChange in AuthContext handles routing automatically
  }

  async function resend() {
    setResending(true);
    const { error } = await supabase.auth.resend({ type: 'signup', email: email as string });
    setResending(false);
    if (error) {
      Alert.alert('Error', error.message);
    } else {
      Alert.alert('Código reenviado', `Revisa ${email}`);
      setCode('');
    }
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.container, { backgroundColor: theme.background }]}
    >
      <View style={styles.content}>
        <MaterialCommunityIcons name="email-check-outline" size={64} color={theme.lilacDark} style={{ marginBottom: 16 }} />

        <Text style={[styles.title, { color: theme.lilacDark }]}>Verifica tu correo</Text>
        <Text style={[styles.subtitle, { color: theme.icon }]}>
          Enviamos un código de verificación a{'\n'}
          <Text style={{ fontWeight: '700', color: theme.text }}>{email}</Text>
        </Text>

        <TextInput
          style={[styles.codeInput, { borderColor: code ? theme.lilacDark : theme.lilacMedium, color: theme.text }]}
          value={code}
          onChangeText={t => setCode(t.replace(/[^0-9]/g, ''))}
          keyboardType="number-pad"
          maxLength={10}
          textAlign="center"
          autoFocus
          placeholder="Ingresa el código"
          placeholderTextColor={theme.icon}
        />

        <TouchableOpacity
          style={[styles.button, { backgroundColor: theme.yellow }]}
          onPress={verify}
          disabled={loading}
        >
          {loading
            ? <ActivityIndicator color="#1A1A1A" />
            : <Text style={styles.buttonText}>Confirmar cuenta</Text>
          }
        </TouchableOpacity>

        <TouchableOpacity style={styles.resendBtn} onPress={resend} disabled={resending}>
          {resending
            ? <ActivityIndicator size="small" color={theme.lilacDark} />
            : <Text style={[styles.resendText, { color: theme.icon }]}>
                ¿No llegó? <Text style={{ color: theme.lilacDark, fontWeight: '700' }}>Reenviar código</Text>
              </Text>
          }
        </TouchableOpacity>

        <TouchableOpacity onPress={() => router.replace('/(auth)/login')} style={{ marginTop: 8 }}>
          <Text style={[styles.resendText, { color: theme.icon }]}>Volver al inicio de sesión</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { flex: 1, padding: 32, justifyContent: 'center', alignItems: 'center' },
  title: { fontSize: 24, fontWeight: '800', textAlign: 'center', marginBottom: 10 },
  subtitle: { fontSize: 14, textAlign: 'center', lineHeight: 22, marginBottom: 36 },
  codeInput: {
    width: '100%',
    height: 64,
    borderWidth: 2,
    borderRadius: 16,
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 32,
    paddingHorizontal: 16,
  },
  button: {
    width: '100%',
    height: 56,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 4,
  },
  buttonText: { fontSize: 17, fontWeight: '800', color: '#1A1A1A' },
  resendBtn: { marginTop: 20, alignItems: 'center' },
  resendText: { fontSize: 14 },
});
