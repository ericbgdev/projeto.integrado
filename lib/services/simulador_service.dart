import 'dart:math';
import '../models/leitura_sensor.dart';
import '../data/sensores_data.dart';
import 'database_service.dart';

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
        if (_random.nextDouble() < 0.1) {
          temperatura = 33.0 + _random.nextDouble() * 5.0;
        }
        
        umidade = 35.0 + _random.nextDouble() * 50.0;
        if (_random.nextDouble() < 0.1) {
          umidade = 90.0 + _random.nextDouble() * 8.0;
        }
        break;
      
      case 'Movimento':
        movimentoDetectado = _random.nextDouble() < 0.4;
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
      qualidadeSinal: 90 + _random.nextInt(11),
    );

    await DatabaseService.salvarLeitura(leitura);
    
    return leitura;
  }

  Future<void> _testarConexoes() async {
    print('Testando conexões...\n');
    
    try {
      await DatabaseService.testarConexao();
      print('');
    } catch (e) {
      print('Erro ao testar MySQL: $e');
      rethrow;
    }
  }

  Future<void> exibirEstatisticas() async {
    print('\n═══════════════════════════════════════════════════════════');
    print('ESTATÍSTICAS DO SISTEMA');
    print('═══════════════════════════════════════════════════════════\n');
    
    try {
      final stats = await DatabaseService.getEstatisticas();
      
      print('GERAL:');
      stats.forEach((key, value) {
        final label = key.replaceAll('_', ' ').toUpperCase();
        print('   $label: $value');
      });
      
      print('\n CONFIGURAÇÃO DO SISTEMA:');
      print('   Lâmpadas por filial: ${LeituraSensor.LAMPADAS_POR_FILIAL} unidades');
      print('   Potência unitária: ${LeituraSensor.POTENCIA_LAMPADA_W}W');
      print('   Tempo de ativação: ${LeituraSensor.TEMPO_ATIVACAO_MIN} minutos');
      print('   Tarifa de energia: R\$ ${LeituraSensor.TARIFA_KWH}/kWh');
      
      final consumoPorAtivacao = (LeituraSensor.POTENCIA_LAMPADA_W * 
                                   LeituraSensor.LAMPADAS_POR_FILIAL * 
                                   (LeituraSensor.TEMPO_ATIVACAO_MIN / 60.0)) / 1000.0;
      final custoPorAtivacao = consumoPorAtivacao * LeituraSensor.TARIFA_KWH;
      
      print('   Consumo por ativação: ${consumoPorAtivacao.toStringAsFixed(4)} kWh');
      print('   Custo por ativação: R\$ ${custoPorAtivacao.toStringAsFixed(4)}');
      
      print('\n ANÁLISE POR FILIAL:');
      final consumoPorFilial = await DatabaseService.getConsumoPorFilial();
      
      if (consumoPorFilial.isEmpty) {
        print('Nenhum dado de consumo disponível');
      } else {
        for (final filial in consumoPorFilial) {
          final nomeFilial = filial['Nome_Filial']?.toString() ?? 'Desconhecida';
          final totalLeituras = filial['total_leituras']?.toString() ?? '0';
          final ativacoes = filial['ativacoes']?.toString() ?? '0';
          
          final consumoStr = filial['consumo_total_kwh']?.toString() ?? '0.0';
          final custoStr = filial['custo_total_reais']?.toString() ?? '0.0';
          
          double consumo = 0.0;
          double custo = 0.0;
          
          try {
            consumo = double.parse(consumoStr);
          } catch (e) {
            consumo = 0.0;
          }
          
          try {
            custo = double.parse(custoStr);
          } catch (e) {
            custo = 0.0;
          }
          
          print('   $nomeFilial:');
          print('      Leituras: $totalLeituras');
          print('      Ativações: $ativacoes');
          print('      Consumo: ${consumo.toStringAsFixed(4)} kWh');
          print('      Custo: R\$ ${custo.toStringAsFixed(2)}');
        }
      }
      
    } catch (e) {
      print('Erro ao exibir estatísticas: $e');
      print('Continuando...');
    }
    
    print('\n═══════════════════════════════════════════════════════════\n');
  }
}
