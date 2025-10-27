import 'package:mysql1/mysql1.dart';

class MySQLService {
  static Future<void> testarConexao() async {
    print('🔌 Testando MySQL...');
    
    final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'sua_senha', // altere para sua senha
      db: 'pi-entrega5',
    ));

    print('✅ MySQL Conectado!');
    await conn.close();
  }
}
