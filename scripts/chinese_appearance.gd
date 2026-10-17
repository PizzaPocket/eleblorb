extends RefCounted

## Fixed named looks derived from the approved census and dress charter.
const LOOKS := {
	"梁臻": {"shirt": Color("575e68"), "pants": Color("575e68"), "trim": Color("292d34"), "vest": Color("252932"), "scale": 1.08, "chest": 1.08, "hip": 1.0, "headwear": "wrap", "sleeve": "long", "gown": true, "tail": 0.18},
	"Mei Lian": {"shirt": Color("6e7378"), "pants": Color("242c36"), "trim": Color("9b352d"), "scale": 0.92, "chest": 0.94, "hip": 1.1, "headwear": "pin", "sleeve": "long", "vest": Color("25282d"), "grey": true, "tail": 0.16, "side_close": true},
	"Wen Zhao": {"shirt": Color("785844"), "pants": Color("202b38"), "trim": Color("c1b79a"), "scale": 1.06, "chest": 1.13, "hip": 1.0, "headwear": "back_hat", "sleeve": "short", "cropped": true},
	"Bo Xiang": {"shirt": Color("c5b997"), "pants": Color("1d252d"), "trim": Color("40685c"), "scale": 1.1, "chest": 1.17, "hip": 1.04, "headwear": "straw", "sleeve": "none"},
	"Hua Chen": {"shirt": Color("dcdccf"), "pants": Color("22364a"), "trim": Color("263e57"), "scale": 0.96, "chest": 0.94, "hip": 1.09, "headwear": "kerchief", "sleeve": "short", "apron": Color("d0cbb4"), "side_close": true},
	"Jin Wei": {"shirt": Color("708b9c"), "pants": Color("273b51"), "trim": Color("497e70"), "scale": 0.98, "chest": 0.96, "hip": 1.12, "headwear": "pin", "sleeve": "short", "side_close": true},
	"Lian Fu": {"shirt": Color("273c58"), "pants": Color("222830"), "trim": Color("8f4639"), "scale": 1.03, "chest": 1.06, "hip": 0.98, "headwear": "wrap", "sleeve": "long"},
	"Yun Tao": {"shirt": Color("bcb89f"), "pants": Color("233044"), "trim": Color("527565"), "scale": 1.01, "chest": 1.09, "hip": 1.02, "headwear": "wrap", "sleeve": "short"},
	"Shu Mei": {"shirt": Color("85878a"), "pants": Color("2c3540"), "trim": Color("c3bdab"), "scale": 0.9, "chest": 0.93, "hip": 1.08, "headwear": "pin", "sleeve": "long", "vest": Color("262a30"), "grey": true, "tail": 0.22, "side_close": true},
	"姥姥": {"shirt": Color("4b606e"), "pants": Color("343044"), "trim": Color("a94438"), "scale": 0.94, "chest": 0.96, "hip": 1.12, "headwear": "pin", "sleeve": "long", "grey": true, "side_close": true, "tail": 0.19},
	"姥爷": {"shirt": Color("304e69"), "pants": Color("252b31"), "trim": Color("7a4437"), "scale": 1.02, "chest": 1.1, "hip": 1.03, "headwear": "wrap", "sleeve": "short", "apron": Color("dedbca"), "cloth": true, "grey": true},
	"陆浩": {"shirt": Color("7894a5"), "pants": Color("29384a"), "trim": Color("9f3b33"), "scale": 1.07, "chest": 1.04, "hip": 0.98, "headwear": "wrap", "sleeve": "short", "cloth": true},
	"Chen": {"shirt": Color("7d6451"), "pants": Color("293343"), "trim": Color("354c5a"), "scale": 1.04, "chest": 1.06, "hip": 1.0, "headwear": "wrap", "sleeve": "long", "pack": true, "tail": 0.23},
	"田伯": {"shirt": Color("62745a"), "pants": Color("4b4338"), "trim": Color("735542"), "scale": 1.0, "chest": 1.08, "hip": 1.03, "headwear": "straw", "sleeve": "short", "bald": true},
	"Ting Ting": {"shirt": Color("829fb0"), "pants": Color("354c63"), "trim": Color("b55146"), "scale": 0.79, "chest": 1.12, "hip": 1.12, "headwear": "ribbons", "sleeve": "long", "child": true, "pigtails": true, "side_close": true},
	"Xiu Xiu": {"shirt": Color("a84d43"), "pants": Color("293d54"), "trim": Color("c0ba9c"), "scale": 0.76, "chest": 1.12, "hip": 1.12, "headwear": "ribbons", "sleeve": "long", "child": true, "pigtails": true, "side_close": true},
	"Pei Pei": {"shirt": Color("5d887c"), "pants": Color("3a3e4e"), "trim": Color("bcb4a0"), "scale": 0.81, "chest": 1.12, "hip": 1.12, "headwear": "ribbons", "sleeve": "short", "child": true, "pigtails": true, "side_close": true},
	"Rong Rong": {"shirt": Color("8a6a50"), "pants": Color("25354b"), "trim": Color("759085"), "scale": 0.82, "chest": 1.12, "hip": 1.12, "headwear": "wrap", "sleeve": "short", "child": true},
	"Bao Bao": {"shirt": Color("3b5775"), "pants": Color("32353b"), "trim": Color("5f7c69"), "scale": 0.78, "chest": 1.12, "hip": 1.12, "headwear": "wrap", "sleeve": "long", "child": true},
	"御厨": {"shirt": Color("e1decc"), "pants": Color("292b32"), "trim": Color("94352d"), "scale": 1.08, "chest": 1.12, "hip": 1.04, "headwear": "", "sleeve": "short", "apron": Color("c8bfa8"), "chef": true},
	"皇帝": {"shirt": Color("a82c2d"), "pants": Color("a82c2d"), "trim": Color("b58f50"), "scale": 1.08, "chest": 1.08, "hip": 1.0, "headwear": "", "sleeve": "long", "emperor": true, "side_close": true},
}

static func apply(npc: Node, identity: String) -> void:
	assert(LOOKS.has(identity),"Missing China appearance: "+identity)
	var p: Dictionary=LOOKS[identity].duplicate(true)
	npc.shirt_color=p.shirt
	npc.pants_color=p.pants
	npc.shoe_color=Color(0.065,0.075,0.085)
	npc.body_scale=p.scale
	npc.chest_build_scale=p.chest
	npc.hip_build_scale=p.hip
	npc.abdomen_width_scale=1.0 if npc.is_female else 1.12
	if p.get("child",false): npc.abdomen_width_scale=1.32
	npc.hair_style=FigureHair.STYLE_BALD if p.get("bald",false) else (FigureHair.STYLE_PIGTAILS if p.get("pigtails",false) else FigureHair.STYLE_BUN)
	npc.hair_color=Color(0.49,0.50,0.47) if p.get("grey",false) else Color(0.045,0.035,0.032)
	npc.sleeve_style=p.sleeve
	npc.cropped_trousers=p.get("cropped",false)
	npc.wears_emperor_regalia=p.get("emperor",false)
	npc.wears_dress=p.get("emperor",false) or p.get("gown",false)
	npc.dress_has_covered_legs=npc.wears_dress
	npc.dress_color=p.shirt
	if p.get("gown",false):
		npc.beard_style="full"
		npc.beard_color=npc.hair_color
	npc.cultural_outfit=p
	npc.set_meta("chinese_appearance",identity)
	if p.get("chef",false):
		npc.beard_style="full"
		npc.beard_scale=0.75
	if p.get("emperor",false):
		npc.wears_emperor_regalia=true
		npc.wears_full_boots=true
		npc.wears_dress=true
		npc.dress_has_covered_legs=true
		npc.dress_color=p.shirt
