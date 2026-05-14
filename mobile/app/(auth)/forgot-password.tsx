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
import { useRouter } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

export default function ForgotPasswordScreen() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const router = useRouter();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  async function sendReset() {
    if (!email || !/\S+@\S+\.\S+/.test(email)) {
      Alert.alert('Error', 'Ingresa un correo electrónico válido');
      return;
    }
    setLoading(true);
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    setLoading(false);
    if (error) {
      Alert.alert('Error', 'No se pudo enviar el enlace. Intenta de nuevo.');
    } else {
      setSent(true);
    }
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.container, { backgroundColor: theme.lilacPale }]}
    >
      <View style={styles.content}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <MaterialCommunityIcons name="arrow-left" size={28} color={theme.lilacDark} />
        </TouchableOpacity>

        <View style={styles.header}>
          <MaterialCommunityIcons name="lock-reset" size={56} color={theme.lilacDark} style={{ marginBottom: 12 }} />
          <Text style={[styles.title, { color: theme.lilacDark }]}>Recuperar contraseña</Text>
          <Text style={[styles.subtitle, { color: theme.icon }]}>
            Ingresa tu correo y te enviaremos{'\n'}un enlace para recuperar el acceso
          </Text>
        </View>

        {sent ? (
          <View style={[styles.sentCard, { backgroundColor: theme.background, borderColor: theme.lilacMedium }]}>
            <MaterialCommunityIcons name="email-check-outline" size={40} color={theme.green} style={{ marginBottom: 12 }} />
            <Text style={[styles.sentTitle, { color: theme.text }]}>¡Enlace enviado!</Text>
            <Text style={[styles.sentSubtitle, { color: theme.icon }]}>
              Revisa tu correo (también la carpeta de spam).
            </Text>
          </View>
        ) : (
          <View style={styles.form}>
            <View style={styles.inputGroup}>
              <Text style={[styles.label, { color: theme.text }]}>Correo electrónico</Text>
              <TextInput
                style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text, backgroundColor: theme.background }]}
                placeholder="correo@ejemplo.com"
                placeholderTextColor={theme.icon}
                autoCapitalize="none"
                keyboardType="email-address"
                value={email}
                onChangeText={setEmail}
              />
            </View>

            <TouchableOpacity
              style={[styles.button, { backgroundColor: theme.yellow }]}
              onPress={sendReset}
              disabled={loading}
            >
              {loading
                ? <ActivityIndicator color="#1A1A1A" />
                : <Text style={styles.buttonText}>Enviar enlace</Text>
              }
            </TouchableOpacity>
          </View>
        )}

        <TouchableOpacity style={styles.backLink} onPress={() => router.replace('/(auth)/login')}>
          <Text style={[styles.backLinkText, { color: theme.icon }]}>
            ← Volver al inicio de sesión
          </Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { flex: 1, padding: 28, paddingTop: 60 },
  backButton: { marginBottom: 20, alignSelf: 'flex-start' },
  header: { alignItems: 'center', marginBottom: 36 },
  title: { fontSize: 24, fontWeight: '800', textAlign: 'center', marginBottom: 10 },
  subtitle: { fontSize: 14, textAlign: 'center', lineHeight: 22 },
  form: { gap: 20 },
  inputGroup: { gap: 8 },
  label: { fontSize: 14, fontWeight: '600' },
  input: {
    height: 52,
    borderWidth: 2,
    borderRadius: 14,
    paddingHorizontal: 16,
    fontSize: 16,
  },
  button: {
    height: 56,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 3,
  },
  buttonText: { color: '#1A1A1A', fontSize: 17, fontWeight: 'bold' },
  sentCard: {
    borderWidth: 2,
    borderRadius: 16,
    padding: 28,
    alignItems: 'center',
  },
  sentTitle: { fontSize: 18, fontWeight: '700', marginBottom: 8 },
  sentSubtitle: { fontSize: 14, textAlign: 'center', lineHeight: 20 },
  backLink: { marginTop: 32, alignItems: 'center' },
  backLinkText: { fontSize: 14 },
});
