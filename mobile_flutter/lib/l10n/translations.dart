// translations.dart
// All user-facing strings for es / en / pt

const Map<String, Map<String, String>> appTranslations = {
  // ────────────────────────────── ESPAÑOL ──────────────────────────────
  'es': {
    // App
    'app_name': 'Pep Education',
    'app_subtitle': 'Tu app de salud y nutrición',

    // Navigation
    'nav_home': 'Inicio',
    'nav_weight': 'Peso',
    'nav_progress': 'Progreso',
    'nav_reminders': 'Recordatorios',

    // Auth — login
    'login_email': 'Correo electrónico',
    'login_password': 'Contraseña',
    'login_btn': 'Iniciar sesión',
    'login_no_account': '¿No tienes cuenta? ',
    'login_register_link': 'Regístrate',
    'login_email_empty': 'Ingresa tu correo',
    'login_email_invalid': 'Correo inválido',
    'login_password_empty': 'Ingresa tu contraseña',
    'login_password_short': 'Mínimo 6 caracteres',

    // Auth — register
    'register_title': 'Crear cuenta',
    'register_subtitle': 'Regístrate',
    'register_confirm_password': 'Confirmar contraseña',
    'register_password_mismatch': 'Las contraseñas no coinciden',
    'register_btn': 'Crear cuenta',
    'register_has_account': '¿Ya tienes cuenta? ',
    'register_login_link': 'Inicia sesión',
    'register_password_empty': 'Ingresa una contraseña',

    // General
    'save_changes': 'Guardar cambios',
    'save': 'Guardar',
    'update': 'Actualizar',
    'cancel': 'Cancelar',
    'delete': 'Eliminar',
    'invalid_number': 'Número inválido',
    'logout': 'Cerrar sesión',
    'my_profile': 'Mi perfil',
    'patient_default': 'Paciente',

    // Units
    'unit_kg': 'kg',
    'unit_lbs': 'lbs',
    'unit_cm': 'cm',
    'unit_ft': 'ft',

    // Profile
    'profile_title': 'Mi Perfil',
    'profile_units_title': 'Sistema de unidades',
    'profile_language': 'Idioma',
    'profile_name': 'Nombre completo',
    'profile_name_empty': 'Ingresa tu nombre',
    'profile_sex': 'Sexo',
    'profile_birth_date': 'Fecha de nacimiento',
    'profile_birth_date_select': 'Seleccionar fecha',
    'profile_height_cm': 'Estatura (cm)',
    'profile_height_ft': 'Estatura (ft)',
    'profile_height_empty': 'Ingresa tu estatura',
    'profile_weight': 'Peso actual ({unit})',
    'profile_weight_empty': 'Ingresa tu peso',
    'profile_target': 'Peso objetivo ({unit})',
    'profile_target_empty': 'Ingresa tu peso objetivo',
    'profile_saved': 'Perfil actualizado correctamente',

    // Sex / demographics
    'sex_male': 'Masculino',
    'sex_female': 'Femenino',
    'years_suffix': '{n} años',

    // Language names (same in all locales)
    'lang_es': 'Español',
    'lang_en': 'English',
    'lang_pt': 'Português',

    // Home
    'home_greeting_morning': 'Buenos días,',
    'home_greeting_afternoon': 'Buenas tardes,',
    'home_greeting_evening': 'Buenas noches,',
    'home_bmi': 'Índice de Masa Corporal',
    'home_next_appointment': 'Próxima cita',
    'home_no_appointments': 'Sin citas programadas',
    'home_default_appointment': 'Cita',
    'home_current_weight': 'Peso actual',
    'home_target_weight': 'Peso objetivo',
    'info_height': 'Estatura',
    'info_sex': 'Sexo',
    'info_age': 'Edad',

    // BMI categories
    'bmi_underweight': 'Bajo peso',
    'bmi_normal': 'Peso normal',
    'bmi_overweight': 'Sobrepeso',
    'bmi_obesity': 'Obesidad',
    'bmi_normal_short': 'Normal',

    // Weight screen
    'weight_title': 'Peso',
    'weight_empty': 'Sin registros aún',
    'weight_empty_hint': 'Toca + para agregar tu primer registro',
    'weight_add_dialog': 'Registrar peso',
    'weight_edit_dialog': 'Editar registro',
    'weight_date': 'Fecha',
    'weight_field': 'Peso ({unit})',
    'weight_notes': 'Notas (opcional)',
    'weight_camera': 'Cámara',
    'weight_gallery': 'Galería',
    'weight_delete_title': 'Eliminar registro',
    'weight_delete_confirm': '¿Seguro que deseas eliminar este registro?',
    'weight_empty_field': 'Ingresa el peso',

    // Progress screen
    'progress_title': 'Progreso',
    'progress_initial_weight': 'Peso inicial',
    'progress_goal': 'Meta',
    'progress_difference': 'Diferencia',
    'progress_chart_title': 'Evolución del peso',
    'progress_no_records': 'Aún no hay registros',
    'progress_no_records_period': 'Sin registros en este período',
    'progress_hint': 'Ve a la pestaña Peso y toca +',
    'progress_history': 'Historial',
    'progress_goal_reached': '¡Meta alcanzada!',
    'progress_lost': 'Has bajado {amount}',
    'progress_started_at': 'Inicio en {amount}',
    'progress_to_go': 'Faltan {amount} para tu meta de {goal}',
    'progress_excellent': '¡Excelente trabajo, sigue así!',
    'progress_start': 'INICIO',
    'progress_today': 'HOY',
    'progress_meta': 'META',
    'progress_achievements': 'Logros',
    'progress_suggestions': 'Sugerencias del día',
    'progress_decreased': 'Has bajado',
    'progress_increased': 'Has subido',
    'bmi_gauge_title': 'Índice de Masa Corporal (IMC)',
    'bmi_healthy_range': 'Rango Saludable: 18.5 – 24.9',
    'chart_meta': 'Meta: {amount}',

    // Reminders screen
    'reminders_title': 'Recordatorios',
    'reminder_add': 'Nueva cita',
    'reminder_edit': 'Editar cita',
    'reminder_title_field': 'Título de la cita',
    'reminder_title_empty': 'Ingresa un título',
    'reminder_date': 'Fecha',
    'reminder_time': 'Hora',
    'reminder_notes': 'Notas (opcional)',
    'reminder_sync': 'Agregar al calendario del dispositivo',
    'reminder_delete_title': 'Eliminar cita',
    'reminder_delete_confirm': '¿Seguro que deseas eliminar esta cita?',
    'reminder_none_today': 'Sin citas este día',
    'reminder_synced': 'Cita sincronizada con el calendario',
    'reminder_count': '{n} cita',
    'reminder_count_plural': '{n} citas',

    // Support screen
    'support_title': 'Soporte',
    'support_question': '¿Necesitas ayuda?',
    'support_description':
        'Nuestro equipo de nutrición está disponible para apoyarte. Contáctanos por WhatsApp.',
    'support_whatsapp_btn': 'Contactar por WhatsApp',
    'support_hours': 'Horario de atención:\nLunes a Viernes · 9:00 – 18:00',
    'support_whatsapp_error':
        'No se pudo abrir WhatsApp. Verifica que esté instalado.',

    // Achievements
    'ach_1_name': 'Primer Paso',
    'ach_1_desc': 'Tu primer pesaje registrado',
    'ach_2_name': 'Semana Activa',
    'ach_2_desc': '7 pesajes registrados',
    'ach_3_name': 'Avance Notable',
    'ach_3_desc': 'Has perdido el 5% de tu peso inicial',
    'ach_4_name': 'Meta Cercana',
    'ach_4_desc': 'A menos de 2 kg de tu meta',
    'ach_5_name': 'Meta Alcanzada',
    'ach_5_desc': '¡Llegaste a tu peso meta!',
    'ach_6_name': 'Salud Óptima',
    'ach_6_desc': 'Tu IMC está en rango normal (18.5–24.9)',

    // Suggestions
    'sug_water_title': 'Hidratación',
    'sug_water_desc_high': 'Bebe al menos 3 litros de agua al día',
    'sug_water_desc_normal': 'Bebe 8 vasos de agua al día',
    'sug_move_title': 'Movimiento',
    'sug_move_senior_desc': '30 min de caminata a paso ligero',
    'sug_move_active_desc': '30 min de actividad física',
  },

  // ────────────────────────────── ENGLISH ──────────────────────────────
  'en': {
    // App
    'app_name': 'Pep Education',
    'app_subtitle': 'Your health & nutrition app',

    // Navigation
    'nav_home': 'Home',
    'nav_weight': 'Weight',
    'nav_progress': 'Progress',
    'nav_reminders': 'Reminders',

    // Auth — login
    'login_email': 'Email address',
    'login_password': 'Password',
    'login_btn': 'Sign in',
    'login_no_account': "Don't have an account? ",
    'login_register_link': 'Sign up',
    'login_email_empty': 'Enter your email',
    'login_email_invalid': 'Invalid email',
    'login_password_empty': 'Enter your password',
    'login_password_short': 'Minimum 6 characters',

    // Auth — register
    'register_title': 'Create account',
    'register_subtitle': 'Sign up',
    'register_confirm_password': 'Confirm password',
    'register_password_mismatch': 'Passwords do not match',
    'register_btn': 'Create account',
    'register_has_account': 'Already have an account? ',
    'register_login_link': 'Sign in',
    'register_password_empty': 'Enter a password',

    // General
    'save_changes': 'Save changes',
    'save': 'Save',
    'update': 'Update',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'invalid_number': 'Invalid number',
    'logout': 'Sign out',
    'my_profile': 'My profile',
    'patient_default': 'Patient',

    // Units
    'unit_kg': 'kg',
    'unit_lbs': 'lbs',
    'unit_cm': 'cm',
    'unit_ft': 'ft',

    // Profile
    'profile_title': 'My Profile',
    'profile_units_title': 'Unit system',
    'profile_language': 'Language',
    'profile_name': 'Full name',
    'profile_name_empty': 'Enter your name',
    'profile_sex': 'Sex',
    'profile_birth_date': 'Date of birth',
    'profile_birth_date_select': 'Select date',
    'profile_height_cm': 'Height (cm)',
    'profile_height_ft': 'Height (ft)',
    'profile_height_empty': 'Enter your height',
    'profile_weight': 'Current weight ({unit})',
    'profile_weight_empty': 'Enter your weight',
    'profile_target': 'Target weight ({unit})',
    'profile_target_empty': 'Enter your target weight',
    'profile_saved': 'Profile updated successfully',

    // Sex / demographics
    'sex_male': 'Male',
    'sex_female': 'Female',
    'years_suffix': '{n} yrs',

    // Language names
    'lang_es': 'Español',
    'lang_en': 'English',
    'lang_pt': 'Português',

    // Home
    'home_greeting_morning': 'Good morning,',
    'home_greeting_afternoon': 'Good afternoon,',
    'home_greeting_evening': 'Good evening,',
    'home_bmi': 'Body Mass Index',
    'home_next_appointment': 'Next appointment',
    'home_no_appointments': 'No appointments scheduled',
    'home_default_appointment': 'Appointment',
    'home_current_weight': 'Current weight',
    'home_target_weight': 'Target weight',
    'info_height': 'Height',
    'info_sex': 'Sex',
    'info_age': 'Age',

    // BMI categories
    'bmi_underweight': 'Underweight',
    'bmi_normal': 'Normal weight',
    'bmi_overweight': 'Overweight',
    'bmi_obesity': 'Obese',
    'bmi_normal_short': 'Normal',

    // Weight screen
    'weight_title': 'Weight',
    'weight_empty': 'No records yet',
    'weight_empty_hint': 'Tap + to add your first entry',
    'weight_add_dialog': 'Log weight',
    'weight_edit_dialog': 'Edit entry',
    'weight_date': 'Date',
    'weight_field': 'Weight ({unit})',
    'weight_notes': 'Notes (optional)',
    'weight_camera': 'Camera',
    'weight_gallery': 'Gallery',
    'weight_delete_title': 'Delete entry',
    'weight_delete_confirm': 'Are you sure you want to delete this entry?',
    'weight_empty_field': 'Enter weight',

    // Progress screen
    'progress_title': 'Progress',
    'progress_initial_weight': 'Initial weight',
    'progress_goal': 'Goal',
    'progress_difference': 'Difference',
    'progress_chart_title': 'Weight evolution',
    'progress_no_records': 'No records yet',
    'progress_no_records_period': 'No records in this period',
    'progress_hint': 'Go to Weight tab and tap +',
    'progress_history': 'History',
    'progress_goal_reached': 'Goal reached!',
    'progress_lost': "You've lost {amount}",
    'progress_started_at': 'Started at {amount}',
    'progress_to_go': '{amount} left to reach your goal of {goal}',
    'progress_excellent': 'Excellent work, keep it up!',
    'progress_start': 'START',
    'progress_today': 'TODAY',
    'progress_meta': 'GOAL',
    'progress_achievements': 'Achievements',
    'progress_suggestions': 'Daily tips',
    'progress_decreased': "You've lost",
    'progress_increased': "You've gained",
    'bmi_gauge_title': 'Body Mass Index (BMI)',
    'bmi_healthy_range': 'Healthy Range: 18.5 – 24.9',
    'chart_meta': 'Goal: {amount}',

    // Reminders screen
    'reminders_title': 'Reminders',
    'reminder_add': 'New appointment',
    'reminder_edit': 'Edit appointment',
    'reminder_title_field': 'Appointment title',
    'reminder_title_empty': 'Enter a title',
    'reminder_date': 'Date',
    'reminder_time': 'Time',
    'reminder_notes': 'Notes (optional)',
    'reminder_sync': 'Add to device calendar',
    'reminder_delete_title': 'Delete appointment',
    'reminder_delete_confirm':
        'Are you sure you want to delete this appointment?',
    'reminder_none_today': 'No appointments today',
    'reminder_synced': 'Appointment synced to calendar',
    'reminder_count': '{n} appointment',
    'reminder_count_plural': '{n} appointments',

    // Support screen
    'support_title': 'Support',
    'support_question': 'Need help?',
    'support_description':
        'Our nutrition team is available to assist you. Contact us via WhatsApp.',
    'support_whatsapp_btn': 'Contact via WhatsApp',
    'support_hours': 'Office hours:\nMonday to Friday · 9:00 – 18:00',
    'support_whatsapp_error':
        'Could not open WhatsApp. Please verify it is installed.',

    // Achievements
    'ach_1_name': 'First Step',
    'ach_1_desc': 'Your first weigh-in recorded',
    'ach_2_name': 'Active Week',
    'ach_2_desc': '7 weigh-ins recorded',
    'ach_3_name': 'Notable Progress',
    'ach_3_desc': "You've lost 5% of your initial weight",
    'ach_4_name': 'Goal Nearby',
    'ach_4_desc': 'Less than 2 kg from your goal',
    'ach_5_name': 'Goal Reached',
    'ach_5_desc': "You've reached your target weight!",
    'ach_6_name': 'Optimal Health',
    'ach_6_desc': 'Your BMI is in normal range (18.5–24.9)',

    // Suggestions
    'sug_water_title': 'Hydration',
    'sug_water_desc_high': 'Drink at least 3 liters of water per day',
    'sug_water_desc_normal': 'Drink 8 glasses of water per day',
    'sug_move_title': 'Movement',
    'sug_move_senior_desc': '30 min of brisk walking',
    'sug_move_active_desc': '30 min of physical activity',
  },

  // ────────────────────────────── PORTUGUÊS ──────────────────────────────
  'pt': {
    // App
    'app_name': 'Pep Education',
    'app_subtitle': 'Seu app de saúde e nutrição',

    // Navigation
    'nav_home': 'Início',
    'nav_weight': 'Peso',
    'nav_progress': 'Progresso',
    'nav_reminders': 'Lembretes',

    // Auth — login
    'login_email': 'E-mail',
    'login_password': 'Senha',
    'login_btn': 'Entrar',
    'login_no_account': 'Não tem conta? ',
    'login_register_link': 'Cadastre-se',
    'login_email_empty': 'Digite seu e-mail',
    'login_email_invalid': 'E-mail inválido',
    'login_password_empty': 'Digite sua senha',
    'login_password_short': 'Mínimo 6 caracteres',

    // Auth — register
    'register_title': 'Criar conta',
    'register_subtitle': 'Cadastre-se',
    'register_confirm_password': 'Confirmar senha',
    'register_password_mismatch': 'As senhas não coincidem',
    'register_btn': 'Criar conta',
    'register_has_account': 'Já tem conta? ',
    'register_login_link': 'Entrar',
    'register_password_empty': 'Digite uma senha',

    // General
    'save_changes': 'Salvar alterações',
    'save': 'Salvar',
    'update': 'Atualizar',
    'cancel': 'Cancelar',
    'delete': 'Excluir',
    'invalid_number': 'Número inválido',
    'logout': 'Sair',
    'my_profile': 'Meu perfil',
    'patient_default': 'Paciente',

    // Units
    'unit_kg': 'kg',
    'unit_lbs': 'lbs',
    'unit_cm': 'cm',
    'unit_ft': 'ft',

    // Profile
    'profile_title': 'Meu Perfil',
    'profile_units_title': 'Sistema de unidades',
    'profile_language': 'Idioma',
    'profile_name': 'Nome completo',
    'profile_name_empty': 'Digite seu nome',
    'profile_sex': 'Sexo',
    'profile_birth_date': 'Data de nascimento',
    'profile_birth_date_select': 'Selecionar data',
    'profile_height_cm': 'Altura (cm)',
    'profile_height_ft': 'Altura (ft)',
    'profile_height_empty': 'Digite sua altura',
    'profile_weight': 'Peso atual ({unit})',
    'profile_weight_empty': 'Digite seu peso',
    'profile_target': 'Peso objetivo ({unit})',
    'profile_target_empty': 'Digite seu peso objetivo',
    'profile_saved': 'Perfil atualizado com sucesso',

    // Sex / demographics
    'sex_male': 'Masculino',
    'sex_female': 'Feminino',
    'years_suffix': '{n} anos',

    // Language names
    'lang_es': 'Español',
    'lang_en': 'English',
    'lang_pt': 'Português',

    // Home
    'home_greeting_morning': 'Bom dia,',
    'home_greeting_afternoon': 'Boa tarde,',
    'home_greeting_evening': 'Boa noite,',
    'home_bmi': 'Índice de Massa Corporal',
    'home_next_appointment': 'Próxima consulta',
    'home_no_appointments': 'Sem consultas agendadas',
    'home_default_appointment': 'Consulta',
    'home_current_weight': 'Peso atual',
    'home_target_weight': 'Peso objetivo',
    'info_height': 'Altura',
    'info_sex': 'Sexo',
    'info_age': 'Idade',

    // BMI categories
    'bmi_underweight': 'Abaixo do peso',
    'bmi_normal': 'Peso normal',
    'bmi_overweight': 'Sobrepeso',
    'bmi_obesity': 'Obesidade',
    'bmi_normal_short': 'Normal',

    // Weight screen
    'weight_title': 'Peso',
    'weight_empty': 'Sem registros ainda',
    'weight_empty_hint': 'Toque + para adicionar seu primeiro registro',
    'weight_add_dialog': 'Registrar peso',
    'weight_edit_dialog': 'Editar registro',
    'weight_date': 'Data',
    'weight_field': 'Peso ({unit})',
    'weight_notes': 'Notas (opcional)',
    'weight_camera': 'Câmera',
    'weight_gallery': 'Galeria',
    'weight_delete_title': 'Excluir registro',
    'weight_delete_confirm': 'Tem certeza que deseja excluir este registro?',
    'weight_empty_field': 'Digite o peso',

    // Progress screen
    'progress_title': 'Progresso',
    'progress_initial_weight': 'Peso inicial',
    'progress_goal': 'Meta',
    'progress_difference': 'Diferença',
    'progress_chart_title': 'Evolução do peso',
    'progress_no_records': 'Ainda não há registros',
    'progress_no_records_period': 'Sem registros neste período',
    'progress_hint': 'Vá para a aba Peso e toque +',
    'progress_history': 'Histórico',
    'progress_goal_reached': 'Meta alcançada!',
    'progress_lost': 'Você perdeu {amount}',
    'progress_started_at': 'Início em {amount}',
    'progress_to_go': 'Faltam {amount} para sua meta de {goal}',
    'progress_excellent': 'Excelente trabalho, continue assim!',
    'progress_start': 'INÍCIO',
    'progress_today': 'HOJE',
    'progress_meta': 'META',
    'progress_achievements': 'Conquistas',
    'progress_suggestions': 'Dicas do dia',
    'progress_decreased': 'Você perdeu',
    'progress_increased': 'Você ganhou',
    'bmi_gauge_title': 'Índice de Massa Corporal (IMC)',
    'bmi_healthy_range': 'Faixa Saudável: 18.5 – 24.9',
    'chart_meta': 'Meta: {amount}',

    // Reminders screen
    'reminders_title': 'Lembretes',
    'reminder_add': 'Nova consulta',
    'reminder_edit': 'Editar consulta',
    'reminder_title_field': 'Título da consulta',
    'reminder_title_empty': 'Digite um título',
    'reminder_date': 'Data',
    'reminder_time': 'Hora',
    'reminder_notes': 'Notas (opcional)',
    'reminder_sync': 'Adicionar ao calendário do dispositivo',
    'reminder_delete_title': 'Excluir consulta',
    'reminder_delete_confirm': 'Tem certeza que deseja excluir esta consulta?',
    'reminder_none_today': 'Sem consultas hoje',
    'reminder_synced': 'Consulta sincronizada com o calendário',
    'reminder_count': '{n} consulta',
    'reminder_count_plural': '{n} consultas',

    // Support screen
    'support_title': 'Suporte',
    'support_question': 'Precisa de ajuda?',
    'support_description':
        'Nossa equipe de nutrição está disponível para te ajudar. Entre em contato pelo WhatsApp.',
    'support_whatsapp_btn': 'Contato pelo WhatsApp',
    'support_hours':
        'Horário de atendimento:\nSegunda a Sexta · 9:00 – 18:00',
    'support_whatsapp_error':
        'Não foi possível abrir o WhatsApp. Verifique se está instalado.',

    // Achievements
    'ach_1_name': 'Primeiro Passo',
    'ach_1_desc': 'Sua primeira pesagem registrada',
    'ach_2_name': 'Semana Ativa',
    'ach_2_desc': '7 pesagens registradas',
    'ach_3_name': 'Avanço Notable',
    'ach_3_desc': 'Você perdeu 5% do seu peso inicial',
    'ach_4_name': 'Meta Próxima',
    'ach_4_desc': 'A menos de 2 kg da sua meta',
    'ach_5_name': 'Meta Alcançada',
    'ach_5_desc': 'Você chegou ao seu peso meta!',
    'ach_6_name': 'Saúde Ótima',
    'ach_6_desc': 'Seu IMC está na faixa normal (18.5–24.9)',

    // Suggestions
    'sug_water_title': 'Hidratação',
    'sug_water_desc_high': 'Beba pelo menos 3 litros de água por dia',
    'sug_water_desc_normal': 'Beba 8 copos de água por dia',
    'sug_move_title': 'Movimento',
    'sug_move_senior_desc': '30 min de caminhada leve',
    'sug_move_active_desc': '30 min de atividade física',
  },
};
