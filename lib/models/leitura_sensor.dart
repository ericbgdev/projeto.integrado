class LeituraSensor {
  static const int LAMPADAS_POR_FILIAL = 100;
  static const int POTENCIA_LAMPADA_W = 20;
  static const int TEMPO_ATIVACAO_MIN = 10;
  static const double TARIFA_KWH = 0.95;

  final int? idLeitura;
  final int idSensor;
  final int idFilial;
  final String tipoSensor;
  final String localizacao;
  final String filial;
  final double? temperatura;
  final double? umidade;
  final bool movimentoDetectado;
  final bool lampadaLigada;
  final DateTime timestamp;
  final int? qualidadeSinal;
  final String? statusLeitura;
  final int qtdLampadasAtivas;
  final int tempoLigadoMin;
  final double consumoKwh;
  final double custoReais;
  //construtor
  LeituraSensor({
    this.idLeitura,
    required this.idSensor,
    required this.idFilial,
    required this.tipoSensor,
    required this.localizacao,
    required this.filial,
    this.temperatura,
    this.umidade,
    required this.movimentoDetectado,
    required this.lampadaLigada,
    required this.timestamp,
    this.qualidadeSinal = 100,
    this.statusLeitura = 'Válida',
    int? qtdLampadasAtivas,
    int? tempoLigadoMin,
    double? consumoKwh,
    double? custoReais,
  })  : qtdLampadasAtivas = qtdLampadasAtivas ?? (lampadaLigada ? LAMPADAS_POR_FILIAL : 0),
        tempoLigadoMin = tempoLigadoMin ?? (lampadaLigada ? TEMPO_ATIVACAO_MIN : 0),
        consumoKwh = consumoKwh ?? _calcularConsumo(lampadaLigada),
        custoReais = custoReais ?? _calcularCusto(lampadaLigada);

  static double _calcularConsumo(bool ligada) {
    if (!ligada) return 0.0;
    return (POTENCIA_LAMPADA_W * LAMPADAS_POR_FILIAL * (TEMPO_ATIVACAO_MIN / 60.0)) / 1000.0;
  }

  static double _calcularCusto(bool ligada) {
    if (!ligada) return 0.0;
    return _calcularConsumo(ligada) * TARIFA_KWH;
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (idLeitura != null) 'ID_Leitura': idLeitura,
      'ID_Sensor': idSensor,
      'ID_Filial': idFilial,
      'Temperatura': temperatura,
      'Umidade': umidade,
      'Movimento_Detectado': movimentoDetectado ? 1 : 0,
      'Lampada_Ligada': lampadaLigada ? 1 : 0,
      'Qtd_Lampadas_Ativas': qtdLampadasAtivas,
      'Tempo_Ligado_Min': tempoLigadoMin,
      'Consumo_kWh': consumoKwh,
      'Custo_Reais': custoReais,
      'Timestamp': timestamp.toIso8601String(),
      'Qualidade_Sinal': qualidadeSinal,
      'Status_Leitura': statusLeitura,
    };
  }

  factory LeituraSensor.fromMap(Map<String, dynamic> map) {
    return LeituraSensor(
      idLeitura: map['ID_Leitura'],
      idSensor: map['ID_Sensor'],
      idFilial: map['ID_Filial'],
      tipoSensor: map['Tipo_Sensor'] ?? 'Desconhecido',
      localizacao: map['Localizacao'] ?? 'Desconhecida',
      filial: map['Nome_Filial'] ?? 'Desconhecida',
      temperatura: map['Temperatura'] != null ? double.parse(map['Temperatura'].toString()) : null,
      umidade: map['Umidade'] != null ? double.parse(map['Umidade'].toString()) : null,
      movimentoDetectado: map['Movimento_Detectado'] == 1,
      lampadaLigada: map['Lampada_Ligada'] == 1,
      qtdLampadasAtivas: map['Qtd_Lampadas_Ativas'] ?? 0,
      tempoLigadoMin: map['Tempo_Ligado_Min'] ?? 0,
      consumoKwh: map['Consumo_kWh'] != null ? double.parse(map['Consumo_kWh'].toString()) : 0.0,
      custoReais: map['Custo_Reais'] != null ? double.parse(map['Custo_Reais'].toString()) : 0.0,
      timestamp: DateTime.parse(map['Timestamp']),
      qualidadeSinal: map['Qualidade_Sinal'],
      statusLeitura: map['Status_Leitura'],
    );
  }

  @override
  String toString() {
    String info = '[$filial] $tipoSensor (ID:$idSensor) | ';
    
    if (temperatura != null) info += '${temperatura!.toStringAsFixed(1)}°C ';
    if (umidade != null) info += '${umidade!.toStringAsFixed(1)}% ';
    if (movimentoDetectado) info += 'MOVIMENTO ';
    if (lampadaLigada) info += 'LÂMPADA ';
    
    return info;
  }

  String toDetailedString() {
    final buffer = StringBuffer();
    
    buffer.writeln('╔════════════════════════════════════╗');
    buffer.writeln('║  LEITURA SENSOR #$idSensor - $filial');
    buffer.writeln('╠════════════════════════════════════╣');
    buffer.writeln('║  Tipo: $tipoSensor');
    buffer.writeln('║  Localização: $localizacao');
    buffer.writeln('║  Timestamp: ${_formatarTimestamp(timestamp)}');
    buffer.writeln('╠════════════════════════════════════╣');
    
    if (movimentoDetectado || lampadaLigada) {
      buffer.writeln('║  🚨 DETECÇÃO:');
      if (movimentoDetectado) {
        buffer.writeln('║     Movimento: DETECTADO');
      }
      if (lampadaLigada) {
        buffer.writeln('║     Sistema de Iluminação: ATIVO');
      }
    }
    
    if (lampadaLigada) {
      buffer.writeln('║  💡 ILUMINAÇÃO:');
      buffer.writeln('║     Lâmpadas Acionadas: $qtdLampadasAtivas un');
      buffer.writeln('║     Potência Unitária: ${POTENCIA_LAMPADA_W}W');
      buffer.writeln('║     Potência Total: ${qtdLampadasAtivas * POTENCIA_LAMPADA_W}W');
      buffer.writeln('║     Tempo Ligado: $tempoLigadoMin minutos');
      buffer.writeln('║  ⚡ ENERGIA:');
      buffer.writeln('║     Consumo: ${consumoKwh.toStringAsFixed(4)} kWh');
      buffer.writeln('║     Consumo: ${(consumoKwh * 1000).toStringAsFixed(2)} Wh');
      buffer.writeln('║     Tarifa: R\$ ${TARIFA_KWH.toStringAsFixed(2)}/kWh');
      buffer.writeln('║     Custo: R\$ ${custoReais.toStringAsFixed(4)}');
    }
    
    if (temperatura != null || umidade != null) {
      buffer.writeln('║  🌡️  AMBIENTE:');
      if (temperatura != null) {
        buffer.writeln('║     Temperatura: ${temperatura!.toStringAsFixed(1)}°C');
      }
      if (umidade != null) {
        buffer.writeln('║     Umidade: ${umidade!.toStringAsFixed(1)}%');
      }
    }
    
    buffer.writeln('╚════════════════════════════════════╝');
    
    return buffer.toString();
  }

  String _formatarTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
