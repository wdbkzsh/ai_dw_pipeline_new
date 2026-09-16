-- ********************************************
-- 验数脚本：WCUBE.FACT_PATROL_TICKET
-- 功能描述：巡查工单事实表数据质量验证
-- 执行时机：INSERT后立即执行
-- 创 建 人： AI
-- 创建日期： 2026-09-14
-- ********************************************

-- ============================================
-- 1. 数据量检查
-- ============================================
SELECT
     'fact_wens_patrol_ticket'         AS table_name
   ,'${bizdate}'                      AS dt
   ,COUNT(*)                          AS total_cnt
   ,COUNT(DISTINCT TICKET_DK)         AS distinct_pk_cnt
FROM WCUBE.FACT_PATROL_TICKET
WHERE DT = '${bizdate}'
;

-- ============================================
-- 2. 主键重复检查
-- ============================================
SELECT
     TICKET_DK
   ,COUNT(*)                          AS dup_cnt
FROM WCUBE.FACT_PATROL_TICKET
WHERE DT = '${bizdate}'
GROUP BY TICKET_DK
HAVING COUNT(*) > 1
;

-- ============================================
-- 3. 关键字段非空检查
-- ============================================
SELECT
     SUM(CASE WHEN TICKET_DK IS NULL OR TRIM(TICKET_DK) = '' THEN 1 ELSE 0 END) AS null_ticket_dk
   ,SUM(CASE WHEN ALERT_DK IS NULL OR TRIM(ALERT_DK) = '' THEN 1 ELSE 0 END) AS null_alert_dk
   ,SUM(CASE WHEN REARER_ID IS NULL OR TRIM(REARER_ID) = '' THEN 1 ELSE 0 END) AS null_rearer_id
   ,SUM(CASE WHEN TICKET_STATUS_CD IS NULL OR TRIM(TICKET_STATUS_CD) = '' THEN 1 ELSE 0 END) AS null_ticket_status_cd
FROM WCUBE.FACT_PATROL_TICKET
WHERE DT = '${bizdate}'
;

-- ============================================
-- 4. 关联完整性检查（工单 → 预警）
-- ============================================
SELECT
     COUNT(*)                          AS total_ticket_cnt
   ,SUM(CASE WHEN A.ALERT_DK IS NOT NULL THEN 1 ELSE 0 END) AS has_alert_cnt
   ,SUM(CASE WHEN A.ALERT_DK IS NULL THEN 1 ELSE 0 END) AS no_alert_cnt
FROM WCUBE.FACT_PATROL_TICKET A
LEFT JOIN WCUBE.FACT_ALERT_EVENT B ON A.ALERT_DK = B.ALERT_DK AND B.DT = '${bizdate}'
WHERE A.DT = '${bizdate}'
;

-- ============================================
-- 5. 工单状态分布检查
-- ============================================
SELECT
     TICKET_STATUS_CD
   ,TICKET_STATUS_NM
   ,COUNT(*)                          AS cnt
FROM WCUBE.FACT_PATROL_TICKET
WHERE DT = '${bizdate}'
GROUP BY TICKET_STATUS_CD, TICKET_STATUS_NM
ORDER BY TICKET_STATUS_CD
;
