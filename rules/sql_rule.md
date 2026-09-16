# SQL生成规范（sql_rule.md）

## 一、总体分层原则

标准链路：

WENSEAS → FACT → TMP（可选） → ADS

原则： 1. FACT沉淀业务事件。 2. TMP承载复杂加工逻辑。 3.
ADS承载应用展示数据。 4. 禁止ADS成为复杂计算层。

## 二、FACT建设规范

FACT用于沉淀业务过程事件。

必须明确： - 业务过程 - 业务粒度 - 事件时间 - 业务主键 - 来源业务对象

FACT不是指标临时表。

FACT字段设计原则：

FACT除保留当前指标需要字段外，
应保留未来分析可能使用的：

- 业务状态
- 业务分类
- 关联对象
- 时间字段
- 原始业务属性
- 业务度量字段


避免后续分析重复回溯WENSEAS。

禁止： - FACT直接计算指标 - FACT提前聚合 - FACT改变事件粒度

## 三、TMP节点规范

TMP用于： - 复杂计算 - 多来源合并 - 多次聚合 - 结果复用

每个TMP必须定义： - 节点名称 - 粒度 - 输入表 - 输出字段 - 处理逻辑

以下情况必须拆TMP： - 一个FACT多次扫描 - 多次GROUP BY - 复杂JOIN -
多指标复用

## 四、ADS建设规范

ADS用于： - 页面查询 - 分析展示 - 固定粒度服务

ADS不是复杂业务计算层。

推荐：

FACT ↓ TMP_BASE ↓ TMP_METRIC ↓ TMP_FINAL ↓ ADS

禁止： - ADS大量子查询 - ADS重复扫描FACT - ADS直接JOIN多个明细FACT -
ADS承担复杂业务逻辑

ADS类型：

1. 明细服务型ADS

用于：
- 多维分析
- 下钻
- 灵活统计


2. 指标汇总型ADS

用于：
- 固定报表
- 固定指标接口


默认优先明细服务型。

只有明确固定口径需求时建设指标汇总型ADS。


# 五、指标计算职责边界规范


## 1. 数据开发与前端计算职责划分


数据开发负责：

- 提供完整业务明细
- 固化业务粒度
- 提供可分析字段
- 提供公共计算基础


前端负责：

- COUNT
- COUNT DISTINCT
- SUM
- AVG
- 比例计算
- 排名
- 展示层计算


原则：

> ADS优先提供可复用分析明细，而不是固定业务结果指标。



---


## 2. 不需要提前计算的指标


以下类型指标：

原则上不在ADS提前计算。


### 2.1 数量类指标


例如：

农户数：

不要：

```sql
COUNT(DISTINCT REARER_ID)
AS REARER_CNT

应该：

ADS提供：

REARER_ID

由前端：

COUNT(DISTINCT REARER_ID)

计算。

2.2 分类统计指标

例如：

异常农户数：

不要：

CASE WHEN STATUS_CD='1'
THEN COUNT(REARER_ID)
END

应该提供：

REARER_ID
STATUS_CD
ALERT_TYPE_CD

前端根据筛选条件统计。

2.3 比例指标

例如：

异常率：

不要：

ABNORMAL_CNT / TOTAL_CNT

应该提供：

分子基础数据：

异常事件明细

分母基础数据：

全部业务对象明细

由应用层计算。

3. ADS设计原则

ADS优先设计为：

分析明细模型

而不是：

指标结果模型

例如：

推荐：

ads_anomaly_status

粒度：

日期
+
组织
+
养户
+
养户种群
+
预警指标
+
预警等级

字段：

REARER_ID
POP_ID
ALERT_METRIC_CD
ALERT_LEVEL_CD
STATUS_CD

前端可产生：

异常农户数
异常猪群数
各等级数量
趋势分析
4. 需要数据开发计算的指标

以下情况可以在ADS计算：

4.1 复杂业务逻辑

例如：

7天复发标识：

原因：

需要时间窗口判断。

可以生成：

REPEAT_ALERT_FLAG
4.2 多表关联结果

例如：

是否完成干预：

需要：

预警事件

关联

巡查工单

可以生成：

INTERVENTION_STATUS
4.3 业务规则转换

例如：

状态枚举：

1 = 持续中
2 = 已关闭

生成：

STATUS_NM
5. 判断原则

判断一个字段是否应该在ADS计算：

如果字段只是：

COUNT
SUM
AVG
比例
排名

优先不计算。

如果字段需要：

业务规则
时间窗口
多表判断
状态转换

可以计算。

## 六、字段命名规范

数据键：XXX_DK

业务编码：XXX_BK

来源系统ID：XXX_ID

名称：XXX_NM

日期：XXX_DT

时间：XXX_TM

数量：XXX_QTY

金额：XXX_AMT

标识：IS_XXX / IF_XXX

## 七、SQL格式规范

禁止：

SELECT \*

必须明确字段。

字段格式：

SELECT A.ID , A.NAME , A.DT

JOIN条件同行。

WHERE条件保持清晰。

## 八、数据验证规范

必须验证：

-   数据量 COUNT(\*)
-   主键重复
-   金额SUM一致性
-   差异数据

## 九、SQL输出要求

生成SQL必须包含：

1.  DDL
2.  字段COMMENT
3.  INSERT OVERWRITE
4.  TMP节点SQL
5.  ADS最终SQL

每个节点说明： - 节点名称 - 粒度 - 来源 - 作用

## 十、生成前检查

生成SQL前确认：

1.  FACT粒度
2.  TMP粒度
3.  ADS最细粒度
4.  是否存在JOIN放大
5.  是否可以复用已有节点
