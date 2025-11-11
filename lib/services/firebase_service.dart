// services/firebase_service.dart
import 'dart:io';
import 'dart:convert';
import '../models/leitura_sensor.dart';

class FirebaseService {
  static final String _firebaseFile = 'firebase_data.json';
  static Map<String, dynamic> _firebaseData = {
    'leituras': [],
    'filiais': [],
    'sensores': [],
  };

  static Future<void> initialize() async {
    print('🔥 Inicializando Firebase simulado...');
    
    try {
      final file = File(_firebaseFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        _firebaseData = Map<String, dynamic>.from(json.decode(content));
        print('✅ Firebase carregado: ${_firebaseData['leituras'].length} leituras');
      }
    } catch (e) {
      print('⚠️  Criando novo Firebase...');
    }
    
    await _salvarFirebase();
  }

  static Future<void> salvarLeituraSimulada(LeituraSensor leitura) async {
    try {
      final leituraFirebase = {
        'id': '${leitura.idSensor}_${leitura.timestamp.millisecondsSinceEpoch}',
        'idSensor': leitura.idSensor,
        'idFilial': leitura.idFilial,
        'filial': leitura.filial,
        'tipoSensor': leitura.tipoSensor,
        'localizacao': leitura.localizacao,
        'temperatura': leitura.temperatura,
        'umidade': leitura.umidade,
        'movimentoDetectado': leitura.movimentoDetectado,
        'lampadaLigada': leitura.lampadaLigada,
        'consumo_kWh': leitura.lampadaLigada ? 0.05 : 0.0,
        'timestamp': leitura.timestamp.toIso8601String(),
        'qualidadeSinal': leitura.qualidadeSinal,
        'statusLeitura': leitura.statusLeitura,
        'sincronizadoEm': DateTime.now().toIso8601String(),
        'fonte': 'Dart_Puro_Simulacao',
      };

      _firebaseData['leituras'].add(leituraFirebase);
      await _salvarFirebase();
      
      print('🔥 Leitura sincronizada com Firebase: ${leitura.filial}');
      
    } catch (e) {
      print('❌ Erro Firebase: $e');
    }
  }

  static Future<void> _salvarFirebase() async {
    try {
      final file = File(_firebaseFile);
      await file.writeAsString(json.encode(_firebaseData, indent: 2));
    } catch (e) {
      print('Erro ao salvar Firebase: $e');
    }
  }

  static List<Map<String, dynamic>> getLeiturasFirebase() {
    return List.from(_firebaseData['leituras']);
  }

  static Future<void> testarConexao() async {
    print('🔥 Testando conexão com Firebase...');
    await Future.delayed(Duration(milliseconds: 500));
    print('✅ Firebase conectado!');
  }
}
