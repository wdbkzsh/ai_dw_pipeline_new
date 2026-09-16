# SQL代码风格规范（SQL Style Rule）


## 1. 适用范围


本规范用于温氏数仓SQL开发。


适用：

- FACT建表SQL
- TMP计算SQL
- ADS应用SQL


本规范只约束SQL代码风格。


业务模型规则遵循：

sql_rule.md



---


# 一、文件头规范


所有SQL文件必须包含文件说明。


格式：


```sql
--****************************************************

-- 目标表：  WCUBE.TABLE_NAME

-- 所属主题：  主题名称

-- 功能描述：  中文业务描述

-- 创建人：

-- 创建日期：

-- 修订日期   修订人 修改内容

--****************************************************

要求：

使用中文描述业务含义
保留修订记录
目标表名称必须准确
二、DDL编写规范
1. 建表格式

统一：

DROP TABLE IF EXISTS WCUBE.TABLE_NAME PURGE;


CREATE TABLE WCUBE.TABLE_NAME
(
      FIELD_A          STRING COMMENT '字段说明'
    , FIELD_B          STRING COMMENT '字段说明'
)
COMMENT '表中文名称'
;

要求：

DROP和CREATE分开
字段逗号放字段前
最后一列不加逗号
三、字段排列规范

字段顺序统一：

ETL字段

↓

主键字段

↓

业务关联字段

↓

状态字段

↓

日期字段

↓

数量字段

↓

金额字段

↓

其他属性字段

例如：

CREATE TABLE FACT_ORDER
(
      ETL_BIZ_DT       STRING COMMENT 'ETL业务日期'
    , ETL_PROC_TM      STRING COMMENT 'ETL处理时间'

    , BILL_DK          STRING COMMENT '单据数据键'
    , BILL_BK          STRING COMMENT '单据编号'

    , STATUS_CD        STRING COMMENT '状态代码'

    , BILL_DT          STRING COMMENT '单据日期'

    , QTY              DOUBLE COMMENT '数量'

    , AMT              DOUBLE COMMENT '金额'
)
;
四、SELECT格式规范
1. 禁止SELECT *

禁止：

SELECT *
FROM TABLE

必须明确字段：

SELECT

      A.FIELD_A
    , A.FIELD_B
    , A.FIELD_C

FROM TABLE A
2. 字段逗号格式

统一：

逗号放字段前。

正确：

SELECT

      A.ID
    , A.NAME
    , A.STATUS

FROM TABLE A

禁止：

SELECT
A.ID,
A.NAME,
A.STATUS
3. AS格式

统一：

A.FIELD AS TARGET_FIELD

例如：

A.FID AS BILL_DK
五、JOIN格式规范
1. JOIN换行规则

推荐：

FROM TABLE_A A

LEFT JOIN TABLE_B B ON A.ID = B.ID

LEFT JOIN TABLE_C C ON B.TYPE = C.TYPE

WHERE 1=1

JOIN条件：

尽量保持一行。

禁止：

LEFT JOIN TABLE_B B

ON

A.ID=B.ID

AND

A.TYPE=B.TYPE
2. 多条件JOIN

超过两个条件可以换行：

LEFT JOIN TABLE_B B 
ON A.ID = B.ID
AND A.DATEKEY = B.DATEKEY

规则：

ON第一条件同行
后续AND换行
六、WHERE格式规范

统一：

WHERE 1=1

  AND A.STATUS='C'

  AND A.DATEKEY = DATE_SUB(CURRENT_DATE(),1)

要求：

第一行WHERE 1=1
后续条件全部AND
AND缩进两个空格
七、CASE WHEN格式规范

统一：

CASE
    WHEN STATUS_CD='1' THEN '正常'
    WHEN STATUS_CD='2' THEN '关闭'
    ELSE NULL
END AS STATUS_NM

要求：

WHEN缩进
THEN同行
END独立
八、INSERT规范

统一：

INSERT OVERWRITE TABLE WCUBE.TABLE_NAME


SELECT

      FIELD_A
    , FIELD_B

FROM SOURCE_TABLE
WHERE 1=1

;

要求：

INSERT和SELECT之间空一行。

九、临时节点SQL规范

TMP节点必须：

单独建表
单独INSERT
有业务说明

例如：

-- TMP说明：
-- 粒度：
-- 一个预警事件

INSERT OVERWRITE TABLE TMP_ALERT


SELECT

      ALERT_ID
    , REARER_ID

FROM SOURCE
;
十、注释规范
1. 字段注释

DDL必须包含COMMENT。

例如：

REARER_DK STRING COMMENT '养户数据键'
2. SQL逻辑注释

复杂逻辑必须说明。

例如：

-- 猪业务状态与禽业务状态枚举不同，此处分别转换
CASE
...
END
十一、Hive参数规范

FACT、ADS大表建议包含：

set hive.exec.dynamic.partition=true;

set hive.exec.dynamic.partition.mode=nonstrict;

set hive.merge.mapfiles=true;

set hive.merge.mapredfiles=true;
十二、空值处理格式
字符串

推荐：

CASE
WHEN FIELD IS NULL
OR TRIM(FIELD)=''
THEN NULL
END
数值

推荐：

NVL(AMT,0)
十三、日期处理规范
当天数据

统一：

DATEKEY = DATE_SUB(CURRENT_DATE(),1)
日期截取

推荐：

SUBSTR(FIELD,1,10)
十四、SQL可读性规范

要求：

关键SQL块之间空行
一个字段一行
一个JOIN一行
一个过滤条件一行

禁止：

超长单行SQL。

十五、禁止事项

禁止：

SELECT *
字段逗号放后
SQL全部压缩一行
无注释复杂CASE
无格式嵌套SQL
使用不统一大小写
随意修改已有SQL风格