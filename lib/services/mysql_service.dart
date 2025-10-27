dart
import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';

class MySQLService {
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'sua_senha',
    db: 'pi-entrega5',
  );

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    final conn = await MySqlConnection.connect(_settings);
    
    try {
      // Usar Stored Procedure do seu SQL anterior
      await conn.query(
        'CALL sp_inserir_leitura(?, ?, ?, ?, ?)',
        [
          leitura.idSensor,
          leitura.temperatura,
          leitura.umidade,
          leitura.movimentoDetectado ? 1 : 0,
          leitura.lampadaLigada ? 1 : 0
        ]
      );
      print('✅ MySQL: Leitura ${leitura.idSensor} salva');
    } catch (e) {
      print('❌ MySQL Error: $e');
    } finally {
      await conn.close();
    }
  }

  static Future<List<LeituraSensor>> buscarHistorico() async {
    final conn = await MySqlConnection.connect(_settings);
    // Implementar busca do histórico
    return [];
  }
}
  }) async {
    print('📝 Simulando inserção via SP...');
    print('Sensor: $idSensor, Temp: $temperatura, Movimento: $movimento');
  }
}
