import 'dart:math';
import '../models/leitura_sensor.dart';
import '../utils/constants.dart';

class SimuladorService {
  final Random _random = Random();
  final Map<String, DateTime> _ultimoMovimento = {};

  // Gerar leitura simulada
  LeituraSensor gerarLeituraSimulada() {
    // Escolher filial aleatória
    final filial = AppConstants.filiais[_random.nextInt(AppConstants.filiais.length)];
    
    // Gerar valores do DHT11
    final temperatura = AppConstants.temperaturaMin +
        _random.nextDouble() * (AppConstants.temperaturaMax - AppConstants.temperaturaMin);
    
    final umidade = AppConstants.umidadeMin +
        _random.nextDouble() * (AppConstants.umidadeMax - AppConstants.umidadeMin);

    // Simular PIR HC-SR501 (30% de chance de movimento)
    final movimentoDetectado = _random.nextDouble() < 0.3;

    // Controlar lâmpada baseado no movimento
    final agora = DateTime.now();
    bool lampada = movimentoDetectado;

    if (movimentoDetectado) {
      _ultimoMovimento[filial] = agora;
    } else if (_ultimoMovimento.containsKey(filial)) {
      final segundosDesdeMovimento = agora.difference(_ultimoMovimento[filial]!).inSeconds;
      // Lâmpada fica ligada por 30 segundos após movimento
      lampada = segundosDesdeMovimento < 30;
    }

    // IDs de sensor baseados na filial
    final idSensor = filial == 'Aguai' 
        ? (_random.nextBool() ? 1 : 2)  // Sensores 1 ou 2 para Aguai
        : (_random.nextBool() ? 4 : 5); // Sensores 4 ou 5 para Casa Branca

    return LeituraSensor(
      temperatura: double.parse(temperatura.toStringAsFixed(1)),
      umidade: double.parse(umidade.toStringAsFixed(1)),
      movimentoDetectado: movimentoDetectado,
      lampada: lampada,
      timestamp: agora,
      localFilial: filial,
      idSensor: idSensor,
    );
  }

  // Gerar múltiplas leituras para teste
  List<LeituraSensor> gerarLeiturasDeTeste(int quantidade) {
    return List.generate(quantidade, (index) => gerarLeituraSimulada());
  }
}
