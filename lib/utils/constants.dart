class DatabaseConfig {
  static const String host = 'localhost';
  static const int port = 3306;
  static const String dbName = 'pi-entrega5';
  static const String user = 'root';
  static const String password = 'sua_senha';
}

class SensorMapping {
  static const Map<String, int> filialParaSensor = {
    'Aguai': 2,
    'Casa Branca': 5,
  };
}
