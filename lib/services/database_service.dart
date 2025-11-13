import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';
import 'firebase_realtime_service.dart'; // ← MUDANÇA AQUI

class DatabaseService {
  static MySqlConnection? _conn;
  static bool _isConnected = false;
  
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'unifeob@123',
    db: 'entrega5',
    timeout: Duration(seconds: 60),
  );

  static Future<MySqlConnection> _getConnection() async {
    if (_conn == null || !_isConnected) {
      try {
        _conn = await MySqlConnection.connect(_settings);
        _isConnected = true;
      } catch (e) {
        _isConnected = false;
        rethrow;
      }
    }
    return _conn!;
  }

  static Future<void> testarConexao() async {
    try {
      final conn = await _getConnection();
      print('✅ Conectado ao MySQL: entrega5');
      
      final resultado = await conn.query('SHOW TABLES');
      print('📊 Tabelas no banco:');
      for (final row in resultado) {
        print('   - ${row[0]}');
      }
      
    } catch (e) {
      print('❌ Erro ao conectar no MySQL: $e');
      rethrow;
    }
  }

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    try {
      final conn = await _getConnection();
      
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
      
      print('💾 Leitura salva via SP: Sensor ${leitura.idSensor}');
      
      // Salvar no Firebase REAL - MUDANÇA AQUI
      await FirebaseRealtimeService.salvarLeitura(leitura);
      
    } catch (e) {
      print('❌ Erro ao salvar leitura: $e');
      print('🔄 Tentando insert direto...');
      await _inserirDireto(leitura);
    }
  }

  static Future<void> _inserirDireto(LeituraSensor leitura) async {
    try {
      final conn = await _getConnection();
      
      final resultadoFilial = await conn.query(
        'SELECT ID_Filial FROM DIM_SENSOR WHERE ID_Sensor = ?',
        [leitura.idSensor]
      );
      
      if (resultadoFilial.isEmpty) {
        throw Exception('Sensor ${leitura.idSensor} não encontrado');
      }
      
      final idFilial = resultadoFilial.first['ID_Filial'];
      final idData = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final consumo = leitura.lampadaLigada ? 0.0500 : 0.0000;

      await _inserirDimTempo(conn, idData, leitura.timestamp);

      await conn.query(
        '''INSERT INTO FATO_LEITURAS 
           (ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, 
            Movimento_Detectado, Lampada_Ligada, Consumo_kWh, Timestamp, 
            Qualidade_Sinal, Status_Leitura)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          leitura.idSensor,
          idFilial,
          idData,
          leitura.temperatura,
          leitura.umidade,
          leitura.movimentoDetectado ? 1 : 0,
          leitura.lampadaLigada ? 1 : 0,
          consumo,
          leitura.timestamp.toIso8601String(),
          leitura.qualidadeSinal ?? 100,
          leitura.statusLeitura ?? 'Válida'
        ]
      );
      
      print('💾 Leitura salva via insert direto');
      // MUDANÇA AQUI
      await FirebaseRealtimeService.salvarLeitura(leitura);
      
    } catch (e) {
      print('❌ Erro no insert direto: $e');
      rethrow;
    }
  }

  static Future<void> _inserirDimTempo(MySqlConnection conn, int idData, DateTime data) async {
    try {
      final periodo = _obterPeriodoDia(data.hour);
      final diaSemana = _obterDiaSemana(data.weekday);
      
      await conn.query(
        '''INSERT IGNORE INTO DIM_TEMPO 
           (ID_Data, Data_Completa, Ano, Mes, Dia, DiaSemana, Hora, Periodo_Dia)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          idData,
          data.toIso8601String(),
          data.year,
          data.month,
          data.day,
          diaSemana,
          data.hour,
          periodo
        ]
      );
    } catch (e) {
      // Silenciar erro se já existir
    }
  }

  static String _obterPeriodoDia(int hora) {
    if (hora >= 0 && hora < 6) return 'Madrugada';
    if (hora >= 6 && hora < 12) return 'Manhã';
    if (hora >= 12 && hora < 18) return 'Tarde';
    return 'Noite';
  }

  static String _obterDiaSemana(int weekday) {
    const dias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return dias[weekday - 1];
  }

  static Future<List<Map<String, dynamic>>> getLeituras() async {
    try {
      final conn = await _getConnection();
      
      final resultado = await conn.query('''
        SELECT fl.*, ds.Tipo_Sensor, ds.Localizacao, df.Nome_Filial
        FROM FATO_LEITURAS fl
        JOIN DIM_SENSOR ds ON fl.ID_Sensor = ds.ID_Sensor
        JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
        ORDER BY fl.Timestamp DESC
        LIMIT 50
      ''');
      
      return resultado.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Erro ao buscar leituras: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getFiliais() async {
    try {
      final conn = await _getConnection();
      final resultado = await conn.query('SELECT * FROM DIM_FILIAL');
      return resultado.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Erro ao buscar filiais: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSensores() async {
    try {
      final conn = await _getConnection();
      final resultado = await conn.query('''
        SELECT ds.*, df.Nome_Filial 
        FROM DIM_SENSOR ds 
        JOIN DIM_FILIAL df ON ds.ID_Filial = df.ID_Filial
      ''');
      return resultado.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Erro ao buscar sensores: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final conn = await _getConnection();
      
      final totalResult = await conn.query('SELECT COUNT(*) as total FROM FATO_LEITURAS');
      final total = totalResult.first['total'];
      
      final tempResult = await conn.query(
        'SELECT AVG(Temperatura) as media FROM FATO_LEITURAS WHERE Temperatura IS NOT NULL'
      );
      final mediaTemp = tempResult.first['media'] ?? 0;
      
      final umidResult = await conn.query(
        'SELECT AVG(Umidade) as media FROM FATO_LEITURAS WHERE Umidade IS NOT NULL'
      );
      final mediaUmid = umidResult.first['media'] ?? 0;
      
      final consumoResult = await conn.query('SELECT SUM(Consumo_kWh) as total FROM FATO_LEITURAS');
      final consumoTotal = consumoResult.first['total'] ?? 0;
      
      final movResult = await conn.query(
        'SELECT COUNT(*) as total FROM FATO_LEITURAS WHERE Movimento_Detectado = 1'
      );
      final movimentos = movResult.first['total'];
      
      final filiaisResult = await conn.query('SELECT COUNT(*) as total FROM DIM_FILIAL');
      final totalFiliais = filiaisResult.first['total'];
      
      final sensoresResult = await conn.query(
        'SELECT COUNT(*) as total FROM DIM_SENSOR WHERE Status = "Ativo"'
      );
      final totalSensores = sensoresResult.first['total'];
      
      return {
        'total_leituras': total,
        'media_temperatura': mediaTemp is num ? mediaTemp.toStringAsFixed(1) : '0.0',
        'media_umidade': mediaUmid is num ? mediaUmid.toStringAsFixed(1) : '0.0',
        'consumo_total': consumoTotal is num ? consumoTotal.toStringAsFixed(2) : '0.00',
        'movimentos_detectados': movimentos,
        'filiais_ativas': totalFiliais,
        'sensores_ativos': totalSensores,
      };
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total_leituras': 0,
        'media_temperatura': '0.0',
        'media_umidade': '0.0',
        'consumo_total': '0.00',
        'movimentos_detectados': 0,
        'filiais_ativas': 0,
        'sensores_ativos': 0,
      };
    }
  }

  static Future<void> close() async {
    try {
      await _conn?.close();
      _conn = null;
      _isConnected = false;
      print('🔌 Conexão MySQL fechada');
    } catch (e) {
      _isConnected = false;
    }
  }
}
