# 图像素材清单 — Living Archive (爬塔卡片)

> 本文档列出了本次内容扩充新增的所有需要补充图像的元素。
> 每项都包含：**用途**、**目标路径**、**推荐尺寸**、**风格提示**、**可选生图 prompt 模板**。

## 生成状态

2026-05-11 已用 Codex 原生 imagegen 生成并切图完成：

- 新卡牌图：45/45，输出到 `tower_game/art/generated/cards/`。
- 新遗物图标：55/55，输出到 `tower_game/art/generated/icons/relic_<id>.png`。
- 新药水图标：12/12，输出到 `tower_game/art/generated/icons/potion_<id>.png`。
- 新敌人立绘：10/10，输出到 `tower_game/art/generated/sprites/`。

资源接入状态：

- 卡牌插画通过 `CardView` 的 `res://art/generated/cards/<card_id>.png` 规则自动接入。
- 敌人立绘按各自 `.tres` 的 `art_path` 自动接入。
- 商店遗物 / 药水 offer 已补 `icon_path`，`ShopView` 会展示对应图标。
- 已通过 `runtime_mvp_check.gd` 与 `runtime_scene_check.gd`。

---

## 0. 全局风格基调

- **世界观**: Living Archive — 一座「活着的档案馆」。蜡烛、羊皮卷、印章、红绳、墨水、铜质装订件。
- **配色**: 主色调蜂蜡黄 (#D9A24A / #B6863A)、深棕羊皮纸 (#3A2B1B)、蜡封红 (#9C3826)、墨黑 (#1A1612)。点缀色：青铜绿、暗紫、暗金。
- **统一画风**: 半写实绘本质感、笔触明显、轻微浮雕感、低饱和、温暖灯光，不要太卡通也不要太写实。可以参考 Slay the Spire 的「印刷质感 + 手绘」，但更偏档案馆/书籍主题。
- **统一负面词** (negative prompt): `text, watermark, signature, modern logos, anime, chibi, photorealistic skin, neon`。

---

## 1. 卡牌图（45 张新卡）

**目标路径**: `tower_game/art/generated/cards/<card_id>.png`（目前占位逻辑按 card_type 选图；如要每张卡显示自己插画，参见末尾「卡面接入说明」）。

**推荐尺寸**: 256 × 320 px（竖向，宽高比 4:5）。

**风格提示**: 中央插画 + 上下舞台射灯式布光。攻击卡偏冷锋利、技能卡偏温和柔光、能力卡偏神圣发光。

| # | ID | 名称 | 类型 | 稀有度 | 费 | 效果 | 推荐 prompt 关键词 |
|---|----|------|------|--------|----|------|--------------------|
| 1 | `binder_smack` | Binder Smack | attack | common | 1 | Deal 10 damage. Lose 2 HP. | "Binder Smack", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 2 | `book_throw` | Book Throw | attack | uncommon | 1 | Deal 12 damage. Exhaust. | "Book Throw", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 3 | `bookmark` | Bookmark | skill | common | 0 | Gain 4 Block. | "Bookmark", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 4 | `cited_blow` | Cited Blow | attack | uncommon | 1 | Deal 11 damage. Gain 4 Block. | "Cited Blow", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 5 | `clean_glasses` | Clean Glasses | skill | uncommon | 1 | Draw 3. | "Clean Glasses", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 6 | `clipped_quote` | Clipped Quote | attack | common | 1 | Deal 8 damage. If target has Vulnerable, draw 1. | "Clipped Quote", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 7 | `closing_argument` | Closing Argument | attack | rare | 1 | Deal 16 damage. Lose 3 HP. | "Closing Argument", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 8 | `copyist_focus` | Copyist Focus | skill | common | 1 | Gain 1 Strength. Exhaust. | "Copyist Focus", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 9 | `deep_breath` | Deep Breath | skill | common | 0 | Gain 1 Dexterity. Exhaust. | "Deep Breath", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 10 | `deep_focus` | Deep Focus | power | uncommon | 1 | Gain 2 Strength. | "Deep Focus", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 11 | `errata_blow` | Errata Blow | attack | uncommon | 2 | Deal 18 damage. | "Errata Blow", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 12 | `final_clause` | Final Clause | attack | rare | 2 | Deal 12 damage. Apply 3 Weak. Apply 3 Vulnerable. | "Final Clause", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 13 | `final_oath` | Final Oath | power | rare | 2 | Gain 2 Max HP. Gain 2 Strength. Exhaust. | "Final Oath", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 14 | `folded_corner` | Folded Corner | skill | common | 1 | Gain 8 Block. Draw 1. | "Folded Corner", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 15 | `footnote_charge` | Footnote Charge | skill | uncommon | 0 | Gain 1 Energy. Exhaust. | "Footnote Charge", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 16 | `holy_quiet` | Holy Quiet | skill | rare | 1 | Gain 18 Block. Draw 2. | "Holy Quiet", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 17 | `index_finger` | Index Finger | attack | uncommon | 1 | Deal 8 damage. Apply 1 Vulnerable. Draw 1. | "Index Finger", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 18 | `ironbound` | Ironbound | power | rare | 2 | Gain 4 Dexterity. | "Ironbound", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 19 | `ledger_edge` | Ledger Edge | attack | common | 2 | Deal 14 damage. | "Ledger Edge", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 20 | `library_vow` | Library Vow | skill | uncommon | 1 | Heal 4 HP. Exhaust. | "Library Vow", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 21 | `living_archive` | Living Archive | power | rare | 2 | Gain 3 Strength. Gain 3 Dexterity. | "Living Archive", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 22 | `long_quotation` | Long Quotation | attack | uncommon | 1 | Deal 5 damage 3 times. | "Long Quotation", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 23 | `morning_inventory` | Morning Inventory | power | uncommon | 1 | Gain 1 Strength. Gain 1 Dexterity. | "Morning Inventory", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 24 | `page_break` | Page Break | attack | uncommon | 1 | Deal 6 damage 2 times. | "Page Break", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 25 | `papercut` | Papercut | attack | common | 0 | Deal 4 damage. | "Papercut", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 26 | `quiet_shelf` | Quiet Shelf | skill | uncommon | 1 | Gain 7 Block. Gain 1 Dexterity. | "Quiet Shelf", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 27 | `reading_glance` | Reading Glance | attack | common | 1 | Deal 7 damage. Apply 1 Weak. | "Reading Glance", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 28 | `red_pen` | Red Pen | attack | uncommon | 1 | Deal 9 damage. Apply 2 Weak. | "Red Pen", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 29 | `reread` | Reread | skill | uncommon | 1 | Draw 2. Gain 4 Block. | "Reread", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 30 | `second_pair` | Second Pair | skill | common | 1 | Gain 5 Block. Apply 1 Weak. | "Second Pair", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 31 | `second_wind` | Second Wind | skill | rare | 1 | Gain 1 Energy. Draw 2. | "Second Wind", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 32 | `sift_pages` | Sift Pages | skill | common | 1 | Draw 2 cards. | "Sift Pages", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 33 | `silent_step` | Silent Step | skill | common | 0 | Apply 1 Weak. | "Silent Step", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 34 | `silver_underline` | Silver Underline | attack | rare | 1 | Deal 14 damage. Apply 2 Vulnerable. Draw 1. | "Silver Underline", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 35 | `split_seal` | Split Seal | attack | uncommon | 1 | Deal 8 damage. Apply 1 Frail. | "Split Seal", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 36 | `steady_hand` | Steady Hand | power | uncommon | 1 | Gain 2 Dexterity. | "Steady Hand", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 37 | `steel_binding` | Steel Binding | skill | uncommon | 1 | Gain 12 Block. | "Steel Binding", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 38 | `steel_quill` | Steel Quill | skill | rare | 1 | Heal 7 HP. Gain 6 Block. Exhaust. | "Steel Quill", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 39 | `thumb_jab` | Thumb Jab | attack | common | 0 | Deal 3 damage. Draw 1. | "Thumb Jab", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 40 | `twin_dot` | Twin Dot | attack | common | 1 | Deal 4 damage twice. | "Twin Dot", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 41 | `twin_writ` | Twin Writ | attack | rare | 1 | Deal 9 damage 3 times. | "Twin Writ", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 42 | `underline` | Underline | attack | common | 1 | Deal 6 damage. Apply 1 Vulnerable. | "Underline", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 43 | `unyielding` | Unyielding | power | rare | 2 | Gain 4 Strength. | "Unyielding", radiant aura, golden seal floating, sacred glow, halo of red wax, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 44 | `vow_of_silence` | Vow of Silence | skill | uncommon | 0 | Apply 2 Weak. Apply 1 Vulnerable. | "Vow of Silence", warm parchment glow, calm gesture, candlelight, supportive aura, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |
| 45 | `writ_of_judgement` | Writ of Judgement | attack | rare | 2 | Deal 22 damage. | "Writ of Judgement", ink-stained iron quill striking, sharp edge, motion blur, cold lighting, archive aesthetic, baroque ornament border, 2.5D illustrated card, 256x320 portrait |

### 卡面接入说明
当前 `card_view.gd` 用 `card_type` 决定占位 art。如果要让每张卡显示自己的插画，在该脚本里加：
```gdscript
var specific := "res://art/generated/cards/%s.png" % card.data.id
if FileAccess.file_exists(specific):
    art_rect.texture = _load_png_texture(specific)
else:
    # 现有的 card_type 占位逻辑
```

---

## 2. 遗物图标（55 个新遗物）

**目标路径**: `tower_game/art/generated/icons/relic_<relic_id>.png`

**推荐尺寸**: 64 × 64 px（最小）；建议直接出 128 × 128 px。

**风格提示**: 单一物体居中，深色虚化背景，物体边缘有微弱金色描边/发光，便于在 HUD 上识别。剪影清晰、可一眼分辨形状。

| # | ID | 名称 | 稀有度 | 描述 | 推荐 prompt 关键词 |
|---|----|------|--------|------|---------------------|
| 1 | `adamant_clasp` | Adamant Clasp | rare | At the start of each combat, gain 3 Dexterity. | "Adamant Clasp", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 2 | `adjudicator_seal` | Adjudicator Seal | boss | At the start of each combat, gain 4 Strength. | "Adjudicator Seal", a single magical archive relic, ornate golden filigree, regal aura, runic engravings, dark vignette background, 128x128 icon, hand-painted |
| 3 | `binding_thread` | Binding Thread | uncommon | At the start of each combat, gain 6 Block and apply 1 Weak. | "Binding Thread", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 4 | `bookmonger_token` | Bookmonger Token | event | At the end of each combat, gain 8 gold. | "Bookmonger Token", a single magical archive relic, mysterious cracked surface, faint purple aura, dark vignette background, 128x128 icon, hand-painted |
| 5 | `brass_compass` | Brass Compass | common | At the start of each combat, gain 4 Block. | "Brass Compass", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 6 | `chip_seal` | Chip Seal | common | At the start of each combat, deal 3 damage and gain 2 Block. | "Chip Seal", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 7 | `chronicler_mantle` | Chronicler Mantle | boss | At the end of each combat, heal 15 HP and gain 15 gold. | "Chronicler Mantle", a single magical archive relic, ornate golden filigree, regal aura, runic engravings, dark vignette background, 128x128 icon, hand-painted |
| 8 | `clarion_bell` | Clarion Bell | uncommon | At the start of each combat, gain 2 Strength. | "Clarion Bell", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 9 | `clarion_horn` | Clarion Horn | rare | At the start of each combat, apply 3 Vulnerable. | "Clarion Horn", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 10 | `clerks_brooch` | Clerk's Brooch | shop | At the start of each combat, draw 2 extra cards. | "Clerk's Brooch", a single magical archive relic, merchant tag, leather strap, dark vignette background, 128x128 icon, hand-painted |
| 11 | `copper_thimble` | Copper Thimble | common | At the start of each combat, gain 2 Block. | "Copper Thimble", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 12 | `cursed_lens` | Cursed Lens | event | At the start of each combat, draw 2 extra cards. (Risky.) | "Cursed Lens", a single magical archive relic, mysterious cracked surface, faint purple aura, dark vignette background, 128x128 icon, hand-painted |
| 13 | `dust_cloth` | Dust Cloth | common | At the start of each combat, gain 1 Dexterity. | "Dust Cloth", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 14 | `endless_ledger` | Endless Ledger | boss | At the start of each combat, draw 4 extra cards. | "Endless Ledger", a single magical archive relic, ornate golden filigree, regal aura, runic engravings, dark vignette background, 128x128 icon, hand-painted |
| 15 | `fastening_pin` | Fastening Pin | uncommon | At the start of each combat, apply 2 Weak. | "Fastening Pin", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 16 | `first_edition` | First Edition | rare | At the start of each combat, gain 3 Strength. | "First Edition", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 17 | `folded_handkerchief` | Folded Handkerchief | common | At the end of each combat, heal 2 HP. | "Folded Handkerchief", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 18 | `folded_treaty` | Folded Treaty | uncommon | At the start of each combat, gain 8 Block. | "Folded Treaty", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 19 | `gilded_quill` | Gilded Quill | rare | At the start of each combat, deal 12 damage to the enemy. | "Gilded Quill", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 20 | `golden_inkpot` | Golden Inkpot | rare | At the start of each combat, gain 1 Energy and draw 1 extra card. | "Golden Inkpot", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 21 | `healing_seal` | Healing Seal | rare | At the end of each combat, heal 10 HP. | "Healing Seal", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 22 | `hex_staple` | Hex Staple | uncommon | At the start of each combat, apply 2 Vulnerable. | "Hex Staple", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 23 | `iron_ring` | Iron Ring | common | At the start of each combat, gain 3 Block. | "Iron Ring", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 24 | `keystone_seal` | Keystone Seal | rare | At the start of each combat, gain 12 Block. | "Keystone Seal", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 25 | `ledger_clasp` | Ledger Clasp | uncommon | At the start of each combat, gain 2 Dexterity. | "Ledger Clasp", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 26 | `library_quiet` | Library Quiet | common | At the end of each combat, heal 1 HP. | "Library Quiet", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 27 | `loyalty_token` | Loyalty Token | rare | At the end of each combat, gain 25 gold. | "Loyalty Token", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 28 | `merchant_compass` | Merchant Compass | shop | At the end of each combat, gain 18 gold. | "Merchant Compass", a single magical archive relic, merchant tag, leather strap, dark vignette background, 128x128 icon, hand-painted |
| 29 | `merchant_satchel` | Merchant Satchel | uncommon | At the end of each combat, gain 12 gold. | "Merchant Satchel", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 30 | `oath_crown` | Oath Crown | boss | At the start of each combat, gain 1 Energy and gain 8 Block. | "Oath Crown", a single magical archive relic, ornate golden filigree, regal aura, runic engravings, dark vignette background, 128x128 icon, hand-painted |
| 31 | `old_promise` | Old Promise | event | At the start of each combat, deal 6 damage and gain 3 Block. | "Old Promise", a single magical archive relic, mysterious cracked surface, faint purple aura, dark vignette background, 128x128 icon, hand-painted |
| 32 | `opening_letter` | Opening Letter | common | At the start of each combat, draw 1 extra card. | "Opening Letter", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 33 | `penny_purse` | Penny Purse | common | At the end of each combat, gain 5 gold. | "Penny Purse", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 34 | `phoenix_feather` | Phoenix Feather | rare | At the start of each combat, gain 8 Block and heal 2 HP. | "Phoenix Feather", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 35 | `polished_seal` | Polished Seal | uncommon | At the start of each combat, gain 1 Energy. | "Polished Seal", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 36 | `reading_lamp` | Reading Lamp | common | At the start of each combat, apply 1 Vulnerable. | "Reading Lamp", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 37 | `sage_inkstone` | Sage Inkstone | uncommon | At the start of each combat, gain 1 Strength and 1 Dexterity. | "Sage Inkstone", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 38 | `second_inkpot` | Second Inkpot | uncommon | At the start of each combat, gain 1 Energy. (Lasting only this combat.) | "Second Inkpot", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 39 | `signed_warrant` | Signed Warrant | shop | At the start of each combat, deal 8 damage to the enemy. | "Signed Warrant", a single magical archive relic, merchant tag, leather strap, dark vignette background, 128x128 icon, hand-painted |
| 40 | `silent_inkwell` | Silent Inkwell | common | At the start of each combat, apply 1 Weak. | "Silent Inkwell", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 41 | `silver_clasp` | Silver Clasp | rare | At the start of each combat, draw 3 extra cards. | "Silver Clasp", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 42 | `silver_kettle` | Silver Kettle | uncommon | At the end of each combat, heal 6 HP. | "Silver Kettle", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 43 | `silver_paperknife` | Silver Paperknife | uncommon | At the start of each combat, deal 7 damage to the enemy. | "Silver Paperknife", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 44 | `steady_compass` | Steady Compass | rare | At the start of each combat, gain 1 Energy and gain 4 Block. | "Steady Compass", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 45 | `steel_pen_nib` | Steel Pen Nib | common | At the start of each combat, deal 4 damage to the enemy. | "Steel Pen Nib", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 46 | `strong_arm_band` | Strong-Arm Band | common | At the start of each combat, gain 1 Strength. | "Strong-Arm Band", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 47 | `twin_quill` | Twin Quill | uncommon | At the start of each combat, draw 2 extra cards. | "Twin Quill", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 48 | `unbroken_oath` | Unbroken Oath | uncommon | At the end of each combat, heal 4 HP. | "Unbroken Oath", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 49 | `vellum_pouch` | Vellum Pouch | shop | At the start of each combat, gain 6 Block and 1 Dexterity. | "Vellum Pouch", a single magical archive relic, merchant tag, leather strap, dark vignette background, 128x128 icon, hand-painted |
| 50 | `warden_aegis` | Warden Aegis | boss | At the start of each combat, gain 4 Dexterity. | "Warden Aegis", a single magical archive relic, ornate golden filigree, regal aura, runic engravings, dark vignette background, 128x128 icon, hand-painted |
| 51 | `warden_glove` | Warden Glove | rare | At the start of each combat, gain 1 Strength, 1 Dexterity, and 4 Block. | "Warden Glove", a single magical archive relic, carved bronze inlay, subtle red wax glow, dark vignette background, 128x128 icon, hand-painted |
| 52 | `warden_pact` | Warden Pact | event | At the start of each combat, gain 2 Strength and lose 5 max HP. (Already paid.) | "Warden Pact", a single magical archive relic, mysterious cracked surface, faint purple aura, dark vignette background, 128x128 icon, hand-painted |
| 53 | `warm_kettle` | Warm Kettle | common | At the end of each combat, heal 3 HP. | "Warm Kettle", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |
| 54 | `warning_chime` | Warning Chime | uncommon | At the start of each combat, deal 5 damage and apply 1 Vulnerable. | "Warning Chime", a single magical archive relic, polished silver detail, parchment ribbon, dark vignette background, 128x128 icon, hand-painted |
| 55 | `weighted_paper` | Weighted Paper | common | At the start of each combat, gain 5 Block. | "Weighted Paper", a single magical archive relic, weathered, simple, archival, dark vignette background, 128x128 icon, hand-painted |

---

## 3. 药水图标（12 瓶新药水）

**目标路径**: `tower_game/art/generated/icons/potion_<potion_id>.png`

**推荐尺寸**: 64 × 96 px（建议 128 × 192 px）。

**风格提示**: 标准 RPG 药水瓶造型，瓶颈处有蜡封 / 绳结。瓶内液体颜色与效果对应：
- damage / fire → 橙红
- block / steel → 钢蓝灰
- weak / vulnerable / frail → 暗紫 / 烟雾
- strength → 红铜
- dexterity → 翠绿
- draw / focus → 浅金
- heal → 粉红 / 玫瑰金
- energy → 亮黄

| # | ID | 名称 | 稀有度 | 描述 | 推荐 prompt 关键词 |
|---|----|------|--------|------|---------------------|
| 1 | `ambrosia` | Ambrosia | rare | Gain 2 Energy. | "Ambrosia" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 2 | `crimson_tonic` | Crimson Tonic | uncommon | Heal 15 HP. | "Crimson Tonic" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 3 | `explosive_potion` | Explosive Potion | uncommon | Deal 10 damage and apply 2 Vulnerable. | "Explosive Potion" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 4 | `fairy_pages` | Fairy Pages | rare | Heal 20 HP. Gain 1 Strength. Gain 1 Dexterity. | "Fairy Pages" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 5 | `fire_potion` | Fire Potion | common | Deal 20 damage to the enemy. | "Fire Potion" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 6 | `focus_potion` | Focus Potion | common | Gain 2 Strength. | "Focus Potion" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 7 | `frail_fume` | Frail Fume | common | Apply 3 Frail. | "Frail Fume" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 8 | `liquid_focus` | Liquid Focus | uncommon | Draw 4 cards. | "Liquid Focus" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 9 | `steel_potion` | Steel Potion | common | Gain 12 Block. | "Steel Potion" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 10 | `swift_potion` | Swift Potion | uncommon | Gain 2 Dexterity. | "Swift Potion" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 11 | `vulnerable_brew` | Vulnerable Brew | common | Apply 3 Vulnerable. | "Vulnerable Brew" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |
| 12 | `weak_distillate` | Weak Distillate | common | Apply 3 Weak. | "Weak Distillate" potion bottle, glass with cork stopper, sealed with red wax, archive table background, 128x192 icon |

---

## 4. 敌人立绘（10 个新敌人）

**目标路径**: `tower_game/art/generated/sprites/<filename>.png`（每条 art_path 已在 .tres 中写好，按下表「目标文件」生成同名 PNG）。

**推荐尺寸**: 普通 256×256，精英 320×384，Boss 512×512。透明背景 PNG 最佳。

**风格提示**: 单体角色立绘，正面或 3/4 视角，居中构图。所有敌人都是档案馆的「活体页面/书简」概念，而非血肉生物。

| # | ID | 名称 | 等级 | HP | 目标文件 | 推荐 prompt |
|---|----|------|------|----|----------|--------------|
| 1 | `b_chronicler_of_lost_pages` | Chronicler of Lost Pages | boss | 220 | `chronicler_of_lost_pages.png` | majestic boss figure made of swirling lost pages and torn margins, half-real ghost of a librarian, glowing red eyes, cathedral hall background, full body, transparent background, archive aesthetic |
| 2 | `b_grand_archivist` | The Grand Archivist | boss | 250 | `grand_archivist.png` | ancient grand archivist on floating throne of bound tomes, golden seal crown, ageless face, hands holding twin master keys, full body, transparent background, archive aesthetic |
| 3 | `e_dust_sentinel` | Dust Sentinel | normal | 30 | `dust_sentinel.png` | dust-coated stone statue of an archive guardian, crumbling parchment for a cape, glowing seal-eyes, full body, transparent background, archive aesthetic |
| 4 | `e_glassed_intern` | Glassed Intern | normal | 18 | `glassed_intern.png` | young apprentice scribe wearing thick glass spectacles, ink-stained sleeves, nervous posture, holding a small ledger, full body, transparent background, archive aesthetic |
| 5 | `e_late_filer` | Late Filer | normal | 28 | `late_filer.png` | haggard clerk overflowing with stacked papers, twitchy, exhausted shoulders, ink fingerprints everywhere, full body, transparent background, archive aesthetic |
| 6 | `e_red_string_imp` | Red String Imp | normal | 22 | `red_string_imp.png` | small mischievous spirit tangled in red string, holding a needle, twitching like marionette, full body, transparent background, archive aesthetic |
| 7 | `e_silent_ledger` | Silent Ledger | normal | 34 | `silent_ledger.png` | humanoid silhouette made of stacked closed ledgers, brass clasps, faceless head shaped like a closed book, full body, transparent background, archive aesthetic |
| 8 | `el_archive_warden` | Archive Warden | elite | 85 | `archive_warden.png` | huge warden in heavy ledger-plate armor, paper banners hanging from shoulders, slow imposing, full body, transparent background, archive aesthetic |
| 9 | `el_ironbound_clerk` | Ironbound Clerk | elite | 78 | `ironbound_clerk.png` | armored clerk with iron-bound book chained to wrist, brass plate over chest, watchful, full body, transparent background, archive aesthetic |
| 10 | `el_quill_judge` | Quill Judge | elite | 68 | `quill_judge.png` | tall judge figure in archive robes, raises an oversized iron quill like a sword, severe expression, full body, transparent background, archive aesthetic |

---

## 5. 速览汇总

- 新卡牌图: **45** 张
- 新遗物图标: **55** 个
- 新药水图标: **12** 瓶
- 新敌人立绘: **10** 个 (5 普通 / 3 精英 / 2 Boss)
- **共需补充图像 ≈ 122 张**

## 6. 优先级建议

如果想最快看到画面变化，按这个顺序补图：

1. **遗物图标（高优先）** — 战斗 HUD 已经接好图标行，每场战斗都会显示。
2. **药水图标（高优先）** — 药水栏会显示，使用频率高。
3. **敌人立绘（中优先）** — 没图的话引擎只渲染 placeholder，遇敌时空画面体感差。
4. **卡面插画（低优先）** — 当前用 card_type 占位图已可玩。需要先在 card_view.gd 加回退逻辑后再生效。

## 7. 工作流建议

- 推荐用 SDXL / Midjourney v6 / Flux 之类支持精确尺寸的模型。
- 把 prompt 列里的关键词与「全局风格基调」拼接，能保持风格一致。
- 生成完成后直接把 PNG 放到对应路径，引擎会自动识别。
- 缺图时引擎已有 fallback：遗物会用 `relic_slot.png`，敌人会显示空 placeholder。
