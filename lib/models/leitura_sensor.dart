class LeituraSensor {
  final double temperatura;
  final double umidade;
  final bool movimentoDetectado;
  final bool lampada;
  final String localFilial;

  LeituraSensor({
    required this.temperatura,
    required this.umidade,
    required this.movimentoDetectado,
    required this.lampada,
    required this.localFilial,
  });

  @override
  String toString() {
    return 'Leitura[$localFilial]: ${temperatura}C, ${umidade}%, Mov: $movimentoDetectado, Lamp: $lampada';
  }
}
