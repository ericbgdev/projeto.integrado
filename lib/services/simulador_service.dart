import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'mysql_service.dart';
import 'firebase_service.dart';

class SimuladorService {
  Random random = Random();
  
  Future<LeituraSensor> gerarLeitura() async {
    // 1. PEGAR DADOS DO EXCEL
    final sensorId = SensoresData.sensores.keys.toList()[random.nextInt(SensoresData.sensores.length)];
    final sensor = SensoresData.sensores[sensorId]!;
    final filial = SensoresData.filiais[sensor['id_filial']]!;

    // 2. GERAR LEITURA SIMULADA
    final leitura = LeituraSensor(
      idSensor: sensorId,
      idFilial: sensor['id_filial'],
      tipoSensor: sensor['tipo'],
      localizacao: sensor['localizacao'],
      filial: filial['nome'],
      temperatura: sensor['tipo'] == 'Temperatura/Umidade' ? 
          (18.0 + random.nextDouble() * 14.0) : null,
      umidade: sensor['tipo'] == 'Temperatura/Umidade' ? 
          (35.0 + random.nextDouble() * 50.0) : null,
      movimentoDetectado: sensor['tipo'] == 'Movimento' ? 
          random.nextDouble() < 0.3 : false,
      lampadaLigada: false,
      timestamp: DateTime.now(),
    );

    // 3. ENVIAR PARA FIREBASE (TEMPO REAL)
    await FirebaseService.salvarLeitura(leitura);
    
    // 4. ENVIAR PARA MYSQL (HISTÓRICO)
    await MySQLService.salvarLeitura(leitura);

    return leitura;
  }
}
