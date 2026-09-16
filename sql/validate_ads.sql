-- ********************************************
-- 验数脚本：ADS层数据质量验证
-- 功能描述：三个ADS表的数据质量综合验证
-- 执行时机：所有ADS INSERT后执行
-- 创 建 人： AI
-- 创建日期： 2026-09-14
-- ********************************************

-- ============================================
-- 1. ads_wens_alert_analysis 数据量与粒度检查
-- ============================================
SELECT
     'ads_wens_alert_analysis'         AS table_name
   ,COUNT(*)                          AS total_cnt
FROM WCUBE.ADS_ALERT_ANALYSIS
WHERE DT = '${bizdate}'
;

-- ADS行数应等于FACT行数（1:1映射，无聚合）
SELECT
     'ads_wens_alert_analysis_vs_fact' AS check_name
   ,A.ads_cnt
   ,B.fact_cnt
   ,CASE WHEN A.ads_cnt = B.fact_cnt THEN 'PASS' ELSE 'FAIL' END AS result
FROM
(
    SELECT COUNT(*) AS ads_cnt FROM WCUBE.ADS_ALERT_ANALYSIS WHERE DT = '${bizdate}'
) A,
(
    SELECT COUNT(*) AS fact_cnt FROM WCUBE.FACT_ALERT_EVENT WHERE DT = '${bizdate}'
) B
;

-- ============================================
-- 2. ads_wens_alert_detail 数据量与粒度检查
-- ============================================
SELECT
     'ads_wens_alert_detail'           AS table_name
   ,COUNT(*)                          AS total_cnt
   ,COUNT(DISTINCT REARER_ID || '_' || REARER_POP_ID) AS distinct_farmer_flock_cnt
FROM WCUBE.ADS_ALERT_DETAIL
WHERE DT = '${bizdate}'
;

-- ADS行数应等于FACT行数（1:1映射，无聚合）
SELECT
     'ads_wens_alert_detail_vs_fact'   AS check_name
   ,A.ads_cnt
   ,B.fact_cnt
   ,CASE WHEN A.ads_cnt = B.fact_cnt THEN 'PASS' ELSE 'FAIL' END AS result
FROM
(
    SELECT COUNT(*) AS ads_cnt FROM WCUBE.ADS_ALERT_DETAIL WHERE DT = '${bizdate}'
) A,
(
    SELECT COUNT(*) AS fact_cnt FROM WCUBE.FACT_ALERT_EVENT WHERE DT = '${bizdate}'
) B
;

-- ============================================
-- 3. ads_wens_patrol_analysis 数据量检查
-- ============================================
SELECT
     'ads_wens_patrol_analysis'        AS table_name
   ,COUNT(*)                          AS total_cnt
   ,COUNT(DISTINCT TICKET_DK)         AS distinct_ticket_cnt
   ,SUM(CASE WHEN RISK_CATEGORY_CD IS NOT NULL THEN 1 ELSE 0 END) AS has_risk_cnt
   ,SUM(CASE WHEN RISK_CATEGORY_CD IS NULL THEN 1 ELSE 0 END) AS no_risk_cnt
FROM WCUBE.ADS_PATROL_ANALYSIS
WHERE DT = '${bizdate}'
;

-- 工单行数检查（应包含所有工单，包括无风险分录的）
SELECT
     'ads_wens_patrol_ticket_coverage' AS check_name
   ,A.ads_ticket_cnt
   ,B.fact_ticket_cnt
   ,CASE WHEN A.ads_ticket_cnt >= B.fact_ticket_cnt THEN 'PASS' ELSE 'FAIL' END AS result
FROM
(
    SELECT COUNT(DISTINCT TICKET_DK) AS ads_ticket_cnt FROM WCUBE.ADS_PATROL_ANALYSIS WHERE DT = '${bizdate}'
) A,
(
    SELECT COUNT(DISTINCT TICKET_DK) AS fact_ticket_cnt FROM WCUBE.FACT_PATROL_TICKET WHERE DT = '${bizdate}'
) B
;

-- ============================================
-- 4. 养户维度冗余一致性检查
-- ============================================
-- 检查同一养户在不同预警记录中是否维度属性一致
SELECT
     REARER_ID
   ,COUNT(DISTINCT REARER_NM)         AS distinct_nm_cnt
   ,COUNT(DISTINCT REARER_NO)         AS distinct_no_cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY REARER_ID
HAVING COUNT(DISTINCT REARER_NM) > 1
    OR COUNT(DISTINCT REARER_NO) > 1
;

-- ============================================
-- 5. 预警状态码与名称一致性检查
-- ============================================
SELECT
     ALERT_STATUS_CD
   ,COUNT(DISTINCT ALERT_STATUS_NM)   AS distinct_nm_cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY ALERT_STATUS_CD
HAVING COUNT(DISTINCT ALERT_STATUS_NM) > 1
;
