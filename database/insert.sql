USE entrega5;


SET FOREIGN_KEY_CHECKS = 0;
SET AUTOCOMMIT = 0;
START TRANSACTION;


INSERT IGNORE INTO dim_filial (ID_Filial, Nome_Filial, Cidade, Estado, Endereco, Gerente, Telefone, CEP) VALUES
(1, 'Aguai', 'Aguai', 'SP', 'Av. Francisco Gonçalves, 409', 'João Silva', '(19) 3652-1234', '13868-000'),
(2, 'Casa Branca', 'Casa Branca', 'SP', 'BLOCO B Estrada Acesso, SP-340', 'Maria Santos', '(19) 3671-5678', '13700-000');

SELECT 'Filiais inseridas/verificadas' AS Status;

INSERT IGNORE INTO dim_sensor (ID_Sensor, Tipo_Sensor, Modelo, Localizacao, ID_Filial, Status) VALUES
(1, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 1, 'Ativo'),
(2, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 1, 'Ativo'),
(4, 'Movimento', 'PIR HC-SR501', 'Entrada Principal', 2, 'Ativo'),
(5, 'Temperatura/Umidade', 'DHT11', 'Sala Principal', 2, 'Ativo'),
(7, 'Iluminacao', 'LED', 'Entrada Principal', 1, 'Ativo'),
(8, 'Iluminacao', 'LED', 'Entrada Principal', 2, 'Ativo');

SELECT 'Sensores inseridos/verificados' AS Status;


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
        
        
        SELECT Tipo_Sensor INTO v_tipo_sensor 
        FROM DIM_SENSOR 
        WHERE ID_Sensor = v_sensor_id;
        
        
        SET v_dias_atras = FLOOR(RAND() * 30);
        SET v_hora = FLOOR(RAND() * 24);
        SET v_minuto = FLOOR(RAND() * 60);
        SET v_timestamp = DATE_SUB(NOW(), INTERVAL v_dias_atras DAY) 
                         + INTERVAL v_hora HOUR 
                         + INTERVAL v_minuto MINUTE
                         + INTERVAL FLOOR(RAND() * 60) SECOND;
        
 
        
        IF v_tipo_sensor = 'Temperatura/Umidade' THEN
            
            IF RAND() < 0.10 THEN
                SET v_temperatura = 33.0 + (RAND() * 5.0);
            ELSE
                SET v_temperatura = 18.0 + (RAND() * 14.0);
            END IF;
            
           
            IF RAND() < 0.10 THEN
                SET v_umidade = 86.0 + (RAND() * 12.0);
            ELSE
                SET v_umidade = 35.0 + (RAND() * 50.0);
            END IF;
            
            SET v_movimento = 0;
            SET v_lampada = 0;
            
        ELSEIF v_tipo_sensor = 'Movimento' THEN
            SET v_temperatura = NULL;
            SET v_umidade = NULL;
            
           
            IF v_hora >= 6 AND v_hora < 18 THEN
                SET v_movimento = IF(RAND() < 0.40, 1, 0);
            ELSE
                SET v_movimento = IF(RAND() < 0.15, 1, 0);
            END IF;
            
            SET v_lampada = v_movimento;
            
        ELSE 
            SET v_temperatura = NULL;
            SET v_umidade = NULL;
           
            IF v_hora >= 18 OR v_hora < 6 THEN
                SET v_movimento = IF(RAND() < 0.50, 1, 0);
            ELSE
                SET v_movimento = IF(RAND() < 0.30, 1, 0);
            END IF;
            
            SET v_lampada = v_movimento;
        END IF;
        
       
        INSERT INTO FATO_LEITURAS (
            ID_Sensor, 
            ID_Filial, 
            ID_Data,
            Temperatura, 
            Umidade, 
            Movimento_Detectado, 
            Lampada_Ligada, 
            Consumo_kWh,
            Timestamp,
            Qualidade_Sinal,
            Status_Leitura
        )
        SELECT 
            v_sensor_id,
            s.ID_Filial,
            UNIX_TIMESTAMP(v_timestamp),
            v_temperatura,
            v_umidade,
            v_movimento,
            v_lampada,
            IF(v_lampada = 1, 0.0500, 0.0000),
            v_timestamp,
            85 + FLOOR(RAND() * 15), -- Qualidade: 85-100%
            'Válida'
        FROM DIM_SENSOR s
        WHERE s.ID_Sensor = v_sensor_id;
        
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
            SELECT CONCAT('Progresso: ', i, '/3000 leituras inseridas (', ROUND(i/30, 1), '%)') AS Status;
        END IF;
        
    END WHILE;
    
    SELECT CONCAT('Total de ', i, ' leituras inseridas com sucesso!') AS Resultado;
    
END$$

DELIMITER ;

SELECT '════════════════════════════════════════════════' AS '';
SELECT 'INICIANDO INSERÇÃO DE 3000 LEITURAS' AS '';
SELECT 'Tempo estimado: 2-3 minutos' AS '';
SELECT 'Período: últimos 30 dias' AS '';
SELECT '════════════════════════════════════════════════' AS '';

CALL sp_gerar_leituras_historico();


COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
SET AUTOCOMMIT = 1;

SELECT 'DADOS SALVOS PERMANENTEMENTE NO DISCO!' AS '';


SELECT '════════════════════════════════════════════════' AS '';
SELECT '📊 VERIFICAÇÃO DOS DADOS INSERIDOS' AS '';
SELECT '════════════════════════════════════════════════' AS '';


SELECT COUNT(*) AS 'Total de Leituras' FROM FATO_LEITURAS;


SELECT 
    f.Nome_Filial AS 'Filial',
    COUNT(*) AS 'Total Leituras',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS 'Porcentagem (%)'
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
GROUP BY f.Nome_Filial;


SELECT 
    s.Tipo_Sensor AS 'Tipo Sensor',
    COUNT(*) AS 'Total Leituras',
    ROUND(AVG(fl.Temperatura), 1) AS 'Temp Média (°C)',
    ROUND(AVG(fl.Umidade), 1) AS 'Umid Média (%)',
    SUM(fl.Movimento_Detectado) AS 'Movimentos',
    ROUND(SUM(fl.Consumo_kWh), 2) AS 'Consumo Total (kWh)'
FROM FATO_LEITURAS fl
JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
GROUP BY s.Tipo_Sensor;


SELECT 
    t.Periodo_Dia AS 'Período',
    COUNT(*) AS 'Total Leituras',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS '%'
FROM FATO_LEITURAS fl
JOIN DIM_TEMPO t ON fl.ID_Data = t.ID_Data
GROUP BY t.Periodo_Dia
ORDER BY FIELD(t.Periodo_Dia, 'Madrugada', 'Manhã', 'Tarde', 'Noite');


SELECT 
    t.DiaSemana AS 'Dia da Semana',
    COUNT(*) AS 'Leituras',
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FATO_LEITURAS), 1) AS '%'
FROM FATO_LEITURAS fl
JOIN DIM_TEMPO t ON fl.ID_Data = t.ID_Data
GROUP BY t.DiaSemana
ORDER BY FIELD(t.DiaSemana, 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo');


SELECT 
    DATE(Timestamp) AS 'Data',
    COUNT(*) AS 'Leituras',
    ROUND(AVG(Temperatura), 1) AS 'Temp Média',
    SUM(Movimento_Detectado) AS 'Movimentos'
FROM FATO_LEITURAS
GROUP BY DATE(Timestamp)
ORDER BY DATE(Timestamp) DESC
LIMIT 30;


SELECT 
    ROUND(MIN(Temperatura), 1) AS 'Temp Mínima (°C)',
    ROUND(AVG(Temperatura), 1) AS 'Temp Média (°C)',
    ROUND(MAX(Temperatura), 1) AS 'Temp Máxima (°C)',
    ROUND(STDDEV(Temperatura), 1) AS 'Desvio Padrão'
FROM FATO_LEITURAS
WHERE Temperatura IS NOT NULL;


SELECT 
    ROUND(MIN(Umidade), 1) AS 'Umid Mínima (%)',
    ROUND(AVG(Umidade), 1) AS 'Umid Média (%)',
    ROUND(MAX(Umidade), 1) AS 'Umid Máxima (%)',
    ROUND(STDDEV(Umidade), 1) AS 'Desvio Padrão'
FROM FATO_LEITURAS
WHERE Umidade IS NOT NULL;


SELECT 
    SUM(Movimento_Detectado) AS 'Total Movimentos',
    ROUND(SUM(Movimento_Detectado) * 100.0 / COUNT(*), 1) AS 'Taxa Detecção (%)',
    SUM(Lampada_Ligada) AS 'Acionamentos Lâmpada',
    ROUND(SUM(Consumo_kWh), 2) AS 'Consumo Total (kWh)'
FROM FATO_LEITURAS;


SELECT 
    fl.Timestamp AS 'Data/Hora',
    f.Nome_Filial AS 'Filial',
    s.Tipo_Sensor AS 'Sensor',
    CONCAT(COALESCE(ROUND(fl.Temperatura, 1), '-'), '°C') AS 'Temp',
    CONCAT(COALESCE(ROUND(fl.Umidade, 1), '-'), '%') AS 'Umid',
    IF(fl.Movimento_Detectado = 1, '✅', '❌') AS 'Mov',
    IF(fl.Lampada_Ligada = 1, '💡', '⚫') AS 'Lamp',
    fl.Consumo_kWh AS 'kWh'
FROM FATO_LEITURAS fl
JOIN DIM_FILIAL f ON fl.ID_Filial = f.ID_Filial
JOIN DIM_SENSOR s ON fl.ID_Sensor = s.ID_Sensor
ORDER BY fl.Timestamp DESC
LIMIT 10;


SELECT '════════════════════════════════════════════════' AS '';
SELECT 'INSERÇÃO DE 3000 LEITURAS CONCLUÍDA!' AS '';
SELECT 'Dados salvos permanentemente no MySQL' AS '';
SELECT 'Período: últimos 30 dias' AS '';
SELECT 'Agora execute: dart run main.dart' AS '';
SELECT 'Ou atualize o Power BI para visualizar' AS '';
SELECT '════════════════════════════════════════════════' AS '';
