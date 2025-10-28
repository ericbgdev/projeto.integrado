import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'mysql_service.dart';
import 'firebase_service.dart';

class SimuladorService {
  final Random _random = Random();
 
  Future<LeituraSensor> gerarLeituraSimulada() async {
    // Escolher sensor aleatório dos dados reais
    final sensoresIds = SensoresData.sensores.keys.toList();
    final sensorId = sensoresIds[_random.nextInt(sensoresIds.length)];
    final sensor = SensoresData.sensores[sensorId]!;
    final filial = SensoresData.filiais[sensor['id_filial']]!;

    // Gerar dados baseados no tipo de sensor
    double? temperatura;
    double? umidade;
    bool movimentoDetectado = false;
    bool lampadaLigada = false;

    switch(sensor['tipo']) {
      case 'Temperatura/Umidade':
        temperatura = 18.0 + _random.nextDouble() * 14.0; // 18-32°C
        umidade = 35.0 + _random.nextDouble() * 50.0; // 35-85%
        break;
     
      case 'Movimento':
        movimentoDetectado = _random.nextDouble() < 0.3; // 30% chance
        lampadaLigada = movimentoDetectado;
        break;
     
      case 'Iluminacao':
        movimentoDetectado = _random.nextDouble() < 0.4; // 40% chance
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

    // SALVAR NAS BASES
    await MySQLService.salvarLeitura(leitura);
    await FirebaseService.salvarLeitura(leitura);
   
    return leitura;
  }
}

