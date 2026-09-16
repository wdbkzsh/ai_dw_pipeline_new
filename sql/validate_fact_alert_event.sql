-- ********************************************
-- 验数脚本：WCUBE.FACT_ALERT_EVENT
-- 功能描述：预警事件事实表数据质量验证
-- 执行时机：INSERT后立即执行
-- 创 建 人： AI
-- 创建日期： 2026-09-14
-- ********************************************

-- ============================================
-- 1. 数据量检查
-- ============================================
SELECT
     'fact_wens_alert_event'           AS table_name
   ,'${bizdate}'                      AS dt
   ,COUNT(*)                          AS total_cnt
   ,COUNT(DISTINCT ALERT_DK)          AS distinct_pk_cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
;

-- ============================================
-- 2. 主键重复检查
-- ============================================
SELECT
     ALERT_DK
   ,COUNT(*)                          AS dup_cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY ALERT_DK
HAVING COUNT(*) > 1
;

-- ============================================
-- 3. 关键字段非空检查
-- ============================================
SELECT
     SUM(CASE WHEN ALERT_DK IS NULL OR TRIM(ALERT_DK) = '' THEN 1 ELSE 0 END) AS null_alert_dk
   ,SUM(CASE WHEN REARER_ID IS NULL OR TRIM(REARER_ID) = '' THEN 1 ELSE 0 END) AS null_rearer_id
   ,SUM(CASE WHEN REARER_POP_ID IS NULL OR TRIM(REARER_POP_ID) = '' THEN 1 ELSE 0 END) AS null_rearer_pop_id
   ,SUM(CASE WHEN ALERT_METRIC_CD IS NULL OR TRIM(ALERT_METRIC_CD) = '' THEN 1 ELSE 0 END) AS null_alert_metric_cd
   ,SUM(CASE WHEN ALERT_LEVEL_CD IS NULL OR TRIM(ALERT_LEVEL_CD) = '' THEN 1 ELSE 0 END) AS null_alert_level_cd
   ,SUM(CASE WHEN ALERT_STATUS_CD IS NULL OR TRIM(ALERT_STATUS_CD) = '' THEN 1 ELSE 0 END) AS null_alert_status_cd
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
;

-- ============================================
-- 4. 枚举值分布检查
-- ============================================
-- 预警状态分布
SELECT
     ALERT_STATUS_CD
   ,ALERT_STATUS_NM
   ,COUNT(*)                          AS cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY ALERT_STATUS_CD, ALERT_STATUS_NM
ORDER BY ALERT_STATUS_CD
;

-- 预警指标分布
SELECT
     ALERT_METRIC_CD
   ,ALERT_METRIC_NM
   ,COUNT(*)                          AS cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY ALERT_METRIC_CD, ALERT_METRIC_NM
ORDER BY ALERT_METRIC_CD
;

-- 预警等级分布
SELECT
     ALERT_LEVEL_CD
   ,ALERT_LEVEL_NM
   ,COUNT(*)                          AS cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY ALERT_LEVEL_CD, ALERT_LEVEL_NM
ORDER BY ALERT_LEVEL_CD
;

-- ============================================
-- 5. 7天复发标识分布检查
-- ============================================
SELECT
     REPEAT_ALERT_FLAG
   ,COUNT(*)                          AS cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
GROUP BY REPEAT_ALERT_FLAG
;

-- ============================================
-- 6. 度量字段合理性检查
-- ============================================
SELECT
     MIN(DURATION_DAY)                 AS min_duration
   ,MAX(DURATION_DAY)                 AS max_duration
   ,AVG(DURATION_DAY)                 AS avg_duration
   ,SUM(CASE WHEN DURATION_DAY < 0 THEN 1 ELSE 0 END) AS negative_duration_cnt
   ,SUM(CASE WHEN DURATION_DAY IS NULL THEN 1 ELSE 0 END) AS null_duration_cnt
FROM WCUBE.FACT_ALERT_EVENT
WHERE DT = '${bizdate}'
;
