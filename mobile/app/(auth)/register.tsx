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
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

export default function RegisterScreen() {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  async function signUp() {
    if (!fullName.trim() || !email || !password || !confirmPassword) {
      Alert.alert('Error', 'Por favor llena todos los campos');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('Error', 'Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      Alert.alert('Error', 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setLoading(true);
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: fullName.trim() },
      },
    });

    if (error) {
      // "User already registered" → direct to login
      if (error.message.toLowerCase().includes('already registered') ||
          error.message.toLowerCase().includes('already been registered')) {
        Alert.alert(
          'Correo ya registrado',
          'Este correo ya tiene una cuenta. Inicia sesión o usa "Olvidé mi contraseña".',
          [{ text: 'Ir a Login', onPress: () => router.replace('/(auth)/login') }]
        );
      } else {
        Alert.alert('Error de Registro', error.message);
      }
    } else if (data.session) {
      // Email confirmation disabled → go directly to onboarding
      router.replace('/(onboarding)');
    } else if (data.user && !data.session) {
      // Confirmation email sent → OTP screen
      router.push({ pathname: '/(auth)/verify', params: { email } });
    }
    setLoading(false);
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.container, { backgroundColor: theme.background }]}
    >
      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <MaterialCommunityIcons name="arrow-left" size={28} color={theme.lilacDark} />
        </TouchableOpacity>

        <View style={styles.header}>
          <MaterialCommunityIcons name="star-circle" size={48} color={theme.lilacDark} style={{ marginBottom: 10 }} />
          <Text style={[styles.title, { color: theme.lilacDark }]}>¡Crea tu cuenta!</Text>
          <Text style={[styles.subtitle, { color: theme.icon }]}>
            Solo necesitamos lo básico para comenzar
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Tu nombre completo</Text>
            <TextInput
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text }]}
              placeholder="Ej. María García"
              placeholderTextColor={theme.icon}
              autoCapitalize="words"
              value={fullName}
              onChangeText={setFullName}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Correo electrónico</Text>
            <TextInput
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text }]}
              placeholder="ej. maria@gmail.com"
              placeholderTextColor={theme.icon}
              autoCapitalize="none"
              keyboardType="email-address"
              value={email}
              onChangeText={setEmail}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Contraseña</Text>
            <TextInput
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text }]}
              placeholder="Mínimo 6 caracteres"
              placeholderTextColor={theme.icon}
              secureTextEntry
              value={password}
              onChangeText={setPassword}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Confirmar contraseña</Text>
            <TextInput
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text }]}
              placeholder="Repite tu contraseña"
              placeholderTextColor={theme.icon}
              secureTextEntry
              value={confirmPassword}
              onChangeText={setConfirmPassword}
            />
          </View>

          <TouchableOpacity
            style={[styles.button, { backgroundColor: theme.yellow }]}
            onPress={signUp}
            disabled={loading}
          >
            <Text style={styles.buttonText}>
              {loading ? 'Creando cuenta...' : 'Crear mi cuenta'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.loginLink}
            onPress={() => router.replace('/(auth)/login')}
          >
            <Text style={[styles.loginText, { color: theme.icon }]}>
              ¿Ya tienes cuenta?{' '}
              <Text style={{ color: theme.lilacDark, fontWeight: 'bold' }}>Inicia sesión</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scrollContent: { flexGrow: 1, padding: 28, paddingTop: 60 },
  backButton: { marginBottom: 20, alignSelf: 'flex-start' },
  header: { alignItems: 'center', marginBottom: 36 },

  title: { fontSize: 26, fontWeight: 'bold', textAlign: 'center' },
  subtitle: { fontSize: 14, marginTop: 8, textAlign: 'center' },
  form: { gap: 18 },
  inputGroup: { gap: 6 },
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
    marginTop: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 3,
  },
  buttonText: { color: '#1A1A1A', fontSize: 17, fontWeight: 'bold' },
  loginLink: { alignItems: 'center', marginTop: 8 },
  loginText: { fontSize: 14 },
});
