# 体验系统重构计划

Project codename: **Tower**

Status: Draft v1

当前原型已经能跑通核心循环（出牌 → 敌人意图 → 奖励 → 地图），但下一轮迭代的瓶颈不再是内容数量，而是**反馈节奏、信息密度、视觉层次**。这份文档定义"如何把原型升级为一款看起来像游戏的 demo"，按 4 条体验线 + 5 个公共组件 + 4 个 Phase 推进。

## 设计原则

1. **不再堆内容，先做体验地基。** 30 卡 / 8 敌人 / 5 事件已经足够支撑一轮可玩性验证。
2. **同一交互只做一次。** 大卡预览、牌堆查看、Card Picker 是被多处复用的组件，必须先抽出。
3. **节奏优先于特效。** Hit pause 50 ms 比一个炫酷粒子更能提升手感。
4. **可达性兜底。** 所有动画必须有"快速结算"开关，关闭后逻辑结果完全等价。

---

## 1. 抽卡 / 手牌体验

### 症状

- 抽牌瞬间刷出，没有"卡从牌堆来"的因果感。
- 手牌偏小、不居中，hover 信息密度低。
- 三个牌堆只有数字，玩家无法据此决策。
- 升级卡视觉和普通卡几乎无差别。

### 修复

- **抽牌动画**：从 draw pile 锚点逐张 tween 入手牌，每张 60–80 ms，stagger 40 ms。
- **弃牌动画**：出牌后 tween 到 discard pile 锚点，落地后才计入弃牌堆。
- **手牌排布**：中心对齐；hover 时上移 24 px、放大到 1.6×；同时唤起 `CardInspector`（大卡 + 完整规则文本 + 当前生效条件高亮）。
- **牌堆按钮可点**：Draw / Discard / Exhaust 三个按钮点击后均弹 `PileModal`，按类型分组、可滚动、显示当前数量。
- **升级态视觉**：金色描边 + `+` 标记 + 数值差异加亮（旧值划线，新值高亮颜色）。
- **占位图回退**：缺专属图时按 Attack / Skill / Power 给三种类型占位纹理，**不**用统一 card back，避免"未完成感"。

### 验收

- 一回合 5 次抽牌全部经过动画且不超过 600 ms。
- 玩家点击任意牌堆按钮都能看到内容并关闭返回。
- 升级卡与原卡同框时可在 0.5 s 内目视分辨。

---

## 2. 战斗反馈节奏

### 症状

- 出牌 → 数值瞬变；没有命中、抖动、震屏、暂停。
- HP 数字直接跳，无 tween。
- Combat log 仍然是主信息源。
- 敌人 intent 切换无提示。

### 修复 — Action Queue

把"打牌 → 命中 → 伤害 → HP → 状态更新"改造成**串行 Action Queue**，而不是同帧结算。

攻击牌序列：

```
card_fly_to_enemy        140 ms
slash VFX + hit_pause     80 + 60 ms
enemy_flash + shake      200 ms
damage_number_pop        (并行入场)
hp_bar_tween             250 ms
block_strip → hp_strip   顺序结算
```

防御牌序列：

```
card_fly_to_player       140 ms
block_pulse              180 ms
block_number_count_up    250 ms
```

敌人回合序列：

```
intent_pulse             300 ms（行动前预告）
enemy_lunge              160 ms
player_flash + low_shake
block_consume → hp_loss  顺序，非同帧
```

### 其他

- **Hit pause**：命中帧 `Engine.time_scale = 0` 持续 50–80 ms，整体质感立刻跳一档。
- **Intent pulse**：每个玩家回合开始时敌人 intent 做一次发光 + 微颤动。
- **Combat log 降级**：右下 toast 队列，最多 3 条，2 s 自动消失。核心反馈交还给动画 + 浮动数字。

### 验收

- 出 1 张攻击牌的总时长 600–900 ms，可被快速结算开关压到 ≤ 100 ms。
- 多段攻击（如 `e_loose_folio.flutter` 3 × 3）每段独立 flash + 独立数字。
- 关闭动画选项后所有计算结果完全等价（用 `21_testing_strategy.md` 中的 effect 单测覆盖）。

---

## 3. 商店体验

### 症状

- 当前是竖排按钮，像 debug 菜单。
- Remove card 固定删第一张 Strike，不让玩家选。
- 没有 Gold HUD、没有 SOLD 状态、没有稀有度边框。

### 修复 — Shop Grid

```
┌────────────────────────────────────────────┐
│  [Vendor portrait]        Gold: 132   ⌖    │
│                                            │
│   [Card]   [Card]   [Card]                 │  3 大卡（复用 CardView）
│   [Relic]  [Relic]                         │  2 遗物（rarity 边框 + tooltip）
│   [Potion] [Potion]   [Remove a card]      │  2 药水 + 1 服务
│                                  [Leave]   │
└────────────────────────────────────────────┘
```

- **价格 tag** 贴在商品右上；买不起时整体灰掉 + 价格变红。
- **SOLD 状态**：购买后商品保留位置，盖一层 SOLD 印章 + 整体降饱和；不离开商店。
- **稀有度边框** 颜色对应 `17_balance_numbers.md` 的 rarity 表（Common 银 / Uncommon 蓝 / Rare 金）。
- **Remove a card**：点击进入 `CardPicker`，玩家从当前 deck 中选一张。
- **离开**通过显式 `Leave` 按钮，避免误触。

### 验收

- 同一 `CardPicker` 组件被商店 remove、营火 upgrade、`ev_clean_margin`、`ev_revision_desk` 复用。
- 商品稀有度在不 hover 的情况下肉眼可分辨。
- 没有任何"列表样式"的 debug 痕迹残留。

---

## 4. 牌组可读性

### 症状

- 地图右侧 deck summary 是文本流，看不清结构。
- 营火升级只显示"已升级 Strike Form"，看不出"强了多少"。

### 修复

- 地图右侧 deck summary 改成胶囊按钮：`Deck 14 · 8 atk · 5 skl · 1 pwr`，点击展开 `DeckModal`。
- `DeckModal` 提供三种排序：默认按类型 / 切到费用 / 切到稀有度。
- 列表项是缩略卡，hover 或点击展开大卡（复用 `CardInspector`）。
- **升级前后对比**：营火 / 事件 / 商店 service 走同一 `CardPicker`，确认前显示新旧值并排（旧值划线，新值加亮）。

### 验收

- 玩家在地图上不进战斗就能完整查阅当前牌组。
- 升级流程在三处场景体验完全一致。

---

## 公共组件（必须先抽出，否则各线重复造）

| 组件 | 主要复用方 |
| --- | --- |
| **CardInspector** — 大卡预览 + 规则高亮 | 手牌 hover、商店、奖励、`DeckModal` |
| **DeckModal / PileModal** — 牌组与牌堆查看 | 地图、营火、事件、战斗中查牌堆 |
| **CardPicker** — 从一组卡里选一张 | 营火升级、`ev_clean_margin`、`ev_revision_desk`、商店 remove |
| **ActionQueue** — 串行播放战斗动画 | 所有出牌 / 敌人行动 / VFX |
| **Toast & FloatingNumber** — 浮动数字、提示 toast | 战斗反馈、combat log 降级、状态变更 |

这五个抽出来后，后续四条线的工作量会显著下降。

---

## 落地顺序（Phase Roadmap）

### Phase A — 信息层（做完即可显著"好懂"）

1. CardInspector。
2. DeckModal + PileModal。
3. 地图右侧 deck summary 胶囊按钮。

### Phase B — 反馈层（做完即可显著"好玩"）

4. ActionQueue 骨架。
5. 出牌飞行 + 敌人 flash + hit pause。
6. HP / Block tween + 浮动数字。

### Phase C — 场景层（做完即可显著"好看"）

7. Shop Grid（复用 CardInspector + CardPicker）。
8. 营火升级前后对比。
9. 抽 / 弃牌动画。

### Phase D — 收尾

10. Combat log → toast 降级。
11. 占位图按类型分流。
12. 音频 hook 接入（直接对接 `20_audio_plan.md` 的 event-to-sound 表）。

---

## 最高 ROI 的第一刀

> CardInspector ＋ 牌堆点击查看 ＋ 打牌飞行动画 ＋ HP tween ＋ Shop Grid

这五件事完成之后，项目会从"原型"一次性跨进"像一款游戏"的台阶。其余动效都是在同一条骨架上叠细节，不会推翻已写代码。

---

## 与其他文档的关系

- **`12_frontend_ui_upgrade_plan.md`**：本文是其延伸，从"视觉一致性"推进到"交互节奏"。12 完成的 P0 卡片视觉是本文 CardInspector 的起点。
- **`17_balance_numbers.md`**：稀有度配色、状态数值供商店与 Inspector 高亮使用。
- **`20_audio_plan.md`**：Phase D 的音频 hook 直接消费其 event 表。
- **`21_testing_strategy.md`**：本文新增的 ActionQueue 必须配套"快速结算开关"自动化校验，纳入回归测试。

## 风险与缓解

| 风险 | 缓解 |
| --- | --- |
| ActionQueue 与现有 1078 行 `combat_manager.gd` 耦合过重。 | 先抽出独立类（`ActionRunner`），不拆 `combat_manager` 即可接入。 |
| 动画时长拉长导致一回合超过 30 s。 | 全局快速结算开关；高 stack 多段攻击合并播放。 |
| 公共组件做大后无人复用。 | 每个 Phase 完成时核对"复用方表格"，缺一个就回填。 |

## Open Questions

- 是否在战斗结束后给一段 cinematic 级别的 victory flourish（参考 reward overlay），还是保持当前简洁？
- DeckModal 是否要支持"模拟一手抽 5 张"按钮便于玩家在地图阶段评估？
- 快速结算开关的默认值：开还是关？建议默认关，演示模式下打开。
