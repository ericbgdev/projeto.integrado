import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'database_service.dart';
import 'firebase_realtime_service.dart'; // ← MUDANÇA AQUI

class SimuladorService {
  final Random _random = Random();
  bool _conexoesTestadas = false;
  
  Future<LeituraSensor> gerarLeituraSimulada() async {
    if (!_conexoesTestadas) {
      await _testarConexoes();
      _conexoesTestadas = true;
    }

    final sensoresIds = SensoresData.sensores.keys.toList();
    final sensorId = sensoresIds[_random.nextInt(sensoresIds.length)];
    final sensor = SensoresData.sensores[sensorId]!;
    final filial = SensoresData.filiais[sensor['id_filial']]!;

    double? temperatura;
    double? umidade;
    bool movimentoDetectado = false;
    bool lampadaLigada = false;

    switch(sensor['tipo']) {
      case 'Temperatura/Umidade':
        temperatura = 18.0 + _random.nextDouble() * 14.0;
        umidade = 35.0 + _random.nextDouble() * 50.0;
        if (_random.nextDouble() < 0.1) temperatura = 33.0 + _random.nextDouble() * 5.0;
        if (_random.nextDouble() < 0.1) umidade = 90.0 + _random.nextDouble() * 8.0;
        break;
      
      case 'Movimento':
        movimentoDetectado = _random.nextDouble() < 0.3;
        lampadaLigada = movimentoDetectado;
        break;
      
      case 'Iluminacao':
        movimentoDetectado = _random.nextDouble() < 0.4;
        lampadaLigada = movimentoDetectado;
        break;
    }

    final leitura = LeituraSensor(
      idSensor: sensorId,
      idFilial: sensor['id_filial'],
      tipoSensor: sensor['tipo'],
      localizacao: sensor['localizacao'],
      filial: filial['nome'],
      temperatura: temperatura,
      umidade: umidade,
      movimentoDetectado: movimentoDetectado,
      lampadaLigada: lampadaLigada,
      timestamp: DateTime.now(),
    );

    await DatabaseService.salvarLeitura(leitura);
    
    return leitura;
  }

  Future<void> _testarConexoes() async {
    print('🔌 Testando conexões...');
    await DatabaseService.testarConexao();
    await FirebaseRealtimeService.testarConexao(); // ← MUDANÇA AQUI
  }
}
