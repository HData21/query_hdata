-- DW-EXIMIO-HML_PSO_ATENDIMENTOS-GRIPARIO-N-GRIPARIO

WITH TAB_ATENDIMENTOS_FILTRADOS AS (
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
TAB_ATENDIMENTOS AS (
	SELECT
		COUNT(DISTINCT FA.CD_ATENDIMENTO) AS QTD_ATENDIMENTOS
	FROM
		TAB_ATENDIMENTOS_FILTRADOS FA
		LEFT JOIN DIM_CLASSIFICACAO_CID DCC ON DCC.CD_CID = FA.SK_CID_ENTRADA
		LEFT JOIN DIM_PRESTADOR_ESPECIALIDADE DPE ON DPE.PK_ESPECIALIDADE = FA.SK_ESPECIALIDADE_ENTRADA
		LEFT JOIN DIM_PRESTADOR DP ON FA.SK_MEDICO_ENTRADA = DP.PK_PRESTADOR
)
SELECT
	FA.SN_GRIPARIO,
	TA.QTD_ATENDIMENTOS QTD_ATENDIMENTOS_GLOBAL,
	COUNT(DISTINCT FA.CD_ATENDIMENTO) QTD_ATENDIMENTO,
	ROUND( (COUNT(DISTINCT FA.CD_ATENDIMENTO)::FLOAT/TA.QTD_ATENDIMENTOS::FLOAT)::NUMERIC * 100, 2) TX_ATENDIMENTOS
FROM TAB_ATENDIMENTOS TA,
	 TAB_ATENDIMENTOS_FILTRADOS FA
	 LEFT JOIN DIM_CLASSIFICACAO_CID DCC ON DCC.CD_CID = FA.SK_CID_ENTRADA
	 LEFT JOIN DIM_PRESTADOR_ESPECIALIDADE DPE ON DPE.PK_ESPECIALIDADE = FA.SK_ESPECIALIDADE_ENTRADA
	 LEFT JOIN DIM_PRESTADOR DP ON FA.SK_MEDICO_ENTRADA = DP.PK_PRESTADOR
GROUP BY
	FA.SN_GRIPARIO,
	TA.QTD_ATENDIMENTOS
;