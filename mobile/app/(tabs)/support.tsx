import { StyleSheet, View, Text, TouchableOpacity, Linking, Image, Alert } from 'react-native';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { MaterialCommunityIcons } from '@expo/vector-icons';

export default function SupportScreen() {
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  const openWhatsApp = () => {
    const phoneNumber = '521234567890'; // Replace with real admin phone
    const message = 'Hola, necesito soporte con mi tratamiento en Pep Education.';
    const url = `whatsapp://send?phone=${phoneNumber}&text=${encodeURIComponent(message)}`;
    
    Linking.canOpenURL(url).then(supported => {
      if (supported) {
        Linking.openURL(url);
      } else {
        const webUrl = `https://wa.me/${phoneNumber}?text=${encodeURIComponent(message)}`;
        Linking.openURL(webUrl);
      }
    });
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.lilacDark }]}>Centro de Soporte</Text>
        <Text style={[styles.subtitle, { color: theme.icon }]}>Estamos aquí para ayudarte</Text>
      </View>

      <View style={styles.cardContainer}>
        <View style={[styles.card, { backgroundColor: theme.lilacPale }]}>
          <MaterialCommunityIcons name="doctor" size={40} color={theme.lilacDark} />
          <Text style={[styles.cardTitle, { color: theme.lilacDark }]}>Tu Médico</Text>
          <Text style={[styles.cardText, { color: theme.icon }]}>
            Consultas directas sobre tu tratamiento médico.
          </Text>
          <TouchableOpacity 
            style={[styles.button, { backgroundColor: theme.lilacDark }]}
            onPress={openWhatsApp}
          >
            <Text style={styles.buttonText}>Contactar Dr. Pep</Text>
          </TouchableOpacity>
        </View>

        <View style={[styles.card, { backgroundColor: theme.yellowSoft }]}>
          <MaterialCommunityIcons name="comment-question-outline" size={40} color={theme.yellow} />
          <Text style={[styles.cardTitle, { color: theme.lilacDark }]}>Preguntas Frecuentes</Text>
          <Text style={[styles.cardText, { color: theme.icon }]}>
            Resuelve dudas rápidas sobre Semaglutida y alimentación.
          </Text>
          <TouchableOpacity 
            style={[styles.button, { backgroundColor: theme.yellow }]}
            onPress={() => Alert.alert('Aviso', 'Sección de FAQ en desarrollo')}
          >
            <Text style={[styles.buttonText, { color: '#1A1A1A' }]}>Ver Preguntas</Text>
          </TouchableOpacity>
        </View>
      </View>

      <Text style={[styles.footerText, { color: theme.icon }]}>
        Atención de Lunes a Viernes, 9:00 AM - 6:00 PM
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 30,
    paddingTop: 80,
  },
  header: {
    gap: 8,
    marginBottom: 40,
  },
  title: {
    fontSize: 30,
    fontWeight: 'bold',
  },
  subtitle: {
    fontSize: 18,
  },
  cardContainer: {
    gap: 20,
    flex: 1,
  },
  card: {
    padding: 25,
    borderRadius: 24,
    alignItems: 'center',
    gap: 12,
  },
  cardTitle: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  cardText: {
    fontSize: 16,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 10,
  },
  button: {
    paddingHorizontal: 30,
    paddingVertical: 14,
    borderRadius: 16,
    width: '100%',
    alignItems: 'center',
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 18,
  },
  footerText: {
    fontSize: 14,
    textAlign: 'center',
    marginTop: 20,
    fontStyle: 'italic',
  },
});
