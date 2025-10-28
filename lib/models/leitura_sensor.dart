class LeituraSensor {
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

  LeituraSensor({
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
