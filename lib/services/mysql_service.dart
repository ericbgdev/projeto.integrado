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

  // MÉTODO QUE USA A STORED PROCEDURE DO SCHEMA.SQL
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    final conn = await MySqlConnection.connect(_settings);
    
    try {
      // CHAMAR A STORED PROCEDURE sp_inserir_leitura
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
      print('✅ MySQL: Leitura do sensor ${leitura.idSensor} salva via SP');
    } catch (e) {
      print('❌ MySQL Error: $e');
      // Fallback: inserção direta se a SP falhar
      await _inserirDireto(conn, leitura);
    } finally {
      await conn.close();
    }
  }

  static Future<void> _inserirDireto(MySqlConnection conn, LeituraSensor leitura) async {
    final consumo = leitura.lampadaLigada ? 0.0500 : 0.0000;
    final idData = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Unix timestamp
    
    await conn.query(
      'INSERT INTO FATO_LEITURAS (ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, Movimento_Detectado, Lampada_Ligada, Consumo_kWh, Timestamp) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        leitura.idSensor,
        leitura.idFilial,
        idData,
        leitura.temperatura,
        leitura.umidade,
        leitura.movimentoDetectado ? 1 : 0,
        leitura.lampadaLigada ? 1 : 0,
        consumo,
        leitura.timestamp
      ]
    );
    print('✅ MySQL: Leitura salva via insert direto');
  }
}
