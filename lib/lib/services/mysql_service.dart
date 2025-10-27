import 'package:mysql1/mysql1.dart';

class MySQLService {
  static Future<void> testarConexao() async {
    try {
      print('🔌 Testando conexão MySQL...');
      
      final conn = await MySqlConnection.connect(ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: 'sua_senha', // ALTERE PARA SUA SENHA
        db: 'pi-entrega5',
      ));

      print('✅ MySQL Conectado com sucesso!');
      
      // Testar se as tabelas existem
      var resultado = await conn.query('SHOW TABLES');
      print('📊 Tabelas no banco: ${resultado.length}');
      
      await conn.close();
      
    } catch (e) {
      print('❌ Erro na conexão MySQL: $e');
    }
  }

  // SUA STORED PROCEDURE - Vamos implementar depois
  static Future<void> inserirLeitura({
    required int idSensor,
    required double? temperatura,
    required double? umidade,
    required int movimento,
    required int lampada,
  }) async {
    print('📝 Simulando inserção via SP...');
    print('Sensor: $idSensor, Temp: $temperatura, Movimento: $movimento');
  }
}
