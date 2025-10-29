class Filial {
  final int id;
  final String nome;
  final String cidade;
  final String estado;
  final String endereco;
  final String gerente;
  final String telefone;
  final String cep;

  Filial({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.estado,
    required this.endereco,
    required this.gerente,
    required this.telefone,
    required this.cep,
  });

  // Converter para Map (ORM - Insert/Update)
  Map<String, dynamic> toMap() {
    return {
      'ID_Filial': id,
      'Nome_Filial': nome,
      'Cidade': cidade,
      'Estado': estado,
      'Endereco': endereco,
      'Gerente': gerente,
      'Telefone': telefone,
      'CEP': cep,
    };
  }

  // Construir a partir do Map (ORM - Select)
  factory Filial.fromMap(Map<String, dynamic> map) {
    return Filial(
      id: map['ID_Filial'],
      nome: map['Nome_Filial'],
      cidade: map['Cidade'],
      estado: map['Estado'],
      endereco: map['Endereco'],
      gerente: map['Gerente'],
      telefone: map['Telefone'],
      cep: map['CEP'],
    );
  }

  @override
  String toString() {
    return 'Filial{id: $id, nome: $nome, cidade: $cidade, estado: $estado}';
  }
}
