
class SensoresData {
  static final Map<int, Map<String, dynamic>> filiais = {
    1: {
      'id': 1,
      'nome': 'Aguai',
      'cidade': 'Aguai',
      'estado': 'SP',
      'endereco': 'Av. Francisco Gonçalves, 409',
      'gerente': 'João Silva',
      'telefone': '(19) 3652-1234',
      'cep': '13868-000',
      'qtd_lampadas': 100,
      'potencia_lampada_w': 20,
      'tempo_ativacao_min': 10,
    },
    2: {
      'id': 2,
      'nome': 'Casa Branca',
      'cidade': 'Casa Branca',
      'estado': 'SP',
      'endereco': 'BLOCO B Estrada Acesso, SP-340',
      'gerente': 'Maria Santos',
      'telefone': '(19) 3671-5678',
      'cep': '13700-000',
      'qtd_lampadas': 100,
      'potencia_lampada_w': 20,
      'tempo_ativacao_min': 10,
    }
  };
  static final Map<int, Map<String, dynamic>> sensores = {
    //aguai
    1: {
      'id': 1,
      'tipo': 'Movimento',
      'modelo': 'PIR HC-SR501',
      'localizacao': 'Entrada Principal',
      'id_filial': 1,
      'status': 'Ativo',
      'descricao': 'Sensor de movimento por infravermelho passivo',
      'alcance_metros': 7,
    },
    2: {
      'id': 2,
      'tipo': 'Temperatura/Umidade',
      'modelo': 'DHT11',
      'localizacao': 'Sala Principal',
      'id_filial': 1,
      'status': 'Ativo',
      'descricao': 'Sensor de temperatura e umidade digital',
      'precisao_temp': '±2°C',
      'precisao_umid': '±5%',
    },
    7: {
      'id': 7,
      'tipo': 'Iluminacao',
      'modelo': 'LED Sistema 100x20W',
      'localizacao': 'Entrada Principal',
      'id_filial': 1,
      'status': 'Ativo',
      'descricao': 'Sistema de iluminação LED inteligente',
      'qtd_lampadas': 100,
      'potencia_total_w': 2000,
    },

    //casabranca
    4: {
      'id': 4,
      'tipo': 'Movimento',
      'modelo': 'PIR HC-SR501',
      'localizacao': 'Entrada Principal',
      'id_filial': 2,
      'status': 'Ativo',
      'descricao': 'Sensor de movimento por infravermelho passivo',
      'alcance_metros': 7,
    },
    5: {
      'id': 5,
      'tipo': 'Temperatura/Umidade',
      'modelo': 'DHT11',
      'localizacao': 'Sala Principal',
      'id_filial': 2,
      'status': 'Ativo',
      'descricao': 'Sensor de temperatura e umidade digital',
      'precisao_temp': '±2°C',
      'precisao_umid': '±5%',
    },
    8: {
      'id': 8,
      'tipo': 'Iluminacao',
      'modelo': 'LED Sistema 100x20W',
      'localizacao': 'Entrada Principal',
      'id_filial': 2,
      'status': 'Ativo',
      'descricao': 'Sistema de iluminação LED inteligente',
      'qtd_lampadas': 100,
      'potencia_total_w': 2000,
    },
  };
//configs
  static const Map<String, dynamic> configuracaoSistema = {
    'versao': '2.0',
    'nome': 'Sistema Packbag IoT',
    'lampadas_por_filial': 100,
    'potencia_lampada_w': 20,
    'tempo_ativacao_min': 10,
    'tarifa_kwh': 0.95,
    'consumo_por_ativacao_kwh': 0.33,
    'custo_por_ativacao_reais': 0.3135,
    'intervalo_leitura_seg': 3,
  };
  
  static String getNomeFilial(int idFilial) {
    return filiais[idFilial]?['nome'] ?? 'Desconhecida';
  }
  static List<int> getSensoresPorFilial(int idFilial) {
    return sensores.entries
        .where((entry) => entry.value['id_filial'] == idFilial)
        .map((entry) => entry.key)
        .toList();
  }

  static List<int> getSensoresPorTipo(String tipo) {
    return sensores.entries
        .where((entry) => entry.value['tipo'] == tipo)
        .map((entry) => entry.key)
        .toList();
  }
  static int getTotalSensoresAtivos() {
    return sensores.values
        .where((sensor) => sensor['status'] == 'Ativo')
        .length;
  }
  static String getInfoSistema() {
    final config = configuracaoSistema;
    return '''
╔════════════════════════════════════════════════════════════════╗
║  CONFIGURAÇÃO DO SISTEMA PACKBAG                               ║
╠════════════════════════════════════════════════════════════════╣
║  Versão: ${config['versao']}                                                         ║
║  Nome: ${config['nome']}                                  ║
║                                                                ║
║  💡 ILUMINAÇÃO:                                                ║
║     • Lâmpadas por filial: ${config['lampadas_por_filial']} unidades                       ║
║     • Potência unitária: ${config['potencia_lampada_w']}W                                  ║
║     • Tempo de ativação: ${config['tempo_ativacao_min']} minutos                          ║
║                                                                ║
║  ⚡ ENERGIA:                                                    ║
║     • Tarifa: R\$ ${config['tarifa_kwh']}/kWh                                   ║
║     • Consumo por ativação: ${config['consumo_por_ativacao_kwh']} kWh                      ║
║     • Custo por ativação: R\$ ${config['custo_por_ativacao_reais']}                    ║
║                                                                ║
║  📊 OPERAÇÃO:                                                  ║
║     • Intervalo de leitura: ${config['intervalo_leitura_seg']} segundos                       ║
║     • Filiais ativas: ${filiais.length}                                          ║
║     • Sensores ativos: ${getTotalSensoresAtivos()}                                       ║
╚════════════════════════════════════════════════════════════════╝
''';
  }
  static String getResumoFiliais() {
    final buffer = StringBuffer();
    buffer.writeln('🏢 FILIAIS PACKBAG:\n');
    
    filiais.forEach((id, filial) {
      buffer.writeln('   ${filial['nome']} (ID: $id)');
      buffer.writeln('   📍 ${filial['endereco']}');
      buffer.writeln('   🏙️  ${filial['cidade']}/${filial['estado']} - CEP: ${filial['cep']}');
      buffer.writeln('   👤 Gerente: ${filial['gerente']}');
      buffer.writeln('   📞 ${filial['telefone']}');
      buffer.writeln('   💡 ${filial['qtd_lampadas']}x${filial['potencia_lampada_w']}W '
                      '(${filial['tempo_ativacao_min']}min)');
      
      final sensoresFilial = getSensoresPorFilial(id);
      buffer.writeln('   📡 Sensores: ${sensoresFilial.length} unidades');
      buffer.writeln('');
    });
    
    return buffer.toString();
  }
  static String getResumoSensores() {
    final buffer = StringBuffer();
    buffer.writeln('📡 SENSORES DO SISTEMA:\n');
    
    sensores.forEach((id, sensor) {
      final filial = getNomeFilial(sensor['id_filial']);
      final status = sensor['status'] == 'Ativo' ? '✅' : '⚠️';
      
      buffer.writeln('   $status Sensor #$id - ${sensor['tipo']}');
      buffer.writeln('      Modelo: ${sensor['modelo']}');
      buffer.writeln('      Localização: ${sensor['localizacao']} - $filial');
      buffer.writeln('      Status: ${sensor['status']}');
      
      if (sensor['tipo'] == 'Iluminacao') {
        buffer.writeln('      💡 ${sensor['qtd_lampadas']} lâmpadas '
                        '(${sensor['potencia_total_w']}W total)');
      }
      
      buffer.writeln('');
    });
    
    return buffer.toString();
  }
}
