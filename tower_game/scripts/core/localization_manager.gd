class_name GameLocalization
extends Node

signal language_changed(language: String)

const SAVE_PATH := "user://tower_settings.json"
const EN := "en"
const ZH := "zh"

var language := ZH

var ui := {
	"zh": {
		"main.title": "活体档案馆",
		"main.subtitle": "可游玩的 Roguelike 卡牌构筑 Demo。选择路线、打出卡牌、强化牌组，并击败封印馆长。",
		"main.saved": "存档：第 %d/%d 层，生命 %d/%d，金币 %d",
		"main.continue": "继续游戏",
		"main.new": "新游戏",
		"main.settings": "设置",
		"main.help": "选择“新游戏”来挑选角色、调整进阶难度，并查看初始牌组。",
		"intro.title": "序章：会记得你的门",
		"intro.story": "活体档案馆在旧塔下开启。每一排书架都记得一份破碎誓言，每一页纸都学会了咬人。你携带着%s，一份微小权限，也是活下去的脆弱借口。\n\n任务：在这座塔把你的名字写入损耗名单之前，从封印馆长手中取回档案钥匙。",
		"intro.enter": "进入档案馆",
		"select.title": "选择入塔者",
		"select.subtitle": "选择角色，查看初始配置，然后设定进阶难度。",
		"select.back": "返回",
		"select.selected": "已选择",
		"select.available": "可选择",
		"select.hp": "初始生命",
		"select.relic": "初始遗物",
		"select.deck": "牌组",
		"select.card_count": "%d 张牌",
		"select.asc": "进阶",
		"select.cards": "初始牌",
		"select.difficulty": "难度",
		"select.keywords": "关键词",
		"select.warning": "开始新游戏会覆盖当前存档。",
		"select.start": "进入档案馆",
		"class.warrior": "战士",
		"class.warlock": "咒术师",
		"class.mage": "法师",
		"class.assassin": "刺客",
		"char.char_vanguard.name": "先锋",
		"char.char_vanguard.subtitle": "铁甲缚身，手持账册，缓慢但难以击倒。",
		"char.char_vanguard.traits": "定位：前线斗士。\n优势：高生命、稳定格挡、攻击成长清晰。\n压力：过牌较慢，挑战精英前需要补强伤害。",
		"char.char_archivist.name": "档案员",
		"char.char_archivist.subtitle": "羽笔迅捷，善收旧账，知道印章藏在哪里。",
		"char.char_archivist.traits": "定位：状态与过牌专家。\n优势：费用灵活、墨迹压制、回合选择更多。\n压力：生命较低，起手防御不稳时更危险。",
		"char.char_mage.name": "法师",
		"char.char_mage.subtitle": "核心术士，先为索引充能，再释放成爆发回合。",
		"char.char_mage.traits": "定位：蓄能爆发法师。\n优势：通过充能、专注和法术生成制造高上限回合。\n压力：准备回合偏脆，需要控制手牌和能量节奏。",
		"char.char_assassin.name": "刺客",
		"char.char_assassin.subtitle": "页边匕首，标记一个名字，然后让页面忘记它。",
		"char.char_assassin.traits": "定位：标记与连击刺客。\n优势：弃牌节奏、毒性压力、标记爆发和高机动性。\n压力：防御依赖节奏，失去连击时容错较低。",
		"char.char_warlock.name": "咒术师",
		"settings.paused": "暂停",
		"settings.hint": "（按 ESC 继续）",
		"settings.title": "设置",
		"settings.master": "主音量",
		"settings.music": "音乐",
		"settings.sfx": "音效",
		"settings.language": "语言",
		"settings.language_value": "中文",
		"settings.fast": "快速结算",
		"settings.tutorial": "显示教程提示",
		"settings.resume": "继续",
		"settings.menu": "主菜单",
		"combat.relics": "遗物：",
		"combat.reset": "重开",
		"combat.player_turn": "玩家回合",
		"combat.enemy_turn": "敌人回合",
		"combat.victory": "胜利",
		"combat.phase": "阶段转换",
		"combat.player_name": "先锋档案员",
		"combat.top_player": "生命 %d/%d    格挡 %d    能量 %d/%d",
		"combat.top_piles": "抽牌 %d    手牌 %d    弃牌 %d    消耗 %d",
		"combat.block": "格挡：%d",
		"combat.hp_block": "%s\n生命 %d/%d  格挡 %d",
		"combat.statuses": "状态：%s",
		"combat.none": "无",
		"combat.energy": "能量\n%d/%d",
		"combat.draw": "抽牌\n%d",
		"combat.discard": "弃牌\n%d",
		"combat.exhaust": "消耗\n%d",
		"combat.deck": "牌组 %d · %d/%d/%d",
		"combat.deck_tip": "点击查看完整牌组（攻/技/能）",
		"combat.hand": "手牌 - 点击卡牌打出。剩余能量：%d",
		"combat.resolving": "卡牌结算中...",
		"combat.end_turn": "结束回合",
		"combat.fast": "快速",
		"combat.ready": "状态：准备就绪",
		"combat.no_energy": "能量不足",
		"combat.log.no_energy_for": "能量不足，无法打出 %s。",
		"combat.log.skipped_reward": "跳过了卡牌奖励。",
		"combat.log.enemy_rises": "%s 从档案地面升起。",
		"combat.log.enemies_rise": "%s 从档案地面升起。",
		"combat.target_tip": "点击切换攻击目标。",
		"combat.tip.hover": "提示：悬停卡牌可查看完整详情和关键词。",
		"combat.tip.target": "提示：点击敌人面板可切换目标。",
		"combat.tip.end_turn": "提示：力量/敏捷会保留；格挡会在每回合重置。",
		"combat.tip.settings": "提示：按 ESC 打开暂停/设置。",
		"intent.ward": "防守",
		"intent.block": "格挡",
		"intent.attack": "攻击",
		"intent.heavy_attack": "重击",
		"intent.buff": "强化",
		"intent.debuff": "削弱",
		"intent.up": "增强",
		"intent.down": "削弱",
		"intent.unknown": "未知",
		"shop.title": "静默商人",
		"shop.hint": "提灯照亮的商人把几件工具铺在绒布上。这里金币说话很轻。",
		"shop.gold": "金币：%d",
		"shop.remove": "移除一张牌 - %d 金币",
		"shop.remove_tip": "从本局牌组中移除一张牌。",
		"shop.remove_tip_blocked": "需要至少一张 Strike Form，且牌组数量大于 8。",
		"shop.leave": "离开",
		"shop.buy": "购买",
		"shop.sold": "已售",
		"shop.price": "%d 金币",
		"shop.empty": "暂无%s商品",
		"shop.kind.card": "卡牌",
		"shop.kind.relic": "遗物",
		"shop.kind.potion": "药水",
		"reward.title": "档案馆战利品",
		"reward.gold": "+18 金币已取得。选择一张牌。",
		"reward.hint": "档案馆给出三份可能的记录。带走一张，或封存它们换取额外金币。",
		"reward.skip": "跳过奖励（+25 金币）",
		"modal.close": "关闭",
		"modal.cancel": "取消",
		"modal.deck_title": "牌组",
		"modal.run_deck": "本局牌组",
		"modal.draw_pile": "抽牌堆（%d）",
		"modal.discard_pile": "弃牌堆（%d）",
		"modal.exhaust_pile": "消耗堆（%d）",
		"modal.summary": "%d 张牌 · %d 攻击 · %d 技能 · %d 能力",
		"modal.sort.type": "按类型",
		"modal.sort.cost": "按费用",
		"modal.sort.rarity": "按稀有度",
		"modal.state": "生命 %d/%d    金币 %d    牌组 %d",
		"picker.default_title": "选择一张牌",
		"picker.remove_strike.title": "移除一张打击架势",
		"picker.remove_strike.hint": "选择要从本局移除的那一张。",
		"picker.upgrade.title": "升级一张牌",
		"picker.upgrade.hint": "选择一张未升级的牌进行强化。",
		"picker.transform.title": "变化一张牌",
		"picker.transform.hint": "选择一张牌。提灯会把它改写为同类型的另一张。",
		"picker.transform_green.hint": "选择一张牌，在绿色蜡火下改写。",
		"picker.offer.title": "献出一张牌",
		"picker.offer.hint": "从本局中移除一张牌。",
		"picker.shop_remove.title": "商店移除",
		"picker.shop_remove.hint": "选择一张打击架势移除。商人已经收下金币。",
		"inspector.upgraded": "升级后 → %s",
		"event.quiet_stack.title": "静默书堆",
		"event.quiet_stack.body": "一张阅读桌停在思绪中断的瞬间。灯下压着一件小物。",
		"event.quiet_stack.choice1": "拿走物件。失去 8 点生命，获得一件遗物。",
		"event.quiet_stack.choice2": "先阅读。失去 4 点生命，获得一件遗物。",
		"event.quiet_stack.choice3": "离开书桌。",
		"event.clean_margin.title": "干净页边",
		"event.clean_margin.body": "有人在桌上留下一块橡皮。它只能擦掉你自己身上的东西。",
		"event.clean_margin.choice1": "支付 75 金币。移除一张打击架势。",
		"event.clean_margin.choice2": "支付 30 金币。获得一张随机卡牌。",
		"event.clean_margin.choice3": "走过去。",
		"event.red_string.title": "红线",
		"event.red_string.body": "一根红线系在你的手指上。不是你系的。",
		"event.red_string.choice1": "接受。获得一件遗物和誓压。",
		"event.red_string.choice2": "剪断它。失去 5 点生命。",
		"event.red_string.choice3": "放着不管。受到 2 点伤害。",
		"event.revision_desk.title": "修订桌",
		"event.revision_desk.body": "这张桌子一直在等你。桌上有笔、印章，以及价码。",
		"event.revision_desk.choice1": "支付 50 金币。升级一张牌。",
		"event.revision_desk.choice2": "以血支付。失去 6 点生命，升级一张牌。",
		"event.revision_desk.choice3": "离开桌子。",
		"event.transform_lantern.title": "变化提灯",
		"event.transform_lantern.body": "一盏燃着绿色蜡火的提灯。盯得够久，你携带的一张牌会自行改写。",
		"event.transform_lantern.choice1": "凝视火焰。变化一张牌。",
		"event.transform_lantern.choice2": "支付 40 金币。变化一张牌。",
		"event.transform_lantern.choice3": "走过去。",
		"event.ink_well.title": "墨井",
		"event.ink_well.body": "一汪黑池，几个世纪以来都被误认为墨水。它其实是别的东西。",
		"event.ink_well.choice1": "饮下。失去 6 点生命，获得 40 金币。",
		"event.ink_well.choice2": "装瓶。获得一瓶随机药水。",
		"event.ink_well.choice3": "保持封存。",
		"event.dust_oracle.title": "尘土神谕",
		"event.dust_oracle.body": "一小堆尘土隐约像个孩子。它索要一张牌，以及一个承诺。",
		"event.dust_oracle.choice1": "献出一张牌。移除它，回复 10 点生命。",
		"event.dust_oracle.choice2": "献上 30 金币。升级一张牌。",
		"event.dust_oracle.choice3": "礼貌拒绝。",
		"event.weighing_scales.title": "称量天平",
		"event.weighing_scales.body": "一台比塔更古老的铜秤。一边要血，一边要金。指针很诚实。",
		"event.weighing_scales.choice1": "放上 8 点生命。获得 80 金币。",
		"event.weighing_scales.choice2": "放上 60 金币。获得 12 点最大生命。",
		"event.weighing_scales.choice3": "退开。",
		"event.burned_archive.title": "焚毁档案室",
		"event.burned_archive.body": "侧厅坍成灰烬。仍可抢救一些东西。书页并不同意。",
		"event.burned_archive.choice1": "抢救。失去 10 点生命，获得一件遗物。",
		"event.burned_archive.choice2": "慢慢搜寻。失去 4 点生命，获得一张随机卡牌。",
		"event.burned_archive.choice3": "封住门。",
		"event.broken_standard.title": "断裂战旗",
		"event.broken_standard.body": "一面折断的战旗斜靠在书架旁。布面仍记得那条没有后退的阵线。",
		"event.broken_standard.choice1": "重新举旗。失去 5 点生命，获得一件战士遗物。",
		"event.broken_standard.choice2": "重整阵线。获得一张守势切击。",
		"event.broken_standard.choice3": "仔细折好它。",
		"event.unpaid_contract.title": "未付契约",
		"event.unpaid_contract.body": "一份黑蜡契约摊开到空白签名处。笔还未落下，墨已经开始移动。",
		"event.unpaid_contract.choice1": "用黑墨签名。失去 6 点生命，获得一件咒术师遗物。",
		"event.unpaid_contract.choice2": "抄下条款。获得一张索引标记和 25 金币。",
		"event.unpaid_contract.choice3": "不签。",
		"event.core_orrery.title": "核心星仪",
		"event.core_orrery.body": "一台小小的黄铜星仪无人自转。蓝色核心等待一个值得燃烧的定理。",
		"event.core_orrery.choice1": "调准核心。失去 5 点生命，获得一件法师遗物。",
		"event.core_orrery.choice2": "抄下轨道。获得一张核心火花和 20 金币。",
		"event.core_orrery.choice3": "让它继续转动。",
		"event.silent_margin.title": "静默页边",
		"event.silent_margin.body": "一条页边在不该出现的地方裂开。里面递出一把没有柄的刀。",
		"event.silent_margin.choice1": "伸手进去。失去 5 点生命，获得一件刺客遗物。",
		"event.silent_margin.choice2": "取走暗路。获得一张烟步和 20 金币。",
		"event.silent_margin.choice3": "合上页边。",
		"event.loose_page.title": "散页",
		"event.loose_page.body": "一页纸从装订里剥落，站了起来。它看起来并不高兴。",
		"event.loose_page.choice1": "与它战斗。",
		"event.loose_page.choice2": "逃走。受到 4 点伤害。",
		"event.loose_page.choice3": "与它交谈。",
		"event.unavailable.title": "无法执行",
		"event.unavailable.gold": "你的金币不够。",
		"event.unavailable.remove": "需要足够金币，且牌组大于 8 张。",
		"event.unavailable.transform": "需要足够金币，并且有一张可变化的非基础牌。",
		"event.unavailable.deck": "牌组太小，不能再献出卡牌。",
		"event.unavailable.continue": "返回路线图。",
		"summary.deck_title": "牌组（%d）",
		"summary.relics_title": "遗物（%d）",
		"summary.victory_title": "档案封存：本局完成",
		"summary.defeat_title": "本局失败：档案馆闭合",
		"summary.subtitle": "%s · 进阶 %d · 种子 %d",
		"summary.new_run": "开始新游戏",
		"summary.main_menu": "主菜单",
		"summary.outcome_victory": "结局：胜利",
		"summary.outcome_defeat": "结局：失败",
		"summary.final_hp": "最终生命：%d / %d",
		"summary.act": "抵达幕数：%d / %d",
		"summary.floor": "抵达层数：%d",
		"summary.encounters": "完成战斗：%d",
		"summary.gold": "持有金币：%d",
		"summary.removals": "移除卡牌：%d",
		"summary.shop_visits": "商店访问：%d",
		"summary.events_seen": "遭遇事件：%d",
		"summary.deck_breakdown": "攻 %d  技 %d  能 %d",
		"summary.deck_curse": "诅 %d",
		"summary.deck_status": "状 %d",
		"summary.deck_upgraded": "升 %d",
		"summary.none": "（无）",
		"completion.title": "档案钥匙已回收",
		"completion.body": "封印馆长归于沉默。档案钥匙在你掌心转动一次，每一排上锁书架都吐出一口气。本 Demo 本局已完成。\n\n最终状态：生命 %d/%d，金币 %d，牌组 %d 张牌。",
		"act2.title": "第二幕：焚页编年室",
		"act2.body": "第一道封印裂开。封印之后，半焚的书页围绕一位等待共读的编年者重新排列。你感到档案馆向更深处移动了一层。",
		"act3.title": "第三幕：大金库",
		"act3.body": "编年者的沉默合拢。一扇金库门打开，里面是一排排未读书架。在最深处，大档案师正在清点你越界的代价。",
		"act.next_title": "下一幕",
		"act.default_body": "档案馆继续向前打开。",
		"act.recover": "%s\n\n你稍稍恢复。沉默把一件新遗物压进你的手里。",
		"act.continue": "继续前进",
		"scene.shop": "[ 提灯商店 ]",
		"scene.camp": "[ 蜡火营地 ]",
		"scene.lost": "[ 本局失败 ]",
		"scene.event": "[ 档案事件 ]",
		"route.select": "选择一个亮起的路线节点。",
		"map.title": "活体档案馆",
		"map.stats": "第 %d/%d 幕  生命 %d/%d  金币 %d  牌组 %d  层数 %d/%d  遗物 %d  药水 %d/3  A%d",
		"map.new": "新游戏",
		"map.task": "当前任务",
		"map.task_body": "%s\n选择一个亮起的路线节点。灰暗图标尚未解锁。",
		"map.deck": "牌组（%d）",
		"map.deck_summary": "牌组 %d · %d 攻击 / %d 技能 / %d 能力",
		"map.quest": "构建可靠的牌组。在进入上层档案前，找到一张伤害牌和一个防御工具。",
		"map.state.available": "可前往",
		"map.state.cleared": "已完成",
		"map.state.locked": "未解锁",
		"map.node.start.title": "外门",
		"map.node.start.subtitle": "档案馆开启了。",
		"map.node.combat.title": "档案战斗",
		"map.node.combat.subtitle": "一份敌意记录挡住去路。",
		"map.node.elite.title": "精英封印",
		"map.node.elite.subtitle": "封印执法者正在等待。",
		"map.node.event.title": "档案事件",
		"map.node.event.subtitle": "一条条款提出交易。",
		"map.node.shop.title": "静默商人",
		"map.node.shop.subtitle": "花费金币，提高稳定性。",
		"map.node.campfire.title": "蜡光休憩处",
		"map.node.campfire.subtitle": "休息，或磨利一张牌。",
		"map.node.treasure.title": "上锁抽屉",
		"map.node.treasure.subtitle": "取得一件存放之物。",
		"map.node.boss.title": "封印馆长",
		"map.node.boss.subtitle": "取回档案馆钥匙。",
		"camp.title": "蜡光休憩处",
		"camp.state": "生命 %d/%d    金币 %d    牌组 %d",
		"camp.body": "温热的蜡在旧刀旁聚成一滩。档案馆短暂安静，允许你喘息一次。",
		"camp.rest": "休息：回复 30% 生命",
		"camp.rest_hint": "回复生命并返回路线图。",
		"camp.upgrade": "锻牌：升级一张牌",
		"camp.upgrade_hint": "从牌组中选择一张未升级的牌。",
		"camp.remove": "焚牌：移除一张牌",
		"camp.remove_hint": "永久烧掉一张非基础牌。",
		"camp.transform": "升腾：变化一张牌",
		"camp.transform_hint": "将一张牌变化为同类型的另一张牌。",
		"enum.attack": "攻击",
		"enum.skill": "技能",
		"enum.power": "能力",
		"enum.curse": "诅咒",
		"enum.status": "状态",
		"enum.basic": "基础",
		"enum.common": "普通",
		"enum.uncommon": "罕见",
		"enum.rare": "稀有",
		"enum.special": "特殊",
		"enum.event": "事件",
	},
}

var names_zh := {
	"char_vanguard": "先锋", "char_archivist": "档案员", "char_mage": "法师", "char_assassin": "刺客",
	"archive_bash": "档案猛击", "binder_smack": "厚册拍击", "binding_cut": "装订割痕",
	"book_throw": "掷书", "bookmark": "书签", "brace": "支撑", "brass_guard": "黄铜守卫",
	"break_rhythm": "打断节奏", "burnt_clause": "焦黑条款", "candle_count": "数烛",
	"cited_blow": "引证重击", "clean_glasses": "擦净镜片", "clipped_quote": "剪裁引文",
	"closed_file": "封档", "closing_argument": "终局陈词", "copyist_focus": "抄写员专注",
	"counterseal": "反印", "curse_burn": "灼烧", "curse_doubt": "疑虑", "curse_regret": "悔意",
	"curse_wound": "创伤", "deep_breath": "深呼吸", "deep_focus": "深度专注",
	"dripping_seal": "滴蜡印", "errata_blow": "勘误重击", "field_order": "现场命令",
	"filing_edge": "归档刃", "final_argument": "最终论证", "final_clause": "最终条款",
	"final_oath": "最终誓言", "folded_corner": "折角", "footnote_charge": "脚注冲锋",
	"forward_step": "前踏", "guard_form": "守卫架势", "hardcopy": "硬拷贝",
	"holy_quiet": "神圣静默", "index_finger": "索引指", "index_thrust": "索引突刺",
	"ink_blot": "墨渍", "ironbound": "铁装订", "last_word": "最后一句",
	"ledger_edge": "账册锋", "ledger_strike": "账册打击", "library_vow": "馆藏誓约",
	"living_archive": "活体档案", "long_quotation": "长引文", "margin_note": "页边注",
	"marginalia": "旁批", "measured_cut": "精确切割", "morning_inventory": "晨间清点",
	"oath_pressure": "誓压", "page_break": "分页斩", "page_turn": "翻页",
	"papercut": "纸割", "quick_read": "速读", "quiet_revision": "静默修订",
	"quiet_shelf": "静默书架", "quill_strike": "羽笔刺击", "reading_glance": "阅读一瞥",
	"red_pen": "红笔", "red_string": "红线", "redline": "红线批注", "reread": "重读",
	"second_pair": "第二副镜片", "second_wind": "再起之息", "shield_tap": "盾击轻敲",
	"sift_pages": "筛页", "silent_step": "静步", "silver_underline": "银色下划线",
	"spilled_inkwell": "打翻墨水瓶", "split_seal": "裂印", "staining_hand": "染墨之手",
	"stamp_down": "盖印压下", "status_dazed": "眩晕", "status_slimed": "黏液",
	"status_void": "虚空", "steady_hand": "稳手", "steel_binding": "钢装订",
	"steel_quill": "钢羽笔", "strike_form": "打击架势", "thumb_jab": "拇指戳刺",
	"twin_dot": "双点", "twin_writ": "双重令状", "underline": "下划线",
	"unyielding": "不屈", "vow_of_silence": "静默誓约", "wax_seal": "蜡封",
	"writ_of_judgement": "审判令",
	"guarded_cut": "守势切击", "line_hold": "守住阵线", "badge_check": "徽章核验",
	"paper_shield": "纸盾", "oath_jab": "誓言刺击", "filing_slam": "归档重击",
	"forced_revision": "强制修订", "clause_armor": "条款护甲", "return_stamp": "退回印章",
	"double_entry": "复式入账", "sealed_counter": "封印反制", "final_rebuttal": "最终反驳",
	"oath_engine": "誓言引擎", "index_mark": "索引标记", "file_needle": "档针",
	"wet_signature": "湿签名", "catalog_pull": "目录牵引", "quiet_stamp": "静默印章",
	"held_note": "留存便条", "ink_wash": "墨洗", "misfile": "误归档",
	"sealed_margin": "封印页边", "black_ledger": "黑账册", "cross_reference": "交叉引用",
	"citation_storm": "引文风暴", "living_index": "活体索引", "redacted_future": "涂黑未来",
	"core_spark": "核心火花", "lampguard": "灯卫", "minor_formula": "小公式",
	"glass_ray": "玻璃射线", "static_margin": "静电页边", "blue_clause": "蓝色条款",
	"white_index": "白色索引", "borrowed_star": "借来的星", "quick_calculation": "速算",
	"ash_equation": "灰烬方程", "circle_ward": "环形护符", "spark_copy": "火花副本",
	"warded_bolt": "护符电弧", "tiny_orbit": "微型轨道", "frost_notation": "霜冻记号",
	"bright_syllable": "亮音节", "refraction": "折射", "sealed_prism": "封印棱镜",
	"mana_audit": "法力审计", "comet_clause": "彗星条款", "page_of_stars": "星页",
	"volatile_glyph": "不稳定符文", "library_current": "馆藏电流", "spiral_binding": "螺旋束缚",
	"starfall_index": "星坠索引", "steady_core": "稳定核心", "thesis_flame": "论文火焰",
	"mirror_footnote": "镜像脚注", "burning_proof": "燃烧证明", "counterspell_note": "反咒便条",
	"astral_rewrite": "星界改写", "inkless_theorem": "无墨定理", "orbital_lock": "轨道锁",
	"grand_conjunction": "大合相", "archive_supernova": "档案超新星", "infinite_margin": "无限页边",
	"red_star_formula": "红星公式", "core_overload": "核心过载", "perfect_diagram": "完美图式",
	"blackboard_sun": "黑板太阳", "sealed_singularity": "封印奇点", "library_ascension": "馆藏升格",
	"final_lantern": "最终提灯", "event_horizon_note": "事件视界笔记", "axiom_engine": "公理引擎",
	"margin_slash": "页边斩", "marked_pin": "标记针", "smoke_step": "烟步",
	"needle_guard": "针卫", "quiet_puncture": "静默刺孔", "low_profile": "低身位",
	"side_cut": "侧切", "throwing_label": "投掷标签", "blind_corner": "盲角",
	"black_boot": "黑靴", "palm_blade": "掌刃", "hush": "噤声",
	"slipstream": "滑流", "venom_note": "毒液便条", "backstep": "后撤步",
	"knife_rain": "刀雨", "afterimage_file": "残影档案", "execution_mark": "处决标记",
	"hidden_hand": "藏手", "garrote_clause": "绞索条款", "shadow_inventory": "影子清点",
	"redacted_path": "涂黑路径", "two_knives": "双刀", "silent_contract": "静默契约",
	"pin_cushion": "针垫", "fade_from_record": "从记录中淡出", "toxin_thread": "毒素线",
	"knife_ladder": "刀梯", "pocket_silence": "袖中静默", "midnight_suture": "午夜缝合",
	"shadow_tax": "影税", "cut_the_witness": "切断目击者", "hidden_route": "隐秘路线",
	"final_angle": "最终角度", "death_by_index": "索引处刑", "vanishing_act": "消失术",
	"poisoned_archive": "染毒档案", "blackout_technique": "熄灯技法", "hundred_cuts": "百切",
	"unseen_payoff": "隐形报酬", "perfect_alibi": "完美不在场", "needle_storm": "针暴",
	"last_shadow": "最后影子", "erase_the_room": "抹去全室", "secret_exit": "秘密出口",
	"sealed_badge": "封印徽章", "scribes_focus": "书记专注", "endless_ledger": "无尽账册",
	"polished_seal": "抛光印章", "swift_potion": "迅捷药剂", "seal_oil": "封印油",
	"wax_stamp": "蜡印章", "torn_badge": "破损徽章", "crimson_tonic": "绯红补剂",
	"ambrosia": "神饮", "guard_draught": "守卫饮剂", "fire_potion": "火焰药剂",
	"explosive_potion": "爆裂药剂", "focus_potion": "专注药剂", "ink_spark": "墨火花",
	"fairy_pages": "妖精书页", "vulnerable_brew": "易伤酿液", "steel_potion": "钢铁药剂",
	"liquid_focus": "液态专注", "clean_breath": "清息药水", "volatile_clause": "不稳定条款",
	"weak_distillate": "虚弱蒸馏液", "frail_fume": "脆弱烟雾",
	"adamant_clasp": "精金扣", "adjudicator_seal": "裁决官印", "binding_thread": "束缚线",
	"bound_key": "束缚钥匙", "brass_bookmark": "黄铜书签", "brass_compass": "黄铜罗盘",
	"chip_seal": "缺口印章", "chronicler_mantle": "编年者披肩", "clarion_bell": "清音铃",
	"clarion_horn": "清音号角", "clerks_brooch": "书记胸针", "clerks_pen": "书记笔",
	"copper_thimble": "铜顶针", "cursed_lens": "诅咒透镜", "dawn_kindling": "黎明引火物",
	"dust_cloth": "拂尘布", "ember_charm": "余烬护符", "fastening_pin": "固定别针",
	"first_edition": "初版书", "folded_handkerchief": "折叠手帕", "folded_treaty": "折叠条约",
	"gilded_quill": "镀金羽笔", "golden_inkpot": "金墨壶", "healing_seal": "愈合印章",
	"hex_staple": "咒钉", "inkstone": "墨砚", "inkwells_grace": "墨井恩典",
	"iron_ring": "铁环", "keystone_seal": "拱顶印章", "last_stand_oath": "背水誓言",
	"ledger_clasp": "账册扣", "library_quiet": "馆藏静默", "lingering_whisper": "余音低语",
	"loyalty_token": "忠诚信物", "merchant_compass": "商人罗盘", "merchant_satchel": "商人挎包",
	"morning_ledger": "晨间账册", "oath_crown": "誓言冠", "old_promise": "旧承诺",
	"opening_letter": "开场信", "penny_purse": "零钱袋", "phoenix_feather": "凤凰羽",
	"quiet_eraser": "静默橡皮", "quiet_resolve": "静默决意", "reading_lamp": "阅读灯",
	"red_string_relic": "红线", "sage_inkstone": "贤者墨砚", "scavengers_satchel": "拾荒者挎包",
	"second_inkpot": "第二墨壶", "signed_warrant": "签署令状", "silent_inkwell": "静默墨水瓶",
	"silver_clasp": "银扣", "silver_kettle": "银壶", "silver_paperknife": "银裁纸刀",
	"steady_compass": "稳定罗盘", "steel_pen_nib": "钢笔尖", "strong_arm_band": "强臂带",
	"twin_quill": "双羽笔", "unbroken_oath": "未断誓言", "vellum_pouch": "羊皮袋",
	"warden_aegis": "守卫护盾", "warden_pact": "守卫契约", "warm_kettle": "温热水壶",
	"warning_chime": "警示风铃", "wax_amulet": "蜡护符", "weighted_paper": "镇纸",
	"field_lantern": "战地提灯", "warden_glove": "典狱手套", "binding_thread_warrior": "束缚线",
	"inkstone_warlock": "黑墨砚", "blood_wax": "血蜡", "adjudicator_seal_warlock": "裁决官印",
	"core_lantern": "核心提灯", "hidden_blade": "藏刃", "spellglass": "咒镜",
	"orrery_pin": "星仪别针", "blue_core_fragment": "蓝核碎片", "silent_boot": "静默靴",
	"black_needle": "黑针", "margin_cloak": "页边斗篷",
	"e_dust_scribe": "尘埃抄写员", "e_loose_folio": "散页怪", "e_wax_acolyte": "蜡印侍从",
	"e_margin_hound": "页边猎犬", "e_burnt_courier": "焦页信使", "e_glassed_intern": "玻璃实习员",
	"e_late_filer": "迟到归档员", "e_silent_ledger": "静默账册", "e_dust_sentinel": "尘埃哨兵",
	"e_red_string_imp": "红线小鬼", "e_index_rat": "索引鼠", "e_staple_swarm": "订书钉群",
	"e_ink_moth": "墨蛾", "e_clause_mender": "条款缝补者", "e_ledger_sentry": "账册哨卫",
	"e_null_page": "空白页", "e_redaction_monk": "涂黑修士", "e_keyhole_mimic": "钥孔拟态",
	"el_wax_sentinel": "蜡印哨卫", "el_first_clause": "第一条款", "el_quill_judge": "羽笔法官",
	"el_ironbound_clerk": "铁装订书记", "el_archive_warden": "档案守卫", "el_dust_chorus": "尘埃合唱",
	"el_penitent_index": "忏悔索引", "el_null_librarian": "空白图书员", "el_redaction_engine": "涂黑引擎",
	"b_sealed_curator": "封印馆长", "b_ink_tyrant": "墨水暴君", "b_chronicler_of_lost_pages": "失页编年者",
	"b_mirror_tribunal": "镜面审判庭", "b_grand_archivist": "大档案师", "b_last_catalog": "最终目录",
}

func _ready() -> void:
	language = _load_language()


func set_language(value: String) -> void:
	var next := ZH if value == ZH else EN
	if language == next:
		return
	language = next
	_save_language()
	language_changed.emit(language)


func toggle_language() -> void:
	set_language(ZH if language == EN else EN)


func is_zh() -> bool:
	return language == ZH


func t(key: String, fallback: String = "") -> String:
	if language == ZH:
		return String(ui.get(ZH, {}).get(key, fallback if fallback != "" else key))
	return fallback if fallback != "" else key


func name_for(id: String, fallback: String) -> String:
	if language == ZH:
		return String(names_zh.get(id, fallback))
	return fallback


func card_description(id: String, fallback: String) -> String:
	if language == ZH:
		return _translate_card_rules(fallback)
	return fallback


func card_description_for(id: String, fallback: String, _upgraded: bool = false) -> String:
	return card_description(id, fallback)


func enum_text(value: String) -> String:
	return t("enum.%s" % value.to_lower(), value.to_upper())


func _translate_card_rules(text: String) -> String:
	if text == "":
		return text
	var result: Array[String] = []
	for raw_sentence in text.split("."):
		var sentence := String(raw_sentence).strip_edges()
		if sentence == "":
			continue
		result.append(_translate_card_sentence(sentence))
	return "".join(result)


func _translate_card_sentence(sentence: String) -> String:
	var normalized := sentence.replace("Block", "block")
	normalized = normalized.replace("strength", "Strength")
	normalized = normalized.replace("dexterity", "Dexterity")
	normalized = normalized.replace("energy", "Energy")
	var direct := {
		"Unplayable": "无法打出。",
		"Exhaust": "消耗：打出后进入消耗堆。",
		"Ethereal": "虚无：回合结束时若仍在手牌则进入消耗堆。",
		"Clogs your hand": "会占住你的手牌。",
		"If target has Vulnerable, draw 1": "若目标有易伤，抽 1 张牌。",
		"At end of turn, lose 2 HP": "回合结束时，失去 2 点生命。",
		"At end of turn, gain 1 Weak": "回合结束时，获得 1 层虚弱。",
		"At end of turn, lose 1 HP per card in hand": "回合结束时，每有 1 张手牌失去 1 点生命。",
		"When drawn, lose 1 Energy": "抽到时，失去 1 点能量。",
		"Retain": "回合结束时保留在手牌。",
		"Exhaust 1 random card in hand": "随机将 1 张手牌置入消耗堆。",
		"Discard 1 random card": "随机弃 1 张牌。",
		"Deal damage equal to twice the target's Ink stacks": "造成目标墨迹层数 2 倍的伤害。",
		"Deal damage equal to three times the target's Ink stacks": "造成目标墨迹层数 3 倍的伤害。",
		"Deal damage equal to four times the target's Ink stacks": "造成目标墨迹层数 4 倍的伤害。",
		"Deal damage equal to five times the target's Ink stacks": "造成目标墨迹层数 5 倍的伤害。"
	}
	if direct.has(normalized):
		return String(direct[normalized])
	var patterns := [
		{"p": "^Deal (\\d+) damage (\\d+) times$", "t": "造成 %s 点伤害 %s 次。"},
		{"p": "^Deal (\\d+) damage twice$", "t": "造成 %s 点伤害 2 次。"},
		{"p": "^Deal (\\d+) damage to ALL enemies$", "t": "对所有敌人造成 %s 点伤害。"},
		{"p": "^Deal (\\d+) damage$", "t": "造成 %s 点伤害。"},
		{"p": "^Gain (\\d+) block$", "t": "获得 %s 点格挡。"},
		{"p": "^Draw (\\d+) cards?$", "t": "抽 %s 张牌。"},
		{"p": "^Draw (\\d+)$", "t": "抽 %s 张牌。"},
		{"p": "^Apply (\\d+) Weak$", "t": "施加 %s 层虚弱。"},
		{"p": "^Apply (\\d+) Vulnerable$", "t": "施加 %s 层易伤。"},
		{"p": "^Apply (\\d+) Frail$", "t": "施加 %s 层脆弱。"},
		{"p": "^Apply (\\d+) Ink$", "t": "施加 %s 层墨迹。"},
		{"p": "^Apply (\\d+) Ink to ALL enemies$", "t": "对所有敌人施加 %s 层墨迹。"},
		{"p": "^Apply (\\d+) Weak to ALL enemies$", "t": "对所有敌人施加 %s 层虚弱。"},
		{"p": "^Apply (\\d+) Vulnerable to ALL enemies$", "t": "对所有敌人施加 %s 层易伤。"},
		{"p": "^Apply (\\d+) Weak and (\\d+) Frail to ALL enemies$", "t": "对所有敌人施加 %s 层虚弱和 %s 层脆弱。"},
		{"p": "^Apply (\\d+) Weak and (\\d+) Vulnerable to ALL enemies$", "t": "对所有敌人施加 %s 层虚弱和 %s 层易伤。"},
		{"p": "^Apply (\\d+) Ink and (\\d+) Weak$", "t": "施加 %s 层墨迹和 %s 层虚弱。"},
		{"p": "^Apply (\\d+) Weak and (\\d+) Vulnerable$", "t": "施加 %s 层虚弱和 %s 层易伤。"},
		{"p": "^Gain (\\d+) Strength$", "t": "获得 %s 点力量。"},
		{"p": "^Gain (\\d+) Dexterity$", "t": "获得 %s 点敏捷。"},
		{"p": "^Gain (\\d+) Energy$", "t": "获得 %s 点能量。"},
		{"p": "^Gain (\\d+) energy$", "t": "获得 %s 点能量。"},
		{"p": "^Gain (\\d+) Max HP$", "t": "获得 %s 点最大生命。"},
		{"p": "^Heal (\\d+) HP$", "t": "回复 %s 点生命。"},
		{"p": "^Lose (\\d+) HP$", "t": "失去 %s 点生命。"}
	]
	for entry in patterns:
		var re := RegEx.new()
		if re.compile(String(entry["p"])) != OK:
			continue
		var m := re.search(normalized)
		if m == null:
			continue
		var captures := []
		for index in range(1, m.get_group_count() + 1):
			captures.append(m.get_string(index))
		return String(entry["t"]) % captures
	return "%s。" % sentence


func _load_language() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ZH
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return ZH
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		return ZH if String(parsed.get("language", ZH)) == ZH else EN
	return ZH


func _save_language() -> void:
	var values := {}
	if FileAccess.file_exists(SAVE_PATH):
		var f_read := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f_read != null:
			var parsed = JSON.parse_string(f_read.get_as_text())
			f_read.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				values = parsed
	values["language"] = language
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(values, "  "))
	f.close()
