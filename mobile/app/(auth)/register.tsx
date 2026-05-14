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
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
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
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { full_name: fullName.trim() } },
      });

      if (error) {
        if (
          error.message.toLowerCase().includes('already registered') ||
          error.message.toLowerCase().includes('already been registered')
        ) {
          Alert.alert(
            'Correo ya registrado',
            'Este correo ya tiene una cuenta. Inicia sesión o usa "Olvidé mi contraseña".',
            [{ text: 'Ir a Login', onPress: () => router.replace('/(auth)/login') }]
          );
        } else {
          Alert.alert('Error', 'No se pudo crear la cuenta. Intenta de nuevo.');
        }
      } else if (data.session) {
        router.replace('/(onboarding)');
      } else if (data.user && !data.session) {
        router.push({ pathname: '/(auth)/verify', params: { email } });
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={[styles.container, { backgroundColor: theme.lilacPale }]}
    >
      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <MaterialCommunityIcons name="arrow-left" size={28} color={theme.lilacDark} />
        </TouchableOpacity>

        <View style={styles.header}>
          <View style={[styles.logoCircle, { backgroundColor: theme.lilacDark }]}>
            <Text style={styles.logoText}>P</Text>
          </View>
          <Text style={[styles.title, { color: theme.lilacDark }]}>¡Crea tu cuenta!</Text>
          <Text style={[styles.subtitle, { color: theme.icon }]}>
            Solo necesitamos lo básico para comenzar
          </Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Tu nombre completo</Text>
            <TextInput
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text, backgroundColor: theme.background }]}
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
              style={[styles.input, { borderColor: theme.lilacMedium, color: theme.text, backgroundColor: theme.background }]}
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
            <View style={[styles.passwordContainer, { borderColor: theme.lilacMedium, backgroundColor: theme.background }]}>
              <TextInput
                style={[styles.passwordInput, { color: theme.text }]}
                placeholder="Mínimo 6 caracteres"
                placeholderTextColor={theme.icon}
                secureTextEntry={!showPassword}
                value={password}
                onChangeText={setPassword}
              />
              <TouchableOpacity onPress={() => setShowPassword(s => !s)} style={styles.eyeBtn}>
                <MaterialCommunityIcons
                  name={showPassword ? 'eye-off-outline' : 'eye-outline'}
                  size={22}
                  color={theme.icon}
                />
              </TouchableOpacity>
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={[styles.label, { color: theme.text }]}>Confirmar contraseña</Text>
            <View style={[styles.passwordContainer, { borderColor: theme.lilacMedium, backgroundColor: theme.background }]}>
              <TextInput
                style={[styles.passwordInput, { color: theme.text }]}
                placeholder="Repite tu contraseña"
                placeholderTextColor={theme.icon}
                secureTextEntry={!showConfirm}
                value={confirmPassword}
                onChangeText={setConfirmPassword}
              />
              <TouchableOpacity onPress={() => setShowConfirm(s => !s)} style={styles.eyeBtn}>
                <MaterialCommunityIcons
                  name={showConfirm ? 'eye-off-outline' : 'eye-outline'}
                  size={22}
                  color={theme.icon}
                />
              </TouchableOpacity>
            </View>
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
  logoCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  logoText: { color: '#fff', fontSize: 28, fontWeight: 'bold' },
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
  passwordContainer: {
    height: 52,
    borderWidth: 2,
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  passwordInput: {
    flex: 1,
    fontSize: 16,
    height: '100%',
  },
  eyeBtn: {
    padding: 4,
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
