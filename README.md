# Sistema PackBag - Monitoramento IoT v2.0

Sistema integrado de monitoramento IoT com **100 lâmpadas LED 20W** por filial, sensores **PIR HC-SR501** (movimento) e **DHT11** (temperatura/umidade) para as filiais Packbag em Aguai e Casa Branca.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange.svg)](https://www.mysql.com/)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime-yellow.svg)](https://firebase.google.com/)

---

## NOVIDADE v2.0 - Sistema de Iluminação Inteligente

### Especificações Técnicas

| Parâmetro | Valor |
|-----------|-------|
| **Lâmpadas por filial** | 100 unidades |
| **Potência unitária** | 20W |
| **Potência total** | 2000W (2 kW) |
| **Tempo de ativação** | 10 minutos |
| **Consumo por ativação** | 0.33 kWh |
| **Tarifa de energia** | R$ 0,95/kWh |
| **Custo por ativação** | R$ 0,3135 |

### Cálculo do Consumo

```
Consumo = (Potência × Quantidade × Tempo) ÷ 1000
Consumo = (20W × 100 × 10min) ÷ 1000
Consumo = (20W × 100 × 0.167h) ÷ 1000
Consumo = 0.33 kWh

Custo = Consumo × Tarifa
Custo = 0.33 kWh × R$ 0,95
Custo = R$ 0,3135 por ativação
```

---

## Equipe

- **Eric Butzloff Gudera** - Integração MySQL e Stored Procedures
- **Gabrielly Cristina dos Reis** - Integração Firebase (Real + Simulado)
- **Lindsay Cristine Oliveira Souza** - Estrutura do Projeto e Configuração

---

## Índice

- [Características](#-características)
- [Arquitetura](#-arquitetura)
- [Requisitos](#-requisitos)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Uso](#-uso)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Banco de Dados](#-banco-de-dados)
- [Firebase](#-firebase)
- [Análise de Custos](#-análise-de-custos)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Solução de Problemas](#-solução-de-problemas)

---

## Características

### Funcionalidades Principais

- **Monitoramento em Tempo Real** - Leituras a cada 3 segundos
- **Dual Storage** - MySQL local + Firebase na nuvem
- **Sensores Simulados** - PIR HC-SR501 e DHT11
- **Sistema de Iluminação Inteligente** - 100 lâmpadas LED 20W
- **Controle de Consumo** - Cálculo automático de kWh e custos
- **2 Filiais** - Aguai e Casa Branca (SP)
- **6 Sensores Ativos** - 3 por filial
- **Stored Procedures** - Otimização de inserções no MySQL
- **Análises SQL Completas** - Relatórios de consumo e custos
- **Dashboard Visual** - Estatísticas em tempo real

### Tipos de Sensores

| Sensor | Modelo | Localização | Função |
|--------|--------|-------------|--------|
| Movimento | PIR HC-SR501 | Entrada Principal | Detecta presença e aciona lâmpadas |
| Temperatura/Umidade | DHT11 | Sala Principal | Monitora clima |
| Iluminação | LED 100x20W | Entrada Principal | Sistema inteligente |

---

## Arquitetura

```
┌─────────────────┐
│  Sensores PIR   │ (Movimento)
│  100 Lâmpadas   │ (20W cada)
│  DHT11          │ (Temp/Umidade)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Dart Simulador  │
│ Cálculo Auto    │ (Consumo + Custo)
└────────┬────────┘
         │
         ├──────────┐
         ▼          ▼
┌─────────────┐  ┌─────────────┐
│   MySQL     │  │  Firebase   │
│   Local     │  │   Realtime  │
│ + SP        │  │   Database  │
└─────────────┘  └─────────────┘
         │          │
         └────┬─────┘
              ▼
     ┌─────────────┐
     │  Análises   │
     │ Custos/kWh  │
     └─────────────┘
```

---

## Requisitos

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

## Instalação

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
2. Execute o arquivo `database/schema.sql` **ATUALIZADO**
3. Verifique se o banco `entrega5` foi criado com novos campos

#### Opção B: Terminal
```bash
mysql -u root -p < database/schema.sql
```

### 4. Verifique os Novos Campos

O schema atualizado inclui:

```sql
-- Tabela DIM_FILIAL
Qtd_Lampadas INT DEFAULT 100
Potencia_Lampada_W INT DEFAULT 20
Tempo_Ativacao_Min INT DEFAULT 10

-- Tabela FATO_LEITURAS
Qtd_Lampadas_Ativas INT
Tempo_Ligado_Min INT
Consumo_kWh DECIMAL(8,4)
Custo_Reais DECIMAL(8,4)
```

---

## Configuração

### 1. Configurar Credenciais MySQL

Edite o arquivo `lib/services/database_service.dart`:

```dart
static final ConnectionSettings _settings = ConnectionSettings(
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'SUA_SENHA_AQUI',  // ← Altere aqui
  db: 'entrega5',
  timeout: Duration(seconds: 60),
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
  http: ^1.1.0
  dart_jsonwebtoken: ^2.12.0
```

4. Execute: `dart pub get`

---

## Uso

### Executar Simulação Principal

```bash
cd lib
dart run main.dart
```

**Saída esperada:**

```
 SISTEMA PACKBAG - MONITORAMENTO IoT v2.0

 NOVO SISTEMA DE ILUMINAÇÃO:
   • 100 Lâmpadas LED por filial
   • Potência: 20W cada
   • Tempo: 10 minutos por ativação
   • Consumo: 0.33 kWh por ativação
   • Custo: R$ 0,3135 por ativação

 Conectado ao MySQL: entrega5
 CONFIGURAÇÃO DE ILUMINAÇÃO:
   Aguai: 100x20W (10min)
   Casa Branca: 100x20W (10min)

=== INICIANDO SIMULAÇÃO ===

 LEITURA 1/10
─────────────────────────────────────
 Leitura salva via SP: Sensor 7
    100x20W ligadas
    Consumo: 0.3300 kWh
    Custo: R$ 0,3135
 Leitura salva no Firebase: Aguai


LEITURA SENSOR #7 - Aguai         
Tipo: Iluminacao                  
Localização: Entrada Principal    
Timestamp: 2024-11-15 14:32:15   

DETECÇÃO:                       
Movimento: DETECTADO           
Sistema de Iluminação: ATIVO   
ILUMINAÇÃO:                     
Lâmpadas Acionadas: 100 un     
Potência Unitária: 20W         
Potência Total: 2000W          
Tempo Ligado: 10 minutos       
ENERGIA:                         
Consumo: 0.3300 kWh            
Consumo: 330.00 Wh             
Tarifa: R$ 0.95/kWh            
Custo: R$ 0.3135               

```

### Verificar Sistema Completo

```bash
dart run verificar_banco.dart
```

---

## Estrutura do Projeto

```
sistema-packbag/
│
├── lib/
│   ├── main.dart                          # ATUALIZADO
│   ├── verificar_banco.dart               # Verificação
│   │
│   ├── models/                            
│   │   ├── filial.dart
│   │   ├── sensor.dart
│   │   └── leitura_sensor.dart            # ATUALIZADO (novos campos)
│   │
│   ├── services/                          
│   │   ├── database_service.dart          # ATUALIZADO (cálculo auto)
│   │   ├── firebase_realtime_service.dart # Firebase Real
│   │   └── simulador_service.dart         # ATUALIZADO (100 lâmpadas)
│   │
│   ├── data/                              
│   │   └── sensores_data.dart             # ATUALIZADO (config iluminação)
│   │
│   └── config/                            
│       └── firebase-credentials.json      
│
├── database/                              
│   ├── schema.sql                         # ATUALIZADO (novos campos)
│   ├── insert_dados.sql                   
│   └── analise_sql_completa.sql           # ATUALIZADO (análise custos)
│
├── pubspec.yaml                           # VERIFICAR dependências
├── README.md                              # ESTE ARQUIVO
└── .gitignore                             

```

---

## Banco de Dados

### Modelo Estrela (Star Schema) - ATUALIZADO

```
        ┌──────────────────┐
        │  DIM_FILIAL      │
        │  + Qtd_Lampadas  │ ← NOVO
        │  + Potencia_W    │ ← NOVO
        │  + Tempo_Min     │ ← NOVO
        └──────┬───────────┘
               │
        ┌──────▼───────────┐
        │  DIM_SENSOR      │
        └──────┬───────────┘
               │
        ┌──────▼─────────────────┐
        │ FATO_LEITURAS          │
        │ + Qtd_Lampadas_Ativas  │ ← NOVO
        │ + Tempo_Ligado_Min     │ ← NOVO
        │ + Consumo_kWh          │ ← ATUALIZADO
        │ + Custo_Reais          │ ← NOVO
        └──────┬─────────────────┘
               │
        ┌──────▼───────┐
        │  DIM_TEMPO   │
        └──────────────┘
```

### Novos Campos

#### DIM_FILIAL
```sql
Qtd_Lampadas INT DEFAULT 100
Potencia_Lampada_W INT DEFAULT 20
Tempo_Ativacao_Min INT DEFAULT 10
```

#### FATO_LEITURAS
```sql
Qtd_Lampadas_Ativas INT NULL DEFAULT 0
Tempo_Ligado_Min INT NULL DEFAULT 0
Consumo_kWh DECIMAL(8,4) NULL DEFAULT '0.0000'
Custo_Reais DECIMAL(8,4) NULL DEFAULT '0.0000'
```

### Stored Procedure Atualizada

```sql
CALL sp_inserir_leitura(
  p_id_sensor INT,
  p_temperatura DECIMAL(4,1),
  p_umidade DECIMAL(4,1),
  p_movimento TINYINT,
  p_lampada TINYINT
);
```

**Cálculo Automático:**
```sql
-- Se lâmpada ligada:
SET v_consumo = (v_potencia_w * v_qtd_lampadas * (v_tempo_min / 60.0)) / 1000.0;
-- Exemplo: (20 * 100 * 0.167) / 1000 = 0.33 kWh

SET v_custo = v_consumo * v_tarifa_kwh;
-- Exemplo: 0.33 * 0.95 = R$ 0,3135
```

---

## Firebase

### Estrutura no Firebase Realtime Database

```json
{
  "leituras": {
    "-ABC123": {
      "id": "7_1699123456789",
      "idSensor": 7,
      "filial": "Aguai",
      "tipoSensor": "Iluminacao",
      "lampadaLigada": true,
      "qtdLampadasAtivas": 100,
      "potenciaLampadaW": 20,
      "tempoLigadoMin": 10,
      "consumoKwh": 0.33,
      "custoReais": 0.3135,
      "tarifaKwh": 0.95,
      "timestamp": "2024-11-15T14:32:15.123Z"
    }
  }
}
```

---

##  Análise de Custos

### Consumo por Ativação

```
1 ativação = 100 lâmpadas × 20W × 10min
           = 2000W × 0.167h
           = 333.33 Wh
           = 0.33 kWh
```

### Custo por Ativação

```
0.33 kWh × R$ 0,95/kWh = R$ 0,3135
```

### Estimativa Mensal (exemplo)

```
Cenário: 50 ativações/dia por filial

Diário:
  50 ativações × 0.33 kWh = 16.5 kWh
  50 ativações × R$ 0,3135 = R$ 15,68

Mensal (30 dias):
  16.5 kWh × 30 = 495 kWh
  R$ 15,68 × 30 = R$ 470,40

Duas Filiais:
  Consumo: 990 kWh/mês
  Custo: R$ 940,80/mês
```

### Consultas SQL de Análise

```sql
-- Consumo total por filial
SELECT 
  df.Nome_Filial,
  SUM(fl.Consumo_kWh) as consumo_total_kwh,
  SUM(fl.Custo_Reais) as custo_total_reais,
  COUNT(CASE WHEN fl.Lampada_Ligada = 1 THEN 1 END) as ativacoes
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL df ON fl.ID_Filial = df.ID_Filial
GROUP BY df.Nome_Filial;

-- Consumo por período do dia
SELECT 
  dt.Periodo_Dia,
  COUNT(*) as ativacoes,
  SUM(fl.Consumo_kWh) as consumo_kwh,
  SUM(fl.Custo_Reais) as custo_reais
FROM FATO_LEITURAS fl
JOIN DIM_TEMPO dt ON fl.ID_Data = dt.ID_Data
WHERE fl.Lampada_Ligada = 1
GROUP BY dt.Periodo_Dia;
```

---

## Scripts Disponíveis

| Script | Comando | Descrição |
|--------|---------|-----------|
| **Simulação Principal** | `dart run main.dart` | 10 leituras com cálculo de custos |
| **Verificação Completa** | `dart run verificar_banco.dart` | MySQL + Firebase + Custos |
| **Análise SQL** | MySQL Workbench | `analise_sql_completa.sql` atualizado |

---

##  Solução de Problemas

### Erro: "Cannot connect to MySQL"

**Solução:**
1. Verifique se o MySQL está rodando
2. Confirme usuário e senha em `database_service.dart`
3. Execute o schema **ATUALIZADO**:
   ```bash
   mysql -u root -p entrega5 < database/schema.sql
   ```

### Erro: "Unknown column 'Qtd_Lampadas_Ativas'"

**Causa:** Schema antigo ainda em uso.

**Solução:**
```sql
-- Adicionar novos campos manualmente
ALTER TABLE DIM_FILIAL 
ADD COLUMN Qtd_Lampadas INT DEFAULT 100,
ADD COLUMN Potencia_Lampada_W INT DEFAULT 20,
ADD COLUMN Tempo_Ativacao_Min INT DEFAULT 10;

ALTER TABLE FATO_LEITURAS
ADD COLUMN Qtd_Lampadas_Ativas INT DEFAULT 0,
ADD COLUMN Tempo_Ligado_Min INT DEFAULT 0,
ADD COLUMN Custo_Reais DECIMAL(8,4) DEFAULT 0.0000;
```

### Custos não aparecem

**Solução:**
1. Verifique se a Stored Procedure foi atualizada
2. Recrie a SP:
   ```bash
   mysql -u root -p entrega5 < database/schema.sql
   ```
3. Execute novamente o simulador

---

## Changelog v2.0

### Adicionado
- Sistema de 100 lâmpadas LED 20W por filial
- Cálculo automático de consumo (kWh)
- Cálculo automático de custos (R$)
- Novos campos no banco de dados
- Stored Procedure atualizada
- Análise de custos por filial/período
- View `vw_consumo_detalhado`
- Relatórios de consumo energético

### Modificado
- Modelo `LeituraSensor` com novos campos
- `DatabaseService` com métodos de análise
- `SimuladorService` com sistema de iluminação
- `SensoresData` com configuração de lâmpadas
- Schema SQL completo
- README atualizado

---

## Licença

Este projeto é parte do trabalho acadêmico da **UNIFEOB** - Centro Universitário da Fundação de Ensino Octávio Bastos.

---

## Agradecimentos

- **UNIFEOB** - Infraestrutura e suporte
- **Professores** - Orientação
- **Packbag** - Oportunidade de desenvolvimento

---

<div align="center">

** Sistema PackBag v2.0 - Monitoramento IoT Inteligente **

** 100 Lâmpadas LED × 20W = Controle Total de Energia **


</div>
