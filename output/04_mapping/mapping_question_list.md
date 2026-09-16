# Mapping 待确认问题清单

## 项目信息
- **项目名称：** 农户生产异常预警分析看板
- **项目ID：** wens_dw_project
- **生成日期：** 2026-09-11
- **文档版本：** 1.0

---

## 问题列表

### 问题1：字段映射关系确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ001 | fk_wens_basedatafield 是否映射到 dim_rearer.rearer_dk？ | fact_production_anomaly.rearer_dk | 高 | 待确认 |
| MQ002 | fk_wens_recbrlrflk_pig 是否映射到 dim_rearer_pop.rearer_pop_dk？ | fact_production_anomaly.rearer_pop_dk | 高 | 待确认 |
| MQ003 | fk_wens_recbrlrflk_pig 对应业务对象是养户种群还是猪群？ | 所有涉及该字段的mapping | 高 | 待确认 |

### 问题2：枚举值确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ004 | fk_wens_status 的枚举值是什么？（1=持续中, 2=已关闭, 3=仅通知？） | 预警状态相关指标 | 高 | 待确认 |
| MQ005 | fk_wens_atrol_ticket_stat 的枚举值是什么？（1=未完成, 2=已完成, 3=未完成(过期)？） | 巡查工单状态相关指标 | 高 | 待确认 |
| MQ006 | fk_wens_alert_metric 的枚举值是什么？ | 预警类型趋势 | 中 | 待确认 |
| MQ007 | fk_wens_alarm_level 的枚举值是什么？ | 预警等级趋势 | 中 | 待确认 |

### 问题3：存储值确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ008 | fk_wens_is_generate_ticke 的存储值是 '是'/'否' 还是 '1'/'0'？ | M003, M004 | 高 | 待确认 |
| MQ009 | fk_wens_custom_is_adopt 的存储值是 '是'/'否' 还是 '1'/'0'？ | M014, 策略采纳率 | 高 | 待确认 |
| MQ010 | fk_wens_custom_is_execute 的存储值是 '是'/'否' 还是 '1'/'0'？ | 策略执行分析 | 中 | 待确认 |

### 问题4：维表状态代码确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ011 | dim_rearer.rearer_status_cd 的有效状态代码是什么？ | M006, 总养户数 | 高 | 待确认 |
| MQ012 | dim_rearer_pop.rearer_pop_status_cd 的在养状态代码是什么？ | fact_production_anomaly过滤 | 高 | 待确认 |

### 问题5：字段融合确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ013 | dim_rearer 是否已完成字段融合（fenable + fk_wens_status + fstatus -> rearer_status_cd）？ | M006, 总养户数 | 高 | 待确认 |
| MQ014 | dim_rearer_pop 是否已完成字段融合（fk_wens_flkstatus -> rearer_pop_status_cd）？ | fact_production_anomaly过滤 | 高 | 待确认 |

### 问题6：时间字段确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ015 | fk_wens_duration 的单位是什么？（天、小时、分钟？） | 平均持续时长 | 中 | 待确认 |
| MQ016 | fk_wens_alarm_time 的格式是什么？ | 时间相关指标 | 中 | 待确认 |

### 问题7：主键生成确认

| 问题ID | 问题描述 | 影响范围 | 优先级 | 状态 |
|--------|----------|----------|--------|------|
| MQ017 | fact_risk_analysis.risk_id 如何生成？（fbillno + entry_id 拼接？） | fact_risk_analysis主键 | 中 | 待确认 |

---

## 问题汇总

| 类别 | 问题数量 | 关键问题 |
|------|----------|----------|
| 字段映射关系 | 3个 | MQ001, MQ002, MQ003 |
| 枚举值确认 | 4个 | MQ004, MQ005, MQ006, MQ007 |
| 存储值确认 | 3个 | MQ008, MQ009, MQ010 |
| 维表状态代码 | 2个 | MQ011, MQ012 |
| 字段融合确认 | 2个 | MQ013, MQ014 |
| 时间字段确认 | 2个 | MQ015, MQ016 |
| 主键生成确认 | 1个 | MQ017 |
| **总计** | **17个** | - |

---

## 确认优先级

### 高优先级（阻塞ETL开发）
- MQ001: fk_wens_basedatafield -> dim_rearer.rearer_dk
- MQ002: fk_wens_recbrlrflk_pig -> dim_rearer_pop.rearer_pop_dk
- MQ003: fk_wens_recbrlrflk_pig 业务对象确认
- MQ004: fk_wens_status 枚举值
- MQ005: fk_wens_atrol_ticket_stat 枚举值
- MQ008: fk_wens_is_generate_ticke 存储值
- MQ009: fk_wens_custom_is_adopt 存储值
- MQ011: dim_rearer.rearer_status_cd 有效状态代码
- MQ012: dim_rearer_pop.rearer_pop_status_cd 在养状态代码
- MQ013: dim_rearer 字段融合确认
- MQ014: dim_rearer_pop 字段融合确认

### 中优先级（影响指标准确性）
- MQ006: fk_wens_alert_metric 枚举值
- MQ007: fk_wens_alarm_level 枚举值
- MQ010: fk_wens_custom_is_execute 存储值
- MQ015: fk_wens_duration 单位
- MQ016: fk_wens_alarm_time 格式
- MQ017: fact_risk_analysis.risk_id 生成方式

---

**文档版本：** 1.0
**生成日期：** 2026-09-11
**状态：** 待确认
