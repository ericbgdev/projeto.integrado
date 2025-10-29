class Sensor {
  final int id;
  final String tipo;
  final String modelo;
  final String localizacao;
  final int idFilial;
  final String status;

  Sensor({
    required this.id,
    required this.tipo,
    required this.modelo,
    required this.localizacao,
    required this.idFilial,
    required this.status,
  });

  // Converter para Map (ORM)
  Map<String, dynamic> toMap() {
    return {
      'ID_Sensor': id,
      'Tipo_Sensor': tipo,
      'Modelo': modelo,
      'Localizacao': localizacao,
      'ID_Filial': idFilial,
      'Status': status,
    };
  }

  // Construir a partir do Map (ORM)
  factory Sensor.fromMap(Map<String, dynamic> map) {
    return Sensor(
      id: map['ID_Sensor'],
      tipo: map['Tipo_Sensor'],
      modelo: map['Modelo'],
      localizacao: map['Localizacao'],
      idFilial: map['ID_Filial'],
      status: map['Status'],
    );
  }

  @override
  String toString() {
    return 'Sensor{id: $id, tipo: $tipo, modelo: $modelo, localizacao: $localizacao, idFilial: $idFilial}';
  }
}
