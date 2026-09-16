-- ********************************************
-- 目 标 表： WCUBE.FACT_RISK_ANALYSIS
-- 所属主题： 农户生产预警
-- 功能描述： 风险分析事件事实表
-- 原子粒度： 一条记录 = 一个风险分析分录
-- 创 建 人： 
-- 创建日期： 2026-09-13
-- 修订日期   修订人 修改内容
-- ********************************************

-- Hive参数设置
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.merge.mapfiles=true;
SET hive.merge.mapredfiles=true;

-- DDL（首次执行时放开DROP）
/*
DROP TABLE IF EXISTS WCUBE.FACT_RISK_ANALYSIS PURGE;

CREATE TABLE IF NOT EXISTS WCUBE.FACT_RISK_ANALYSIS
(
      RISK_DK                   STRING      COMMENT '风险分析数据键（工单编号+分录ID）'
    , RISK_BK                   STRING      COMMENT '风险分析业务键（工单编号+分录ID）'
    , TICKET_DK                 STRING      COMMENT '关联工单数据键（关联FACT_PATROL_TICKET.TICKET_DK）'
    , ALERT_DK                  STRING      COMMENT '关联预警数据键（关联FACT_PRODUCTION_ANOMALY.ALERT_DK）'
    , REARER_ID                 STRING      COMMENT '养户ID（主数据内码）'
    , REARER_POP_ID             STRING      COMMENT '养户种群ID（主数据内码）'
    , ORG_ID                    STRING      COMMENT '组织ID'
    , RISK_CATEGORY_CD          STRING      COMMENT '风险大类（自定义文本，无独立编码）'
    , RISK_ITEM_CD              STRING      COMMENT '风险项（自定义文本）'
    , STRATEGY_CD               STRING      COMMENT '应对策略（自定义文本）'
    , ADOPT_FLAG                STRING      COMMENT '策略采纳标志（1=是,0=否）'
    , EXECUTE_FLAG              STRING      COMMENT '策略执行标志（1=是,0=否）'
    , ETL_PROC_TM               STRING      COMMENT 'ETL处理时间'
)
COMMENT '风险分析事件事实表（巡查工单分录）'
PARTITIONED BY (DT STRING COMMENT '数据日期（yyyyMMdd）')
STORED AS PARQUET
TBLPROPERTIES ('parquet.compress'='SNAPPY')
;
*/

-- INSERT SQL
-- 说明：TK_WENS_RISK_ITEM_ENTRY 为巡查工单分录表（自定义文本口径），
--      通过 FBILLNO 关联工单表头补齐业务外键；
--      FENTRYID 为苍穹分录表分录主键字段（以实际表结构为准）
INSERT OVERWRITE TABLE WCUBE.FACT_RISK_ANALYSIS PARTITION (DATEKEY)
SELECT
      CONCAT(E.FBILLNO, '_', E.FENTRYID)                    AS RISK_DK
    , CONCAT(E.FBILLNO, '_', E.FENTRYID)                    AS RISK_BK
    , E.FBILLNO                                             AS TICKET_DK
    , T.FK_WENS_WARNING_BILLNO                              AS ALERT_DK
    , T.FK_WENS_BASEDATAFIELD                               AS REARER_ID
    , T.FK_WENS_RECBRLRFLK_PIG                              AS REARER_POP_ID
    , T.FORGID                                              AS ORG_ID

    , E.FK_WENS_RISK_ITEM                                   AS RISK_CATEGORY_CD
    , E.FK_WENS_CUSTOM_RISK_ITEME                           AS RISK_ITEM_CD
    , E.FK_WENS_CUSTOM_POLICY                               AS STRATEGY_CD
    , CASE E.FK_WENS_CUSTOM_IS_ADOPT
        WHEN '1' THEN '1'
        ELSE '0'
      END                                                   AS ADOPT_FLAG
    , CASE E.FK_WENS_CUSTOM_IS_EXECUTE
        WHEN '1' THEN '1'
        ELSE '0'
      END                                                   AS EXECUTE_FLAG
    , DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyy-MM-dd HH:mm:ss') AS ETL_PROC_TM
FROM WENSEAS.TK_WENS_RISK_ITEM_ENTRY E
LEFT JOIN WENSEAS.TK_WENS_PATROL_TICKET T ON E.FBILLNO = T.FBILLNO
WHERE 1 = 1
 AND T.FBILLSTATUS = 'C'          -- 已审核，待确认
;