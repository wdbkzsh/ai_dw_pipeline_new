-- ********************************************
-- 目 标 表：  WCUBE.ADS_ALERT_ANALYSIS
-- 所属主题：  农户生产预警
-- 功能描述：  预警分析明细ADS
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
DROP TABLE IF EXISTS WCUBE.ADS_ALERT_ANALYSIS PURGE;

CREATE TABLE WCUBE.ADS_ALERT_ANALYSIS
(
    ETL_BIZ_DT                 STRING      COMMENT 'ETL业务日期'
   ,ETL_PROC_TM                STRING      COMMENT 'ETL处理时间'
   -- 日期维度
   ,ALERT_DT                   STRING      COMMENT '预警日期'
   ,MONTH_ID                   STRING      COMMENT '预警月份'
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
   -- 预警维度
   ,ALERT_METRIC_CD            STRING      COMMENT '预警指标代码'
   ,ALERT_METRIC_NM            STRING      COMMENT '预警指标名称'
   ,ALERT_LEVEL_CD             STRING      COMMENT '预警等级代码'
   ,ALERT_LEVEL_NM             STRING      COMMENT '预警等级名称'
   ,ALERT_STATUS_CD            STRING      COMMENT '预警状态代码'
   ,ALERT_STATUS_NM            STRING      COMMENT '预警状态名称'
   -- 事件明细
   ,ALERT_TM                   STRING      COMMENT '预警时间'
   ,DURATION_DAY               BIGINT      COMMENT '持续时长（天）'
   ,ALARM_VALUE                STRING      COMMENT '触发预警时数值'
   ,IS_PATROL_FLAG             STRING      COMMENT '是否巡查标志'
   ,REPEAT_ALERT_FLAG          STRING      COMMENT '7天复发标识'
   -- 总养户数（C01分母，全局常量）
   ,TOTAL_REARER_CNT           BIGINT      COMMENT '总养户数'
) COMMENT '预警分析明细ADS（支撑现状监控/趋势分析/效果评估）'
STORED AS PARQUET
;
*/

INSERT OVERWRITE TABLE WCUBE.ADS_ALERT_ANALYSIS
SELECT
  '${azkaban.flow.1.days.ago}'                              AS ETL_BIZ_DT              
  ,CURRENT_TIMESTAMP                                         AS ETL_PROC_TM
   -- 日期维度
   ,DATE_FORMAT(A.ALERT_TM, 'yyyyMMdd')                     AS ALERT_DT
   ,DATE_FORMAT(A.ALERT_TM, 'yyyy-MM')                      AS MONTH_ID
   -- 组织维度
   ,A.ORG_ID                                                 AS ORG_ID
   -- 养户维度
   ,A.REARER_ID                                              AS REARER_ID
   ,A.REARER_NO                                              AS REARER_NO
   ,A.REARER_NM                                              AS REARER_NM
   -- 猪群维度
   ,A.REARER_POP_ID                                          AS REARER_POP_ID
   ,A.REARER_POP_NO                                          AS REARER_POP_NO
   ,A.REARER_POP_NM                                          AS REARER_POP_NM
   -- 预警维度
   ,A.ALERT_METRIC_CD                                        AS ALERT_METRIC_CD
   ,A.ALERT_METRIC_NM                                        AS ALERT_METRIC_NM
   ,A.ALERT_LEVEL_CD                                         AS ALERT_LEVEL_CD
   ,A.ALERT_LEVEL_NM                                         AS ALERT_LEVEL_NM
   ,A.ALERT_STATUS_CD                                        AS ALERT_STATUS_CD
   ,A.ALERT_STATUS_NM                                        AS ALERT_STATUS_NM
   -- 事件明细
   ,A.ALERT_TM                                               AS ALERT_TM
   ,A.DURATION_DAY                                           AS DURATION_DAY
   ,A.ALARM_VALUE                                            AS ALARM_VALUE
   ,A.IS_PATROL_FLAG                                         AS IS_PATROL_FLAG
   ,A.REPEAT_ALERT_FLAG                                      AS REPEAT_ALERT_FLAG
   -- 总养户数（C01分母，子查询取全局常量）
   ,(SELECT COUNT(*) FROM WENSEAS.TK_WENS_REA_FARM_INFO WHERE FSTATUS = 'C' AND FENABLE = '1') AS TOTAL_REARER_CNT
FROM WCUBE.FACT_ALERT_EVENT A
;
