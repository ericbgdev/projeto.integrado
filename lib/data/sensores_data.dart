class SensoresData {
  static final Map<int, Map<String, dynamic>> filiais = {
    1: {
      'id': 1, 'nome': 'Aguai', 'cidade': 'Aguai', 'estado': 'SP',
      'endereco': 'Av. Francisco Gonçalves, 409', 'gerente': 'João Silva'
    },
    2: {
      'id': 2, 'nome': 'Casa Branca', 'cidade': 'Casa Branca', 'estado': 'SP', 
      'endereco': 'BLOCO B Estrada Acesso, SP-340', 'gerente': 'Maria Santos'
    }
  };

  static final Map<int, Map<String, dynamic>> sensores = {
    1: {'id': 1, 'tipo': 'Movimento', 'modelo': 'PIR HC-SR501', 'localizacao': 'Entrada Principal', 'id_filial': 1},
    2: {'id': 2, 'tipo': 'Temperatura/Umidade', 'modelo': 'DHT11', 'localizacao': 'Sala Principal', 'id_filial': 1},
    4: {'id': 4, 'tipo': 'Movimento', 'modelo': 'PIR HC-SR501', 'localizacao': 'Entrada Principal', 'id_filial': 2},
    5: {'id': 5, 'tipo': 'Temperatura/Umidade', 'modelo': 'DHT11', 'localizacao': 'Sala Principal', 'id_filial': 2},
    7: {'id': 7, 'tipo': 'Iluminacao', 'modelo': 'LED', 'localizacao': 'Entrada Principal', 'id_filial': 1},
    8: {'id': 8, 'tipo': 'Iluminacao', 'modelo': 'LED', 'localizacao': 'Entrada Principal', 'id_filial': 2},
  };
}
