import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';
import '../models/filial.dart';
import '../models/sensor.dart';
import 'firebase_service.dart';

class MySQLService {
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'unifeob@123',
    db: 'entrega5',
  );

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    MySqlConnection? conn;
    
    try {
      conn = await MySqlConnection.connect(_settings);
      
      await _salvarNoFirebase(leitura);
      
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
      print('MySQL: Salvo via Stored Procedure');
      
    } catch (e) {
      print('MySQL SP Error: $e');
      print('Tentando insert direto...');
      await _inserirDireto(conn!, leitura);
    } finally {
      await conn?.close();
    }
  }

  static Future<void> _salvarNoFirebase(LeituraSensor leitura) async {
    try {
      await FirebaseService.salvarLeitura({
        'idSensor': leitura.idSensor,
        'idFilial': leitura.idFilial,
        'filial': leitura.filial,
        'temperatura': leitura.temperatura,
        'umidade': leitura.umidade,
        'movimentoDetectado': leitura.movimentoDetectado,
        'lampadaLigada': leitura.lampadaLigada,
        'consumo_kWh': leitura.lampadaLigada ? 0.05 : 0.0,
        'timestamp': leitura.timestamp,
        'fonte': 'MySQL_Em_Tempo_Real',
      });
      print('Firebase: Leitura salva em tempo real');
    } catch (e) {
      print('Firebase Error: $e');
    }
  }

  // ... (manter todos os outros métodos originais)
}
