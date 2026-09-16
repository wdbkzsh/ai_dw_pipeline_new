-- ********************************************
-- 目 标 表：  WCUBE.ADS_ALERT_DETAIL
-- 所属主题：  农户生产预警
-- 功能描述：  异常农户清单明细ADS
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
DROP TABLE IF EXISTS WCUBE.ADS_ALERT_DETAIL PURGE;

CREATE TABLE WCUBE.ADS_ALERT_DETAIL
(
    ETL_BIZ_DT                 STRING      COMMENT 'ETL业务日期'
   ,ETL_PROC_TM                STRING      COMMENT 'ETL处理时间'
   -- 组织维度
   ,ORG_ID                     STRING      COMMENT '组织ID'
   -- 养户维度（含扩展属性）
   ,REARER_ID                  STRING      COMMENT '养户ID'
   ,REARER_NO                  STRING      COMMENT '养户编码'
   ,REARER_NM                  STRING      COMMENT '养户名称'
   ,REARER_MANAGER_ID          STRING      COMMENT '养户管理员ID'
   ,REARER_MANAGER_NM          STRING      COMMENT '养户管理员姓名'
   -- 猪群维度（含扩展属性）
   ,REARER_POP_ID              STRING      COMMENT '猪群ID'
   ,REARER_POP_NO              STRING      COMMENT '猪群编码'
   ,REARER_POP_NM              STRING      COMMENT '猪群名称'
   ,REARER_POP_SEED_DT         STRING      COMMENT '进苗日期'
   ,REARER_POP_SEED_QTY        BIGINT      COMMENT '进苗数'
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
) COMMENT '异常农户清单明细ADS（支撑异常农户清单页面）'
STORED AS PARQUET
;
*/

INSERT OVERWRITE TABLE WCUBE.ADS_ALERT_DETAIL
SELECT
     A.ETL_BIZ_DT                                           AS ETL_BIZ_DT
   ,A.ETL_PROC_TM                                           AS ETL_PROC_TM
   -- 组织维度
   ,A.ORG_ID                                                 AS ORG_ID
   -- 养户维度（含扩展属性）
   ,A.REARER_ID                                              AS REARER_ID
   ,A.REARER_NO                                              AS REARER_NO
   ,A.REARER_NM                                              AS REARER_NM
   ,A.REARER_MANAGER_ID                                      AS REARER_MANAGER_ID
   ,A.REARER_MANAGER_NM                                      AS REARER_MANAGER_NM
   -- 猪群维度（含扩展属性）
   ,A.REARER_POP_ID                                          AS REARER_POP_ID
   ,A.REARER_POP_NO                                          AS REARER_POP_NO
   ,A.REARER_POP_NM                                          AS REARER_POP_NM
   ,A.REARER_POP_SEED_DT                                     AS REARER_POP_SEED_DT
   ,A.REARER_POP_SEED_QTY                                    AS REARER_POP_SEED_QTY
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

FROM WCUBE.FACT_ALERT_EVENT A
;
