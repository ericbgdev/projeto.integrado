// services/database_service.dart
import 'dart:io';
import 'dart:convert';
import '../models/leitura_sensor.dart';

class DatabaseService {
  static final String _dbFile = 'database.json';
  static final String _logFile = 'leituras_log.txt';
  
  // Simular estrutura do banco
  static Map<String, dynamic> _database = {
    'DIM_FILIAL': [],
    'DIM_SENSOR': [],
    'DIM_TEMPO': [],
    'FATO_LEITURAS': [],
  };

  static Future<void> initialize() async {
    print('📀 Inicializando banco de dados simulado...');
    
    // Carregar dados do arquivo se existir
    try {
      final file = File(_dbFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        _database = Map<String, dynamic>.from(json.decode(content));
        print('✅ Banco carregado: ${_database['FATO_LEITURAS'].length} leituras');
      }
    } catch (e) {
      print('⚠️  Criando novo banco...');
    }
    
    // Inserir dados iniciais do schema
    await _inserirDadosIniciais();
  }

  static Future<void> _inserirDadosIniciais() async {
    if (_database['DIM_FILIAL'].isEmpty) {
      // Inserir filiais do schema
      _database['DIM_FILIAL'].addAll([
        {
          'ID_Filial': 1,
          'Nome_Filial': 'Aguai',
          'Cidade': 'Aguai',
          'Estado': 'SP',
          'Endereco': 'Av. Francisco Gonçalves, 409',
          'Gerente': 'João Silva',
          'Telefone': '(19) 3652-1234',
          'CEP': '13868-000'
        },
        {
          'ID_Filial': 2,
          'Nome_Filial': 'Casa Branca',
          'Cidade': 'Casa Branca',
          'Estado': 'SP',
          'Endereco': 'BLOCO B Estrada Acesso, SP-340',
          'Gerente': 'Maria Santos',
          'Telefone': '(19) 3671-5678',
          'CEP': '13700-000'
        }
      ]);
    }

    if (_database['DIM_SENSOR'].isEmpty) {
      // Inserir sensores do schema
      _database['DIM_SENSOR'].addAll([
        {
          'ID_Sensor': 1,
          'Tipo_Sensor': 'Movimento',
          'Modelo': 'PIR HC-SR501',
          'Localizacao': 'Entrada Principal',
          'ID_Filial': 1,
          'Status': 'Ativo'
        },
        {
          'ID_Sensor': 2,
          'Tipo_Sensor': 'Temperatura/Umidade',
          'Modelo': 'DHT11',
          'Localizacao': 'Sala Principal',
          'ID_Filial': 1,
          'Status': 'Ativo'
        },
        {
          'ID_Sensor': 4,
          'Tipo_Sensor': 'Movimento',
          'Modelo': 'PIR HC-SR501',
          'Localizacao': 'Entrada Principal',
          'ID_Filial': 2,
          'Status': 'Ativo'
        },
        {
          'ID_Sensor': 5,
          'Tipo_Sensor': 'Temperatura/Umidade',
          'Modelo': 'DHT11',
          'Localizacao': 'Sala Principal',
          'ID_Filial': 2,
          'Status': 'Ativo'
        },
        {
          'ID_Sensor': 7,
          'Tipo_Sensor': 'Iluminacao',
          'Modelo': 'LED',
          'Localizacao': 'Entrada Principal',
          'ID_Filial': 1,
          'Status': 'Ativo'
        },
        {
          'ID_Sensor': 8,
          'Tipo_Sensor': 'Iluminacao',
          'Modelo': 'LED',
          'Localizacao': 'Entrada Principal',
          'ID_Filial': 2,
          'Status': 'Ativo'
        }
      ]);
    }

    await _salvarBanco();
    print('✅ Dados iniciais inseridos:');
    print('   - ${_database['DIM_FILIAL'].length} filiais');
    print('   - ${_database['DIM_SENSOR'].length} sensores');
  }

  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    try {
      // Gerar ID_Data baseado no timestamp (simulando DIM_TEMPO)
      final idData = leitura.timestamp.millisecondsSinceEpoch;
      
      // Adicionar à dimensão tempo se não existir
      final periodo = _obterPeriodoDia(leitura.timestamp.hour);
      final tempoEntry = {
        'ID_Data': idData,
        'Data_Completa': leitura.timestamp.toIso8601String(),
        'Ano': leitura.timestamp.year,
        'Mes': leitura.timestamp.month,
        'Dia': leitura.timestamp.day,
        'DiaSemana': _obterDiaSemana(leitura.timestamp.weekday),
        'Hora': leitura.timestamp.hour,
        'Periodo_Dia': periodo,
      };
      
      if (!_database['DIM_TEMPO'].any((t) => t['ID_Data'] == idData)) {
        _database['DIM_TEMPO'].add(tempoEntry);
      }

      // Inserir na fato leituras (simulando stored procedure)
      final novaLeitura = {
        'ID_Leitura': DateTime.now().millisecondsSinceEpoch,
        'ID_Sensor': leitura.idSensor,
        'ID_Filial': leitura.idFilial,
        'ID_Data': idData,
        'Temperatura': leitura.temperatura,
        'Umidade': leitura.umidade,
        'Movimento_Detectado': leitura.movimentoDetectado ? 1 : 0,
        'Lampada_Ligada': leitura.lampadaLigada ? 1 : 0,
        'Consumo_kWh': leitura.lampadaLigada ? 0.0500 : 0.0000,
        'Timestamp': leitura.timestamp.toIso8601String(),
        'Qualidade_Sinal': leitura.qualidadeSinal,
        'Status_Leitura': leitura.statusLeitura,
      };

      _database['FATO_LEITURAS'].add(novaLeitura);

      // Salvar no banco e Firebase
      await _salvarBanco();
      await _salvarLog(leitura);
      await FirebaseService.salvarLeituraSimulada(leitura);

      print('💾 Leitura salva no banco: Sensor ${leitura.idSensor}');
      
    } catch (e) {
      print('❌ Erro ao salvar leitura: $e');
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

  static Future<void> _salvarBanco() async {
    try {
      final file = File(_dbFile);
      await file.writeAsString(json.encode(_database, indent: 2));
    } catch (e) {
      print('Erro ao salvar banco: $e');
    }
  }

  static Future<void> _salvarLog(LeituraSensor leitura) async {
    try {
      final file = File(_logFile);
      final logEntry = '${leitura.timestamp.toIso8601String()} | '
          'Sensor: ${leitura.idSensor} | '
          'Filial: ${leitura.filial} | '
          'Temp: ${leitura.temperatura}°C | '
          'Umid: ${leitura.umidade}% | '
          'Mov: ${leitura.movimentoDetectado} | '
          'Lamp: ${leitura.lampadaLigada}\n';
      
      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Erro ao salvar log: $e');
    }
  }

  // Métodos de consulta
  static List<Map<String, dynamic>> getLeituras() {
    return List.from(_database['FATO_LEITURAS']);
  }

  static List<Map<String, dynamic>> getFiliais() {
    return List.from(_database['DIM_FILIAL']);
  }

  static List<Map<String, dynamic>> getSensores() {
    return List.from(_database['DIM_SENSOR']);
  }

  static Map<String, dynamic> getEstatisticas() {
    final leituras = _database['FATO_LEITURAS'];
    final temps = leituras.where((l) => l['Temperatura'] != null).map((l) => l['Temperatura']).toList();
    final umids = leituras.where((l) => l['Umidade'] != null).map((l) => l['Umidade']).toList();
    
    final mediaTemp = temps.isNotEmpty ? temps.reduce((a, b) => a + b) / temps.length : 0;
    final mediaUmid = umids.isNotEmpty ? umids.reduce((a, b) => a + b) / umids.length : 0;
    
    return {
      'total_leituras': leituras.length,
      'media_temperatura': mediaTemp.toStringAsFixed(1),
      'media_umidade': mediaUmid.toStringAsFixed(1),
      'consumo_total': (leituras.where((l) => l['Lampada_Ligada'] == 1).length * 0.05).toStringAsFixed(2),
      'movimentos_detectados': leituras.where((l) => l['Movimento_Detectado'] == 1).length,
      'filiais_ativas': _database['DIM_FILIAL'].length,
      'sensores_ativos': _database['DIM_SENSOR'].length,
    };
  }
}
