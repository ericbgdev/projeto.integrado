import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';

class MySQLService {
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'sua_senha', // ALTERAR PARA SUA SENHA
    db: 'pi-entrega5',
  );

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    final conn = await MySqlConnection.connect(_settings);
   
    try {
      // Tentar usar a Stored Procedure
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
      print('   💾 MySQL: Salvo via SP');
    } catch (e) {
      print('   ⚠️ MySQL SP Error: $e - Usando insert direto');
      await _inserirDireto(conn, leitura);
    } finally {
      await conn.close();
    }
  }

  static Future<void> _inserirDireto(MySqlConnection conn, LeituraSensor leitura) async {
    final consumo = leitura.lampadaLigada ? 0.0500 : 0.0000;
    final idData = DateTime.now().millisecondsSinceEpoch ~/ 1000;
   
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
    print('   💾 MySQL: Salvo via insert direto');
  }
}
