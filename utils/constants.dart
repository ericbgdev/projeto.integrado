class AppConstants {
  static const String appName = 'Monitoramento Packbag';
  static const String companyName = 'Packbag';
  
  // Configurações dos sensores DHT11
  static const double temperaturaMin = 18.0;
  static const double temperaturaMax = 32.0;
  static const double umidadeMin = 35.0;
  static const double umidadeMax = 85.0;
  
  // Filiais
  static const List<String> filiais = ['Aguai', 'Casa Branca'];
  
  // Cores do tema
  static const int primaryColor = 0xFF2196F3; // Azul
  static const int secondaryColor = 0xFF4CAF50; // Verde
  
  // Configurações de alertas
  static const double temperaturaAlta = 28.0;
  static const double temperaturaBaixa = 20.0;
  static const double umidadeAlta = 75.0;
  static const double umidadeBaixa = 40.0;
  
  // URLs e configurações
  static const String githubRepo = 'https://github.com/ericbgdev/projeto.integrado';
  static const String databaseName = 'pi-entrega5';
}
