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
}
