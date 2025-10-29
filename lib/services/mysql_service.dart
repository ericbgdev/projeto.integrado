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
    db: 'pi-entrega5',
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

  static Future<void> _inserirDireto(MySqlConnection conn, LeituraSensor leitura) async {
    try {
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
      print('MySQL: Salvo via insert direto');
    } catch (e) {
      print('MySQL Insert Error: $e');
    }
  }

  static Future<List<LeituraSensor>> buscarLeituras({int? idFilial, int limite = 50}) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      String query = '''
        SELECT fl.*, f.Nome_Filial, s.Tipo_Sensor, s.Localizacao 
        FROM FATO_LEITURAS fl
        JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
        JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
      ''';
      
      if (idFilial != null) {
        query += ' WHERE fl.ID_Filial = ?';
      }
      
      query += ' ORDER BY fl.Timestamp DESC LIMIT ?';
      
      var resultados = await conn.query(
        query, 
        idFilial != null ? [idFilial, limite] : [limite]
      );
      
      return resultados.map((row) => LeituraSensor.fromMap(row.fields)).toList();
      
    } catch (e) {
      print('Erro ao buscar leituras: $e');
      return [];
    } finally {
      await conn?.close();
    }
  }

  static Future<List<LeituraSensor>> buscarLeiturasPorSensor(int idSensor, {int limite = 20}) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      var resultados = await conn.query('''
        SELECT fl.*, f.Nome_Filial, s.Tipo_Sensor, s.Localizacao 
        FROM FATO_LEITURAS fl
        JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
        JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
        WHERE fl.ID_Sensor = ?
        ORDER BY fl.Timestamp DESC 
        LIMIT ?
      ''', [idSensor, limite]);
      
      return resultados.map((row) => LeituraSensor.fromMap(row.fields)).toList();
      
    } catch (e) {
      print('Erro ao buscar leituras do sensor: $e');
      return [];
    } finally {
      await conn?.close();
    }
  }

  static Future<List<Filial>> buscarFiliais() async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      var resultados = await conn.query('SELECT * FROM DIM_FILIAL ORDER BY Nome_Filial');
      
      return resultados.map((row) => Filial.fromMap(row.fields)).toList();
      
    } catch (e) {
      print('Erro ao buscar filiais: $e');
      return [];
    } finally {
      await conn?.close();
    }
  }

  static Future<Filial?> buscarFilialPorId(int id) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      var resultados = await conn.query(
        'SELECT * FROM DIM_FILIAL WHERE ID_Filial = ?', 
        [id]
      );
      
      if (resultados.isNotEmpty) {
        return Filial.fromMap(resultados.first.fields);
      }
      return null;
      
    } catch (e) {
      print('Erro ao buscar filial: $e');
      return null;
    } finally {
      await conn?.close();
    }
  }

  static Future<List<Sensor>> buscarSensores({int? idFilial}) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      String query = 'SELECT * FROM DIM_SENSOR WHERE Status = "Ativo"';
      List<dynamic> params = [];
      
      if (idFilial != null) {
        query += ' AND ID_Filial = ?';
        params.add(idFilial);
      }
      
      query += ' ORDER BY ID_Sensor';
      
      var resultados = await conn.query(query, params);
      
      return resultados.map((row) => Sensor.fromMap(row.fields)).toList();
      
    } catch (e) {
      print('Erro ao buscar sensores: $e');
      return [];
    } finally {
      await conn?.close();
    }
  }

  static Future<Sensor?> buscarSensorPorId(int id) async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      
      var resultados = await conn.query(
        'SELECT * FROM DIM_SENSOR WHERE ID_Sensor = ?', 
        [id]
      );
      
      if (resultados.isNotEmpty) {
        return Sensor.fromMap(resultados.first.fields);
      }
      return null;
      
    } catch (e) {
      print('Erro ao buscar sensor: $e');
      return null;
    } finally {
      await conn?.close();
    }
  }

  static Future<void> sincronizarDadosExistentes() async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      print('SINCRONIZANDO DADOS EXISTENTES MYSQL -> FIREBASE');
      
      var filiais = await buscarFiliais();
      for (var filial in filiais) {
        await FirebaseService.salvarFilial(filial.toMap());
      }
      print('${filiais.length} filiais sincronizadas');

      var sensores = await buscarSensores();
      for (var sensor in sensores) {
        var filial = await buscarFilialPorId(sensor.idFilial);
        await FirebaseService.salvarSensor({
          ...sensor.toMap(),
          'filial': filial?.nome ?? 'Desconhecida',
        });
      }
      print('${sensores.length} sensores sincronizados');

      var leituras = await buscarLeituras(limite: 200);
      int contador = 0;
      
      for (var leitura in leituras) {
        await FirebaseService.salvarLeitura({
          'idLeitura': leitura.idLeitura,
          'idSensor': leitura.idSensor,
          'idFilial': leitura.idFilial,
          'filial': leitura.filial,
          'tipoSensor': leitura.tipoSensor,
          'temperatura': leitura.temperatura,
          'umidade': leitura.umidade,
          'movimentoDetectado': leitura.movimentoDetectado,
          'lampadaLigada': leitura.lampadaLigada,
          'consumo_kWh': leitura.consumoKwh,
          'timestamp': leitura.timestamp,
          'qualidadeSinal': leitura.qualidadeSinal,
          'statusLeitura': leitura.statusLeitura,
          'fonte': 'MySQL_Historico',
        });
        contador++;
        
        if (contador % 50 == 0) {
          print('$contador leituras processadas...');
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      print('$contador leituras historicas sincronizadas');
      print('SINCRONIZACAO CONCLUIDA!');
      
    } catch (e) {
      print('Erro na sincronizacao: $e');
    } finally {
      await conn?.close();
    }
  }

  static Future<void> testarConexao() async {
    try {
      final conn = await MySqlConnection.connect(_settings);
      final resultado = await conn.query('SELECT COUNT(*) as total FROM DIM_SENSOR');
      print('MySQL: Conectado! ${resultado.first['total']} sensores no banco');
      await conn.close();
    } catch (e) {
      print('MySQL Connection Error: $e');
      rethrow;
    }
  }
}
