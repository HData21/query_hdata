-- DW-EXIMIO-HML_PSO_ATENDIMENTO-INDICADORES-ATENDIMENTO-EVASAO-INTERNACAO

WITH TAB_ATENDIMENTOS_PERIODO AS (
    SELECT * FROM VIEW_TAB_ATENDIMENTOS  
    WHERE SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND DT_ATENDIMENTO_INICIO::DATE BETWEEN :DT_ATENDIMENTO_MIN AND :DT_ATENDIMENTO_MAX
),
TAB_ATENDIMENTOS_FILTRADOS AS (
    SELECT * FROM VIEW_TAB_ATENDIMENTOS  
    WHERE SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND DT_ATENDIMENTO_INICIO::DATE BETWEEN :DT_ATENDIMENTO_MIN AND :DT_ATENDIMENTO_MAX
		AND CDE_CONVENIO = ANY(:CONVENIO) --OPTIONAL_FILTER
		AND CDE_CLASSIFICACAO_RISCO = ANY(:CLASSIFICACAO_RISCO) --OPTIONAL_FILTER
		AND CDE_ATENDIMENTO_ALTA_HOSPITALAR = ANY(:ATENDIMENTO_ALTA_HOSPITALAR) --OPTIONAL_FILTER
		AND SK_IDADE = ANY(:CODIGO_IDADE) --OPTIONAL_FILTER
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
		AND CD_CID = ANY(:CID_ENTRADA) --OPTIONAL_FILTER
		AND DS_GRUPO_EPIDEMIOLOGICO = ANY(:GRUPO_EPIDEMIOLOGICO) --OPTIONAL_FILTER
        AND CDE_PRESTADOR = ANY(:PRESTADOR) --OPTIONAL_FILTER
        AND SN_HOUVE_INTERNACAO = ANY(:HOUVE_INTERNACAO) --OPTIONAL_FILTER
        AND SN_GRIPARIO = ANY(:GRIPARIO) --OPTIONAL_FILTER
        AND TP_EVASAO = ANY(:TIPO_EVASAO) --OPTIONAL_FILTER
        AND TP_CONVERSAO = ANY(:TIPO_CONVERSAO) --OPTIONAL_FILTER
        AND TP_TURNO = ANY(:TP_TURNO) --OPTIONAL_FILTER
        AND FAIXA_HORARIO = ANY(:FAIXA_TEMPO) --OPTIONAL_FILTER
        AND TP_DIA = ANY(:TP_DIA) --OPTIONAL_FILTER
	    AND DIA_SEMANA = ANY(:DIA_SEMANA) --OPTIONAL_FILTER
	    AND TP_RETORNO = ANY(:TIPOS_DE_RETORNO) --OPTIONAL_FILTER
),
TAB_ATENDIMENTOS_DATA_PERIODO AS (
    SELECT DISTINCT
		CONCAT(min(FA.DT_ATENDIMENTO_INICIO)::date, ' - ', max(FA.DT_ATENDIMENTO_INICIO)::date) AS DS_PERIODO
    FROM TAB_ATENDIMENTOS_PERIODO FA
),
TAB_ATENDIMENTOS_QTD_PERIODO AS (
    SELECT 
		COUNT(distinct FA.CD_ATENDIMENTO) QTD_ATENDIMENTOS_GLOBAL,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO = TRUE OR FA.SN_CONVERSAO_UTI = TRUE 
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_GLOBAL,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO = TRUE
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_UI_GLOBAL,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO_UTI = TRUE
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_UTI_GLOBAL,
    	SUM(CASE WHEN 
    			FA.SN_EVASAO = TRUE AND FA.TP_EVASAO = 'PÓS-CONSULTA'
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL,
    	SUM(CASE WHEN 
    			FA.SN_EVASAO = TRUE AND FA.TP_EVASAO = 'PRÉ-CONSULTA'
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL,
    	FA.SN_SEG_EVASAO_PS,
    	FA.SN_SEG_CONVERSAO_PS
    FROM TAB_ATENDIMENTOS_PERIODO FA
    GROUP BY 
    	FA.SN_SEG_EVASAO_PS,
    	FA.SN_SEG_CONVERSAO_PS
),
TAB_ATENDIMENTOS_QTD_FILTRADO AS (
    SELECT  
		COUNT(distinct FA.CD_ATENDIMENTO) QTD_ATENDIMENTOS_FILTRO,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO = TRUE OR FA.SN_CONVERSAO_UTI = TRUE 
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_FILTRO,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO = TRUE
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_UI_FILTRO,
    	SUM(CASE WHEN 
    			FA.SN_CONVERSAO_UTI = TRUE
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_INTERNACAO_UTI_FILTRO,
    	SUM(CASE WHEN 
    			FA.SN_EVASAO = TRUE AND FA.TP_EVASAO = 'PÓS-CONSULTA'
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO,
    	SUM(CASE WHEN 
    			FA.SN_EVASAO = TRUE AND FA.TP_EVASAO = 'PRÉ-CONSULTA'
				THEN 1
				ELSE 0 END
    	) QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO
    FROM TAB_ATENDIMENTOS_FILTRADOS FA
),
TAB_META_EVASAO_PRE_CONSULTA AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 6
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'PRÉ_CONSULTA'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
),
TAB_META_EVASAO_POS_CONSULTA AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 6
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'PÓS_CONSULTA'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
),
TAB_META_EVASAO AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 6
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'GERAL'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
),
TAB_META_INTERNACAO AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 19
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'COM_INTERNACAO'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
),
TAB_META_INTERNACAO_UI AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 19
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'COM_INTERNACAO_UI'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
),
TAB_META_INTERNACAO_UTI AS (
	SELECT 
		CASE
			WHEN DI.SN_ABSOLUTO = TRUE THEN TIM.VL_META
			ELSE ROUND(TIM.VL_META::numeric * 100, 2)
		END VL_META
	FROM TAB_INDICADOR_META TIM
		INNER JOIN DIM_INDICADOR DI on DI.PK_INDICADOR = TIM.SK_INDICADOR
	WHERE TIM.SK_REDE_UNIDADE_SETOR = :HDATA_USUARIO_REDE_SETOR
		AND :DT_ATENDIMENTO_MIN BETWEEN TIM.DT_VIGENCIA_INICIO::DATE AND TIM.DT_VIGENCIA_FIM::DATE
		AND TIM.SK_INDICADOR = 19
		AND TIM.TP_UTILIZACAO = 'OPERACIONAL'
		AND TIM.TP_INSERCAO = 'AUTOMATICO'
		AND TIM.METRICA = 'COM_INTERNACAO_UTI'
		AND CDE_ESPECIALIDADE = ANY(:ESPECIALIDADE_ENTRADA) --OPTIONAL_FILTER
	ORDER BY CDE_ESPECIALIDADE ASc, DT_VIGENCIA_INICIO DESC
	LIMIT 1
)
SELECT
	FA_DATA.DS_PERIODO,
	FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO, 0) QTD_ATENDIMENTOS_FILTRO,
	coalesce(FA_PERIODO.QTD_ATENDIMENTOS_INTERNACAO_GLOBAL, 0) QTD_ATENDIMENTOS_INTERNACAO_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_INTERNACAO_FILTRO, 0) QTD_ATENDIMENTOS_INTERNACAO_FILTRO,
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_INTERNACAO_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) AS TX_ATENDIMENTOS_INTERNACAO_GLOBAL,
	CASE
		WHEN FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO > 0 THEN ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_INTERNACAO_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 )
		ELSE 0
	END	TX_ATENDIMENTOS_INTERNACAO_FILTRO,
	coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL, 0) + coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL, 0) QTD_ATENDIMENTOS_EVASAO_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO, 0) + coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO, 0) QTD_ATENDIMENTOS_EVASAO_FILTRO,
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) +
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) AS TX_ATENDIMENTOS_EVASAO_GLOBAL,
	CASE
		WHEN FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO > 0 THEN ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 ) +
	                                                      ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 )
		ELSE 0
	END	TX_ATENDIMENTOS_EVASAO_FILTRO,
	coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL, 0) QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO, 0) QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO,
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) AS TX_ATENDIMENTOS_EVASAO_POS_CONSULTA_GLOBAL,
	CASE
		WHEN FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO > 0 THEN ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 )
		ELSE 0
	END	TX_ATENDIMENTOS_EVASAO_POS_CONSULTA_FILTRO,
	coalesce(FA_PERIODO.QTD_ATENDIMENTOS_INTERNACAO_UTI_GLOBAL, 0) QTD_ATENDIMENTOS_INTERNACAO_UTI_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_INTERNACAO_UTI_FILTRO, 0) QTD_ATENDIMENTOS_INTERNACAO_UTI_FILTRO,
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_INTERNACAO_UTI_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) AS TX_ATENDIMENTOS_INTERNACAO_UTI_GLOBAL,
	CASE
		WHEN FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO > 0 THEN ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_INTERNACAO_UTI_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 )
		ELSE 0
	END	TX_ATENDIMENTOS_INTERNACAO_UTI_FILTRO,
	coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL, 0) QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL,
	coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO, 0) QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO,
	ROUND( (coalesce(FA_PERIODO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL, 0)::NUMERIC / FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL::NUMERIC) * 100, 2 ) AS TX_ATENDIMENTOS_EVASAO_PRE_CONSULTA_GLOBAL,
	CASE
		WHEN FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO > 0 THEN ROUND( (coalesce(FA_FILTRADO.QTD_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO, 0)::NUMERIC / FA_FILTRADO.QTD_ATENDIMENTOS_FILTRO::NUMERIC) * 100, 2 )
		ELSE 0
	END	TX_ATENDIMENTOS_EVASAO_PRE_CONSULTA_FILTRO,
	TMEPRE.VL_META TX_META_EVASAO_PRE_CONSULTA,
	TMEPOS.VL_META TX_META_EVASAO_POS_CONSULTA,
	TME.VL_META TX_META_EVASAO_GLOBAL,
	TMI.VL_META TX_META_INTERNACAO,
	TMIUI.VL_META TX_META_INTERNACAO_UI,
	TMIUTI.VL_META TX_META_INTERNACAO_UTI,
	FA_PERIODO.SN_SEG_EVASAO_PS,
	FA_PERIODO.SN_SEG_CONVERSAO_PS
FROM TAB_ATENDIMENTOS_QTD_PERIODO FA_PERIODO
	LEFT JOIN TAB_ATENDIMENTOS_DATA_PERIODO FA_DATA ON true
	LEFT JOIN TAB_ATENDIMENTOS_QTD_FILTRADO FA_FILTRADO ON true
	LEFT JOIN TAB_META_EVASAO TME ON true
	LEFT JOIN TAB_META_EVASAO_PRE_CONSULTA TMEPRE ON true
	LEFT JOIN TAB_META_EVASAO_POS_CONSULTA TMEPOS ON true
	LEFT JOIN TAB_META_INTERNACAO TMI ON true
	LEFT JOIN TAB_META_INTERNACAO_UI TMIUI ON true
	LEFT JOIN TAB_META_INTERNACAO_UTI TMIUTI ON true
WHERE FA_PERIODO.QTD_ATENDIMENTOS_GLOBAL > 0
;