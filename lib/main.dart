import 'dart:async';
import 'dart:math';

// Model simplificado
class LeituraSensor {
  final int idSensor;
  final int idFilial;
  final String tipoSensor;
  final String filial;
  final double? temperatura;
  final double? umidade;
  final bool movimentoDetectado;
  final bool lampadaLigada;

  LeituraSensor({
    required this.idSensor,
    required this.idFilial,
    required this.tipoSensor,
    required this.filial,
    this.temperatura,
    this.umidade,
    required this.movimentoDetectado,
    required this.lampadaLigada,
  });

  @override
  String toString() {
    String info = '[$filial] $tipoSensor (ID:$idSensor) | ';
    if (temperatura != null) info += '🌡️${temperatura!.toStringAsFixed(1)}°C ';
    if (umidade != null) info += '💧${umidade!.toStringAsFixed(1)}% ';
    if (movimentoDetectado) info += '🏃MOVIMENTO ';
    if (lampadaLigada) info += '💡LÂMPADA ';
    return info;
  }
}

// Serviço MySQL simplificado
class MySQLService {
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    // Simular salvamento no MySQL
    await Future.delayed(Duration(milliseconds: 100));
    print('   💾 MySQL: Leitura ${leitura.idSensor} salva (simulado)');
  }
}

// Serviço Firebase simplificado  
class FirebaseService {
  static Future<void> salvarLeitura(LeituraSensor leitura) async {
    // Simular salvamento no Firebase
    await Future.delayed(Duration(milliseconds: 100));
    print('   🔥 Firebase: Leitura salva (simulado)');
  }
}

// Simulador principal
class SimuladorService {
  final Random _random = Random();
  final List<Map<String, dynamic>> _sensores = [
    {'id': 1, 'tipo': 'Movimento', 'filial': 'Aguai', 'id_filial': 1},
    {'id': 2, 'tipo': 'Temperatura/Umidade', 'filial': 'Aguai', 'id_filial': 1},
    {'id': 4, 'tipo': 'Movimento', 'filial': 'Casa Branca', 'id_filial': 2},
    {'id': 5, 'tipo': 'Temperatura/Umidade', 'filial': 'Casa Branca', 'id_filial': 2},
  ];

  Future<LeituraSensor> gerarLeitura() async {
    final sensor = _sensores[_random.nextInt(_sensores.length)];
    
    double? temperatura;
    double? umidade;
    bool movimentoDetectado = false;
    bool lampadaLigada = false;

    if (sensor['tipo'] == 'Temperatura/Umidade') {
      temperatura = 18.0 + _random.nextDouble() * 14.0;
      umidade = 35.0 + _random.nextDouble() * 50.0;
    } else {
      movimentoDetectado = _random.nextDouble() < 0.3;
      lampadaLigada = movimentoDetectado;
    }

    final leitura = LeituraSensor(
      idSensor: sensor['id'],
      idFilial: sensor['id_filial'],
      tipoSensor: sensor['tipo'],
      filial: sensor['filial'],
      temperatura: temperatura,
      umidade: umidade,
      movimentoDetectado: movimentoDetectado,
      lampadaLigada: lampadaLigada,
    );

    // Salvar nas bases (simulado)
    await MySQLService.salvarLeitura(leitura);
    await FirebaseService.salvarLeitura(leitura);
    
    return leitura;
  }
}

void main() async {
  print('🚀 SISTEMA PACKBAG - MODO SIMULAÇÃO');
  print('📡 Sensores: PIR HC-SR501 + DHT11');
  print('🏢 Filiais: Aguai e Casa Branca\n');

  final simulador = SimuladorService();
  var contador = 0;

  // Simular por 30 segundos
  final timer = Timer.periodic(Duration(seconds: 3), (timer) async {
    contador++;
    if (contador > 10) {
      timer.cancel();
      print('\n✅ Simulação concluída!');
      return;
    }

    try {
      final leitura = await simulador.gerarLeitura();
      print('${contador}. ${leitura.toString()}');
    } catch (e) {
      print('❌ Erro: $e');
    }
  });
}
