import 'package:mysql1/mysql1.dart';
import '../models/leitura_sensor.dart';
import 'firebase_service.dart'; // ← ADICIONE ESTA IMPORT

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
      
      // 🔄 PRIMEIRO: SALVAR NO FIREBASE (EM TEMPO REAL)
      await _salvarNoFirebase(leitura);
      
      // 🔄 DEPOIS: SALVAR NO MYSQL (BACKUP/HISTÓRICO)
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
      print('   💾 MySQL: Salvo via Stored Procedure');
      
    } catch (e) {
      print('   ⚠️ MySQL SP Error: $e');
      print('   🔄 Tentando insert direto...');
      await _inserirDireto(conn!, leitura);
    } finally {
      await conn?.close();
    }
  }

  // 🔥 NOVO MÉTODO: SALVAR NO FIREBASE
  static Future<void> _salvarNoFirebase(LeituraSensor leitura) async {
    try {
      await FirebaseService.salvarLeitura({
        'idSensor': leitura.idSensor,
        'idFilial': leitura.idFilial,
        'filial': leitura.localFilial,
        'temperatura': leitura.temperatura,
        'umidade': leitura.umidade,
        'movimentoDetectado': leitura.movimentoDetectado,
        'lampadaLigada': leitura.lampadaLigada,
        'consumo_kWh': leitura.lampadaLigada ? 0.05 : 0.0,
        'timestamp': leitura.timestamp,
        'fonte': 'MySQL_Em_Tempo_Real',
      });
      print('   🔥 Firebase: Leitura salva em tempo real');
    } catch (e) {
      print('   ⚠️ Firebase Error: $e');
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
      print('   💾 MySQL: Salvo via insert direto');
    } catch (e) {
      print('   ❌ MySQL Insert Error: $e');
    }
  }

  // 🔥 NOVO MÉTODO: SINCRONIZAR DADOS EXISTENTES
  static Future<void> sincronizarDadosExistentes() async {
    MySqlConnection? conn;
    try {
      conn = await MySqlConnection.connect(_settings);
      print('🔄 SINCRONIZANDO DADOS EXISTENTES MYSQL → FIREBASE');
      
      // 1. SINCRONIZAR FILIAIS
      var filiais = await conn.query('SELECT * FROM DIM_FILIAL');
      for (var row in filiais) {
        await FirebaseService.salvarFilial({
          'id': row['ID_Filial'],
          'nome': row['Nome_Filial'],
          'cidade': row['Cidade'],
          'estado': row['Estado'],
          'endereco': row['Endereco'],
          'gerente': row['Gerente'],
          'telefone': row['Telefone'],
          'cep': row['CEP'],
        });
      }
      print('   ✅ ${filiais.length} filiais sincronizadas');

      // 2. SINCRONIZAR SENSORES
      var sensores = await conn.query('''
        SELECT s.*, f.Nome_Filial 
        FROM DIM_SENSOR s 
        JOIN DIM_FILIAL f ON s.ID_Filial = f.ID_Filial
      ''');
      for (var row in sensores) {
        await FirebaseService.salvarSensor({
          'id': row['ID_Sensor'],
          'tipo': row['Tipo_Sensor'],
          'modelo': row['Modelo'],
          'localizacao': row['Localizacao'],
          'idFilial': row['ID_Filial'],
          'filial': row['Nome_Filial'],
          'status': row['Status'],
        });
      }
      print('   ✅ ${sensores.length} sensores sincronizados');

      // 3. SINCRONIZAR LEITURAS RECENTES
      var leituras = await conn.query('''
        SELECT fl.*, f.Nome_Filial, s.Tipo_Sensor 
        FROM FATO_LEITURAS fl
        JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
        JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
        ORDER BY fl.Timestamp DESC 
        LIMIT 200
      ''');
      
      int contador = 0;
      for (var row in leituras) {
        await FirebaseService.salvarLeitura({
          'idLeitura': row['ID_Leitura'],
          'idSensor': row['ID_Sensor'],
          'idFilial': row['ID_Filial'],
          'filial': row['Nome_Filial'],
          'tipoSensor': row['Tipo_Sensor'],
          'temperatura': row['Temperatura'],
          'umidade': row['Umidade'],
          'movimentoDetectado': row['Movimento_Detectado'] == 1,
          'lampadaLigada': row['Lampada_Ligada'] == 1,
          'consumo_kWh': row['Consumo_kWh'],
          'timestamp': row['Timestamp'],
          'qualidadeSinal': row['Qualidade_Sinal'],
          'statusLeitura': row['Status_Leitura'],
          'fonte': 'MySQL_Historico',
        });
        contador++;
        
        // Não sobrecarregar o Firebase
        if (contador % 50 == 0) {
          print('   📦 $contador leituras processadas...');
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      print('   ✅ $contador leituras históricas sincronizadas');
      
      print('🎉 SINCRONIZAÇÃO CONCLUÍDA!');
      
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      await conn?.close();
    }
  }

  // Testar conexão
  static Future<void> testarConexao() async {
    try {
      final conn = await MySqlConnection.connect(_settings);
      final resultado = await conn.query('SELECT COUNT(*) as total FROM DIM_SENSOR');
      print('   ✅ MySQL: Conectado! ${resultado.first['total']} sensores no banco');
      await conn.close();
    } catch (e) {
      print('   ❌ MySQL Connection Error: $e');
      rethrow;
    }
  }
}
