# 🚀 Sistema PackBag - Monitoramento IoT

Sistema integrado de monitoramento IoT com sensores **PIR HC-SR501** (movimento) e **DHT11** (temperatura/umidade) para as filiais Packbag em Aguai e Casa Branca.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange.svg)](https://www.mysql.com/)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime-yellow.svg)](https://firebase.google.com/)

---

## 👥 Equipe

- **Eric Butzloff Gudera** - Integração MySQL e Stored Procedures
- **Gabrielly Cristina dos Reis** - Integração Firebase (Real + Simulado)
- **Lindsay Cristine Oliveira Souza** - Estrutura do Projeto e Configuração

---

## 📋 Índice

- [Características](#-características)
- [Arquitetura](#-arquitetura)
- [Requisitos](#-requisitos)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Uso](#-uso)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Banco de Dados](#-banco-de-dados)
- [Firebase](#-firebase)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Análises SQL](#-análises-sql)
- [To-Do](#-to-do)

---

## ✨ Características

### 🎯 Funcionalidades Principais

- ✅ **Monitoramento em Tempo Real** - Leituras a cada 3 segundos
- ✅ **Dual Storage** - MySQL local + Firebase na nuvem
- ✅ **Sensores Simulados** - PIR HC-SR501 e DHT11
- ✅ **2 Filiais** - Aguai e Casa Branca (SP)
- ✅ **6 Sensores Ativos** - 3 por filial
- ✅ **Stored Procedures** - Otimização de inserções no MySQL
- ✅ **Análises SQL Completas** - 11 tipos de relatórios
- ✅ **Dashboard Visual** - Estatísticas em tempo real

### 📊 Tipos de Sensores

| Sensor | Modelo | Localização | Função |
|--------|--------|-------------|--------|
| Movimento | PIR HC-SR501 | Entrada Principal | Detecta presença |
| Temperatura/Umidade | DHT11 | Sala Principal | Monitora clima |
| Iluminação | LED | Entrada Principal | Controle automático |

---

## 🏗️ Arquitetura

```
┌─────────────┐
│  Sensores   │ (PIR + DHT11)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Dart Puro   │ (Simulador)
└──────┬──────┘
       │
       ├──────────┐
       ▼          ▼
┌──────────┐  ┌──────────┐
│  MySQL   │  │ Firebase │
│  Local   │  │  Cloud   │
└──────────┘  └──────────┘
       │          │
       └────┬─────┘
            ▼
     ┌─────────────┐
     │  Análises   │
     │ Dashboard   │
     └─────────────┘
```

---

## 🔧 Requisitos

### Software Necessário

- **Dart SDK** >= 3.0.0
- **MySQL** 8.0+
- **Git** (para clone do repositório)
- **MySQL Workbench** (recomendado)

### Conta Firebase (Opcional)

Para integração com Firebase Real:
- Conta Google
- Projeto Firebase criado
- Service Account JSON

---

## 📥 Instalação

### 1. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/sistema-packbag.git
cd sistema-packbag
```

### 2. Instale as Dependências

```bash
dart pub get
```

### 3. Configure o Banco MySQL

#### Opção A: MySQL Workbench
1. Abra o MySQL Workbench
2. Execute o arquivo `database/schema.sql`
3. Verifique se o banco `entrega5` foi criado

#### Opção B: Terminal
```bash
mysql -u root -p < database/schema.sql
```

### 4. Insira Dados Iniciais (Opcional)

```bash
mysql -u root -p entrega5 < database/insert_dados.sql
```

---

## ⚙️ Configuração

### 1. Configurar Credenciais MySQL

Edite o arquivo `lib/services/database_service.dart`:

```dart
static final ConnectionSettings _settings = ConnectionSettings(
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'SUA_SENHA_AQUI',  // ← Altere aqui
  db: 'entrega5',
  timeout: Duration(seconds: 30),
);
```

### 2. Configurar Firebase (Opcional)

#### Para usar Firebase Real:

1. Baixe `firebase-credentials.json` do Firebase Console
2. Coloque em: `lib/config/firebase-credentials.json`
3. Edite `pubspec.yaml`:

```yaml
dependencies:
  mysql1: ^0.20.0
  http: ^1.1.0              # ← Adicione
  dart_jsonwebtoken: ^2.12.0 # ← Adicione
```

4. Execute: `dart pub get`

5. Substitua no código:
```dart
// Em database_service.dart
import 'firebase_service.dart';        // ← Remova
import 'firebase_realtime_service.dart'; // ← Adicione
```

#### Para usar Firebase Simulado (padrão):
Não precisa fazer nada! O sistema já usa arquivo local `firebase_data.json`.

---

## 🚀 Uso

### Executar Simulação Principal

```bash
cd lib
dart run main.dart
```

**Saída esperada:**
```
🚀 SISTEMA PACKBAG - DART PURO + MySQL REAL
📡 Sensores: PIR HC-SR501 + DHT11
🏢 Filiais: Aguai e Casa Branca
💾 Banco: entrega5 (MySQL Real) + 🔥 Firebase Simulado

✅ Conectado ao MySQL: entrega5
📊 Tabelas no banco:
   - dim_filial
   - dim_sensor
   - dim_tempo
   - fato_leituras

=== 🎯 INICIANDO SIMULAÇÃO ===

--- 📝 Leitura 1 ---
💾 Leitura salva via SP: Sensor 2
🔥 Leitura sincronizada com Firebase: Aguai
📊 Dados: [Aguai] Temperatura/Umidade (ID:2) | 23.1°C 53.3%
...
```

### Verificar Sistema Completo

```bash
dart run verificar_banco.dart
```

Mostra:
- Status MySQL
- Status Firebase
- Comparação entre ambos
- Conectividade por filial
- Resumo geral

### Executar Análises SQL

No MySQL Workbench, execute:
```bash
database/analise_sql_completa.sql
```

Gera 11 tipos de relatórios completos!

---

## 📁 Estrutura do Projeto

```
sistema-packbag/
│
├── lib/
│   ├── main.dart                          # Ponto de entrada
│   ├── verificar_banco.dart               # Script de verificação
│   │
│   ├── models/                            # Modelos de dados
│   │   ├── filial.dart
│   │   ├── sensor.dart
│   │   └── leitura_sensor.dart
│   │
│   ├── services/                          # Lógica de negócio
│   │   ├── database_service.dart          # MySQL
│   │   ├── firebase_service.dart          # Firebase Simulado
│   │   ├── firebase_realtime_service.dart # Firebase Real
│   │   └── simulador_service.dart         # Gerador de dados
│   │
│   ├── data/                              # Dados estáticos
│   │   └── sensores_data.dart
│   │
│   └── config/                            # Configurações
│       └── firebase-credentials.json      # (não versionado)
│
├── database/                              # Scripts SQL
│   ├── schema.sql                         # Estrutura do banco
│   ├── insert_dados.sql                   # Dados iniciais
│   └── analise_sql_completa.sql           # Análises
│
├── pubspec.yaml                           # Dependências
├── README.md                              # Este arquivo
└── .gitignore                             # Arquivos ignorados

```

---

## 🗄️ Banco de Dados

### Modelo Estrela (Star Schema)

```
        ┌──────────────┐
        │  DIM_FILIAL  │
        └──────┬───────┘
               │
        ┌──────▼───────┐
        │  DIM_SENSOR  │
        └──────┬───────┘
               │
        ┌──────▼────────┐
        │ FATO_LEITURAS │◄─────┐
        └──────┬────────┘      │
               │                │
        ┌──────▼───────┐        │
        │  DIM_TEMPO   │        │
        └──────────────┘        │
                                │
                    (Foreign Keys)
```

### Tabelas

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| `DIM_FILIAL` | 2 | Aguai e Casa Branca |
| `DIM_SENSOR` | 6 | 3 sensores por filial |
| `DIM_TEMPO` | Variável | Dimensão temporal |
| `FATO_LEITURAS` | Crescente | Todas as leituras |

### Stored Procedure

```sql
CALL sp_inserir_leitura(
  p_id_sensor INT,
  p_temperatura DECIMAL(4,1),
  p_umidade DECIMAL(4,1),
  p_movimento TINYINT,
  p_lampada TINYINT
);
```

**Vantagens:**
- ✅ Insere automaticamente na `DIM_TEMPO`
- ✅ Calcula consumo de energia
- ✅ Determina período do dia
- ✅ Otimiza performance

---

## 🔥 Firebase

### Modo Simulado (Padrão)

Armazena dados em `firebase_data.json`:

```json
{
  "leituras": [
    {
      "id": "2_1699123456789",
      "idSensor": 2,
      "filial": "Aguai",
      "temperatura": 24.5,
      "umidade": 62.3,
      "timestamp": "2024-11-11T15:30:45.123Z"
    }
  ]
}
```

### Modo Real (Opcional)

**Estrutura no Firebase Realtime Database:**

```
packbag-iot/
└── leituras/
    ├── -NxYz123abc/
    │   ├── id: "2_1699123456789"
    │   ├── filial: "Aguai"
    │   ├── temperatura: 24.5
    │   └── ...
    └── -NxYz456def/
        └── ...
```

**Vantagens:**
- ✅ Acesso em tempo real
- ✅ Sincronização automática
- ✅ Disponível de qualquer lugar
- ✅ Dashboard no Firebase Console

---

## 📜 Scripts Disponíveis

| Script | Comando | Descrição |
|--------|---------|-----------|
| **Simulação Principal** | `dart run main.dart` | Gera 8 leituras simuladas |
| **Verificação Completa** | `dart run verificar_banco.dart` | Verifica MySQL + Firebase |
| **Teste Firebase** | `dart run test_firebase.dart` | Testa integração Firebase Real |
| **Análise SQL** | MySQL Workbench | Executa `analise_sql_completa.sql` |

---

## 📊 Análises SQL

O arquivo `database/analise_sql_completa.sql` gera **11 relatórios**:

1. **Resumo Geral** - Visão geral do sistema
2. **Análise por Filial** - Desempenho Aguai vs Casa Branca
3. **Análise por Sensor** - Performance de cada tipo
4. **Temperatura/Umidade** - Estatísticas (min, max, média, desvio)
5. **Movimento** - Taxa de detecção e eficiência
6. **Consumo de Energia** - Custos e consumo por filial/sensor
7. **Análise Temporal** - Por hora, dia da semana, período
8. **Alertas** - Temperaturas extremas, sensores inativos
9. **Rankings** - Sensores mais ativos
10. **Tendências** - Correlações e insights
11. **Últimas Leituras** - Visão detalhada recente

---

## 📝 To-Do

### Funcionalidades Futuras

- [ ] Adicionar mais 15 dias de leituras históricas
- [ ] Implementar autenticação de usuários
- [ ] Dashboard web com Flutter
- [ ] Alertas por email/SMS
- [ ] Machine Learning para predições
- [ ] API REST para integração externa
- [ ] Gráficos interativos (Plotly/Chart.js)
- [ ] Exportação de relatórios (PDF/Excel)
- [ ] Modo escuro no dashboard
- [ ] Suporte a mais filiais

### Melhorias Técnicas

- [ ] Testes unitários
- [ ] CI/CD com GitHub Actions
- [ ] Docker para ambiente de desenvolvimento
- [ ] Cache Redis para performance
- [ ] Backup automático do banco
- [ ] Logs estruturados
- [ ] Documentação API

---

## 🐛 Solução de Problemas

### Erro: "Cannot connect to MySQL"

**Solução:**
1. Verifique se o MySQL está rodando:
   ```bash
   mysql -u root -p
   ```
2. Confirme usuário e senha em `database_service.dart`
3. Certifique-se que o banco `entrega5` existe

### Erro: "Firebase credentials not found"

**Solução:**
- Se usar Firebase Real: baixe `firebase-credentials.json`
- Se usar Firebase Simulado: ignore o erro (é normal)

### Erro: "Stored procedure not found"

**Solução:**
Execute novamente o `schema.sql`:
```bash
mysql -u root -p entrega5 < database/schema.sql
```

### Leituras não aparecem

**Solução:**
1. Verifique conexão MySQL
2. Confirme que os sensores estão em `sensores_data.dart`
3. Execute `verificar_banco.dart` para diagnóstico

---

## 📄 Licença

Este projeto é parte do trabalho acadêmico da **UNIFEOB** - Centro Universitário da Fundação de Ensino Octávio Bastos.

---

## 📞 Contato

**Dúvidas ou sugestões?**

- Eric Butzloff Gudera - MySQL Integration
- Gabrielly Cristina dos Reis - Firebase Integration
- Lindsay Cristine Oliveira Souza - Estrutura e Configuração

---

## 🙏 Agradecimentos

- **UNIFEOB** - Pela infraestrutura e suporte
- **Professores** - Pela orientação
- **Packbag** - Pela oportunidade de desenvolvimento real

---

<div align="center">

**🚀 Sistema PackBag - Monitoramento IoT 🚀**

Feito com ❤️ em São João da Boa Vista, SP

</div>
