Step 7：数据模型字段 Mapping 分析
1. 分析目标

基于已完成的：

business_analysis.md
data_analysis.md
data_asset_analysis.yaml
metric_implementation.yaml
model_design.md
model_design.yaml

生成数据模型字段级 Mapping 分析。

本阶段目标：

明确目标模型字段如何由来源数据加工生成，为 ETL 开发提供实现依据。

2. 分析边界
2.1 本阶段负责

必须分析：

FACT字段来源
ADS字段来源
字段转换逻辑
主键生成规则
维度关联关系
Join条件
过滤条件
聚合逻辑
数据质量校验
2.2 本阶段禁止

禁止：

重新分析业务需求
修改业务对象定义
修改FACT粒度
修改ADS设计
新建DIM设计
直接绕过FACT连接业务源表生成ADS

原则：

业务分析决定统计什么

模型设计决定存什么

Mapping决定怎么加工
3. Mapping对象范围

必须覆盖以下模型：

FACT层
fact_production_anomaly

业务过程：

生产异常预警事件

粒度：

一条记录 =
一个养户种群对应的一次生产异常预警事件

来源：

event_source:

  tk_wens_production_anomal


dimension_reference:

  dim_rearer

  dim_rearer_pop
fact_patrol_ticket

业务过程：

巡查工单处理事件

粒度：

一条记录 =
一个巡查工单

来源：

event_source:

  tk_wens_patrol_ticket

关联：

parent_reference:

  fact_production_anomaly
fact_risk_analysis

业务过程：

风险分析事件

粒度：

一条记录 =
一个风险分析分录

来源：

event_source:

  tk_wens_risk_item_entry


parent_reference:

  tk_wens_patrol_ticket
4. 字段 Mapping 定义规范

每个目标字段必须包含以下信息：

target_field

目标模型字段名称。

示例：

rearer_dk
target_comment

目标字段业务含义。

示例：

养户数据键
mapping_type

字段来源类型。

枚举：

direct

lookup

derived

aggregate

constant
direct

直接映射。

示例：

fact_production_anomaly.alert_status

↓

tk_wens_production_anomal.fk_wens_status
lookup

维度查找。

示例：

来源：

production_anomaly.fk_wens_basedatafield


关联：

dim_rearer.rearer_dk

生成：

rearer_dk
derived

计算生成。

示例：

warning_duration_days

=

fk_wens_duration
aggregate

聚合生成。

示例：

warning_farmer_cnt

=

COUNT(DISTINCT rearer_dk)
constant

固定值。

示例：

source_system='WENS'
5. 来源类型定义

所有来源必须区分：

event_source

业务事件来源。

例如：

event_source:

 tk_wens_production_anomal
dimension_reference

维度引用。

例如：

dimension_reference:

 dim_rearer

 dim_rearer_pop

说明：

维度参与字段补充和分析关联。

不代表事实来源。

parent_reference

父业务关联。

例如：

fact_risk_analysis

↓

fact_patrol_ticket
lookup_reference

辅助查询。

例如：

策略配置表。

6. FACT Mapping要求
6.1 fact_production_anomaly

必须输出：

主键

来源：

fbillno

目标：

alert_id
维度键

必须包含：

目标	来源
rearer_dk	fk_wens_basedatafield + dim_rearer
rearer_pop_dk	fk_wens_recbrlrflk_pig + dim_rearer_pop
事实字段

至少包含：

alert_metric
alert_level
alert_status
alert_time
duration
6.2 fact_patrol_ticket

必须包含：

ticket_id
alert_id
rearer_dk
rearer_pop_dk
ticket_status
6.3 fact_risk_analysis

必须包含：

risk_category
risk_item
strategy
adopt_flag

来源：

风险分析分录。

7. ADS Mapping要求

ADS必须遵循：

FACT

↓

聚合

↓

ADS

禁止：

业务表

↓

ADS
ADS001 ads_anomaly_status

来源：

fact_production_anomaly
fact_patrol_ticket

说明：

其中：

fact_patrol_ticket：

仅用于：

巡查处理指标
干预效果指标

不作为异常状态基础数据来源。

ADS002 ads_cause_analysis

来源：

fact_risk_analysis

fact_patrol_ticket

fact_production_anomaly

用于：

风险分布
策略分析
策略采纳分析
8. 聚合逻辑要求

所有ADS指标必须明确：

group_by

例如：

dt

org_dk

rearer_dk

rearer_pop_dk

alert_metric

alert_level
aggregation_logic

示例：

数量：

COUNT(DISTINCT alert_id)

平均：

AVG(duration)

比例：

numerator / denominator
9. Join规则要求

每个关联必须描述：

join_key

例如：

production_anomaly.fk_wens_basedatafield

=

dim_rearer.rearer_dk
join_type

例如：

LEFT JOIN
join_reason

例如：

补充养户维度属性
10. 过滤规则

必须输出：

例如：

生产异常：

fbillstatus='C'

养户：

rearer_status_cd='ACTIVE'

如未知：

必须标记：

待确认

禁止猜测。

11. 数据质量校验

每个模型必须输出：

主键唯一性

示例：

fact_production_anomaly:

alert_id唯一
粒度校验

示例：

alert_id + rearer_pop_dk 唯一
关联完整性

示例：

生产异常必须能够关联养户维度
空值检查

示例：

rearer_pop_dk不能为空
12. 输出文件

生成：

04_mapping/

├── mapping_analysis.md

├── mapping_schema.yaml

├── mapping.yaml

└── mapping_question_list.md
13. 输出质量要求

最终输出必须满足：

检查项	要求
字段级映射	必须
来源字段	必须
转换逻辑	必须
Join条件	必须
聚合逻辑	必须
粒度校验	必须
未知信息	进入问题清单
业务重新解释	禁止
设计原则

Mapping阶段只回答：

数据如何从来源进入目标模型。

不回答：

为什么业务需要这个指标。

不重新设计：

业务对象
FACT
DIM
ADS

文档版本：1.0

模块：04_mapping

状态：用于生成 mapping_schema.yaml 与 mapping.yaml