# 农户生产异常预警分析 - 模型设计文档

## 1. 模型建设策略

### 1.1 建设方法

采用 **维度建模（Kimball）** 方法，以业务过程为中心设计FACT表，配合独立维度表支撑ADS应用。

### 1.2 目标层次

```
WENSEAS（业务数据源）
    ↓
FACT（业务事件沉淀）
    ↓
ADS（应用支撑）
```

### 1.3 设计原则

1. **FACT沉淀业务事件**：明确粒度为一条事件记录，避免ADS直接依赖WENSEAS
2. **维度表独立建设**：养户、猪群等维度被多个FACT复用，保证口径统一
3. **ADS按维度体系拆分**：非按页面数量拆分，支持细粒度上卷
4. **计算类指标BI端完成**：占比、比率等由前端计算，模型提供明细数据
5. **暂不建设DWS**：当前指标较少，FACT可直接支撑ADS

---

## 2. 业务过程识别

| 业务过程 | 过程类型 | 建模模式 | 业务粒度 | 来源业务对象 |
|---------|---------|---------|---------|------------|
| 预警事件产生 | event | fact_event | 一条记录 = 一次生产异常预警事件 | 预警事件、养户、猪群 |
| 巡查处理 | event | fact_event | 一条记录 = 一次巡查工单 | 巡查工单、预警事件、养户、猪群 |

---

## 3. FACT设计

### 3.1 建设决策

**状态**：mandatory（必须建设）

**原因**：
- 预警事件和巡查工单是核心业务过程，需要沉淀为可复用的FACT模型
- 避免ADS直接依赖WENSEAS源表，保证指标口径统一
- 两个业务过程独立，需分别建FACT

### 3.2 fact_wens_alert_event（预警事件FACT）

| 属性 | 说明 |
|------|------|
| **表名** | fact_wens_alert_event |
| **业务过程** | 预警事件产生 |
| **FACT类型** | transaction_fact（事务事实表） |
| **粒度** | 一条记录 = 一次生产异常预警事件 |
| **来源表** | wens_production_anomaly（WENSEAS） |
| **关联维度** | dim_wens_farmer、dim_wens_flock、dim_wens_alert_metric、dim_wens_alarm_level、dim_wens_alert_status |
| **支撑指标** | M01、M02、M03、M04、M05、M06、M07、M08、T01、T02、T04、T05 |
| **度量** | alert_duration（持续时长）、alert_value（触发预警时数值） |
| **过滤条件** | fbillstatus = 'C'（已审核） |

**设计原因**：
- 12个指标依赖此数据，是核心FACT
- 沉淀为FACT可避免ADS直接依赖WENSEAS，保证口径统一
- 过滤已审核状态，确保数据质量

### 3.3 fact_wens_patrol_ticket（巡查工单FACT）

| 属性 | 说明 |
|------|------|
| **表名** | fact_wens_patrol_ticket |
| **业务过程** | 巡查处理 |
| **FACT类型** | transaction_fact（事务事实表） |
| **粒度** | 一条记录 = 一次巡查工单 |
| **来源表** | wens_patrol_ticket（WENSEAS） |
| **关联维度** | dim_wens_farmer、dim_wens_flock、dim_wens_alert_metric、dim_wens_alarm_level、dim_wens_patrol_status |
| **支撑指标** | M09、T03、异常原因分布、策略有效性 |
| **度量** | 巡查工单状态（退化维度） |
| **过滤条件** | fbillstatus = 'C'（已审核） |

**设计原因**：
- 巡查工单是独立业务过程，支撑有效干涉率和归因分析
- 与预警事件FACT通过预警单据编号关联
- 两个分录数据需在Mapping阶段处理

---

## 4. 维度设计

### 4.1 维度表清单

| 维度表 | 类型 | 来源 | 说明 |
|--------|------|------|------|
| dim_wens_farmer | standard_dimension | wens_rearer_farm_pig | 养户维度，提供养户属性 |
| dim_wens_flock | standard_dimension | wens_recbrlrflk_pig | 猪群维度，提供猪群属性 |
| dim_wens_alert_metric | standard_dimension | 枚举映射 | 预警指标维度（1-9） |
| dim_wens_alarm_level | standard_dimension | 枚举映射 | 预警等级维度（1-4） |
| dim_wens_alert_status | standard_dimension | 枚举映射 | 预警状态维度（1-3） |
| dim_wens_patrol_status | standard_dimension | 枚举映射 | 巡查工单状态维度（1-3） |
| dim_wens_handle_strategy | standard_dimension | wens_handle_strategy | 应对策略维度 |

### 4.2 维度复用关系

```
                    ┌─────────────────┐
                    │ dim_wens_farmer │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────┴───────┐     │     ┌────────┴───────┐
     │ fact_wens_     │     │     │ fact_wens_     │
     │ alert_event    │     │     │ patrol_ticket  │
     └────────┬───────┘     │     └────────┬───────┘
              │              │              │
              │     ┌────────┴───────┐     │
              └────→│ dim_wens_flock │←────┘
                    └────────────────┘
```

---

## 5. DWS设计

### 5.1 建设决策

**状态**：unnecessary（暂不建设）

**原因**：
- 当前指标数量较少（15个）
- 大部分为明细类或BI端计算类指标
- FACT可直接支撑ADS，无公共汇总逻辑需要复用

**替代方案**：
- 后续如指标数量增加或出现多个ADS复用相同统计逻辑时
- 可建设DWS层沉淀公共汇总（如按月+组织的预警汇总）

---

## 6. ADS设计

### 6.1 ads_wens_alert_analysis（预警分析ADS）

| 属性 | 说明 |
|------|------|
| **表名** | ads_wens_alert_analysis |
| **业务主题** | 预警事件分析 |
| **业务用途** | 支撑预警现状监控、趋势分析和效果评估 |
| **最细粒度** | 一条记录 = 一次已审核的生产异常预警事件 |
| **来源模型** | fact_wens_alert_event、dim_wens_farmer、dim_wens_flock |

**维度**：
- 日期（预警时间）
- 组织
- 养户
- 猪群
- 预警指标
- 预警等级
- 预警状态
- 是否巡查

**上卷粒度**：
- 月份+组织
- 月份+组织+预警指标
- 月份+组织+预警等级
- 月份+组织+养户
- 日+组织
- 组织
- 全量

**承载指标**：
- M01 生产异常农户总数（COUNT DISTINCT 养户）
- M02 持续中预警农户数
- M03 持续中-需巡查农户数
- M04 持续中-无需巡查农户数
- M05 今日仅通知农户数
- M06 预警关闭占比（BI端计算）
- M07 平均持续时长（AVG）
- M08 7天复发率（BI端计算）
- T01 按预警指标趋势
- T02 按预警等级趋势
- T04 平均持续时长趋势
- T05 7天复发率趋势
- C01 异常农户占比（BI端计算）

**服务页面**：
- 核心指标卡
- 持续中预警细分
- 按预警指标趋势（折线图）
- 按预警等级趋势（柱状图）
- 预警清单
- 本月预警效果评估
- 趋势折线图

**拆分原因**：
- 预警分析具有独立的维度体系（日期+组织+养户+猪群+预警指标+预警等级+预警状态）
- 与巡查分析的维度体系不同，需独立设计

### 6.2 ads_wens_patrol_analysis（巡查分析ADS）

| 属性 | 说明 |
|------|------|
| **表名** | ads_wens_patrol_analysis |
| **业务主题** | 巡查工单分析 |
| **业务用途** | 支撑有效干涉率分析和归因分析 |
| **最细粒度** | 一条记录 = 一次已审核的巡查工单 |
| **来源模型** | fact_wens_patrol_ticket、dim_wens_farmer、dim_wens_flock、dim_wens_handle_strategy |

**维度**：
- 日期（创建时间）
- 组织
- 养户
- 猪群
- 预警指标
- 预警等级
- 巡查工单状态
- 风险大类
- 风险项
- 对应策略
- 是否执行
- 是否采纳

**上卷粒度**：
- 月份+组织
- 月份+组织+风险大类
- 月份+组织+风险项
- 组织
- 全量

**承载指标**：
- M09 有效干涉率（BI端计算）
- T03 有效干涉率趋势
- 异常原因分布（BI端计算）
- 策略有效性（BI端计算）

**服务页面**：
- 异常原因分布
- 策略有效性
- 有效干涉率趋势

**拆分原因**：
- 巡查分析的维度体系包含风险大类、风险项、策略等独特维度
- 与预警分析维度不同，需独立设计

### 6.3 ads_wens_alert_detail（异常农户清单ADS）

| 属性 | 说明 |
|------|------|
| **表名** | ads_wens_alert_detail |
| **业务主题** | 异常农户清单 |
| **业务用途** | 支撑异常农户清单展示 |
| **最细粒度** | 一条记录 = 一次已审核的生产异常预警事件 |
| **来源模型** | fact_wens_alert_event、dim_wens_farmer、dim_wens_flock |

**维度**：
- 组织
- 养户
- 猪群编码
- 管理员
- 加权进苗日期
- 苗总数量
- 预警指标
- 预警等级
- 预警状态
- 触发预警时数值
- 预警时间

**服务页面**：
- 异常农户清单

**拆分原因**：
- 异常农户清单为明细展示，需要关联养户和猪群的扩展属性（管理员、进苗信息）
- 作为预警分析ADS的明细补充

---

## 7. 指标承载关系

| 指标ID | 指标名称 | 目标模型 | 目标层 | 计算层 | 说明 |
|--------|---------|---------|--------|--------|------|
| M01 | 生产异常农户总数 | ads_wens_alert_analysis | ADS | ADS | BI端COUNT DISTINCT养户 |
| M02 | 持续中预警农户数 | ads_wens_alert_analysis | ADS | ADS | BI端筛选持续中后去重 |
| M03 | 持续中-需巡查农户数 | ads_wens_alert_analysis | ADS | ADS | BI端筛选持续中+需巡查 |
| M04 | 持续中-无需巡查农户数 | ads_wens_alert_analysis | ADS | ADS | BI端筛选持续中+无需巡查 |
| M05 | 今日仅通知农户数 | ads_wens_alert_analysis | ADS | ADS | BI端筛选仅通知+当日 |
| M06 | 预警关闭占比 | ads_wens_alert_analysis | ADS | ADS | BI端计算占比 |
| M07 | 平均持续时长 | ads_wens_alert_analysis | ADS | ADS | BI端计算AVG |
| M08 | 7天复发率 | ads_wens_alert_analysis | ADS | ADS | BI端计算复发率 |
| M09 | 有效干涉率 | ads_wens_patrol_analysis | ADS | ADS | BI端计算占比 |
| C01 | 异常农户占比 | ads_wens_alert_analysis | ADS | ADS | BI端计算，分子预警ADS分母养户维度 |
| T01 | 按预警指标趋势 | ads_wens_alert_analysis | ADS | ADS | BI端按月聚合 |
| T02 | 按预警等级趋势 | ads_wens_alert_analysis | ADS | ADS | BI端按月聚合 |
| T03 | 有效干涉率趋势 | ads_wens_patrol_analysis | ADS | ADS | BI端按月计算占比 |
| T04 | 平均持续时长趋势 | ads_wens_alert_analysis | ADS | ADS | BI端按月计算AVG |
| T05 | 7天复发率趋势 | ads_wens_alert_analysis | ADS | ADS | BI端按月切片计算 |

---

## 8. 设计决策记录

| 决策点 | 决策 | 原因 | 替代方案 |
|--------|------|------|---------|
| 是否建设FACT层？ | 建设两个FACT表 | 预警事件和巡查工单是核心业务过程，需沉淀为可复用模型 | 不建设FACT，ADS直接依赖WENSEAS（会造成烟囱式开发） |
| 是否建设DWS层？ | 暂不建设 | 指标数量较少，FACT可直接支撑ADS，无公共汇总复用需求 | 后续指标增加时建设DWS沉淀公共汇总 |
| ADS如何拆分？ | 按维度体系拆分为3个ADS | 预警分析和巡查分析维度体系不同，需独立设计 | 按页面数量拆分（错误做法） |
| 计算类指标在哪层？ | BI端计算 | 占比、比率等由前端计算，模型提供明细数据 | 在ADS层预计算（增加复杂度） |
| 维度表是否独立建设？ | 独立建设 | 养户、猪群等维度被多个FACT复用，保证口径统一 | 维度退化到FACT中（不利于复用） |
