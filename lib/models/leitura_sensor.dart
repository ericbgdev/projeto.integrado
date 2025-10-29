class LeituraSensor {
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
  final double? consumoKwh;
  final int? qualidadeSinal;
  final String? statusLeitura;

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
    this.consumoKwh,
    this.qualidadeSinal = 100,
    this.statusLeitura = 'Válida',
  });

  Map<String, dynamic> toMap() {
    return {
      if (idLeitura != null) 'ID_Leitura': idLeitura,
      'ID_Sensor': idSensor,
      'ID_Filial': idFilial,
      'Temperatura': temperatura,
      'Umidade': umidade,
      'Movimento_Detectado': movimentoDetectado ? 1 : 0,
      'Lampada_Ligada': lampadaLigada ? 1 : 0,
      'Consumo_kWh': consumoKwh ?? (lampadaLigada ? 0.05 : 0.0),
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
      timestamp: DateTime.parse(map['Timestamp']),
      consumoKwh: map['Consumo_kWh'] != null ? double.parse(map['Consumo_kWh'].toString()) : null,
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
}
