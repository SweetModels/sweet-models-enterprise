import 'package:flutter/material.dart';

/// App localizations for multi-language support
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'CO'),
    Locale('pt', 'BR'),
  ];
  
  // Translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Sweet Models Enterprise',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      
      // Authentication
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'login_success': 'Login successful',
      'login_failed': 'Login failed',
      'invalid_credentials': 'Invalid email or password',
      'session_expired': 'Session expired. Please login again.',
      
      // Dashboard
      'dashboard': 'Dashboard',
      'welcome_back': 'Welcome back',
      'total_earnings': 'Total Earnings',
      'tokens_today': 'Tokens Today',
      'goal_progress': 'Goal Progress',
      'daily_goal': 'Daily Goal',
      'tokens_remaining': 'tokens remaining',
      'goal_achieved': '🎉 Goal Achieved!',
      
      // Moderator Console
      'moderator_console': 'Moderator Console',
      'register_production': 'Register Production',
      'production_date': 'Production Date',
      'tokens_earned': 'Tokens Earned',
      'group_name': 'Group Name',
      'members': 'members',
      'total_tokens': 'Total Tokens',
      'submit': 'Submit',
      'production_registered': 'Production registered successfully',
      'offline_queued': 'Saved offline. Will sync when connected.',
      
      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark All as Read',
      'unread_count': '{count} unread',
      'notification_types': 'Notification Types',
      'achievement': 'Achievement',
      'payment': 'Payment',
      'contract': 'Contract',
      'info': 'Info',
      'warning': 'Warning',
      
      // Admin Dashboard
      'admin_dashboard': 'Admin Dashboard',
      'total_users': 'Total Users',
      'total_models': 'Total Models',
      'active_users': 'Active Users',
      'total_groups': 'Total Groups',
      'revenue_30_days': 'Revenue (30 days)',
      'top_performers': 'Top Performers',
      'export_data': 'Export Data',
      'refresh_dashboard': 'Refresh Dashboard',
      
      // Export
      'export': 'Export',
      'export_type': 'Export Type',
      'export_format': 'Format',
      'export_payroll': 'Payroll',
      'export_production': 'Production Logs',
      'export_users': 'Users',
      'export_audit': 'Audit Trail',
      'export_contracts': 'Contracts',
      'format_csv': 'CSV',
      'format_excel': 'Excel',
      'format_pdf': 'PDF',
      'export_initiated': 'Export initiated. Download will be ready shortly.',
      
      // Contracts
      'contracts': 'Contracts',
      'sign_contract': 'Sign Contract',
      'contract_signed': 'Contract signed successfully',
      'contract_pending': 'Pending',
      'contract_active': 'Active',
      'contract_expired': 'Expired',
      
      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'notifications_settings': 'Notification Preferences',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'achievement_notifications': 'Achievement Notifications',
      'payment_notifications': 'Payment Notifications',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      
      // Errors
      'network_error': 'Network error. Please check your connection.',
      'server_error': 'Server error. Please try again later.',
      'unknown_error': 'An unknown error occurred.',
      'validation_error': 'Please fill all required fields.',
    },
    'es': {
      // Common
      'app_name': 'Sweet Models Enterprise',
      'ok': 'Aceptar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'search': 'Buscar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'retry': 'Reintentar',
      'yes': 'Sí',
      'no': 'No',
      'close': 'Cerrar',
      
      // Authentication
      'login': 'Iniciar Sesión',
      'logout': 'Cerrar Sesión',
      'register': 'Registrarse',
      'email': 'Correo Electrónico',
      'password': 'Contraseña',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'login_success': 'Inicio de sesión exitoso',
      'login_failed': 'Error al iniciar sesión',
      'invalid_credentials': 'Correo o contraseña inválidos',
      'session_expired': 'Sesión expirada. Por favor inicia sesión nuevamente.',
      
      // Dashboard
      'dashboard': 'Panel de Control',
      'welcome_back': 'Bienvenido de nuevo',
      'total_earnings': 'Ganancias Totales',
      'tokens_today': 'Tokens Hoy',
      'goal_progress': 'Progreso de Meta',
      'daily_goal': 'Meta Diaria',
      'tokens_remaining': 'tokens restantes',
      'goal_achieved': '🎉 ¡Meta Alcanzada!',
      
      // Moderator Console
      'moderator_console': 'Consola del Moderador',
      'register_production': 'Registrar Producción',
      'production_date': 'Fecha de Producción',
      'tokens_earned': 'Tokens Ganados',
      'group_name': 'Nombre del Grupo',
      'members': 'miembros',
      'total_tokens': 'Tokens Totales',
      'submit': 'Enviar',
      'production_registered': 'Producción registrada exitosamente',
      'offline_queued': 'Guardado sin conexión. Se sincronizará cuando haya conexión.',
      
      // Notifications
      'notifications': 'Notificaciones',
      'no_notifications': 'Sin notificaciones',
      'mark_all_read': 'Marcar Todas como Leídas',
      'unread_count': '{count} sin leer',
      'notification_types': 'Tipos de Notificación',
      'achievement': 'Logro',
      'payment': 'Pago',
      'contract': 'Contrato',
      'info': 'Información',
      'warning': 'Advertencia',
      
      // Admin Dashboard
      'admin_dashboard': 'Panel de Administrador',
      'total_users': 'Usuarios Totales',
      'total_models': 'Modelos Totales',
      'active_users': 'Usuarios Activos',
      'total_groups': 'Grupos Totales',
      'revenue_30_days': 'Ingresos (30 días)',
      'top_performers': 'Mejores Performers',
      'export_data': 'Exportar Datos',
      'refresh_dashboard': 'Actualizar Panel',
      
      // Export
      'export': 'Exportar',
      'export_type': 'Tipo de Exportación',
      'export_format': 'Formato',
      'export_payroll': 'Nómina',
      'export_production': 'Logs de Producción',
      'export_users': 'Usuarios',
      'export_audit': 'Auditoría',
      'export_contracts': 'Contratos',
      'format_csv': 'CSV',
      'format_excel': 'Excel',
      'format_pdf': 'PDF',
      'export_initiated': 'Exportación iniciada. La descarga estará lista pronto.',
      
      // Contracts
      'contracts': 'Contratos',
      'sign_contract': 'Firmar Contrato',
      'contract_signed': 'Contrato firmado exitosamente',
      'contract_pending': 'Pendiente',
      'contract_active': 'Activo',
      'contract_expired': 'Expirado',
      
      // Settings
      'settings': 'Configuración',
      'language': 'Idioma',
      'notifications_settings': 'Preferencias de Notificaciones',
      'push_notifications': 'Notificaciones Push',
      'email_notifications': 'Notificaciones por Email',
      'achievement_notifications': 'Notificaciones de Logros',
      'payment_notifications': 'Notificaciones de Pagos',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      
      // Errors
      'network_error': 'Error de red. Por favor verifica tu conexión.',
      'server_error': 'Error del servidor. Intenta nuevamente más tarde.',
      'unknown_error': 'Ocurrió un error desconocido.',
      'validation_error': 'Por favor completa todos los campos requeridos.',
    },
    'pt': {
      // Common
      'app_name': 'Sweet Models Enterprise',
      'ok': 'OK',
      'cancel': 'Cancelar',
      'save': 'Salvar',
      'delete': 'Excluir',
      'edit': 'Editar',
      'search': 'Pesquisar',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',
      'retry': 'Tentar Novamente',
      'yes': 'Sim',
      'no': 'Não',
      'close': 'Fechar',
      
      // Authentication
      'login': 'Entrar',
      'logout': 'Sair',
      'register': 'Registrar',
      'email': 'E-mail',
      'password': 'Senha',
      'forgot_password': 'Esqueceu a senha?',
      'login_success': 'Login bem-sucedido',
      'login_failed': 'Falha no login',
      'invalid_credentials': 'E-mail ou senha inválidos',
      'session_expired': 'Sessão expirada. Por favor, faça login novamente.',
      
      // Dashboard
      'dashboard': 'Painel',
      'welcome_back': 'Bem-vindo de volta',
      'total_earnings': 'Ganhos Totais',
      'tokens_today': 'Tokens Hoje',
      'goal_progress': 'Progresso da Meta',
      'daily_goal': 'Meta Diária',
      'tokens_remaining': 'tokens restantes',
      'goal_achieved': '🎉 Meta Alcançada!',
      
      // Additional translations...
      'moderator_console': 'Console do Moderador',
      'notifications': 'Notificações',
      'admin_dashboard': 'Painel de Administrador',
      'settings': 'Configurações',
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Convenience getters
  String get appName => translate('app_name');
  String get login => translate('login');
  String get logout => translate('logout');
  String get email => translate('email');
  String get password => translate('password');
  String get dashboard => translate('dashboard');
  String get notifications => translate('notifications');
  String get settings => translate('settings');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get moderatorConsole => translate('moderator_console');
  String get adminDashboard => translate('admin_dashboard');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'pt'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
