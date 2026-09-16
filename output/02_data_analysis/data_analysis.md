# 农户生产异常预警分析 - 数据分析报告

## 1. 数据资产分析

### 1.1 源数据表概览

| 逻辑表名 | 物理表名 | 业务角色 | 表类型 | 说明 |
|---------|---------|---------|--------|------|
| wens_production_anomaly | tk_wens_production_anomal | 预警事件主表 | transaction_data | 核心事实数据，支撑大部分指标 |
| wens_patrol_ticket | tk_wens_patrol_ticket | 巡查工单主表 | transaction_data | 支撑有效干涉率和归因分析 |
| wens_rearer_farm_pig | tk_wens_rea_farm_info | 养户维度表 | dimension_data | 支撑总养户数和养户属性 |
| wens_recbrlrflk_pig | tk_wens_recbrlrflk | 猪群维度表 | dimension_data | 支撑猪群属性和异常农户清单 |
| wens_handle_strategy | tk_wens_handle_strategy | 策略参考表 | auxiliary_data | 支撑归因分析中的风险分类 |

### 1.2 指标-数据表映射

| 指标ID | 指标名称 | 主要来源表 | 辅助来源表 |
|--------|---------|-----------|-----------|
| M01 | 生产异常农户总数 | wens_production_anomaly | — |
| M02 | 持续中预警农户数 | wens_production_anomaly | — |
| M03 | 持续中-需巡查农户数 | wens_production_anomaly | — |
| M04 | 持续中-无需巡查农户数 | wens_production_anomaly | — |
| M05 | 今日仅通知农户数 | wens_production_anomaly | — |
| M06 | 预警关闭占比 | wens_production_anomaly | — |
| M07 | 平均持续时长 | wens_production_anomaly | — |
| M08 | 7天复发率 | wens_production_anomaly | — |
| M09 | 有效干涉率 | wens_patrol_ticket | — |
| C01 | 异常农户占比 | wens_production_anomaly | wens_rearer_farm_pig |
| T01 | 按预警指标趋势 | wens_production_anomaly | — |
| T02 | 按预警等级趋势 | wens_production_anomaly | — |
| T03 | 有效干涉率趋势 | wens_patrol_ticket | — |
| T04 | 平均持续时长趋势 | wens_production_anomaly | — |
| T05 | 7天复发率趋势 | wens_production_anomaly | — |

---

## 2. 表粒度分析

### 2.1 wens_production_anomaly（预警事件表）

| 维度 | 说明 |
|------|------|
| **业务粒度** | 一条记录 = 一次生产异常预警事件 |
| **技术粒度** | 单据级（每行一条预警单据，含主表和分录） |
| **候选主键** | fbillno（单据编号） |
| **近似唯一键** | forgid + fk_wens_basedatafield + fk_wens_recbrlrflk_pig + fk_wens_alert_metric + fk_wens_alarm_level + fk_wens_alarm_time |
| **粒度依据** | fbillno为唯一标识；每条记录关联一个养户+一个猪群；一个养户可有多条不同预警 |
| **置信度** | high |

**验证项：**
- fbillno 是否唯一
- 同一养户+猪群+指标+等级是否存在多条记录
- fk_wens_status 枚举值是否只有 1/2/3
- fk_wens_duration 单位确认

### 2.2 wens_patrol_ticket（巡查工单表）

| 维度 | 说明 |
|------|------|
| **业务粒度** | 一条记录 = 一次巡查工单 |
| **技术粒度** | 单据级（每行一条工单，含两个分录表） |
| **候选主键** | fbillno（单据编号） |
| **粒度依据** | fbillno为唯一标识；通过fk_wens_warning_billno关联预警；含两个分录 |
| **置信度** | high |

**验证项：**
- fbillno 是否唯一
- 一条预警是否对应多条工单
- fk_wens_atrol_ticket_stat 枚举值是否只有 1/2/3

### 2.3 wens_rearer_farm_pig（养户档案表）

| 维度 | 说明 |
|------|------|
| **业务粒度** | 一条记录 = 一个养户档案 |
| **技术粒度** | 基础资料级（每行一个养户主数据） |
| **候选主键** | fmasterid（主数据内码） |
| **粒度依据** | fmasterid为唯一标识；fnumber为业务编码 |
| **置信度** | high |

**验证项：**
- fmasterid/fnumber 是否唯一
- fk_wens_status 枚举值分布

### 2.4 wens_recbrlrflk_pig（畜禽档案表）

| 维度 | 说明 |
|------|------|
| **业务粒度** | 一条记录 = 一个猪群 |
| **技术粒度** | 基础资料级（每行一个猪群主数据） |
| **候选主键** | fmasterid（主数据内码） |
| **粒度依据** | fmasterid为唯一标识；每个猪群关联一个养户 |
| **置信度** | high |

**验证项：**
- 一个养户下是否有多个猪群
- fk_wens_flkstatus 枚举值分布

### 2.5 wens_handle_strategy（应对策略表）

| 维度 | 说明 |
|------|------|
| **业务粒度** | 一条记录 = 一条风险-策略映射关系 |
| **技术粒度** | 基础资料级 |
| **候选主键** | fmasterid（主数据内码） |
| **置信度** | medium |

---

## 3. 实体关系分析

### 3.1 ER 关系图

```
┌──────────────┐     fk_wens_basedatafield      ┌──────────────────┐
│              │ ──────────────────────────────→ │                  │
│   预警事件    │                                 │     养户档案      │
│              │     fk_wens_recbrlrflk_pig      │                  │
│  wens_       │ ──────────────────────────────→ ├──────────────────┤
│  production_ │                                 │                  │
│  anomaly     │     fbillno                     │     猪群档案      │
│              │ ←────────────────────────────── │                  │
└──────┬───────┘     fk_wens_warning_billno      │  wens_recbrlrflk │
       │           ┌─────────────────────────────│     _pig         │
       │           │                             └──────────────────┘
       │           │
       │    ┌──────┴───────┐    tk_cause_analysis     ┌──────────────┐
       └──→ │              │ ───────────────────────→ │              │
            │   巡查工单    │    fk_wens_handle_       │   应对策略    │
            │              │    strategy               │              │
            │  wens_       │                           │  wens_       │
            │  patrol_     │                           │  handle_     │
            │  ticket      │                           │  strategy    │
            └──────────────┘                           └──────────────┘
```

### 3.2 关系明细

| 源表 | 目标表 | 关系类型 | 关联字段 | 置信度 |
|------|--------|---------|---------|--------|
| wens_production_anomaly | wens_rearer_farm_pig | many_to_one | fk_wens_basedatafield = fmasterid | high |
| wens_production_anomaly | wens_recbrlrflk_pig | many_to_one | fk_wens_recbrlrflk_pig = fmasterid | high |
| wens_patrol_ticket | wens_production_anomaly | many_to_one | fk_wens_warning_billno = fbillno | high |
| wens_patrol_ticket | wens_rearer_farm_pig | many_to_one | fk_wens_basedatafield = fmasterid | high |
| wens_patrol_ticket | wens_recbrlrflk_pig | many_to_one | fk_wens_recbrlrflk_pig = fmasterid | high |
| wens_patrol_ticket.tk_cause_analysis | wens_handle_strategy | many_to_many | fk_wens_handle_strategy = fmasterid | high |
| wens_rearer_farm_pig | wens_recbrlrflk_pig | one_to_many | fmasterid = fk_wens_recrearer | high |

---

## 4. 指标实现分析

### 4.1 M01 生产异常农户总数

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_basedatafield（养户）, fk_wens_status（预警状态）
- **技术逻辑**：筛选 fk_wens_status IN ('1','3')，按 fk_wens_basedatafield 去重计数
- **伪代码**：`COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status IN ('1','3')`
- **风险**：需确认是否过滤单据状态

### 4.2 M02 持续中预警农户数

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_basedatafield, fk_wens_status
- **技术逻辑**：筛选 fk_wens_status = '1'，按养户去重计数
- **伪代码**：`COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status = '1'`

### 4.3 M03 持续中-需巡查农户数

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_basedatafield, fk_wens_status, fk_wens_is_generate_ticke
- **技术逻辑**：筛选持续中且是否巡查为是，按养户去重计数
- **伪代码**：`COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status='1' AND fk_wens_is_generate_ticke='是'`
- **风险**：fk_wens_is_generate_ticke 枚举值待确认

### 4.4 M04 持续中-无需巡查农户数

- **数据来源**：wens_production_anomaly
- **技术逻辑**：筛选持续中且是否巡查为否，按养户去重计数
- **风险**：同M03

### 4.5 M05 今日仅通知农户数

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_basedatafield, fk_wens_status, fk_wens_alarm_time
- **技术逻辑**：筛选仅通知状态且预警时间为当日，按养户去重计数
- **伪代码**：`COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status='3' AND DATE(fk_wens_alarm_time)=CURRENT_DATE`

### 4.6 M06 预警关闭占比

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_status
- **技术逻辑**：已关闭记录数 / 全部记录数
- **伪代码**：`SUM(CASE WHEN fk_wens_status='2' THEN 1 ELSE 0 END) / COUNT(*)`
- **风险**：按月还是全量统计待确认

### 4.7 M07 平均持续时长

- **数据来源**：wens_production_anomaly
- **关键字段**：fk_wens_duration
- **技术逻辑**：对持续时长字段取平均值
- **伪代码**：`AVG(fk_wens_duration)`
- **结论**：单位虽不明确但全局统一，不影响趋势分析和对比

### 4.8 M08 7天复发率

- **数据来源**：wens_production_anomaly
- **关键字段**：forgid, fk_wens_basedatafield, fk_wens_recbrlrflk_pig, fk_wens_alert_metric, fk_wens_alarm_level, fk_wens_alarm_time
- **技术逻辑**：按分组条件分组，组内按时间排序，判断相邻预警间隔≤7天，计算有复发的组数/总组数
- **伪代码**：
  ```sql
  WITH grouped AS (
    SELECT ..., LAG(fk_wens_alarm_time) OVER (PARTITION BY ... ORDER BY fk_wens_alarm_time) AS prev_time
    FROM tk_wens_production_anomal
  ),
  recurrence AS (
    SELECT ..., MAX(CASE WHEN DATEDIFF(fk_wens_alarm_time, prev_time) <= 7 THEN 1 ELSE 0 END) AS has_recurrence
    FROM grouped GROUP BY 分组条件
  )
  SELECT SUM(has_recurrence) / COUNT(*) FROM recurrence
  ```
- **风险**：计算复杂，需窗口函数；需确认是否过滤预警状态

### 4.9 M09 有效干涉率

- **数据来源**：wens_patrol_ticket
- **关键字段**：fk_wens_atrol_ticket_stat
- **技术逻辑**：已完成工单数 / 总工单数
- **伪代码**：`SUM(CASE WHEN fk_wens_atrol_ticket_stat='2' THEN 1 ELSE 0 END) / COUNT(*)`

### 4.10 C01 异常农户占比

- **数据来源**：wens_production_anomaly + wens_rearer_farm_pig
- **技术逻辑**：分子=异常农户数（M01），分母=总养户数
- **伪代码**：`M01 / COUNT(*) FROM wens_rearer_farm_pig WHERE fstatus='C' AND fenable='1'`
- **结论**：总养户数 = 已审核(fstatus='C') 且 可用(fenable='1') 的养户档案数

### 4.11 T01-T05 趋势指标

- **通用逻辑**：在原子指标基础上增加 DATE_FORMAT(fk_wens_alarm_time, '%Y-%m') 作为分组维度
- **特殊处理**：T05（7天复发率趋势）需按月切片计算

---

## 5. 数据风险

### 5.1 高风险项

| 风险ID | 影响指标 | 问题描述 | 状态 | 结论 |
|--------|---------|---------|------|------|
| RISK03 | M07, T04 | 持续时长字段单位不明确（天/小时） | ✅ 已解决 | 单位全局统一，不影响趋势分析 |
| RISK05 | C01 | 总养户数统计口径待确认 | ✅ 已解决 | 取 fbillstatus='C' AND fenable='1' 的养户 |
| RISK07 | 异常原因分布, 策略有效性 | 巡查工单两个分录的取数逻辑不明确 | ⚠️ 暂定 | 按需求分析关联逻辑实现，后续变更再调整 |
| RISK11 | 全部指标 | 预警表和巡查工单表的预警指标枚举值有差异 | ✅ 已解决 | 已确认无差异，数据字典解析差异 |

### 5.2 中风险项

| 风险ID | 影响指标 | 问题描述 | 状态 | 结论 |
|--------|---------|---------|------|------|
| RISK01 | M01-M05 | 单据状态过滤条件未明确 | ✅ 已解决 | 需过滤 fbillstatus='C'（已审核） |
| RISK04 | M08, T05 | 7天复发率计算复杂，性能风险 | ⚠️ 已知 | 暂不过滤预警状态，关注性能 |
| RISK08 | M03, M04 | 是否巡查字段枚举值不明确 | ✅ 已解决 | 0=否，1=是 |
| RISK09 | M06 | 预警关闭占比时间范围不明确 | ✅ 已解决 | BI端计算，模型提供明细数据 |
| RISK10 | 异常农户清单 | 猪群编码关联可能失败 | 中 | 待确认 |

### 5.3 低风险项

| 风险ID | 影响指标 | 问题描述 | 影响 |
|--------|---------|---------|------|
| RISK02 | M01-M05 | 养户在不同指标间可能重复计算 | 指标间关系异常 |
| RISK06 | M09, T03 | 巡查工单状态枚举值完整性 | 分母不完整 |

---

## 6. 待确认问题汇总

| 编号 | 问题 | 影响范围 | 状态 | 结论 |
|------|------|---------|------|------|
| 1 | 持续时长字段(fk_wens_duration)的单位是天还是小时？ | M07, T04 | ✅ 已解决 | 单位全局统一，不影响分析 |
| 2 | 总养户数是否过滤饲养状态？ | C01 | ✅ 已解决 | 取 fbillstatus='C' AND fenable='1' |
| 3 | 巡查工单两个分录的取数逻辑？ | 异常原因分布, 策略有效性 | ⚠️ 暂定 | 按需求分析逻辑实现，后续再调整 |
| 4 | 预警表和巡查工单表的预警指标枚举值是否一致？ | 全部关联指标 | ✅ 已解决 | 已确认无差异 |
| 5 | 是否需要过滤单据状态(fbillstatus)？ | M01-M05 | ✅ 已解决 | 需过滤 fbillstatus='C' |
| 6 | 是否巡查字段(fk_wens_is_generate_ticke)的枚举值？ | M03, M04 | ✅ 已解决 | 0=否，1=是 |
| 7 | 预警关闭占比是按月统计还是全量？ | M06 | ✅ 已解决 | BI端计算，模型提供明细 |
| 8 | 7天复发率是否需要额外过滤预警状态？ | M08, T05 | ✅ 已解决 | 暂不过滤 |
