# 数据分析文档

## 项目信息
- **项目名称：** 农户生产异常预警分析看板
- **项目ID：** wens_dw_project
- **生成日期：** 2026-09-10
- **文档版本：** 1.0

---

## 1. 数据资产分析

### 1.1 源数据表概览

| 表名 | 物理表名 | 业务角色 | 主要用途 |
|------|----------|----------|----------|
| wens_rearer_farm_pig | tk_wens_rea_farm_info | 主数据表 | 存储养户基本信息 |
| wens_recbrlrflk_pig | tk_wens_recbrlrflk | 主数据表 | 存储猪群基本信息 |
| wens_production_anomaly | tk_wens_production_anomal | 业务单据表 | 存储预警记录 |
| wens_patrol_ticket | tk_wens_patrol_ticket | 业务单据表 | 存储巡查记录 |
| wens_handle_strategy | tk_wens_handle_strategy | 基础资料表 | 存储策略配置 |

### 1.2 业务对象与源表映射

#### 养户（E001）
- **主表：** wens_rearer_farm_pig
- **主键：** fmasterid
- **关键字段：**
  - fnumber：养户编码
  - fname：养户名称
  - fenable：使用状态（0=禁用, 1=可用）
  - fk_wens_status：饲养状态（1=在养, 2=空栏中, 3=已停养, 4=销户）
  - fstatus：数据状态（A=暂存, B=已提交, C=已审核）

#### 猪群（E002）
- **主表：** wens_recbrlrflk_pig
- **主键：** fmasterid
- **关键字段：**
  - fnumber：猪群编码
  - fk_wens_recrearer：关联养户
  - fk_wens_flkstatus：猪群状态（0=申请领苗, 1=在养, 2=已上市, 3=已结算）
  - fk_wens_stockqty：存栏量
  - fk_wens_deadqty：总死淘数

#### 生产异常预警（E003）
- **主表：** wens_production_anomaly
- **主键：** fbillno
- **关键字段：**
  - fk_wens_basedatafield：关联养户
  - fk_wens_recbrlrflk_pig：关联猪群
  - fk_wens_alert_metric：预警指标（1=两周死淘率, 2=五周死淘率, ...）
  - fk_wens_alarm_level：预警等级（1=一级告警, 2=二级告警, 3=三级告警, 4=四级告警）
  - fk_wens_status：预警状态（1=持续中, 2=已关闭, 3=仅通知）
  - fk_wens_alarm_time：预警时间
  - fk_wens_duration：持续时长

#### 巡查工单（E004）
- **主表：** wens_patrol_ticket
- **主键：** fbillno
- **关键字段：**
  - fk_wens_atrol_ticket_stat：工单状态（1=未完成, 2=已完成, 3=未完成(过期)）
  - fk_wens_warning_billno：关联预警单据编号
- **分录：**
  - tk_wens_risk_item_entry：风险项分录
  - tk_cause_analysis：原因分析分录

#### 应对策略（E005）
- **主表：** wens_handle_strategy
- **主键：** fnumber
- **关键字段：**
  - fname：策略名称
  - fk_wens_patrol_risk_type：风险大类
  - fk_wens_risk_project：风险项

---

## 2. 表粒度分析

### 2.1 粒度定义

| 表名 | 业务粒度 | 技术粒度 | 主键 | 置信度 |
|------|----------|----------|------|--------|
| wens_rearer_farm_pig | 一个养户一条记录 | 单一实体 | fmasterid | 高 |
| wens_recbrlrflk_pig | 一个猪群一条记录 | 单一实体 | fmasterid | 高 |
| wens_production_anomaly | 一条预警记录对应一个预警事件 | 单一实体 | fbillno | 高 |
| wens_patrol_ticket | 一条巡查工单对应一条预警记录 | 单一实体（含分录） | fbillno | 高 |
| wens_handle_strategy | 一条策略配置对应一个风险类型 | 单一实体 | fnumber | 高 |

### 2.2 粒度关系

| 源表 | 目标表 | 关系类型 | 关联字段 | 业务含义 |
|------|--------|----------|----------|----------|
| wens_production_anomaly | wens_rearer_farm_pig | 多对一 | fk_wens_basedatafield -> fmasterid | 一条预警记录属于一个养户 |
| wens_production_anomaly | wens_recbrlrflk_pig | 多对一 | fk_wens_recbrlrflk_pig -> fmasterid | 一条预警记录属于一个猪群 |
| wens_patrol_ticket | wens_production_anomaly | 多对一 | fk_wens_warning_billno -> fbillno | 一条巡查工单对应一条预警记录 |
| wens_patrol_ticket | wens_handle_strategy | 多对多 | tk_cause_analysis.fk_wens_handle_strategy -> fmasterid | 一条巡查工单可以关联多个应对策略 |

---

## 3. 实体关系

### 3.1 ER 图描述

```
[养户] --1:N-- [猪群]
    |               |
    1:N             1:N
    |               |
    v               v
[生产异常预警] --1:N-- [巡查工单] --N:M-- [应对策略]
```

### 3.2 关系说明

1. **养户 -> 猪群（1:N）**
   - 一个养户可以拥有多个猪群
   - 通过 wens_recbrlrflk_pig.fk_wens_recrearer 关联

2. **养户 -> 生产异常预警（1:N）**
   - 一个养户可以有多条预警记录
   - 通过 wens_production_anomaly.fk_wens_basedatafield 关联

3. **猪群 -> 生产异常预警（1:N）**
   - 一个猪群可以有多条预警记录
   - 通过 wens_production_anomaly.fk_wens_recbrlrflk_pig 关联

4. **生产异常预警 -> 巡查工单（1:N）**
   - 一条预警记录可以生成多条巡查工单
   - 通过 wens_patrol_ticket.fk_wens_warning_billno 关联

5. **巡查工单 -> 应对策略（N:M）**
   - 一条巡查工单可以关联多个应对策略
   - 通过 tk_cause_analysis.fk_wens_handle_strategy 关联

---

## 4. 指标实现分析

### 4.1 原子指标

| 指标ID | 指标名称 | 数据来源 | 技术逻辑 | 伪代码 |
|--------|----------|----------|----------|--------|
| M001 | 生产异常农户数 | wens_production_anomaly | 统计预警状态为"持续中"或"仅通知"的养户数量，按养户去重 | COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status IN ('1', '3') |
| M002 | 持续中预警农户数 | wens_production_anomaly | 统计预警状态为"持续中"的养户数量，按养户去重 | COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status = '1' |
| M003 | 需巡查农户数 | wens_production_anomaly | 统计预警状态为"持续中"且需要巡查的养户数量，按养户去重 | COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status = '1' AND fk_wens_is_generate_ticke = '是' |
| M005 | 今日仅通知农户数 | wens_production_anomaly | 统计当前预警状态为"仅通知"的养户数量，按养户去重 | COUNT(DISTINCT fk_wens_basedatafield) WHERE fk_wens_status = '3' |
| M006 | 总养户数 | wens_rearer_farm_pig | 统计使用状态为"可用"、饲养状态为"在养"、数据状态为"已审核"的养户数量 | COUNT(DISTINCT fmasterid) WHERE fenable = '1' AND fk_wens_status = '1' AND fstatus = 'C' |
| M007 | 预警关闭数 | wens_production_anomaly | 统计预警状态为"已关闭"的记录数 | COUNT(*) WHERE fk_wens_status = '2' |
| M008 | 预警总数 | wens_production_anomaly | 统计所有预警记录数 | COUNT(*) |
| M009 | 平均持续时长 | wens_production_anomaly | 计算预警持续时长的平均值 | AVG(fk_wens_duration) |
| M010 | 巡查工单已完成数 | wens_patrol_ticket | 统计巡查工单状态为"已完成"的记录数 | COUNT(*) WHERE fk_wens_atrol_ticket_stat = '2' |
| M011 | 巡查工单总数 | wens_patrol_ticket | 统计所有巡查工单数 | COUNT(*) |
| M012 | 复发记录数 | wens_production_anomaly | 7天内同一组织、养户、猪群、预警指标、预警等级的预警记录视为复发 | 自关联查询，ABS(DATEDIFF(day, a.fk_wens_alarm_time, b.fk_wens_alarm_time)) <= 7 |
| M013 | 风险大类记录数 | wens_patrol_ticket | 按风险大类分组统计巡查工单分录数 | COUNT(*) GROUP BY fk_wens_risk_item |
| M014 | 策略采纳记录数 | wens_patrol_ticket | 统计策略采纳状态为"是"的巡查工单分录数 | COUNT(*) WHERE fk_wens_custom_is_adopt = '1' |

### 4.2 复合指标

| 指标ID | 指标名称 | 公式 | 伪代码 |
|--------|----------|------|--------|
| C001 | 生产异常农户占比 | M001 / M006 | (生产异常农户数) / (总养户数) |
| C002 | 预警关闭占比 | M007 / M008 | (预警关闭数) / (预警总数) |
| C003 | 有效干涉率 | 有已完成工单的预警数 / 预警总数 | (COUNT(DISTINCT fk_wens_warning_billno) WHERE fk_wens_atrol_ticket_stat = '2') / COUNT(*) |
| C004 | 7天复发率 | M012 / M008 | (复发记录数) / (预警总数) |
| C005 | 风险大类占比 | M013 / 预警总数 | (风险大类记录数) / (预警总数) |
| C006 | 策略采纳率 | M014 / 预警总数 | (策略采纳记录数) / (预警总数) |

### 4.3 趋势指标

| 指标ID | 指标名称 | 时间维度 | 分析维度 | 度量指标 |
|--------|----------|----------|----------|----------|
| T001 | 预警类型趋势 | 月份 | 预警指标 | 异常养户数 |
| T002 | 预警等级趋势 | 月份 | 预警等级 | 异常养户数 |
| T003 | 平均持续时长趋势 | 月份 | - | 平均持续时长 |
| T004 | 7天复发率趋势 | 月份 | - | 7天复发率 |
| T005 | 有效干涉率趋势 | 月份 | - | 有效干涉率 |

---

## 5. 数据风险

### 5.1 粒度问题

| 风险ID | 风险描述 | 影响 | 缓解措施 |
|--------|----------|------|----------|
| GR001 | 预警记录粒度不明确 | 可能导致指标统计重复或遗漏 | 需要确认预警记录的业务粒度 |

### 5.2 状态问题

| 风险ID | 风险描述 | 影响 | 缓解措施 |
|--------|----------|------|----------|
| SR001 | 预警状态枚举值不一致 | 过滤条件可能失效 | 需要验证实际数据中的枚举值 |
| SR002 | 巡查工单状态枚举值不一致 | 过滤条件可能失效 | 需要验证实际数据中的枚举值 |
| SR003 | 复选框字段存储值不一致 | 过滤条件可能失效 | 需要验证实际数据中的存储值 |

### 5.3 时间问题

| 风险ID | 风险描述 | 影响 | 缓解措施 |
|--------|----------|------|----------|
| TR001 | 时间字段格式不一致 | 时间计算可能出错 | 需要统一时间格式 |
| TR002 | 持续时长字段单位不明确 | 平均持续时长计算可能不准确 | 需要确认字段的单位 |

### 5.4 关系问题

| 风险ID | 风险描述 | 影响 | 缓解措施 |
|--------|----------|------|----------|
| RR001 | 预警记录与养户的关联可能不完整 | 指标统计可能遗漏 | 需要验证关联完整性 |

---

## 6. 建议的验证步骤

### 6.1 验证枚举值

```sql
-- 验证预警状态枚举值
SELECT DISTINCT fk_wens_status, COUNT(*)
FROM tk_wens_production_anomal
GROUP BY fk_wens_status

-- 验证巡查工单状态枚举值
SELECT DISTINCT fk_wens_atrol_ticket_stat, COUNT(*)
FROM tk_wens_patrol_ticket
GROUP BY fk_wens_atrol_ticket_stat
```

### 6.2 验证复选框字段

```sql
-- 验证是否巡查字段
SELECT DISTINCT fk_wens_is_generate_ticke, COUNT(*)
FROM tk_wens_production_anomal
GROUP BY fk_wens_is_generate_ticke
```

### 6.3 验证时间字段

```sql
-- 验证预警时间字段
SELECT
  MIN(fk_wens_alarm_time) as min_time,
  MAX(fk_wens_alarm_time) as max_time,
  COUNT(*) as total_count,
  COUNT(fk_wens_alarm_time) as non_null_count
FROM tk_wens_production_anomal

-- 验证持续时长字段
SELECT
  MIN(fk_wens_duration) as min_duration,
  MAX(fk_wens_duration) as max_duration,
  AVG(fk_wens_duration) as avg_duration
FROM tk_wens_production_anomal
WHERE fk_wens_duration IS NOT NULL
```

### 6.4 验证关联完整性

```sql
-- 验证预警记录与养户的关联完整性
SELECT
  COUNT(*) as total_alerts,
  COUNT(fk_wens_basedatafield) as has_farmer,
  COUNT(*) - COUNT(fk_wens_basedatafield) as missing_farmer
FROM tk_wens_production_anomal
WHERE fbillstatus = 'C'
```

---

## 7. 输出文件清单

1. **data_analysis.md** - 本文档，面向开发人员的数据分析说明
2. **data_asset_analysis.yaml** - 业务对象对应源数据资产
3. **grain_analysis.yaml** - 源表粒度分析
4. **entity_relation.yaml** - 业务 ER 关系
5. **metric_implementation.yaml** - 指标技术实现分析
6. **data_quality_risk.yaml** - 数据风险

---

**文档版本：** 1.0
**生成日期：** 2026-09-10
**分析状态：** 已完成
