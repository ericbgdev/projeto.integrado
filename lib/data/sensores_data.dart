class SensoresData {
  static final Map<int, Map<String, dynamic>> filiais = {
    1: {
      'id': 1, 'nome': 'Aguai', 'cidade': 'Aguai', 'estado': 'SP',
      'endereco': 'Av. Francisco Gonçalves, 409', 'gerente': 'João Silva',
      'telefone': '(19) 3652-1234', 'cep': '13868-000'
    },
    2: {
      'id': 2, 'nome': 'Casa Branca', 'cidade': 'Casa Branca', 'estado': 'SP', 
      'endereco': 'BLOCO B Estrada Acesso, SP-340', 'gerente': 'Maria Santos',
      'telefone': '(19) 3671-5678', 'cep': '13700-000'
    }
  };

  static final Map<int, Map<String, dynamic>> sensores = {
    1: {'id': 1, 'tipo': 'Movimento', 'modelo': 'PIR HC-SR501', 'localizacao': 'Entrada Principal', 'id_filial': 1, 'status': 'Ativo'},
    2: {'id': 2, 'tipo': 'Temperatura/Umidade', 'modelo': 'DHT11', 'localizacao': 'Sala Principal', 'id_filial': 1, 'status': 'Ativo'},
    4: {'id': 4, 'tipo': 'Movimento', 'modelo': 'PIR HC-SR501', 'localizacao': 'Entrada Principal', 'id_filial': 2, 'status': 'Ativo'},
    5: {'id': 5, 'tipo': 'Temperatura/Umidade', 'modelo': 'DHT11', 'localizacao': 'Sala Principal', 'id_filial': 2, 'status': 'Ativo'},
    7: {'id': 7, 'tipo': 'Iluminacao', 'modelo': 'LED', 'localizacao': 'Entrada Principal', 'id_filial': 1, 'status': 'Ativo'},
    8: {'id': 8, 'tipo': 'Iluminacao', 'modelo': 'LED', 'localizacao': 'Entrada Principal', 'id_filial': 2, 'status': 'Ativo'},
  };
}
