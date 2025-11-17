// ════════════════════════════════════════════════════════════════
// SERVIÇO: DatabaseService
// MySQL com Sistema de 100 Lâmpadas LED 20W
// Firebase obrigatório
// ════════════════════════════════════════════════════════════════

import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';
import 'firebase_realtime_service.dart';

class DatabaseService {
  static MySqlConnection? _conn;
  static bool _isConnected = false;
  
  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'unifeob@123', // ← ALTERE AQUI PARA SUA SENHA
    db: 'entrega5',
    timeout: Duration(seconds: 60),
  );

  // ════════════════════════════════════════════════════════════════
  // OBTER CONEXÃO
  // ════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════
  // TESTAR CONEXÃO
  // ════════════════════════════════════════════════════════════════
  static Future<void> testarConexao() async {
    try {
      final conn = await _getConnection();
      print('✅ Conectado ao MySQL: entrega5');
      
      final resultado = await conn.query('SHOW TABLES');
      print('📊 Tabelas no banco:');
      for (final row in resultado) {
        print('   - ${row[0]}');
      }
      
      // Verificar configuração das filiais
      final filiais = await conn.query('''
        SELECT Nome_Filial, Qtd_Lampadas, Potencia_Lampada_W, Tempo_Ativacao_Min 
        FROM DIM_FILIAL
      ''');
      
      print('\n💡 CONFIGURAÇÃO DE ILUMINAÇÃO:');
      for (final filial in filiais) {
        print('   ${filial['Nome_Filial']}: ${filial['Qtd_Lampadas']}x${filial['Potencia_Lampada_W']}W '
              '(${filial['Tempo_Ativacao_Min']}min)');
      }
      
    } catch (e) {
      print('❌ Erro ao conectar no MySQL: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SALVAR LEITURA (via Stored Procedure)
  // ════════════════════════════════════════════════════════════════
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    try {
      final conn = await _getConnection();
      
      // Chamar stored procedure que calcula tudo automaticamente
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
      
      if (leitura.lampadaLigada) {
        print('   💡 ${leitura.qtdLampadasAtivas}x${LeituraSensor.POTENCIA_LAMPADA_W}W ligadas');
        print('   ⚡ Consumo: ${leitura.consumoKwh.toStringAsFixed(4)} kWh');
        print('   💰 Custo: R\$ ${leitura.custoReais.toStringAsFixed(4)}');
      }
      
      // Salvar no Firebase (obrigatório)
      if (FirebaseRealtimeService.isInitialized) {
        await FirebaseRealtimeService.salvarLeitura(leitura);
      }
      
    } catch (e) {
      print('❌ Erro ao salvar leitura: $e');
      print('🔄 Tentando insert direto...');
      await _inserirDireto(leitura);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // INSERT DIRETO (fallback)
  // ════════════════════════════════════════════════════════════════
  static Future<void> _inserirDireto(LeituraSensor leitura) async {
    try {
      final conn = await _getConnection();
      
      // Buscar ID da filial
      final resultadoFilial = await conn.query(
        'SELECT ID_Filial FROM DIM_SENSOR WHERE ID_Sensor = ?',
        [leitura.idSensor]
      );
      
      if (resultadoFilial.isEmpty) {
        throw Exception('Sensor ${leitura.idSensor} não encontrado');
      }
      
      final idFilial = resultadoFilial.first['ID_Filial'];
      final idData = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Inserir DIM_TEMPO
      await _inserirDimTempo(conn, idData, leitura.timestamp);

      // Inserir leitura
      await conn.query(
        '''INSERT INTO FATO_LEITURAS 
           (ID_Sensor, ID_Filial, ID_Data, Temperatura, Umidade, 
            Movimento_Detectado, Lampada_Ligada, 
            Qtd_Lampadas_Ativas, Tempo_Ligado_Min,
            Consumo_kWh, Custo_Reais,
            Timestamp, Qualidade_Sinal, Status_Leitura)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          leitura.idSensor,
          idFilial,
          idData,
          leitura.temperatura,
          leitura.umidade,
          leitura.movimentoDetectado ? 1 : 0,
          leitura.lampadaLigada ? 1 : 0,
          leitura.qtdLampadasAtivas,
          leitura.tempoLigadoMin,
          leitura.consumoKwh,
          leitura.custoReais,
          leitura.timestamp.toIso8601String(),
          leitura.qualidadeSinal ?? 100,
          leitura.statusLeitura ?? 'Válida'
        ]
      );
      
      print('💾 Leitura salva via insert direto');
      
      // Salvar no Firebase
      if (FirebaseRealtimeService.isInitialized) {
        await FirebaseRealtimeService.salvarLeitura(leitura);
      }
      
    } catch (e) {
      print('❌ Erro no insert direto: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // INSERIR DIM_TEMPO
  // ════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════
  // BUSCAR LEITURAS RECENTES
  // ════════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getLeituras({int limite = 50}) async {
    try {
      final conn = await _getConnection();
      
      final resultado = await conn.query('''
        SELECT fl.*, ds.Tipo_Sensor, ds.Localizacao, df.Nome_Filial
        FROM FATO_LEITURAS fl
        JOIN DIM_SENSOR ds ON fl.ID_Sensor = ds.ID_Sensor
        JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
        ORDER BY fl.Timestamp DESC
        LIMIT ?
      ''', [limite]);
      
      return resultado.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Erro ao buscar leituras: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BUSCAR FILIAIS
  // ════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════
  // BUSCAR SENSORES
  // ════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════
  // ESTATÍSTICAS DO SISTEMA
  // ════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final conn = await _getConnection();
      
      // Total de leituras
      final totalResult = await conn.query('SELECT COUNT(*) as total FROM FATO_LEITURAS');
      final total = totalResult.first['total'];
      
      // Temperatura média
      final tempResult = await conn.query(
        'SELECT AVG(Temperatura) as media FROM FATO_LEITURAS WHERE Temperatura IS NOT NULL'
      );
      final mediaTemp = tempResult.first['media'] ?? 0;
      
      // Umidade média
      final umidResult = await conn.query(
        'SELECT AVG(Umidade) as media FROM FATO_LEITURAS WHERE Umidade IS NOT NULL'
      );
      final mediaUmid = umidResult.first['media'] ?? 0;
      
      // Consumo total
      final consumoResult = await conn.query('SELECT SUM(Consumo_kWh) as total FROM FATO_LEITURAS');
      final consumoTotal = consumoResult.first['total'] ?? 0;
      
      // Custo total
      final custoResult = await conn.query('SELECT SUM(Custo_Reais) as total FROM FATO_LEITURAS');
      final custoTotal = custoResult.first['total'] ?? 0;
      
      // Movimentos detectados
      final movResult = await conn.query(
        'SELECT COUNT(*) as total FROM FATO_LEITURAS WHERE Movimento_Detectado = 1'
      );
      final movimentos = movResult.first['total'];
      
      // Ativações de lâmpadas
      final lampResult = await conn.query(
        'SELECT COUNT(*) as total FROM FATO_LEITURAS WHERE Lampada_Ligada = 1'
      );
      final ativacoes = lampResult.first['total'];
      
      // Filiais ativas
      final filiaisResult = await conn.query('SELECT COUNT(*) as total FROM DIM_FILIAL');
      final totalFiliais = filiaisResult.first['total'];
      
      // Sensores ativos
      final sensoresResult = await conn.query(
        'SELECT COUNT(*) as total FROM DIM_SENSOR WHERE Status = "Ativo"'
      );
      final totalSensores = sensoresResult.first['total'];
      
      return {
        'total_leituras': total,
        'media_temperatura': mediaTemp is num ? mediaTemp.toStringAsFixed(1) : '0.0',
        'media_umidade': mediaUmid is num ? mediaUmid.toStringAsFixed(1) : '0.0',
        'consumo_total_kwh': consumoTotal is num ? consumoTotal.toStringAsFixed(4) : '0.0000',
        'custo_total_reais': custoTotal is num ? custoTotal.toStringAsFixed(2) : '0.00',
        'movimentos_detectados': movimentos,
        'ativacoes_lampadas': ativacoes,
        'filiais_ativas': totalFiliais,
        'sensores_ativos': totalSensores,
      };
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return {
        'total_leituras': 0,
        'media_temperatura': '0.0',
        'media_umidade': '0.0',
        'consumo_total_kwh': '0.0000',
        'custo_total_reais': '0.00',
        'movimentos_detectados': 0,
        'ativacoes_lampadas': 0,
        'filiais_ativas': 0,
        'sensores_ativos': 0,
      };
    }
  }

  // ════════════════════════════════════════════════════════════════
  // RELATÓRIO DE CONSUMO POR FILIAL
  // ════════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getConsumoPorFilial() async {
    try {
      final conn = await _getConnection();
      
      final resultado = await conn.query('''
        SELECT 
          df.Nome_Filial,
          COUNT(*) as total_leituras,
          SUM(CASE WHEN fl.Lampada_Ligada = 1 THEN 1 ELSE 0 END) as ativacoes,
          SUM(fl.Consumo_kWh) as consumo_total_kwh,
          SUM(fl.Custo_Reais) as custo_total_reais,
          AVG(fl.Consumo_kWh) as consumo_medio_kwh,
          MAX(fl.Custo_Reais) as custo_maximo
        FROM FATO_LEITURAS fl
        JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
        GROUP BY df.Nome_Filial
        ORDER BY consumo_total_kwh DESC
      ''');
      
      return resultado.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Erro ao buscar consumo por filial: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FECHAR CONEXÃO
  // ════════════════════════════════════════════════════════════════
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
