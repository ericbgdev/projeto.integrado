-- POPULAR BANCO - SISTEMA PACKBAG v2.0
-- 3000 Leituras Históricas (30 dias)
-- Sistema: 100 Lâmpadas LED 20W por Filial
-- Consumo: 0.33 kWh por ativação
-- Custo: R$ 0,3135 por ativação


USE entrega5;

SET FOREIGN_KEY_CHECKS = 0;
SET AUTOCOMMIT = 0;
START TRANSACTION;

-- 1. INSERIR/ATUALIZAR FILIAIS COM CONFIGURAÇÃO DE ILUMINAÇÃO

INSERT INTO dim_filial (ID_Filial, Nome_Filial, Cidade, Estado, Endereco, Gerente, Telefone, CEP, Qtd_Lampadas, Potencia_Lampada_W, Tempo_Ativacao_Min) 
VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000', 100, 20, 10),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000', 100, 20, 10)
ON DUPLICATE KEY UPDATE
    Qtd_Lampadas = VALUES(Qtd_Lampadas),
    Potencia_Lampada_W = VALUES(Potencia_Lampada_W),
    Tempo_Ativacao_Min = VALUES(Tempo_Ativacao_Min);

SELECT 'Filiais inseridas/atualizadas com configuração de iluminação' AS Status;

-- 2. INSERIR/ATUALIZAR SENSORES

INSERT INTO dim_sensor (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) 
VALUES
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
(7, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 1, 'Ativo'),
(8, 'Iluminacao', 'LED Sistema 100x20W', 'Entrada Principal', 2, 'Ativo')
ON DUPLICATE KEY UPDATE
    Modelo = VALUES(Modelo),
    Status = VALUES(Status);

SELECT 'Sensores inseridos/atualizados' AS Status;

-- 3. STORED PROCEDURE - GERAR 3000 LEITURAS HISTÓRICAS

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_gerar_leituras_historico$$

CREATE PROCEDURE sp_gerar_leituras_historico()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_sensor_id INT;
    DECLARE v_temperatura DECIMAL(4,1);
    DECLARE v_umidade DECIMAL(4,1);
    DECLARE v_movimento TINYINT;
    DECLARE v_lampada TINYINT;
    DECLARE v_timestamp DATETIME;
    DECLARE v_dias_atras INT;
    DECLARE v_hora INT;
    DECLARE v_minuto INT;
    DECLARE v_tipo_sensor VARCHAR(50);
    DECLARE v_pos INT;
    
    -- Variáveis para o novo sistema de iluminação
    DECLARE v_id_filial INT;
    DECLARE v_qtd_lampadas INT;
    DECLARE v_potencia_w INT;
    DECLARE v_tempo_min INT;
    DECLARE v_consumo DECIMAL(8,4);
    DECLARE v_custo DECIMAL(8,4);
    DECLARE v_tarifa DECIMAL(6,4) DEFAULT 0.9500;
    
    SELECT '════════════════════════════════════════════════' AS '';
    SELECT 'INICIANDO GERAÇÃO DE 3000 LEITURAS' AS '';
    SELECT 'Sistema: 100 Lâmpadas LED 20W' AS '';
    SELECT 'Consumo: 0.33 kWh por ativação' AS '';
    SELECT 'Custo: R$ 0,3135 por ativação' AS '';
    SELECT '════════════════════════════════════════════════' AS '';
    
    WHILE i < 3000 DO
        SET v_pos = FLOOR(1 + RAND() * 6);
        SET v_sensor_id = CASE v_pos
            WHEN 1 THEN 1
            WHEN 2 THEN 2
            WHEN 3 THEN 4
            WHEN 4 THEN 5
            WHEN 5 THEN 7
            ELSE 8
        END;
        
      
        SELECT 
            s.Tipo_Sensor,
            s.ID_Filial,
            f.Qtd_Lampadas,
            f.Potencia_Lampada_W,
            f.Tempo_Ativacao_Min
        INTO 
            v_tipo_sensor,
            v_id_filial,
            v_qtd_lampadas,
            v_potencia_w,
            v_tempo_min
        FROM DIM_SENSOR s
        JOIN DIM_FILIAL f ON s.ID_Filial = f.ID_Filial
        WHERE s.ID_Sensor = v_sensor_id;
        
      
        SET v_dias_atras = FLOOR(RAND() * 30);
        SET v_hora = FLOOR(RAND() * 24);
        SET v_minuto = FLOOR(RAND() * 60);
        SET v_timestamp = DATE_SUB(NOW(), INTERVAL v_dias_atras DAY) 
                         + INTERVAL v_hora HOUR 
                         + INTERVAL v_minuto MINUTE
                         + INTERVAL FLOOR(RAND() * 60) SECOND;
        
      
        IF v_tipo_sensor = 'Temperatura/Umidade' THEN
            -- Temperatura normal: 18-32°C, com 10% de chance de alerta
            IF RAND() < 0.10 THEN
                SET v_temperatura = 33.0 + (RAND() * 5.0); -- 33-38°C (alerta)
            ELSE
                SET v_temperatura = 18.0 + (RAND() * 14.0); -- 18-32°C (normal)
            END IF;
            
            -- Umidade normal: 35-85%, com 10% de chance de alerta
            IF RAND() < 0.10 THEN
                SET v_umidade = 86.0 + (RAND() * 12.0); -- 86-98% (alerta)
            ELSE
                SET v_umidade = 35.0 + (RAND() * 50.0); -- 35-85% (normal)
            END IF;
            
            SET v_movimento = 0;
            SET v_lampada = 0;
            
        ELSEIF v_tipo_sensor = 'Movimento' THEN
            SET v_temperatura = NULL;
            SET v_umidade = NULL;
            
            -- Movimentos mais frequentes durante o dia (6h-18h)
            IF v_hora >= 6 AND v_hora < 18 THEN
                SET v_movimento = IF(RAND() < 0.40, 1, 0); -- 40% de chance
            ELSE
                SET v_movimento = IF(RAND() < 0.15, 1, 0); -- 15% de chance
            END IF;
            
            SET v_lampada = v_movimento;
            
        ELSE -- Iluminacao
            SET v_temperatura = NULL;
            SET v_umidade = NULL;
            
            -- Iluminação mais ativa à noite (18h-6h)
            IF v_hora >= 18 OR v_hora < 6 THEN
                SET v_movimento = IF(RAND() < 0.50, 1, 0); -- 50% de chance
            ELSE
                SET v_movimento = IF(RAND() < 0.30, 1, 0); -- 30% de chance
            END IF;
            
            SET v_lampada = v_movimento;
        END IF;
        
     
        IF v_lampada = 1 THEN
            -- Fórmula: (Potência_W × Quantidade × Tempo_H) / 1000 = kWh
            SET v_consumo = (v_potencia_w * v_qtd_lampadas * (v_tempo_min / 60.0)) / 1000.0;
            -- Exemplo: (20 × 100 × 0.167) / 1000 = 0.33 kWh
            
            SET v_custo = v_consumo * v_tarifa;
            -- Exemplo: 0.33 × 0.95 = R$ 0,3135
        ELSE
            SET v_consumo = 0.0000;
            SET v_custo = 0.0000;
            SET v_qtd_lampadas = 0;
            SET v_tempo_min = 0;
        END IF;
        

        INSERT INTO FATO_LEITURAS (
            ID_Sensor, 
            ID_Filial, 
            ID_Data,
            Temperatura, 
            Umidade, 
            Movimento_Detectado, 
            Lampada_Ligada,
            Qtd_Lampadas_Ativas,
            Tempo_Ligado_Min,
            Consumo_kWh,
            Custo_Reais,
            Timestamp,
            Qualidade_Sinal,
            Status_Leitura
        ) VALUES (
            v_sensor_id,
            v_id_filial,
            UNIX_TIMESTAMP(v_timestamp),
            v_temperatura,
            v_umidade,
            v_movimento,
            v_lampada,
            v_qtd_lampadas,
            v_tempo_min,
            v_consumo,
            v_custo,
            v_timestamp,
            85 + FLOOR(RAND() * 15), -- Qualidade: 85-100%
            'Válida'
        );
        
       
        INSERT IGNORE INTO DIM_TEMPO (
            ID_Data,
            Data_Completa,
            Ano,
            Mes,
            Dia,
            DiaSemana,
            Hora,
            Periodo_Dia
        ) VALUES (
            UNIX_TIMESTAMP(v_timestamp),
            v_timestamp,
            YEAR(v_timestamp),
            MONTH(v_timestamp),
            DAY(v_timestamp),
            CASE DAYOFWEEK(v_timestamp)
                WHEN 1 THEN 'Domingo'
                WHEN 2 THEN 'Segunda'
                WHEN 3 THEN 'Terça'
                WHEN 4 THEN 'Quarta'
                WHEN 5 THEN 'Quinta'
                WHEN 6 THEN 'Sexta'
                WHEN 7 THEN 'Sábado'
            END,
            HOUR(v_timestamp),
            CASE
                WHEN HOUR(v_timestamp) >= 0 AND HOUR(v_timestamp) < 6 THEN 'Madrugada'
                WHEN HOUR(v_timestamp) >= 6 AND HOUR(v_timestamp) < 12 THEN 'Manhã'
                WHEN HOUR(v_timestamp) >= 12 AND HOUR(v_timestamp) < 18 THEN 'Tarde'
                ELSE 'Noite'
            END
        );
        
        SET i = i + 1;
        
        
        IF MOD(i, 500) = 0 THEN
            SELECT CONCAT(
                'Progresso: ', i, '/3000 leituras inseridas (',
                ROUND(i/30, 1), '%)'
            ) AS Status;
        END IF;
        
    END WHILE;
    
    SELECT '════════════════════════════════════════════════' AS '';
    SELECT CONCAT(' SUCESSO ', i, ' leituras inseridas com sucesso!') AS Resultado;
    SELECT '════════════════════════════════════════════════' AS '';
    
END$$

DELIMITER ;

-- 4. EXECUTAR GERAÇÃO DE LEITURAS


SELECT '' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT 'INICIANDO INSERÇÃO DE 3000 LEITURAS' AS '';
SELECT 'Tempo estimado: 2-3 minutos' AS '';
SELECT 'Período: últimos 30 dias' AS '';
SELECT 'Sistema: 100 Lâmpadas LED 20W por filial' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT '' AS '';

CALL sp_gerar_leituras_historico();

-- 5. COMMIT E RESTAURAR CONFIGURAÇÕES

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
SET AUTOCOMMIT = 1;

SELECT '' AS '';
SELECT 'DADOS SALVOS PERMANENTEMENTE NO DISCO!' AS '';
SELECT '' AS '';

-- 6. VERIFICAÇÕES E ESTATÍSTICAS

SELECT '' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT 'VERIFICAÇÃO DOS DADOS INSERIDOS' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT '' AS '';

-- Total de leituras
SELECT COUNT(*) AS 'Total de Leituras' FROM FATO_LEITURAS;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'LEITURAS POR FILIAL' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    f.Nome_Filial AS 'Filial',
    COUNT(*) AS 'Total Leituras',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS 'Porcentagem (%)'
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
GROUP BY f.Nome_Filial;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'LEITURAS POR TIPO DE SENSOR' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    s.Tipo_Sensor AS 'Tipo Sensor',
    COUNT(*) AS 'Total Leituras',
    ROUND(AVG(fl.Temperatura), 1) AS 'Temp Média (°C)',
    ROUND(AVG(fl.Umidade), 1) AS 'Umid Média (%)',
    SUM(fl.Movimento_Detectado) AS 'Movimentos',
    SUM(fl.Lampada_Ligada) AS 'Ativações',
    ROUND(SUM(fl.Consumo_kWh), 2) AS 'Consumo (kWh)',
    CONCAT('R$ ', FORMAT(SUM(fl.Custo_Reais), 2, 'pt_BR')) AS 'Custo Total'
FROM FATO_LEITURAS fl
JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
GROUP BY s.Tipo_Sensor;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'ANÁLISE DE ILUMINAÇÃO' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    f.Nome_Filial AS 'Filial',
    f.Qtd_Lampadas AS 'Lâmpadas',
    CONCAT(f.Potencia_Lampada_W, 'W') AS 'Potência',
    CONCAT(f.Tempo_Ativacao_Min, 'min') AS 'Tempo',
    SUM(fl.Lampada_Ligada) AS 'Ativações',
    ROUND(SUM(fl.Consumo_kWh), 2) AS 'Consumo (kWh)',
    CONCAT('R$ ', FORMAT(SUM(fl.Custo_Reais), 2, 'pt_BR')) AS 'Custo Total',
    CONCAT('R$ ', FORMAT(AVG(CASE WHEN fl.Lampada_Ligada = 1 THEN fl.Custo_Reais END), 4, 'pt_BR')) AS 'Custo/Ativação'
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
WHERE fl.Lampada_Ligada = 1
GROUP BY f.Nome_Filial, f.Qtd_Lampadas, f.Potencia_Lampada_W, f.Tempo_Ativacao_Min;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'LEITURAS POR PERÍODO DO DIA' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    t.Periodo_Dia AS 'Período',
    COUNT(*) AS 'Total Leituras',
    SUM(fl.Lampada_Ligada) AS 'Ativações',
    ROUND(SUM(fl.Consumo_kWh), 2) AS 'Consumo (kWh)',
    CONCAT('R$ ', FORMAT(SUM(fl.Custo_Reais), 2, 'pt_BR')) AS 'Custo',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS '%'
FROM FATO_LEITURAS fl
JOIN DIM_TEMPO t ON fl.ID_Data = t.ID_Data
GROUP BY t.Periodo_Dia
ORDER BY FIELD(t.Periodo_Dia, 'Madrugada', 'Manhã', 'Tarde', 'Noite');

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'LEITURAS POR DIA DA SEMANA' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    t.DiaSemana AS 'Dia da Semana',
    COUNT(*) AS 'Leituras',
    SUM(fl.Lampada_Ligada) AS 'Ativações',
    ROUND(SUM(fl.Consumo_kWh), 2) AS 'Consumo (kWh)',
    CONCAT('R$ ', FORMAT(SUM(fl.Custo_Reais), 2, 'pt_BR')) AS 'Custo',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS '%'
FROM FATO_LEITURAS fl
JOIN DIM_TEMPO t ON fl.ID_Data = t.ID_Data
GROUP BY t.DiaSemana
ORDER BY FIELD(t.DiaSemana, 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo');

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'RESUMO DOS ÚLTIMOS 30 DIAS' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    DATE(Timestamp) AS 'Data',
    COUNT(*) AS 'Leituras',
    SUM(Lampada_Ligada) AS 'Ativações',
    ROUND(AVG(Temperatura), 1) AS 'Temp Média',
    ROUND(SUM(Consumo_kWh), 2) AS 'Consumo (kWh)',
    CONCAT('R$ ', FORMAT(SUM(Custo_Reais), 2, 'pt_BR')) AS 'Custo'
FROM FATO_LEITURAS
GROUP BY DATE(Timestamp)
ORDER BY DATE(Timestamp) DESC
LIMIT 30;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'ESTATÍSTICAS DE TEMPERATURA' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    ROUND(MIN(Temperatura), 1) AS 'Temp Mínima (°C)',
    ROUND(AVG(Temperatura), 1) AS 'Temp Média (°C)',
    ROUND(MAX(Temperatura), 1) AS 'Temp Máxima (°C)',
    ROUND(STDDEV(Temperatura), 1) AS 'Desvio Padrão',
    SUM(CASE WHEN Temperatura > 32 THEN 1 ELSE 0 END) AS 'Alertas (>32°C)'
FROM FATO_LEITURAS
WHERE Temperatura IS NOT NULL;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'ESTATÍSTICAS DE UMIDADE' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    ROUND(MIN(Umidade), 1) AS 'Umid Mínima (%)',
    ROUND(AVG(Umidade), 1) AS 'Umid Média (%)',
    ROUND(MAX(Umidade), 1) AS 'Umid Máxima (%)',
    ROUND(STDDEV(Umidade), 1) AS 'Desvio Padrão',
    SUM(CASE WHEN Umidade > 85 THEN 1 ELSE 0 END) AS 'Alertas (>85%)'
FROM FATO_LEITURAS
WHERE Umidade IS NOT NULL;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'ESTATÍSTICAS DE MOVIMENTO E CONSUMO' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    SUM(Movimento_Detectado) AS 'Total Movimentos',
    ROUND(SUM(Movimento_Detectado) * 100.0 / COUNT(*), 1) AS 'Taxa Detecção (%)',
    SUM(Lampada_Ligada) AS 'Acionamentos Lâmpada',
    ROUND(SUM(Consumo_kWh), 2) AS 'Consumo Total (kWh)',
    CONCAT('R$ ', FORMAT(SUM(Custo_Reais), 2, 'pt_BR')) AS 'Custo Total',
    CONCAT('R$ ', FORMAT(AVG(CASE WHEN Lampada_Ligada = 1 THEN Custo_Reais END), 4, 'pt_BR')) AS 'Custo Médio/Ativação'
FROM FATO_LEITURAS;

SELECT '' AS '';
SELECT '─────────────────────────────────────────────' AS '';
SELECT 'ÚLTIMAS 10 LEITURAS' AS '';
SELECT '─────────────────────────────────────────────' AS '';

SELECT 
    fl.Timestamp AS 'Data/Hora',
    f.Nome_Filial AS 'Filial',
    s.Tipo_Sensor AS 'Sensor',
    CONCAT(COALESCE(ROUND(fl.Temperatura, 1), '-'), '°C') AS 'Temp',
    CONCAT(COALESCE(ROUND(fl.Umidade, 1), '-'), '%') AS 'Umid',
    IF(fl.Movimento_Detectado = 1, 'SUCESSO', 'ERRO') AS 'Mov',
    IF(fl.Lampada_Ligada = 1, 'LIGADA', 'DESLIGADA') AS 'Lamp',
    fl.Qtd_Lampadas_Ativas AS 'Qtd',
    fl.Consumo_kWh AS 'kWh',
    CONCAT('R$ ', FORMAT(fl.Custo_Reais, 4, 'pt_BR')) AS 'Custo'
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
ORDER BY fl.Timestamp DESC
LIMIT 10;

-- 7. MENSAGEM FINAL

SELECT '' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT 'INSERÇÃO DE 3000 LEITURAS CONCLUÍDA!' AS '';
SELECT '' AS '';
SELECT 'Dados salvos permanentemente no MySQL' AS '';
SELECT 'Período: últimos 30 dias' AS '';
SELECT 'Sistema: 100 Lâmpadas LED 20W' AS '';
SELECT 'Consumo calculado automaticamente' AS '';
SELECT 'Custos registrados (R$ 0,95/kWh)' AS '';
SELECT '' AS '';
SELECT 'PRÓXIMOS PASSOS:' AS '';
SELECT '   1. Execute: dart run main.dart' AS '';
SELECT '   2. Ou: dart run verificar_banco.dart' AS '';
SELECT '   3. Análises SQL: analise_custos_energia.sql' AS '';
SELECT '   4. Atualize Power BI para visualizar' AS '';
SELECT '' AS '';
SELECT '════════════════════════════════════════════════' AS '';
SELECT '' AS '';
