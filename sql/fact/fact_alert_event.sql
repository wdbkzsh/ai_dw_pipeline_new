-- ********************************************
-- 目 标 表：  WCUBE.FACT_ALERT_EVENT
-- 所属主题：  农户生产预警
-- 功能描述：  预警事件事实表
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
DROP TABLE IF EXISTS WCUBE.FACT_ALERT_EVENT PURGE;

CREATE TABLE WCUBE.FACT_ALERT_EVENT
(
    ETL_BIZ_DT                 STRING      COMMENT 'ETL业务日期'
   ,ETL_PROC_TM                STRING      COMMENT 'ETL处理时间'
   ,ALERT_DK                   STRING      COMMENT '单据数据键'
   ,ALERT_BK                   STRING      COMMENT '单据编号'
   ,REARER_ID                  STRING      COMMENT '养户ID（主数据内码）'
   ,REARER_NO                  STRING      COMMENT '养户编码'
   ,REARER_NM                  STRING      COMMENT '养户名称'
   ,REARER_MANAGER_ID          STRING      COMMENT '养户管理员ID'
   ,REARER_MANAGER_NM          STRING      COMMENT '养户管理员姓名'
   ,REARER_RAISE_STATUS_CD     STRING      COMMENT '养户饲养状态代码'
   ,REARER_RAISE_STATUS_NM     STRING      COMMENT '养户饲养状态名称'
   ,REARER_USE_STATUS_CD       STRING      COMMENT '养户使用状态代码'
   ,REARER_BILL_STATUS_CD      STRING      COMMENT '养户数据状态代码'
   ,REARER_POP_ID              STRING      COMMENT '猪群ID'
   ,REARER_POP_NO              STRING      COMMENT '猪群编码'
   ,REARER_POP_NM              STRING      COMMENT '猪群名称'
   ,REARER_POP_STATUS_CD       STRING      COMMENT '猪群状态代码'
   ,REARER_POP_STATUS_NM       STRING      COMMENT '猪群状态名称'
   ,REARER_POP_BREED_ID        STRING      COMMENT '饲养品种ID'
   ,REARER_POP_SEED_DT         STRING      COMMENT '进苗日期（首次进苗日期）'
   ,REARER_POP_SEED_QTY        BIGINT      COMMENT '进苗数（苗总数量）'
   ,ORG_ID                     STRING      COMMENT '组织ID'
   ,ALERT_METRIC_CD            STRING      COMMENT '预警指标代码'
   ,ALERT_METRIC_NM            STRING      COMMENT '预警指标名称'
   ,ALERT_LEVEL_CD             STRING      COMMENT '预警等级代码'
   ,ALERT_LEVEL_NM             STRING      COMMENT '预警等级名称'
   ,ALERT_STATUS_CD            STRING      COMMENT '预警状态代码'
   ,ALERT_STATUS_NM            STRING      COMMENT '预警状态名称'
   ,ALERT_TM                   STRING      COMMENT '预警时间'
   ,DURATION_DAY               BIGINT      COMMENT '持续时长（天）'
   ,ALARM_VALUE                STRING      COMMENT '触发预警时数值'
   ,IS_PATROL_FLAG             STRING      COMMENT '是否巡查标志'
   ,BILL_STATUS_CD             STRING      COMMENT '单据状态代码'
   ,REPEAT_ALERT_FLAG          STRING      COMMENT '7天复发标识'
) COMMENT '预警事件事实表'
STORED AS PARQUET
;
*/


WITH TMP_REPEAT_ALERT AS
(
    SELECT
         FBILLNO
       ,CASE
            WHEN COUNT(*) OVER (
                PARTITION BY FORGID
                    ,FK_WENS_BASEDATAFIELD
                    ,FK_WENS_RECBRLRFLK_PIG
                    ,FK_WENS_ALERT_METRIC
                    ,FK_WENS_ALARM_LEVEL
                ORDER BY UNIX_TIMESTAMP(FK_WENS_ALARM_TIME)
                RANGE BETWEEN 604800 PRECEDING AND CURRENT ROW
            ) > 1 THEN '1'
            ELSE '0'
        END AS REPEAT_ALERT_FLAG
    FROM WENSEAS.TK_WENS_PRODUCTION_ANOMAL
    WHERE FBILLSTATUS = 'C'
    AND DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
)

-- INSERT SQL
INSERT OVERWRITE TABLE WCUBE.FACT_ALERT_EVENT
SELECT
  '${azkaban.flow.1.days.ago}'                              AS ETL_BIZ_DT              
  ,CURRENT_TIMESTAMP                                         AS ETL_PROC_TM
   ,A.FBILLNO                                                AS ALERT_DK
   ,A.FBILLNO                                                AS ALERT_BK
   ,A.FK_WENS_BASEDATAFIELD                                  AS REARER_ID
   ,R.FNUMBER                                                AS REARER_NO
   ,R.FNAME                                                  AS REARER_NM
   ,R.FK_WENS_USERFIELD                                      AS REARER_MANAGER_ID
   ,U.FNAME                                                  AS REARER_MANAGER_NM
   ,R.FK_WENS_STATUS                                         AS REARER_RAISE_STATUS_CD
   ,CASE R.FK_WENS_STATUS WHEN '1' THEN '在养'
                           WHEN '2' THEN '空栏中'
                           WHEN '3' THEN '已停养'
                           WHEN '4' THEN '销户'
                           ELSE '未知'
    END                                                      AS REARER_RAISE_STATUS_NM
   ,R.FENABLE                                                AS REARER_USE_STATUS_CD
   ,R.FSTATUS                                                AS REARER_BILL_STATUS_CD
   ,A.FK_WENS_RECBRLRFLK_PIG                                 AS REARER_POP_ID
   ,P.FNUMBER                                                AS REARER_POP_NO
   ,P.FNAME                                                  AS REARER_POP_NM
   ,P.FK_WENS_FLKSTATUS                                      AS REARER_POP_STATUS_CD
   ,CASE P.FK_WENS_FLKSTATUS WHEN '0' THEN '申请领苗'
                              WHEN '1' THEN '在养'
                              WHEN '2' THEN '已上市'
                              WHEN '3' THEN '已结算'
                              ELSE '未知'
    END                                                      AS REARER_POP_STATUS_NM
   ,P.FK_WENS_MATERIAL                                       AS REARER_POP_BREED_ID
   ,P.FK_WENS_SEEDTIME                                       AS REARER_POP_SEED_DT
   ,CAST(P.FK_WENS_CHICKQTY AS BIGINT)                       AS REARER_POP_SEED_QTY
   ,A.FORGID                                                 AS ORG_ID
   ,A.FK_WENS_ALERT_METRIC                                   AS ALERT_METRIC_CD
   ,CASE A.FK_WENS_ALERT_METRIC WHEN '1' THEN '两周死淘率'
                                WHEN '2' THEN '五周死淘率'
                                WHEN '3' THEN '单日死淘率'
                                WHEN '4' THEN '连续2天死淘率'
                                WHEN '5' THEN '连续3天死淘率'
                                WHEN '6' THEN '连续4天死淘率'
                                WHEN '7' THEN '单日采食量'
                                WHEN '8' THEN '连续2天采食量'
                                WHEN '9' THEN '连续3天采食量'
                                ELSE '未知'
    END                                                      AS ALERT_METRIC_NM
   ,A.FK_WENS_ALARM_LEVEL                                    AS ALERT_LEVEL_CD
   ,CASE A.FK_WENS_ALARM_LEVEL WHEN '1' THEN '一级告警'
                               WHEN '2' THEN '二级告警'
                               WHEN '3' THEN '三级告警'
                               WHEN '4' THEN '四级告警'
                               ELSE '未知'
    END                                                      AS ALERT_LEVEL_NM
   ,A.FK_WENS_STATUS                                         AS ALERT_STATUS_CD
   ,CASE A.FK_WENS_STATUS WHEN '1' THEN '持续中'
                          WHEN '2' THEN '已关闭'
                          WHEN '3' THEN '仅通知'
                          ELSE '未知'
    END                                                      AS ALERT_STATUS_NM
   ,A.FK_WENS_ALARM_TIME                                     AS ALERT_TM
   ,CAST(A.FK_WENS_DURATION AS BIGINT)                       AS DURATION_DAY
   ,A.FK_WENS_ALARM_VALUE                                    AS ALARM_VALUE
   ,A.FK_WENS_IS_GENERATE_TICKE                              AS IS_PATROL_FLAG
   ,A.FBILLSTATUS                                            AS BILL_STATUS_CD
   -- 7天复发标识
   ,B.REPEAT_ALERT_FLAG                                      AS REPEAT_ALERT_FLAG
FROM WENSEAS.TK_WENS_PRODUCTION_ANOMAL A
LEFT JOIN WENSEAS.TK_WENS_REA_FARM_INFO R ON A.FK_WENS_BASEDATAFIELD = R.FMASTERID AND R.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
LEFT JOIN WENSEAS.TK_WENS_RECBRLRFLK P ON A.FK_WENS_RECBRLRFLK_PIG = P.FMASTERID AND P.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
LEFT JOIN WENSEAS.BOS_USER U ON R.FK_WENS_USERFIELD = U.FID  AND U.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
LEFT JOIN TMP_REPEAT_ALERT B ON A.FBILLNO = B.FBILLNO  
WHERE A.FBILLSTATUS = 'C'
AND A.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
;