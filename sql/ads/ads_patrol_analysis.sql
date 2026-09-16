-- ********************************************
-- 目 标 表：  WCUBE.ADS_PATROL_ANALYSIS
-- 所属主题：  农户生产预警
-- 功能描述：  巡查分析明细ADS
-- 创 建 人：  
-- 创建日期：  2026-09-14
-- 修订日期   修订人 修改内容
-- ********************************************

-- Hive参数设置
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.merge.mapfiles=true;
set hive.merge.mapredfiles=true;

/*
-- DDL
DROP TABLE IF EXISTS WCUBE.ADS_PATROL_ANALYSIS PURGE;

CREATE TABLE WCUBE.ADS_PATROL_ANALYSIS
(
    ETL_BIZ_DT                 STRING      COMMENT 'ETL业务日期'
   ,ETL_PROC_TM                STRING      COMMENT 'ETL处理时间'
   -- 日期维度（月份取预警时间，支撑T03按月统计）
   ,ALERT_DT                   STRING      COMMENT '预警日期'
   ,MONTH_ID                   STRING      COMMENT '预警月份'
   ,CREATE_DT                  STRING      COMMENT '工单创建日期'
   -- 组织维度
   ,ORG_ID                     STRING      COMMENT '组织ID'
   -- 养户维度
   ,REARER_ID                  STRING      COMMENT '养户ID'
   ,REARER_NO                  STRING      COMMENT '养户编码'
   ,REARER_NM                  STRING      COMMENT '养户名称'
   -- 猪群维度
   ,REARER_POP_ID              STRING      COMMENT '猪群ID'
   ,REARER_POP_NO              STRING      COMMENT '猪群编码'
   ,REARER_POP_NM              STRING      COMMENT '猪群名称'
   -- 工单维度
   ,TICKET_DK                  STRING      COMMENT '巡查工单数据键'
   ,TICKET_STATUS_CD           STRING      COMMENT '巡查工单状态代码（1=未完成,2=已完成,3=未完成(过期)）'
   ,TICKET_STATUS_NM           STRING      COMMENT '巡查工单状态名称'
   -- 关联预警维度
   ,ALERT_DK                   STRING      COMMENT '关联预警数据键'
   ,ALERT_METRIC_CD            STRING      COMMENT '预警指标代码'
   ,ALERT_LEVEL_CD             STRING      COMMENT '预警等级代码'
   -- 风险维度（来自fact_wens_risk_analysis，可能为NULL）
   ,RISK_CATEGORY_CD           STRING      COMMENT '风险大类'
   ,RISK_ITEM_CD               STRING      COMMENT '风险项'
   ,STRATEGY_CD                STRING      COMMENT '应对策略'
   ,ADOPT_FLAG                 STRING      COMMENT '策略采纳标志'
   ,EXECUTE_FLAG               STRING      COMMENT '策略执行标志'
) COMMENT '巡查分析明细ADS'
STORED AS PARQUET
;
*/

INSERT OVERWRITE TABLE WCUBE.ADS_PATROL_ANALYSIS
SELECT
    '${azkaban.flow.1.days.ago}'                              AS ETL_BIZ_DT              
  ,CURRENT_TIMESTAMP()                                         AS ETL_PROC_TM
   -- 日期维度（月份取预警时间，支撑T03有效干涉率趋势按月统计）
   ,DATE_FORMAT(A.ALERT_TM, 'yyyyMMdd')                      AS ALERT_DT
   ,DATE_FORMAT(A.ALERT_TM, 'yyyy-MM')                       AS MONTH_ID
   ,DATE_FORMAT(T.CREATE_TM, 'yyyyMMdd')                     AS CREATE_DT
   -- 组织维度
   ,T.ORG_ID                                                 AS ORG_ID
   -- 养户维度
   ,T.REARER_ID                                              AS REARER_ID
   ,T.REARER_NO                                              AS REARER_NO
   ,T.REARER_NM                                              AS REARER_NM
   -- 猪群维度
   ,T.REARER_POP_ID                                          AS REARER_POP_ID
   ,T.REARER_POP_NO                                          AS REARER_POP_NO
   ,T.REARER_POP_NM                                          AS REARER_POP_NM
   -- 工单维度
   ,T.TICKET_DK                                              AS TICKET_DK
   ,T.TICKET_STATUS_CD                                       AS TICKET_STATUS_CD
   ,T.TICKET_STATUS_NM                                       AS TICKET_STATUS_NM
   -- 关联预警维度
   ,T.ALERT_DK                                               AS ALERT_DK
   ,A.ALERT_METRIC_CD                                        AS ALERT_METRIC_CD
   ,A.ALERT_LEVEL_CD                                         AS ALERT_LEVEL_CD
   -- 风险维度（LEFT JOIN，无风险分录时为NULL）
   ,R.RISK_CATEGORY_CD                                       AS RISK_CATEGORY_CD
   ,R.RISK_ITEM_CD                                           AS RISK_ITEM_CD
   ,R.STRATEGY_CD                                            AS STRATEGY_CD
   ,R.ADOPT_FLAG                                             AS ADOPT_FLAG
   ,R.EXECUTE_FLAG                                           AS EXECUTE_FLAG
FROM WCUBE.FACT_PATROL_TICKET T
LEFT JOIN WCUBE.FACT_RISK_ANALYSIS R ON T.TICKET_DK = R.TICKET_DK 
LEFT JOIN WCUBE.FACT_ALERT_EVENT A ON T.ALERT_DK = A.ALERT_DK 
;
