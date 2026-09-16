-- ********************************************
-- 目 标 表：  WCUBE.FACT_PATROL_TICKET
-- 所属主题：  农户生产预警
-- 功能描述：  巡查工单事实表
-- 创 建 人：  
-- 创建日期：  2026-09-14
-- 修订日期   修订人 修改内容
-- ********************************************

-- Hive参数设置
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.merge.mapfiles=true;
set hive.merge.mapredfiles=true;

-- DDL
DROP TABLE IF EXISTS WCUBE.FACT_PATROL_TICKET PURGE;

CREATE TABLE WCUBE.FACT_PATROL_TICKET
(
    ETL_BIZ_DT                 STRING      COMMENT 'ETL业务日期'
   ,ETL_PROC_TM                STRING      COMMENT 'ETL处理时间'
   -- 主键
   ,TICKET_DK                  STRING      COMMENT '单据数据键'
   ,TICKET_BK                  STRING      COMMENT '单据编号'
   -- 关联键
   ,ALERT_DK                   STRING      COMMENT '预警数据键'
   -- 养户维度（冗余自 TK_WENS_REA_FARM_INFO）
   ,REARER_ID                  STRING      COMMENT '养户ID（主数据内码）'
   ,REARER_NO                  STRING      COMMENT '养户编码'
   ,REARER_NM                  STRING      COMMENT '养户名称'
   ,REARER_MANAGER_ID          STRING      COMMENT '养户管理员ID'
   -- 猪群维度（冗余自 TK_WENS_RECBRLRFLK）
   ,REARER_POP_ID              STRING      COMMENT '猪群ID（主数据内码）'
   ,REARER_POP_NO              STRING      COMMENT '猪群编码'
   ,REARER_POP_NM              STRING      COMMENT '猪群名称'
   -- 组织
   ,ORG_ID                     STRING      COMMENT '组织ID'
   -- 工单事实
   ,TICKET_STATUS_CD           STRING      COMMENT '巡查工单状态代码'
   ,TICKET_STATUS_NM           STRING      COMMENT '巡查工单状态名称'
   ,EXECUTOR_ID                STRING      COMMENT '执行人ID'
   ,BILL_STATUS_CD             STRING      COMMENT '单据状态代码'
   ,CREATE_TM                  STRING      COMMENT '工单创建时间'
) COMMENT '巡查工单事实表（含养户/猪群退化维度）'
STORED AS PARQUET
TBLPROPERTIES ('parquet.compress'='SNAPPY')
;

-- INSERT SQL
INSERT OVERWRITE TABLE WCUBE.FACT_PATROL_TICKET
SELECT
  '${azkaban.flow.1.days.ago}'                              AS ETL_BIZ_DT              
  ,CURRENT_TIMESTAMP                                         AS ETL_PROC_TM
   -- 主键
   ,A.FID                                                   AS TICKET_DK
   ,A.FBILLNO                                                AS TICKET_BK
   -- 关联键
   ,A.FK_WENS_WARNING_BILLNO                                 AS ALERT_DK
   -- 养户维度
   ,A.FK_WENS_BASEDATAFIELD                                  AS REARER_ID
   ,R.FNUMBER                                                AS REARER_NO
   ,R.FNAME                                                  AS REARER_NM
   ,R.FK_WENS_USERFIELD                                      AS REARER_MANAGER_ID
   -- 猪群维度
   ,A.FK_WENS_RECBRLRFLK_PIG                                 AS REARER_POP_ID
   ,P.FNUMBER                                                AS REARER_POP_NO
   ,P.FNAME                                                  AS REARER_POP_NM
   -- 组织
   ,A.FORGID                                                 AS ORG_ID
   -- 工单事实
   ,A.FK_WENS_ATROL_TICKET_STAT                              AS TICKET_STATUS_CD
   ,CASE A.FK_WENS_ATROL_TICKET_STAT WHEN '1' THEN '未完成'
                                     WHEN '2' THEN '已完成'
                                     WHEN '3' THEN '未完成(过期)'
                                     ELSE '未知'
    END                                                      AS TICKET_STATUS_NM
   ,A.FK_WENS_EXECUTOR                                       AS EXECUTOR_ID
   ,A.FBILLSTATUS                                            AS BILL_STATUS_CD
   ,A.FCREATETIME                                            AS CREATE_TM
FROM WENSEAS.TK_WENS_PATROL_TICKET A
LEFT JOIN WENSEAS.TK_WENS_REA_FARM_INFO R ON A.FK_WENS_BASEDATAFIELD = R.FMASTERID AND R.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
LEFT JOIN WENSEAS.TK_WENS_RECBRLRFLK P ON A.FK_WENS_RECBRLRFLK_PIG = P.FMASTERID AND P.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
WHERE A.FBILLSTATUS = 'C'
AND A.DATEKEY = DATE_SUB(CURRENT_DATE(),1) 
;