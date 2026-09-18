class_name ChineseLexicon
extends RefCounted

## Word-by-word breakdown of every Chinese line spoken in the Chinese
## village (see chinese_village.gd -- Chen the vendor, the farmer 田伯, the
## emperor 皇帝, the royal chef 御厨, the eight VILLAGER_IDENTITIES, and the
## five KID_IDENTITIES). Powers DialogUI's own Chinese-learning presentation
## for exactly these characters (see DialogUI.show_line()'s own use of
## is_chinese()/segments_for()) -- no other NPC in the project speaks
## Chinese, so nothing else is affected.
##
## WORDS is the shared vocabulary: one entry per distinct word/phrase, keyed
## by its exact hanzi, each carrying its own pinyin (tone marks) and English
## gloss. LINES maps each full displayed dialogue string (an exact match
## against the `line` argument chinese_village.gd already passes into
## DialogUI.show_line()) to an ordered Array of tokens that concatenate back
## into that exact string: a token present as a WORDS key is a selectable
## word; any other token (punctuation) is shown as plain, non-selectable
## text. Multi-character words are kept as single tokens throughout (e.g.
## "灯笼" is one token, not "灯"+"笼"), per direct instruction that
## multi-character words should stay clustered together.

const WORDS := {
	"都": {"pinyin": "dōu", "english": "all / both"},
	"是": {"pinyin": "shì", "english": "to be; is"},
	"竹林": {"pinyin": "zhú lín", "english": "bamboo forest"},
	"后面": {"pinyin": "hòu miàn", "english": "behind"},
	"新鲜": {"pinyin": "xīn xiān", "english": "fresh"},
	"采": {"pinyin": "cǎi", "english": "to pick, gather"},
	"的": {"pinyin": "de", "english": "[possessive/descriptive particle]"},
	"信不信": {"pinyin": "xìn bú xìn", "english": "believe it or not"},
	"由你": {"pinyin": "yóu nǐ", "english": "up to you"},
	"这": {"pinyin": "zhè", "english": "this"},
	"豆子": {"pinyin": "dòu zi", "english": "bean"},
	"可不是": {"pinyin": "kě bú shì", "english": "that's for sure; definitely"},
	"开玩笑": {"pinyin": "kāi wán xiào", "english": "to joke"},
	"种": {"pinyin": "zhòng", "english": "to plant"},
	"下去": {"pinyin": "xià qù", "english": "to go on, continue"},
	"看看": {"pinyin": "kàn kan", "english": "to take a look"},
	"就": {"pinyin": "jiù", "english": "then; just"},
	"知道": {"pinyin": "zhī dào", "english": "to know"},
	"了": {"pinyin": "le", "english": "[completed-action particle]"},
	"别": {"pinyin": "bié", "english": "don't"},
	"问": {"pinyin": "wèn", "english": "to ask"},
	"我": {"pinyin": "wǒ", "english": "I; me"},
	"怎么回事": {"pinyin": "zěn me huí shì", "english": "what's going on"},
	"灯笼": {"pinyin": "dēng lóng", "english": "lantern"},
	"、": {"pinyin": "", "english": "[enumeration comma]"},
	"包子": {"pinyin": "bāo zi", "english": "steamed bun"},
	"路上": {"pinyin": "lù shang", "english": "on the road; along the way"},
	"缺": {"pinyin": "quē", "english": "to lack, be missing"},
	"什么": {"pinyin": "shén me", "english": "what"},
	"尽管": {"pinyin": "jǐn guǎn", "english": "feel free to; by all means"},
	"皇帝": {"pinyin": "huáng dì", "english": "emperor"},
	"每年": {"pinyin": "měi nián", "english": "every year"},
	"从": {"pinyin": "cóng", "english": "from"},
	"地里": {"pinyin": "dì lǐ", "english": "in the field"},
	"多": {"pinyin": "duō", "english": "more"},
	"要": {"pinyin": "yào", "english": "to want, demand"},
	"一些": {"pinyin": "yī xiē", "english": "some, a few"},
	"再": {"pinyin": "zài", "english": "further, again"},
	"这样": {"pinyin": "zhè yàng", "english": "like this, this way"},
	"没": {"pinyin": "méi", "english": "not; don't have"},
	"地方": {"pinyin": "dì fang", "english": "place"},
	"潘迪": {"pinyin": "Pān dí", "english": "Pandy (name)"},
	"地": {"pinyin": "dì", "english": "land, ground"},
	"跟着": {"pinyin": "gēn zhe", "english": "following"},
	"很多": {"pinyin": "hěn duō", "english": "many, a lot of"},
	"年": {"pinyin": "nián", "english": "year"},
	"它": {"pinyin": "tā", "english": "it"},
	"比": {"pinyin": "bǐ", "english": "compared to; than"},
	"还": {"pinyin": "hái", "english": "even more; still"},
	"懂得": {"pinyin": "dǒng de", "english": "to know how to"},
	"躲懒": {"pinyin": "duǒ lǎn", "english": "to shirk work, slack off"},
	"还给": {"pinyin": "huán gěi", "english": "to give back to"},
	"这些": {"pinyin": "zhè xiē", "english": "these"},
	"年头": {"pinyin": "nián tou", "english": "years; times"},
	"一回": {"pinyin": "yī huí", "english": "one time, for once"},
	"不用": {"pinyin": "bú yòng", "english": "no need to"},
	"看": {"pinyin": "kàn", "english": "to look, watch"},
	"脸色": {"pinyin": "liǎn sè", "english": "facial expression"},
	"已经": {"pinyin": "yǐ jīng", "english": "already"},
	"认": {"pinyin": "rèn", "english": "to recognize, accept"},
	"你": {"pinyin": "nǐ", "english": "you"},
	"跟": {"pinyin": "gēn", "english": "with"},
	"谁": {"pinyin": "shéi", "english": "who"},
	"不": {"pinyin": "bù", "english": "not"},
	"亲": {"pinyin": "qīn", "english": "close, intimate"},
	"除了": {"pinyin": "chú le", "english": "except for"},
	"我们": {"pinyin": "wǒ men", "english": "we; us"},
	"俩": {"pinyin": "liǎ", "english": "two (people)"},
	"整个": {"pinyin": "zhěng gè", "english": "whole, entire"},
	"山谷": {"pinyin": "shān gǔ", "english": "valley"},
	"连": {"pinyin": "lián", "english": "even"},
	"脚下": {"pinyin": "jiǎo xià", "english": "underfoot"},
	"浮岛": {"pinyin": "fú dǎo", "english": "floating island"},
	"朕": {"pinyin": "zhèn", "english": "I (royal, used only by the emperor)"},
	"疆土": {"pinyin": "jiāng tǔ", "english": "territory"},
	"御厨": {"pinyin": "yù chú", "english": "royal chef"},
	"最": {"pinyin": "zuì", "english": "most"},
	"懂": {"pinyin": "dǒng", "english": "to understand"},
	"治国": {"pinyin": "zhì guó", "english": "to govern the country"},
	"他": {"pinyin": "tā", "english": "he; him"},
	"说": {"pinyin": "shuō", "english": "to say"},
	"严厉": {"pinyin": "yán lì", "english": "strict, severe"},
	"一点": {"pinyin": "yī diǎn", "english": "a little"},
	"百姓": {"pinyin": "bǎi xìng", "english": "common people"},
	"才": {"pinyin": "cái", "english": "only then"},
	"会": {"pinyin": "huì", "english": "will, would"},
	"听话": {"pinyin": "tīng huà", "english": "to obey"},
	"像": {"pinyin": "xiàng", "english": "to resemble, be like"},
	"做": {"pinyin": "zuò", "english": "to do, make"},
	"一场": {"pinyin": "yī chǎng", "english": "one (occurrence of)"},
	"很": {"pinyin": "hěn", "english": "very"},
	"长": {"pinyin": "cháng", "english": "long"},
	"噩梦": {"pinyin": "è mèng", "english": "nightmare"},
	"如今": {"pinyin": "rú jīn", "english": "now, nowadays"},
	"这座": {"pinyin": "zhè zuò", "english": "this (large structure/place)"},
	"村庄": {"pinyin": "cūn zhuāng", "english": "village"},
	"作主": {"pinyin": "zuò zhǔ", "english": "to be in charge, decide"},
	"原来": {"pinyin": "yuán lái", "english": "it turns out; originally"},
	"一直": {"pinyin": "yī zhí", "english": "all along, continuously"},
	"在": {"pinyin": "zài", "english": "[ongoing action]; at"},
	"蒙蔽": {"pinyin": "méng bì", "english": "to deceive, hoodwink"},
	"救": {"pinyin": "jiù", "english": "to save, rescue"},
	"和": {"pinyin": "hé", "english": "and"},
	"从今日起": {"pinyin": "cóng jīn rì qǐ", "english": "from today onward"},
	"农人": {"pinyin": "nóng rén", "english": "farmer"},
	"小事": {"pinyin": "xiǎo shì", "english": "small matter, trifle"},
	"不值得": {"pinyin": "bù zhí de", "english": "not worth"},
	"费心": {"pinyin": "fèi xīn", "english": "to trouble oneself"},
	"只": {"pinyin": "zhǐ", "english": "only"},
	"等": {"pinyin": "děng", "english": "to wait for"},
	"献上": {"pinyin": "xiàn shàng", "english": "to offer up, present"},
	"完美": {"pinyin": "wán měi", "english": "perfect"},
	"肉包": {"pinyin": "ròu bāo", "english": "meat bun"},
	"农田": {"pinyin": "nóng tián", "english": "farmland"},
	"正在": {"pinyin": "zhèng zài", "english": "currently (in the middle of)"},
	"寻找": {"pinyin": "xún zhǎo", "english": "to search for"},
	"天下": {"pinyin": "tiān xià", "english": "the whole world"},
	"……": {"pinyin": "", "english": "[trailing off]"},
	"等等": {"pinyin": "děng děng", "english": "wait a moment"},
	"圆滚滚": {"pinyin": "yuán gǔn gǔn", "english": "round and plump"},
	"正是": {"pinyin": "zhèng shì", "english": "precisely, exactly"},
	"送去": {"pinyin": "sòng qù", "english": "to send off, deliver"},
	"御膳房": {"pinyin": "yù shàn fáng", "english": "royal kitchen"},
	"总是": {"pinyin": "zǒng shì", "english": "always"},
	"亮": {"pinyin": "liàng", "english": "bright; to light up"},
	"到": {"pinyin": "dào", "english": "until; to"},
	"半夜": {"pinyin": "bàn yè", "english": "midnight"},
	"没人": {"pinyin": "méi rén", "english": "nobody"},
	"记得": {"pinyin": "jì de", "english": "to remember"},
	"规矩": {"pinyin": "guī ju", "english": "rule, custom"},
	"定下": {"pinyin": "dìng xià", "english": "to set, establish"},
	"走": {"pinyin": "zǒu", "english": "to walk, go"},
	"这么": {"pinyin": "zhè me", "english": "so, this (much)"},
	"远": {"pinyin": "yuǎn", "english": "far"},
	"来": {"pinyin": "lái", "english": "to come"},
	"找": {"pinyin": "zhǎo", "english": "to look for"},
	"很少": {"pinyin": "hěn shǎo", "english": "rarely, very few"},
	"有人": {"pinyin": "yǒu rén", "english": "someone; there is someone"},
	"特意": {"pinyin": "tè yì", "english": "specially, on purpose"},
	"村里": {"pinyin": "cūn lǐ", "english": "in the village"},
	"每座": {"pinyin": "měi zuò", "english": "every (large structure)"},
	"屋顶": {"pinyin": "wū dǐng", "english": "roof"},
	"角度": {"pinyin": "jiǎo dù", "english": "angle"},
	"不一样": {"pinyin": "bù yī yàng", "english": "different, not the same"},
	"爷爷": {"pinyin": "yé ye", "english": "grandfather"},
	"盖": {"pinyin": "gài, gě", "english": "to build, cover"},
	"一半": {"pinyin": "yī bàn", "english": "half"},
	"没有": {"pinyin": "méi yǒu", "english": "there isn't; don't have"},
	"一个": {"pinyin": "yī gè", "english": "one"},
	"对得上": {"pinyin": "duì de shàng", "english": "to match up"},
	"荒地": {"pinyin": "huāng dì", "english": "wasteland"},
	"大多时候": {"pinyin": "dà duō shí hou", "english": "most of the time"},
	"安静": {"pinyin": "ān jìng", "english": "quiet"},
	"早就": {"pinyin": "zǎo jiù", "english": "long ago, already"},
	"不介意": {"pinyin": "bú jiè yì", "english": "don't mind"},
	"走去": {"pinyin": "zǒu qù", "english": "to walk to"},
	"井边": {"pinyin": "jǐng biān", "english": "by the well"},
	"天气": {"pinyin": "tiān qì", "english": "weather"},
	"好": {"pinyin": "hǎo", "english": "good"},
	"时候": {"pinyin": "shí hou", "english": "time; when"},
	"南边": {"pinyin": "nán biān", "english": "south side"},
	"镇子": {"pinyin": "zhèn zi", "english": "town"},
	"做买卖": {"pinyin": "zuò mǎi mài", "english": "to do business, trade"},
	"路": {"pinyin": "lù", "english": "road"},
	"住过": {"pinyin": "zhù guo", "english": "have lived (in)"},
	"三个": {"pinyin": "sān gè", "english": "three"},
	"不同": {"pinyin": "bù tóng", "english": "different"},
	"屋子": {"pinyin": "wū zi", "english": "room, house"},
	"各有各的好": {"pinyin": "gè yǒu gè de hǎo", "english": "each has its own merits"},
	"这里": {"pinyin": "zhè lǐ", "english": "here"},
	"城门": {"pinyin": "chéng mén", "english": "city gate"},
	"传送门": {"pinyin": "chuán sòng mén", "english": "portal"},
	"把": {"pinyin": "bǎ", "english": "[object-marking particle]"},
	"吞": {"pinyin": "tūn", "english": "to swallow"},
	"别处": {"pinyin": "bié chù", "english": "elsewhere"},
	"去": {"pinyin": "qù", "english": "to go"},
	"只有": {"pinyin": "zhǐ yǒu", "english": "only"},
	"风": {"pinyin": "fēng", "english": "wind"},
	"一转": {"pinyin": "yī zhuǎn", "english": "as soon as it turns"},
	"屋檐": {"pinyin": "wū yán", "english": "eaves"},
	"呼啸起来": {"pinyin": "hū xiào qǐ lái", "english": "to start howling"},
	"花了": {"pinyin": "huā le", "english": "spent"},
	"好多": {"pinyin": "hǎo duō", "english": "so many, a lot"},
	"不觉得": {"pinyin": "bù jué de", "english": "don't feel"},
	"瘆人": {"pinyin": "shèn rén", "english": "creepy, eerie"},
	"母亲": {"pinyin": "mǔ qīn", "english": "mother"},
	"挂起": {"pinyin": "guà qǐ", "english": "to hang up"},
	"这一排": {"pinyin": "zhè yī pái", "english": "this row"},
	"第一批": {"pinyin": "dì yī pī", "english": "the first batch"},
	"只是": {"pinyin": "zhǐ shì", "english": "just, merely"},
	"换": {"pinyin": "huàn", "english": "to change, replace"},
	"纸": {"pinyin": "zhǐ", "english": "paper"},
	"渐渐": {"pinyin": "jiàn jiàn", "english": "gradually"},
	"习惯": {"pinyin": "xí guàn", "english": "to get used to"},
	"地平线": {"pinyin": "dì píng xiàn", "english": "horizon"},
	"有多远": {"pinyin": "yǒu duō yuǎn", "english": "how far"},
	"去了": {"pinyin": "qù le", "english": "went"},
	"热闹": {"pinyin": "rè nao", "english": "lively, bustling"},
	"反倒": {"pinyin": "fǎn dào", "english": "instead, on the contrary"},
	"不习惯": {"pinyin": "bù xí guàn", "english": "not used to"},
	"有些": {"pinyin": "yǒu xiē", "english": "some"},
	"晚上": {"pinyin": "wǎn shang", "english": "evening, night"},
	"家家户户": {"pinyin": "jiā jiā hù hù", "english": "every household"},
	"窗户": {"pinyin": "chuāng hu", "english": "window"},
	"亮着": {"pinyin": "liàng zhe", "english": "lit up"},
	"村子": {"pinyin": "cūn zi", "english": "village"},
	"好像": {"pinyin": "hǎo xiàng", "english": "seems like"},
	"一起": {"pinyin": "yī qǐ", "english": "together"},
	"醒着": {"pinyin": "xǐng zhe", "english": "awake"},
	"不再": {"pinyin": "bú zài", "english": "no longer"},
	"旅人": {"pinyin": "lǚ rén", "english": "traveler"},
	"哪里": {"pinyin": "nǎ lǐ", "english": "where"},
	"大多数": {"pinyin": "dà duō shù", "english": "most, the majority"},
	"答案": {"pinyin": "dá àn", "english": "answer"},
	"说不通": {"pinyin": "shuō bù tōng", "english": "doesn't make sense"},
	"瓦": {"pinyin": "wǎ", "english": "roof tile"},
	"颜色": {"pinyin": "yán sè", "english": "color"},
	"很久以前": {"pinyin": "hěn jiǔ yǐ qián", "english": "long ago"},
	"别处运来的": {"pinyin": "bié chù yùn lái de", "english": "transported here from elsewhere"},
	"运来": {"pinyin": "yùn lái", "english": "transported here"},
	"现在": {"pinyin": "xiàn zài", "english": "now"},
	"这附近": {"pinyin": "zhè fù jìn", "english": "nearby here"},
	"烧得出": {"pinyin": "shāo de chū", "english": "can fire/produce (in a kiln)"},
	"喜欢": {"pinyin": "xǐ huan", "english": "to like"},
	"黄昏前": {"pinyin": "huáng hūn qián", "english": "before dusk"},
	"那段": {"pinyin": "nà duàn", "english": "that stretch of"},
	"时光": {"pinyin": "shí guāng", "english": "time, times"},
	"还没": {"pinyin": "hái méi", "english": "not yet"},
	"亮起": {"pinyin": "liàng qǐ", "english": "to light up"},
	"往西走": {"pinyin": "wǎng xī zǒu", "english": "to go west"},
	"尽头": {"pinyin": "jìn tóu", "english": "end"},
	"大概": {"pinyin": "dà gài", "english": "probably"},
	"住得最远": {"pinyin": "zhù de zuì yuǎn", "english": "live the farthest"},
	"人家": {"pinyin": "rén jiā", "english": "household, family"},
	"数过": {"pinyin": "shǔ guo", "english": "have counted"},
	"路边": {"pinyin": "lù biān", "english": "roadside"},
	"灯笼柱": {"pinyin": "dēng lóng zhù", "english": "lantern post"},
	"很多次": {"pinyin": "hěn duō cì", "english": "many times"},
	"从来": {"pinyin": "cóng lái", "english": "never (with negation)"},
	"数不出": {"pinyin": "shǔ bù chū", "english": "can't count out"},
	"一样": {"pinyin": "yī yàng", "english": "same"},
	"数字": {"pinyin": "shù zì", "english": "number"},
	"今早": {"pinyin": "jīn zǎo", "english": "this morning"},
	"扎辫子": {"pinyin": "zā biàn zi", "english": "to braid one's hair"},
	"扎了": {"pinyin": "zā le", "english": "braided"},
	"好久": {"pinyin": "hǎo jiǔ", "english": "a long time"},
	"不过": {"pinyin": "bú guò", "english": "but, however"},
	"值得": {"pinyin": "zhí de", "english": "worth it"},
	"才不怕": {"pinyin": "cái bú pà", "english": "not afraid at all"},
	"呢": {"pinyin": "ne", "english": "[softening particle]"},
	"才不太怕": {"pinyin": "cái bú tài pà", "english": "not really that afraid"},
	"能": {"pinyin": "néng", "english": "can, to be able to"},
	"全都": {"pinyin": "quán dōu", "english": "all"},
	"数出来": {"pinyin": "shǔ chū lái", "english": "to count out, enumerate"},
	"信": {"pinyin": "xìn", "english": "to believe"},
	"但": {"pinyin": "dàn", "english": "but"},
	"真的": {"pinyin": "zhēn de", "english": "really"},
	"可以": {"pinyin": "kě yǐ", "english": "can, may"},
	"妈妈": {"pinyin": "mā ma", "english": "mom"},
	"不许": {"pinyin": "bù xǔ", "english": "not allowed to"},
	"一个人": {"pinyin": "yī gè rén", "english": "alone, by oneself"},
	"跑去": {"pinyin": "pǎo qù", "english": "to run to"},
	"那边": {"pinyin": "nà biān", "english": "over there"},
	"比赛": {"pinyin": "bǐ sài", "english": "to compete, race"},
	"吧": {"pinyin": "ba", "english": "[suggestion particle]"},
	"昨天": {"pinyin": "zuó tiān", "english": "yesterday"},
	"抓到": {"pinyin": "zhuā dào", "english": "caught"},
	"一只": {"pinyin": "yī zhī", "english": "one (animal)"},
	"蟋蟀": {"pinyin": "xī shuài", "english": "cricket"},
	"又": {"pinyin": "yòu", "english": "again"},
	"放走": {"pinyin": "fàng zǒu", "english": "to let go, release"},
	"货郎": {"pinyin": "huò láng", "english": "peddler"},
	"给": {"pinyin": "gěi", "english": "to give; for"},
	"看过": {"pinyin": "kàn guo", "english": "have seen, shown"},
	"一根": {"pinyin": "yī gēn", "english": "one (long thin object)"},
	"手臂": {"pinyin": "shǒu bì", "english": "arm"},
	"大人": {"pinyin": "dà ren", "english": "adult"},
	"总说": {"pinyin": "zǒng shuō", "english": "always say"},
	"响": {"pinyin": "xiǎng", "english": "to make a sound"},
	"风声": {"pinyin": "fēng shēng", "english": "sound of wind"},
	"长大以后": {"pinyin": "zhǎng dà yǐ hòu", "english": "after growing up"},
	"文昭": {"pinyin": "Wén Zhāo", "english": "Wen Zhao (name)"},
	"家": {"pinyin": "jiā", "english": "home, family"},
	"想": {"pinyin": "xiǎng", "english": "to want, think"},
	"石头": {"pinyin": "shí tou", "english": "rock, stone"},
	"收藏": {"pinyin": "shōu cáng", "english": "collection"},
	"吗": {"pinyin": "ma", "english": "[question particle]"},
	"不错": {"pinyin": "bú cuò", "english": "pretty good, not bad"},
	"陛下": {"pinyin": "bì xià", "english": "Your Majesty"},
	"火": {"pinyin": "huǒ", "english": "fire"},
	"旺": {"pinyin": "wàng", "english": "roaring, vigorous (of fire)"},
	"它们": {"pinyin": "tā men", "english": "they (things)"},
	"不会": {"pinyin": "bú huì", "english": "won't"},
	"跳": {"pinyin": "tiào", "english": "to jump"},
	"门": {"pinyin": "mén", "english": "door"},
	"一关": {"pinyin": "yī guān", "english": "once closed"},
	"外面": {"pinyin": "wài miàn", "english": "outside"},
	"人": {"pinyin": "rén", "english": "person"},
	"听不见": {"pinyin": "tīng bu jiàn", "english": "can't hear"},
	"里面": {"pinyin": "lǐ miàn", "english": "inside"},
	"发生": {"pinyin": "fā shēng", "english": "to happen"},
	"讲究": {"pinyin": "jiǎng jiu", "english": "to value, pay attention to"},
	"耐心": {"pinyin": "nài xīn", "english": "patience"},
	"火候": {"pinyin": "huǒ hou", "english": "cooking heat/timing"},
	"未到": {"pinyin": "wèi dào", "english": "not yet arrived"},
	"不能": {"pinyin": "bù néng", "english": "cannot"},
	"急着": {"pinyin": "jí zhe", "english": "in a hurry to"},
	"下锅": {"pinyin": "xià guō", "english": "to put into the pot"},
	"近来": {"pinyin": "jìn lái", "english": "recently"},
	"胃口": {"pinyin": "wèi kǒu", "english": "appetite"},
	"挑剔": {"pinyin": "tiāo ti", "english": "picky"},
	"帮": {"pinyin": "bāng", "english": "to help"},
	"找到": {"pinyin": "zhǎo dào", "english": "to find"},
	"配得上": {"pinyin": "pèi de shàng", "english": "worthy of, a match for"},
	"皇室": {"pinyin": "huáng shì", "english": "royal family"},
	"滋味": {"pinyin": "zī wèi", "english": "flavor, taste"},
	"案台": {"pinyin": "àn tái", "english": "kitchen counter"},
	"日日": {"pinyin": "rì rì", "english": "every day"},
	"擦洗": {"pinyin": "cā xǐ", "english": "to scrub, clean"},
	"真正": {"pinyin": "zhēn zhèng", "english": "truly, genuinely"},
	"珍贵": {"pinyin": "zhēn guì", "english": "precious"},
	"食材": {"pinyin": "shí cái", "english": "ingredients"},
	"送来": {"pinyin": "sòng lái", "english": "delivered"},
	"派上用场": {"pinyin": "pài shàng yòng chǎng", "english": "put to use, come in handy"},
	"不是": {"pinyin": "bú shì", "english": "is not"},
	"献给": {"pinyin": "xiàn gěi", "english": "offered to"},
	"魔王": {"pinyin": "mó wáng", "english": "Demon King"},
	"力量": {"pinyin": "lì liàng", "english": "power"},
	"而": {"pinyin": "ér", "english": "and yet"},
	"来得正好": {"pinyin": "lái de zhèng hǎo", "english": "arrived at just the right time"},
	"揭穿": {"pinyin": "jiē chuān", "english": "to expose, unmask"},
	"听信": {"pinyin": "tīng xìn", "english": "to believe (what someone says)"},
	"话": {"pinyin": "huà", "english": "words"},
	"年年": {"pinyin": "nián nián", "english": "every year"},
	"加重": {"pinyin": "jiā zhòng", "english": "to increase, intensify"},
	"征收": {"pinyin": "zhēng shōu", "english": "to levy, collect (taxes)"},
	"一小块": {"pinyin": "yī xiǎo kuài", "english": "one small plot/piece"},
	"也": {"pinyin": "yě", "english": "also"},
	"保不住": {"pinyin": "bǎo bú zhù", "english": "can't keep, can't protect"},
	"终于": {"pinyin": "zhōng yú", "english": "finally"},
	"清醒": {"pinyin": "qīng xǐng", "english": "clear-headed, awake"},
	"若": {"pinyin": "ruò", "english": "if"},
	"信得过": {"pinyin": "xìn de guò", "english": "trustworthy"},
	"替": {"pinyin": "tì", "english": "on behalf of, for"},
	"照看": {"pinyin": "zhào kàn", "english": "to look after"},
	"田地": {"pinyin": "tián dì", "english": "farmland, fields"},
	"寸步不离": {"pinyin": "cùn bù bù lí", "english": "never leaves (someone's) side"},
	"从前": {"pinyin": "cóng qián", "english": "before, formerly"},
	"并不是": {"pinyin": "bìng bú shì", "english": "is not (emphatic)"},
	"这个样子": {"pinyin": "zhè ge yàng zi", "english": "like this"},
	"请": {"pinyin": "qǐng", "english": "please"},
	"田伯": {"pinyin": "Tián Bó", "english": "Old Tian (name)"},
	"代为": {"pinyin": "dài wéi", "english": "on behalf of"},
	"治理": {"pinyin": "zhì lǐ", "english": "to govern, manage"},
}

## See this file's own class doc comment for the exact token contract.
const LINES := {
	"都是竹林后面新鲜采的,信不信由你。": [
		"都", "是", "竹林", "后面", "新鲜", "采", "的", ",", "信不信", "由你", "。"
	],
	"这豆子可不是开玩笑的。种下去看看就知道了,别问我是怎么回事。": [
		"这", "豆子", "可不是", "开玩笑", "的", "。",
		"种", "下去", "看看", "就", "知道", "了", ",", "别", "问", "我", "是", "怎么回事", "。"
	],
	"灯笼、包子,路上缺什么尽管问我。": [
		"灯笼", "、", "包子", ",", "路上", "缺", "什么", "尽管", "问", "我", "。"
	],
	"皇帝每年都从我的地里多要一些。再这样下去,我就没地方种豆子了。": [
		"皇帝", "每年", "都", "从", "我", "的", "地里", "多", "要", "一些", "。",
		"再", "这样", "下去", ",", "我", "就", "没", "地方", "种", "豆子", "了", "。"
	],
	"潘迪跟着我很多年了。它比我还懂得躲懒。": [
		"潘迪", "跟着", "我", "很多", "年", "了", "。",
		"它", "比", "我", "还", "懂得", "躲懒", "。"
	],
	"地还给我了。这些年头一回,我不用看皇帝的脸色。": [
		"地", "还给", "我", "了", "。",
		"这些", "年头", "一回", ",", "我", "不用", "看", "皇帝", "的", "脸色", "。"
	],
	"潘迪已经认你了。它跟谁都不亲,除了我们俩。": [
		"潘迪", "已经", "认", "你", "了", "。",
		"它", "跟", "谁", "都", "不", "亲", ",", "除了", "我们", "俩", "。"
	],
	"整个山谷,连脚下的浮岛,都是朕的疆土。": [
		"整个", "山谷", ",", "连", "脚下", "的", "浮岛", ",", "都", "是", "朕", "的", "疆土", "。"
	],
	"御厨最懂治国。他说严厉一点，百姓才会听话。": [
		"御厨", "最", "懂", "治国", "。",
		"他", "说", "严厉", "一点", "，", "百姓", "才", "会", "听话", "。"
	],
	"朕像做了一场很长的噩梦。如今这座村庄由你作主。": [
		"朕", "像", "做", "了", "一场", "很", "长", "的", "噩梦", "。",
		"如今", "这座", "村庄", "由你", "作主", "。"
	],
	"原来御厨一直在蒙蔽朕。你救了朕和百姓——从今日起，这座村庄由你作主。": [
		"原来", "御厨", "一直", "在", "蒙蔽", "朕", "。",
		"你", "救", "了", "朕", "和", "百姓", "——", "从今日起", "，", "这座", "村庄", "由你", "作主", "。"
	],
	"农人的小事不值得朕费心。朕只等御厨献上最完美的肉包。": [
		"农人", "的", "小事", "不值得", "朕", "费心", "。",
		"朕", "只", "等", "御厨", "献上", "最", "完美", "的", "肉包", "。"
	],
	"你说什么农田？朕正在寻找天下最完美的肉包……等等，这些圆滚滚的正是！送去御膳房！": [
		"你", "说", "什么", "农田", "？",
		"朕", "正在", "寻找", "天下", "最", "完美", "的", "肉包", "……",
		"等等", "，", "这些", "圆滚滚", "的", "正是", "！",
		"送去", "御膳房", "！"
	],
	"灯笼总是亮到半夜。没人记得这规矩是谁定下的。": [
		"灯笼", "总是", "亮", "到", "半夜", "。",
		"没人", "记得", "这", "规矩", "是", "谁", "定下", "的", "。"
	],
	"你走了这么远来找我们。很少有人是特意来的。": [
		"你", "走", "了", "这么", "远", "来", "找", "我们", "。",
		"很少", "有人", "是", "特意", "来", "的", "。"
	],
	"村里每座屋顶的角度都不一样。我爷爷盖了一半,没有一个对得上。": [
		"村里", "每座", "屋顶", "的", "角度", "都", "不一样", "。",
		"我", "爷爷", "盖", "了", "一半", ",", "没有", "一个", "对得上", "。"
	],
	"荒地大多时候很安静。我早就不介意走去井边了。": [
		"荒地", "大多时候", "很", "安静", "。",
		"我", "早就", "不介意", "走去", "井边", "了", "。"
	],
	"天气好的时候,我们会和南边的镇子做买卖。路很远。": [
		"天气", "好", "的", "时候", ",", "我们", "会", "和", "南边", "的", "镇子", "做买卖", "。",
		"路", "很", "远", "。"
	],
	"我在村里住过三个不同的屋子,各有各的好。": [
		"我", "在", "村里", "住过", "三个", "不同", "的", "屋子", ",", "各有各的好", "。"
	],
	"这里没有城门,没有传送门,没有什么会把你吞到别处去。只有我们。": [
		"这里", "没有", "城门", ",", "没有", "传送门", ",",
		"没有", "什么", "会", "把", "你", "吞", "到", "别处", "去", "。",
		"只有", "我们", "。"
	],
	"风一转,屋檐就呼啸起来。我花了好多年才不觉得瘆人。": [
		"风", "一转", ",", "屋檐", "就", "呼啸起来", "。",
		"我", "花了", "好多", "年", "才", "不觉得", "瘆人", "。"
	],
	"我母亲挂起了这一排的第一批灯笼。我只是一直在换纸。": [
		"我", "母亲", "挂起", "了", "这一排", "的", "第一批", "灯笼", "。",
		"我", "只是", "一直", "在", "换", "纸", "。"
	],
	"你会渐渐习惯这里地平线有多远。去了热闹的地方,反倒不习惯了。": [
		"你", "会", "渐渐", "习惯", "这里", "地平线", "有多远", "。",
		"去了", "热闹", "的", "地方", ",", "反倒", "不习惯", "了", "。"
	],
	"有些晚上家家户户的窗户都亮着。整个村子好像一起醒着。": [
		"有些", "晚上", "家家户户", "的", "窗户", "都", "亮着", "。",
		"整个", "村子", "好像", "一起", "醒着", "。"
	],
	"我不再问旅人从哪里来了。大多数答案早就说不通了。": [
		"我", "不再", "问", "旅人", "从", "哪里", "来", "了", "。",
		"大多数", "答案", "早就", "说不通", "了", "。"
	],
	"这瓦的颜色是很久以前从别处运来的。现在这附近没人烧得出这颜色了。": [
		"这", "瓦", "的", "颜色", "是", "很久以前", "从", "别处", "运来", "的", "。",
		"现在", "这附近", "没人", "烧得出", "这", "颜色", "了", "。"
	],
	"我最喜欢黄昏前那段安静时光,灯笼还没亮起的时候。": [
		"我", "最", "喜欢", "黄昏前", "那段", "安静", "时光", ",",
		"灯笼", "还没", "亮起", "的", "时候", "。"
	],
	"再往西走,荒地就没有尽头了。我们大概是住得最远的人家了。": [
		"再", "往西走", ",", "荒地", "就", "没有", "尽头", "了", "。",
		"我们", "大概", "是", "住得最远", "的", "人家", "了", "。"
	],
	"我数过路边的灯笼柱很多次,从来数不出一样的数字。": [
		"我", "数过", "路边", "的", "灯笼柱", "很多次", ",",
		"从来", "数不出", "一样", "的", "数字", "。"
	],
	"我今早扎辫子扎了好久,不过很值得。": [
		"我", "今早", "扎辫子", "扎了", "好久", ",", "不过", "很", "值得", "。"
	],
	"我才不怕竹林呢。才、才不太怕。": [
		"我", "才不怕", "竹林", "呢", "。",
		"才", "、", "才不太怕", "。"
	],
	"我能把灯笼全都数出来。没人信,但我真的可以。": [
		"我", "能", "把", "灯笼", "全都", "数出来", "。",
		"没人", "信", ",", "但", "我", "真的", "可以", "。"
	],
	"妈妈说不许一个人跑去竹林那边。": [
		"妈妈", "说", "不许", "一个人", "跑去", "竹林", "那边", "。"
	],
	"我们比赛跑去井边吧!": [
		"我们", "比赛", "跑去", "井边", "吧", "!"
	],
	"我昨天抓到一只蟋蟀,不过又把它放走了。": [
		"我", "昨天", "抓到", "一只", "蟋蟀", ",", "不过", "又", "把", "它", "放走", "了", "。"
	],
	"货郎给我看过他的一根豆子。比我的手臂还长。": [
		"货郎", "给", "我", "看过", "他", "的", "一根", "豆子", "。",
		"比", "我", "的", "手臂", "还", "长", "。"
	],
	"大人总说屋檐响只是风声。": [
		"大人", "总说", "屋檐", "响", "只是", "风声", "。"
	],
	"长大以后我要盖一个像文昭家一样的屋顶。": [
		"长大以后", "我", "要", "盖", "一个", "像", "文昭", "家", "一样", "的", "屋顶", "。"
	],
	"想看看我的石头收藏吗?真的很不错。": [
		"想", "看看", "我", "的", "石头", "收藏", "吗", "?", "真的", "很", "不错", "。"
	],
	"陛下说这些是肉包。等火再旺一些，它们就不会跳了。": [
		"陛下", "说", "这些", "是", "肉包", "。",
		"等", "火", "再", "旺", "一些", "，", "它们", "就", "不会", "跳", "了", "。"
	],
	"御膳房的门一关，外面的人就听不见里面发生什么。": [
		"御膳房", "的", "门", "一关", "，",
		"外面", "的", "人", "就", "听不见", "里面", "发生", "什么", "。"
	],
	"御膳房最讲究耐心。火候未到，什么都不能急着下锅。": [
		"御膳房", "最", "讲究", "耐心", "。",
		"火候", "未到", "，", "什么", "都", "不能", "急着", "下锅", "。"
	],
	"陛下近来胃口挑剔。我只是在帮他找到配得上皇室的滋味。": [
		"陛下", "近来", "胃口", "挑剔", "。",
		"我", "只是", "在", "帮", "他", "找到", "配得上", "皇室", "的", "滋味", "。"
	],
	"这些案台日日擦洗。等真正珍贵的食材送来，就派上用场了。": [
		"这些", "案台", "日日", "擦洗", "。",
		"等", "真正", "珍贵", "的", "食材", "送来", "，", "就", "派上用场", "了", "。"
	],
	"这些不是肉包。它们是献给魔王的力量——而你来得正好。": [
		"这些", "不是", "肉包", "。",
		"它们", "是", "献给", "魔王", "的", "力量", "——", "而", "你", "来得正好", "。"
	],
	"揭穿他。": [
		"揭穿", "他", "。"
	],
	"皇帝听信御厨的话，年年加重征收。再这样下去，我连一小块种豆子的地也保不住。": [
		"皇帝", "听信", "御厨", "的", "话", "，", "年年", "加重", "征收", "。",
		"再", "这样", "下去", "，", "我", "连", "一小块", "种", "豆子", "的", "地", "也", "保不住", "。"
	],
	"陛下终于清醒了。你若信得过我，我会替你照看村庄和这里的田地。": [
		"陛下", "终于", "清醒", "了", "。",
		"你", "若", "信得过", "我", "，", "我", "会", "替", "你", "照看", "村庄", "和", "这里", "的", "田地", "。"
	],
	"御厨近来寸步不离陛下。皇帝从前并不是这个样子。": [
		"御厨", "近来", "寸步不离", "陛下", "。",
		"皇帝", "从前", "并不是", "这个样子", "。"
	],
	"请田伯代为治理村庄。": [
		"请", "田伯", "代为", "治理", "村庄", "。"
	],
}


## True if `text` contains any CJK Unified Ideograph -- the one signal
## DialogUI.show_line() needs to decide whether a line came from a Chinese
## speaker at all, without every call site needing its own flag.
static func is_chinese(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if code >= 0x4E00 and code <= 0x9FFF:
			return true
	return false


## The segmented token list for `line`, or a single-token fallback (the
## whole line, non-selectable) if it isn't in LINES yet -- so a Chinese line
## that hasn't been added here still displays correctly, just without word
## lookup, rather than breaking.
static func segments_for(line: String) -> Array:
	if LINES.has(line):
		return LINES[line]
	return [line]


static func word_info(word: String) -> Dictionary:
	return WORDS.get(word, {})
