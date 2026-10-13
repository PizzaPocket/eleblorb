"""Authoring tool for Moy's plan (docs/architecture/city.md, section 7 and the
building schedule). It holds the named streets, squares, precincts and
numbered buildings, fills every street block with lots from its street edges
inward, checks the result, and writes scripts/city_plan.gd, the one plan the
city builder and tools/validate_city_plan.tscn read.

    python3 tools/city_layout.py [--json out.json]

--json also writes the plan as JSON, for drawings of the plan.

Edit the streets and buildings here, never in city_plan.gd. World metres:
+X east, -Z north; Moy's centre is (-560, 0) and the Rim Walk's radius 200 m.
"""
import json, math, os, sys
CX=-560; R=197
def inside(x,z):
    # the whole 1 m cell, not just its centre, lies within the built radius
    return max(math.hypot(x+dx-CX,z+dz) for dx in (0,1) for dz in (0,1))<=R
# ---- named streets: (name, kind, x0,z0,x1,z1). kind: main 12, avenue 10, shop 8, lane 4
STREETS=[
 ('Park Ring','main',-637,-62,-483,-50),
 ('Park Ring','main',-637,50,-483,62),
 ('Park Ring','main',-637,-50,-625,50),
 ('Park Ring','main',-495,-50,-483,50),
 ('Meridian Avenue','main',-391,-6,-340,6),
 ('Meridian North','avenue',-483,-38,-340,-30),
 ('Meridian South','avenue',-483,30,-340,38),
 ('Clock Street','lane',-397,-30,-391,30),
 ('West Street','main',-780,-6,-694,6),
 ('North Street','main',-566,-220,-554,-62),
 ('South Street','main',-566,62,-554,220),
 ('Arcade Street','shop',-694,-220,-686,220),
 ('Market Street','shop',-780,114,-487,122),
 ('Cinema Lane','lane',-734,-220,-730,220),
 ('Tank Lane','lane',-780,-122,-694,-118),
 ('Pine Lane','lane',-780,-62,-694,-58),
 ('Clinic Lane','lane',-780,58,-637,62),
 ('Library Lane','lane',-686,-96,-566,-92),
 ('Museum Lane','lane',-641,62,-637,114),
 ('Garden Walk','lane',-641,-92,-637,-30),
 ('Lamp Lane','lane',-694,170,-487,174),
 ('Estate Lane','lane',-487,-220,-483,-62),
 ('Market Lane','lane',-487,62,-483,220),
 ('Hotel Lane','lane',-483,-102,-340,-98),
 ('Glass Lane','lane',-483,98,-340,102),
]
OPENS=[
 ('park',-625,-50,-495,50),
 ('Civic Plaza',-483,-30,-431,30),
 ('Library Square',-686,-30,-637,30),
 ('Market Square',-590,122,-530,164),
 ('Estate Square',-554,-118,-516,-84),
 ('Cinema Square',-752,6,-734,34),
]
B=[]
def b(n,name,r,kind,h,who=''): B.append(dict(n=n,name=name,r=r,kind=kind,h=h,who=who))
NB=lambda: 'homes (no one the hero meets)'
b(1,'Grand Hotel',(-483,-98,-431,-38),'civic','podium 4 storeys, guest tower 25 floors (97 m)','Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work')
b(2,'City hall',(-431,-30,-397,30),'civic','exterior only: portico, balcony, side wings and a 45 m clock tower on Clock Street, at the head of Civic Plaza (section 8a)','Mayor Teodora Vance, Kenji Mori (clerk)')
b(3,'Library',(-686,-92,-641,-30),'civic','art deco limestone, renovated; the galleried Great Hall, 22 m, with a heritage room below (section 9)','Ada Fong, Nia Calder, Benji Okoro')
b(4,'Natural history museum',(-637,62,-575,100),'civic','3 storeys, top-lit hall','Dr. Imani Osei (curator)')
b(5,'Moonlight Cinema',(-730,6,-700,34),'civic','2 storeys, built later into the old town; flat above','Leon Duarte (lives above)')
b(6,'Police box',(-652,30,-646,38),'civic','1 storey, back room','Kate Byrne')
b(7,'Clinic',(-712,62,-698,80),'civic','3 storeys; flat above','Dr. Arjun Mehta (lives above)')
b(8,'Primary school',(-664,122,-641,152),'civic','3 storeys, roof playground','Yuki Hayashi (teacher); Lily, Kofi')
b(9,'Tea house',(-618,24,-604,36),'civic','1 storey; flat above and keeper\'s room behind','Old Fu (keeper); Kenji Mori (above)')
b(10,'Park lodge',(-508,30,-498,38),'civic','1 storey','Orin Pike (park keeper)')
b(11,'Giant playground',None,'play','climbing towers 12–20 m','Lily, Kofi')
b(12,'Windspire',(-431,-80,-389,-38),'tower','about 70 storeys, 280 m, on a podium','the Windworks (headquarters, observation deck)')
b(13,'Glass tower',(-483,38,-443,78),'tower','about 45 storeys, 180 m, on a podium','Raman & Reese (Elizabeth, Priya, Venn); Tanglewire (Dan)')
b(14,'North tower',(-483,-142,-443,-102),'tower','about 45 storeys, 175 m, on a podium','start-up floors (Theo Park)')
b(15,'South tower',(-483,102,-443,142),'tower','about 40 storeys, 150 m, on a podium','flats over offices; Dr. Vera Kask')
b(16,'BLOCK',(-431,38,-393,80),'civic','6 storeys, research labs round a court','Dr. Vera Kask (director)')
b(17,'Block 1',(-674,-143,-660,-109),'estate','slab block, 28 storeys, west side of the west court, turned 30° off the grid','Tomas Wren')
b(18,'Block 2',(-547,-184,-511,-166),'estate','slab block, 32 storeys, north side of the east court, turned 30° off the grid','Siti Rahman')
b(19,'Block 3',(-512,-94,-487,-62),'estate','broad point block, 36 storeys, on the Park Ring','Juno Rell (20th floor)')
b(20,'Block 4',(-643,-131,-621,-111),'estate','twin broad point block, 40 storeys, turned 30° off the grid; sky bridge and sky garden at the 26th floor',NB())
b(21,'Block 5',(-615,-147,-593,-127),'estate','twin broad point block, 40 storeys, turned 30° off the grid','Dr. Imani Osei and Kofi')
b(22,'Block 6',(-635,-78,-568,-62),'estate','slab block, 14 storeys, shops in its void deck on the Park Ring',NB())
b(23,'Hawker centre',(-554,-82,-516,-62),'civic','1 storey, open-sided, on the Park Ring and Estate Square','Siti\'s laksa stall')
b(24,'Garden Row',(-660,40,-637,58),'home','3 townhouses, 3 storeys, facing the Park Ring','Teodora Vance; Ada Fong and Sora Ishida; Priya Raman')
b(25,"Sol's café",(-750,34,-734,44),'shop','old tower house, 5 storeys; flat above','Sol Brant')
b(26,'Bakery',(-730,-22,-720,-6),'shop','old tower house, 6 storeys; flats above','Felix Tanaka (above)')
b(27,"Pinestein's building",(-716,-118,-707,-102),'shop','old tower house, 9 storeys; laboratory on the roof beside its wind tower','Palbert Pinestein (top floor)')
b(28,"Mara's building",(-716,-58,-707,-42),'shop','8 storeys; rooftop studio','Mara Quill')
b(29,"Benji's building",(-686,40,-678,56),'shop','6 storeys','Benji Okoro')
b(30,"Theo's building",(-730,74,-722,90),'shop','6 storeys','Theo Park')
b(31,"Yuki's building",(-686,62,-678,78),'shop','6 storeys','Yuki Hayashi')
b(32,"Suri's building",(-702,-112,-694,-96),'shop','7 storeys','Suri Vale')
b(33,'Wet market',(-530,122,-490,160),'civic','2 storeys; sign studio on the roof','Rosa Delgado, Wen Li; Zara Quinn (roof studio)')
b(34,'Market flats',(-637,146,-609,170),'shop','tong lau, 8 storeys','Mei and Lily Chan, Rosa, Wen, Pia Rowe')
b(35,'Wing Fat Mansion',(-637,122,-605,146),'shop','mansion block, 22 storeys on a podium','Ah Keung, Iris Dune, Nia Calder, Venn Harlow, Dax Merrow, Bea and Wilfred Ho')
b(36,'Vertical farm',(-686,122,-664,146),'civic','windowless, 12 storeys of growing racks','Sora Ishida')
b(37,'All-night store',(-554,62,-546,74),'shop','5 storeys; flat above','Hiro Sato')
b(38,'Helmsmith',(-600,174,-590,186),'shop','2 storeys; home behind','Gideon Hale')
b(39,'City works yard',(-540,174,-514,186),'civic','sheds and a flat','Kade Morrow')
b(52,'Reese–Miller house',(-704,-40,-694,-24),'home','old tower house, 7 storeys; wind tower and roof terrace','Elizabeth Reese, Dan Miller and Jammer (away at the farm)')
b(49,'Block 7',(-580,-176,-566,-102),'estate','slab block, 16 storeys, shops in its void deck on North Street',NB())
b(50,'Block 8',(-508,-150,-487,-106),'estate','slab block, 34 storeys, east side of the east court',NB())
b(53,'Block 9',(-658,-170,-612,-154),'estate','slab block, 24 storeys, north side of the west court, turned 30° off the grid',NB())
b(51,'Neighbourhood centre',(-554,-150,-516,-118),'civic','2 storeys: minimart, kindergarten, community club, roof garden','Juno Rell (Housing Board office)')
for n,name,r,kind,h,who in [
 (40,'Battery works',(-789,-8,-767,8),'works','2 storeys','Omar Haddad (flat)'),
 (41,'Recycling works',(-789,14,-771,26),'works','1 storey',''),
 (42,'Water works',(-700,-226,-680,-212),'works','pump house and keeper\'s house','Rafael Ortiz'),
 (43,'Water tower',(-722,-226,-712,-216),'works','35 m',''),
 (44,'Fish tanks',(-676,-206,-656,-190),'works','covered tanks','')]: b(n,name,r,kind,h,who)

# ---- raster
X0,X1,Z0,Z1=-800,-330,-215,215
street=set(); opn=set()
def cells(r):
    x0,z0,x1,z1=r
    for x in range(x0,x1):
        for z in range(z0,z1): yield (x,z)
for s in STREETS:
    for p in cells(s[2:]): street.add(p)
for o in OPENS:
    for p in cells(o[1:]): opn.add(p)
def free(p): return inside(*p) and p not in street and p not in opn
# components
seen=set(); comps=[]
for x in range(X0,X1):
    for z in range(Z0,Z1):
        p=(x,z)
        if p in seen or not free(p): continue
        st=[p]; seen.add(p); px=[]
        while st:
            a=st.pop(); px.append(a)
            for dx,dz in ((1,0),(-1,0),(0,1),(0,-1)):
                q=(a[0]+dx,a[1]+dz)
                if q not in seen and free(q): seen.add(q); st.append(q)
        comps.append(set(px))
# largest axis-aligned rectangle inside each component (histogram method)
def maxrect(comp):
    xs=[p[0] for p in comp]; zs=[p[1] for p in comp]
    x0,x1,z0,z1=min(xs),max(xs)+1,min(zs),max(zs)+1
    hgt=[0]*(x1-x0); best=(0,None)
    for z in range(z0,z1):
        for i,x in enumerate(range(x0,x1)):
            hgt[i]=hgt[i]+1 if (x,z) in comp else 0
        st=[]
        for i in range(len(hgt)+1):
            hh=hgt[i] if i<len(hgt) else 0
            start=i
            while st and st[-1][1]>=hh:
                si,sh=st.pop()
                area=sh*(i-si)
                if area>best[0]: best=(area,(x0+si,z-sh+1,x0+i,z+1))
                start=si
            st.append((start,hh))
    return best[1]
blocks=[]
for comp in comps:
    if len(comp)<60: continue
    zs=[p[1] for p in comp]; xs=[p[0] for p in comp]
    cx,cz=sum(xs)/len(xs),sum(zs)/len(zs)
    if cx>-487 and cz<-62 and cx<-483: typ='precinct'
    if cx>-487: typ='midrise'
    elif cz<-64 and cx>-690 and not (cx<-637 and cz>-96): typ='precinct'
    else: typ='fabric'
    r=maxrect(comp)
    if not r or r[2]-r[0]<6 or r[3]-r[1]<6: continue
    blocks.append(dict(r=r,type=typ,comp=comp))
def ov(a,c): return a[0]<c[2] and c[0]<a[2] and a[1]<c[3] and c[1]<a[3]
named=[x for x in B if x['r']]
# every named building must have a face on a street, square, park or (estate) its precinct garden
problems=[]
def faces(r):
    x0,z0,x1,z1=r; ring=[]
    for x in range(x0,x1): ring+= [(x,z0-1),(x,z1)]
    for z in range(z0,z1): ring+= [(x0-1,z),(x1,z)]
    return ring
for nb in named:
    r=nb['r']
    if math.hypot((r[0]+r[2])/2-CX,(r[1]+r[3])/2)>200: continue
    host=[bl for bl in blocks if (int((r[0]+r[2])/2),int((r[1]+r[3])/2)) in bl['comp']]
    if host and host[0]['type']=='precinct': continue
    if not any(p in street or p in opn for p in faces(r)): problems.append(('no frontage',nb['n']))
# lots: fill each whole block from its edges inward; trim each lot to the block's own ground
def trim(lot,comp):
    x0,z0,x1,z1=lot
    for _ in range(60):
        bad={'w':0,'e':0,'n':0,'s':0}; ok=True
        for x in range(x0,x1):
            if (x,z0) not in comp: bad['n']+=1; ok=False
            if (x,z1-1) not in comp: bad['s']+=1; ok=False
        for z in range(z0,z1):
            if (x0,z) not in comp: bad['w']+=1; ok=False
            if (x1-1,z) not in comp: bad['e']+=1; ok=False
        if ok: return (x0,z0,x1,z1)
        k=max(bad,key=bad.get)
        if k=='n': z0+=1
        elif k=='s': z1-=1
        elif k=='w': x0+=1
        else: x1-=1
        if x1-x0<3 or z1-z0<3: return None
    return None
FW=[8,6,10,7,9,6,8,10]; MW=[24,30,20,34,26,22]
FH=[6,8,5,9,7,4,6,8]; MH=[14,18,12,20,16,22,12]
lots=[]; courts=[]; k=0
for bl in blocks:
    if bl['type']=='precinct': continue
    comp=bl['comp']
    xs=[p[0] for p in comp]; zs=[p[1] for p in comp]
    x0,x1,z0,z1=min(xs),max(xs)+1,min(zs),max(zs)+1
    w=x1-x0; h=z1-z0
    D=15 if bl['type']=='fabric' else 20
    WID=FW if bl['type']=='fabric' else MW
    HT=FH if bl['type']=='fabric' else MH
    dz=min(D,h//2); dx=min(D,w//2)
    if 0<h-2*dz<7: dz=h//2
    if 0<w-2*dx<7: dx=w//2
    cand=[]
    def run(o,a0,b0,a1,b1):
        global k
        pos=a0 if o=='h' else b0; end=a1 if o=='h' else b1
        while pos<end:
            ww=WID[k%len(WID)]; ht=HT[k%len(HT)]; k+=1
            q=min(pos+ww,end)
            if end-q<5: q=end
            cand.append(((pos,b0,q,b1) if o=='h' else (a0,pos,a1,q),ht)); pos=q
    run('h',x0,z0,x1,z0+dz)
    if z1-dz>=z0+dz: run('h',x0,z1-dz,x1,z1)
    if h-2*dz>0:
        run('v',x0,z0+dz,x0+dx,z1-dz)
        if x1-dx>=x0+dx: run('v',x1-dx,z0+dz,x1,z1-dz)
    nr=[nb['r'] for nb in named]
    for lot,ht in cand:
        t=trim(lot,comp)
        if not t: continue
        # carve around named buildings
        hits=[r for r in nr if ov(r,t)]
        if hits:
            r=hits[0]
            pieces=[(t[0],t[1],r[0],t[3]),(r[2],t[1],t[2],t[3]),(max(t[0],r[0]),t[1],min(t[2],r[2]),r[1]),(max(t[0],r[0]),r[3],min(t[2],r[2]),t[3])]
            for pcs in pieces:
                if pcs[2]-pcs[0]>=3 and pcs[3]-pcs[1]>=3 and not any(ov(q,pcs) for q in nr): lots.append(pcs+(ht,bl['type']))
            continue
        lots.append(t+(ht,bl['type']))
    if h-2*dz>0 and w-2*dx>0:
        inner=trim((x0+dx,z0+dz,x1-dx,z1-dz),comp)
        if inner:
            touches_rim=any(not inside(*p) for x in range(inner[0]-1,inner[2]+1) for p in ((x,inner[1]-1),(x,inner[3])))
            if touches_rim: lots.append(inner+(HT[0],bl['type']))
            else: courts.append(inner)
# keep only real buildings with a street face: anything left behind becomes a garden yard
FRONT_REACH=6  # a face counts if a street, square or the Rim Walk lies within this, across open ground
def has_front(l,occupied):
    x0,z0,x1,z1=[int(v) for v in l[:4]]
    starts=[((x,z0-1),(0,-1)) for x in range(x0,x1)]+[((x,z1),(0,1)) for x in range(x0,x1)]+[((x0-1,z),(-1,0)) for z in range(z0,z1)]+[((x1,z),(1,0)) for z in range(z0,z1)]
    for (x,z),(dx,dz) in starts:
        for d in range(FRONT_REACH):
            p=(x+dx*d,z+dz*d)
            if p in street or p in opn or not inside(*p): return True
            if p in occupied: break
    return False
lots=[l for l in lots if min(l[2]-l[0],l[3]-l[1])>=3]
def occ(ls):
    o=set()
    for l in ls:
        for x in range(int(l[0]),int(l[2])):
            for z in range(int(l[1]),int(l[3])): o.add((x,z))
    for nb in named:
        for x in range(nb['r'][0],nb['r'][2]):
            for z in range(nb['r'][1],nb['r'][3]): o.add((x,z))
    return o
while True:
    o=occ(lots)
    bad=[l for l in lots if not has_front(l,o)]
    if not bad: break
    lots=[l for l in lots if l not in bad]
# lots must not overlap named buildings (trim leftovers)
lots=[l for l in lots if not any(ov(l[:4],nr) for nr in [nb['r'] for nb in named])]
# street connectivity check: each street end must meet street/open/outside
def end_ok(s):
    name,kind,x0,z0,x1,z1=s
    res=[]
    if x1-x0>=z1-z0:
        for x in (x0-1,x1):
            zs=range(z0,z1)
            res.append(all((not inside(x,z)) or (x,z) in street and not (x0<=x<x1) or (x,z) in opn for z in zs) or any((x,z) in opn or (not inside(x,z)) for z in zs) or all(((x,z) in street) for z in zs))
    else:
        for z in (z0-1,z1):
            xs=range(x0,x1)
            res.append(any((x,z) in opn or (not inside(x,z)) for x in xs) or all(((x,z) in street) for x in xs))
    return res
for s in STREETS:
    if s[0]=='Park Ring': continue
    r=end_ok(s)
    if not all(r): problems.append(('dead end?',s[0],r))
for bl in blocks: bl.pop('comp')

RESIDENT_HOMES={
 'Elizabeth Reese':52,'Dan Miller':52,'Lucinda Wah':1,'Felix Tanaka':26,'Ah Keung':35,'Iris Dune':35,
 'Teodora Vance':24,'Kenji Mori':9,'Ada Fong':24,'Nia Calder':35,'Benji Okoro':29,'Imani Osei':21,
 'Leon Duarte':5,'Mara Quill':28,'Pia Rowe':34,'Old Fu':9,'Sora Ishida':24,'Sol Brant':25,'Mei Chan':34,
 'Hiro Sato':37,'Rosa Delgado':34,'Wen Li':34,'Gideon Hale':38,'Zara Quinn':33,'Siti Rahman':18,
 'Tomas Wren':17,'Priya Raman':24,'Venn Harlow':35,'Theo Park':30,'Arjun Mehta':7,'Kate Byrne':6,
 'Yuki Hayashi':31,'Juno Rell':19,'Dax Merrow':35,'Kade Morrow':39,'Suri Vale':32,'Orin Pike':10,
 'Bea Ho':35,'Wilfred Ho':35,'Lily Chan':34,'Kofi Osei':21,'Palbert Pinestein':27,'Vera Kask':15,
 'Omar Haddad':40,'Rafael Ortiz':42,
}
## Heights (m, to the main roof) and crowns of the numbered buildings, and
## the plan forms of the towers (city.md 7c, 8): one source for the plan, the
## skyline and the elevations.
HEIGHTS={1:91,2:22,3:22,4:16,5:9,6:4,7:11,8:12,9:4,10:4,12:262,13:180,14:175,15:150,16:22,
 17:91,18:104,19:117,20:130,21:130,22:46,23:6,24:11,25:17,26:20,27:29,28:26,29:20,30:20,31:20,
 32:23,33:9,34:26,35:72,36:42,37:17,38:7,39:6,49:52,50:110,51:8,52:23,53:78,40:8,41:4,42:6,43:35,44:3}
CROWNS={1:104,2:45,3:26,12:280}
## Plan forms: twist (a rounded triangle turning as it rises), screen (round-
## cornered square in a screen), capsule (core with plug-in capsules), dune
## (rippling balconies), deco (podium with a set-back tower: TOWER_PART).
FORMS={12:'twist',13:'screen',14:'capsule',15:'dune',1:'deco',2:'clock'}
## Sub-footprints that rise above their building's podium: the hotel's guest
## tower and city hall's clock tower.
TOWER_PART={1:(-473,-96,-441,-74),2:(-405,-4,-397,4)}
PODIUM_HEIGHT={1:20}
## Fabric storeys are 3.25 m, downtown mid-rise storeys 3.6 m.
STOREY={'fabric':3.25,'midrise':3.6}
## The park and the giant playground (city.md 7a, 7b), world metres.
PARK={
 'rect':(-625,-50,-495,50),
 'walks':[(-625,-3,-495,3),(-563,-50,-557,50)],
 'dry_garden':(-620,-45,-568,-6),
 'pond':{'c':(-522,-26),'r':(22,15)},
 'lawn':(-552,8,-500,46),
 'parasols':[(-612,12),(-598,14),(-586,22),(-596,32),(-584,40),(-612,44)],
 'playground':{'c':(-560,0),'track':(24,28),
   'towers':[(-560,0,20,4.5,'Lookout'),(-548,-7,16,3.5,''),(-574,-4,14,3.2,''),(-560,14,12,3,'')],
   'perches':[(-566,18),(-554,18),(-560,21)],'perch_height':12,
   'hoops':[[-560+(9+i*1.6)*math.cos(-math.pi/2+i*0.75),(9+i*1.6)*math.sin(-math.pi/2+i*0.75)] for i in range(8)]},
 'wind_trees':[(-526,-26),(-594,-26),(-526,26),(-594,26)],'wind_tree_height':32,
}
## The North Estate's precincts (clipped by the Rim Walk): west of North Street,
## north of Library Lane plus the strip along the Park Ring; east of it.
PRECINCTS=[[(-686,-200,-566,-96),(-637,-92,-566,-62)],[(-554,-200,-487,-62)]]
## Turned footprints (city.md 7d). A building with an angle stands on its
## rect turned about the rect's centre by that many degrees, positive
## clockwise on the plan with north up (from +X toward +Z). The estate's
## blocks standing back from the streets share one turn, ESTATE_TURN; the
## blocks that hold a street edge keep the city grid.
ESTATE_TURN=-30
ANGLE={17:ESTATE_TURN,20:ESTATE_TURN,21:ESTATE_TURN,53:ESTATE_TURN,18:ESTATE_TURN}
def turn(cx,cz,a,pts):
    t=math.radians(a); c,s_=math.cos(t),math.sin(t)
    return [(round(cx+u*c-v*s_,1),round(cz+u*s_+v*c,1)) for u,v in pts]
def corners_of(b):
    x0,z0,x1,z1=b['r']; cx,cz=(x0+x1)/2,(z0+z1)/2; hw,hd=(x1-x0)/2,(z1-z0)/2
    return turn(cx,cz,ANGLE.get(b['n'],0),[(-hw,-hd),(hw,-hd),(hw,hd),(-hw,hd)])
## The west precinct's turned frame: the ring of Blocks 1, 4, 5 and 9 is laid
## out in local (u, v) metres about the west court's centre.
WEST_FRAME=(-628,-146)
def west(pts): return turn(WEST_FRAME[0],WEST_FRAME[1],ESTATE_TURN,pts)
def box(u0,v0,u1,v1): return [(u0,v0),(u1,v0),(u1,v1),(u0,v1)]
## The North Estate's courts and grounds (city.md 7d), for the drawings, as
## world polygons and polylines: courts, the twins' gate and sky bridge, the
## community garden, playgrounds, chess pavilions and covered linkways.
ESTATE={
 'courts':[west(box(-37,-9,27,10)),[(-552,-158),(-487,-158),(-487,-150),(-552,-150)],[(-509,-158),(-487,-170),(-487,-158)]],
 'gate':west(box(-5,10,5,30)),
 'sky_bridge':west(box(-5,19,5,21)),
 'garden':west(box(-18,-33,20,-27)),
 'playgrounds':west([(-22,0)])+[(-498,-163)],
 'pavilions':west([(12,0)])+[(-542,-154)],
 'linkways':[
  west([(-35,-7),(25,-7),(25,8),(-35,8),(-35,-7)]),
  west([(0,8),(0,30)])+[(-608,-96),(-608,-78)],
  west([(25,0)])+[(-566,west([(25,0)])[0][1])],
  [(-552,-154),(-489,-154)],
  [(-512,-154),(-512,-98),(-500,-98),(-500,-94)],
 ],
}
def _axes(P):
    for i in range(len(P)):
        a,b_=P[i],P[(i+1)%len(P)]; yield (-(b_[1]-a[1]),b_[0]-a[0])
def poly_gap(P,Q):
    best=-1e9
    for ax in list(_axes(P))+list(_axes(Q)):
        n=math.hypot(*ax); ax=(ax[0]/n,ax[1]/n)
        pa=[p[0]*ax[0]+p[1]*ax[1] for p in P]; qa=[q_[0]*ax[0]+q_[1]*ax[1] for q_ in Q]
        best=max(best,min(qa)-max(pa),min(pa)-max(qa))
    return best
def rpoly(r): return [(r[0],r[1]),(r[2],r[1]),(r[2],r[3]),(r[0],r[3])]
for nb in [x for x in B if x['n'] in ANGLE]:
    P=corners_of(nb)
    if any(math.hypot(x-CX,z)>R for x,z in P): problems.append(('turned block past the Rim Walk',nb['n']))
    for st in STREETS:
        if poly_gap(P,rpoly(st[2:]))<0: problems.append(('turned block on a street',nb['n'],st[0]))
    for o in OPENS:
        if poly_gap(P,rpoly(o[1:]))<0: problems.append(('turned block on a square',nb['n'],o[0]))
    for other in named:
        if other is nb: continue
        if poly_gap(P,corners_of(other))<8: problems.append(('turned block within 8 m of',nb['n'],other['n']))
TURBINES=[(-310,-200),(-310,200),(-740,-270),(-740,270)]
## Old Moy's tower houses (docs/architecture/moy_tower_house.md). Every Old
## Moy lot gets a kit: a tower house where the short side is 6 m or more
## (room for the 3.4 m ramp core inside 0.9 m earth walls), the later pencil infill
## where it is narrower. Variants come from a fixed hash of the lot.
FIRST_WELL=(-743,20)  # on Cinema Square (city.md 7)
def old_moy(x,z):
    if math.hypot(x-CX,z)>200 or x>-487: return False
    if z>=114 or (z>62 and x>-641): return False
    return x<-637
STREET_KIND={}
for st in STREETS:
    for p_ in cells(st[2:]): STREET_KIND.setdefault(p_,st[1])
def front_of(r):
    x0,z0,x1,z1=r; best=None
    rank={'main':0,'shop':1,'avenue':2,'lane':3,'open':4}
    for side,ring in (('n',[(x,z0-1) for x in range(x0,x1)]),('s',[(x,z1) for x in range(x0,x1)]),('w',[(x0-1,z) for z in range(z0,z1)]),('e',[(x1,z) for z in range(z0,z1)])):
        kinds=[STREET_KIND[c] if c in STREET_KIND else ('open' if c in opn else None) for c in ring]
        kinds=[k_ for k_ in kinds if k_]
        if kinds:
            k_=min(kinds,key=lambda t: rank[t]); cand=(rank[k_],-len(kinds),side,k_)
            if best is None or cand<best: best=cand
    return (best[2],best[3]) if best else (None,None)
def kit_for(r,storeys,named_n=None):
    x0,z0,x1,z1=r
    h=(abs(x0)*73856093 ^ abs(z0)*19349663 ^ abs(x1)*83492791) & 0xffff
    side,kind=front_of(r)
    tower=min(x1-x0,z1-z0)>=6 or named_n is not None
    k={'kit':'tower' if tower else 'infill','storeys':storeys,'front':side or 'n','shop':kind in ('main','shop')}
    if tower:
        # earth bases are the oldest houses, most of them round the first well
        # on Cinema Square; the rest stand on stone
        cx_,cz_=(x0+x1)/2,(z0+z1)/2
        earth=(h//144)%3==0 if math.hypot(cx_-FIRST_WELL[0],cz_-FIRST_WELL[1])<60 else (h//144)%9==0
        base=max(2,min(2+h%3,(2*storeys)//3)) if earth else 1+h%3 if storeys>=6 else 1+h%2
        k.update(base_kind='earth' if earth else 'stone',base=base,kishk=(h//3)%3 if storeys>=6 else 0,
                 manzar=(h//9)%4==0,parapet=(h//36)%3,frieze=(h//108)%4,polite=kind in ('main','shop','open'))
    return k
LOT_KITS=[kit_for(tuple(int(v) for v in l[:4]),l[4]) if old_moy((l[0]+l[2])/2,(l[1]+l[3])/2) else None for l in lots]
## the numbered tower houses (city.md schedule), and the Reese-Miller house
## as briefed (moy_tower_house.md 4)
BUILDING_KITS={}
for nb in B:
    if nb['n'] in (25,26,27,28,29,30,31,32,52):
        BUILDING_KITS[nb['n']]=kit_for(nb['r'],round(HEIGHTS[nb['n']]/3.25),nb['n'])
BUILDING_KITS[52].update(storeys=7,base_kind='earth',base=3,front='e',shop=True,kishk=1,manzar=True,polite=True)
BUILDING_KITS[27].update(polite=True); BUILDING_KITS[25].update(polite=True)
# the market flats: four tile houses built as one terrace, rounded at the
# corner of Market Street and Museum Lane (moy_market_lanes.md 4)
BUILDING_KITS[34]={'kit':'tong_lau','storeys':8,'front':'s','shop':True,'gen':'tile','veranda':False,
                   'corner':True,'colour':1,'signs':3,'roof':'laundry','core':'own','pair':-1,'lift':True,'units':4}
# two neighbours never share both parapet pattern and base height
def touching(a,b_): return a[0]<=b_[2] and b_[0]<=a[2] and a[1]<=b_[3] and b_[1]<=a[3]
for i,ki in enumerate(LOT_KITS):
    if not ki or ki['kit']!='tower': continue
    for j in range(i):
        kj=LOT_KITS[j]
        if kj and kj['kit']=='tower' and touching(lots[i],lots[j]) and (ki['parapet'],ki['base'],ki['frieze'])==(kj['parapet'],kj['base'],kj['frieze']):
            ki['parapet']=(ki['parapet']+1)%3
for i,ki in enumerate(LOT_KITS):
    if not ki or ki['kit']!='tower': continue
    if min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])<6: problems.append(('tower house on a narrow lot',i))
    lo,hi=(2,max(2,(2*ki['storeys'])//3)) if ki['base_kind']=='earth' else (1,3)
    if not lo<=ki['base']<=hi: problems.append(('base out of range',i))
## The market lanes' tong lau (docs/architecture/moy_market_lanes.md). Every
## market-lane lot gets a tenement shophouse: a boom house (4 or 5 storeys,
## a veranda on main streets and squares) or a tile house (6 to 9, rounded
## corner on corner lots). Narrow houses share a ramp core with the
## neighbour across their party wall, as tong lau pairs share a stair.
def market_lane(x,z):
    if math.hypot(x-CX,z)>200 or x>-487: return False
    return z>=114 or (z>62 and x>-641)
def street_sides(r):
    x0,z0,x1,z1=r; out={}
    for side,ring in (('n',[(x,z0-1) for x in range(x0,x1)]),('s',[(x,z1) for x in range(x0,x1)]),('w',[(x0-1,z) for z in range(z0,z1)]),('e',[(x1,z) for z in range(z0,z1)])):
        hits=[c for c in ring if c in STREET_KIND or c in opn]
        if len(hits)>=max(2,len(ring)//3): out[side]=True
    return out
PERP={'n':'ew','s':'ew','e':'ns','w':'ns'}
def market_kit_for(r,storeys):
    x0,z0,x1,z1=r
    h=(abs(x0)*2654435761 ^ abs(z0)*40503 ^ abs(z1)*97) & 0xffff
    side,kind=front_of(r)
    side=side or 'n'
    boom=storeys<=5
    sides=street_sides(r)
    corner=any(sd in sides for sd in PERP[side])
    k={'kit':'tong_lau','storeys':storeys,'front':side,'shop':True,'gen':'boom' if boom else 'tile',
       'veranda':boom and kind in ('main','open'),'corner':(not boom) and corner,
       'colour':h%5,'signs':(2+h%2) if kind in ('main','shop','open') else h%2,
       'roof':['tanks','laundry','greenhouse','garden'][(h//5)%4] if boom or (h//5)%4!=2 else 'tanks',
       'core':'own','pair':-1,'lift':storeys>=7}
    return k
for i,l in enumerate(lots):
    if market_lane((l[0]+l[2])/2,(l[1]+l[3])/2):
        LOT_KITS[i]=market_kit_for(tuple(int(v) for v in l[:4]),l[4])
# pairs share a ramp core on their party wall: narrow houses (under 9 m
# across) with the same front, touching along a wall at least 5 m long
def party_wall(a,b_,front):
    if front in 'ns':
        if a[2]==b_[0] or b_[2]==a[0]: return min(a[3],b_[3])-max(a[1],b_[1])
    else:
        if a[3]==b_[1] or b_[3]==a[1]: return min(a[2],b_[2])-max(a[0],b_[0])
    return 0
TL=[i for i,k_ in enumerate(LOT_KITS) if k_ and k_['kit']=='tong_lau']
narrow=lambda i: min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])<9
for i in sorted(TL,key=lambda i: min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])):
    ki=LOT_KITS[i]
    if ki['pair']>=0 or not narrow(i): continue
    best=None
    for j in TL:
        kj=LOT_KITS[j]
        if j==i or kj['pair']>=0 or kj['front']!=ki['front']: continue
        w_=party_wall(lots[i],lots[j],ki['front'])
        if w_>=5 and (best is None or w_>best[0]): best=(w_,j)
    if best:
        j=best[1]; ki['pair']=j; LOT_KITS[j]['pair']=i; ki['core']=LOT_KITS[j]['core']='shared'
# a sliver with no neighbour to share a core becomes a two-storey lock-up
# shop: a shop below and its store or a small flat above, reached by the
# shop's own ladder ramp (moy_market_lanes.md 3)
for i in TL:
    ki=LOT_KITS[i]
    if min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])<6 and ki['core']!='shared':
        LOT_KITS[i]={'kit':'lockup','storeys':2,'front':ki['front'],'shop':True,'colour':ki['colour'],'signs':ki['signs']}
        lots[i]=lots[i][:4]+(2,)+lots[i][5:]
TL=[i for i in TL if LOT_KITS[i]['kit']=='tong_lau']
# neighbours differ in colour
for i in TL:
    for j in TL:
        if j<i and touching(lots[i],lots[j]) and LOT_KITS[i]['colour']==LOT_KITS[j]['colour']:
            LOT_KITS[i]['colour']=(LOT_KITS[i]['colour']+1)%5
for i in TL:
    ki=LOT_KITS[i]
    if (ki['gen']=='boom')!=(ki['storeys']<=5): problems.append(('tong lau generation does not fit its storeys',i))
    if ki['veranda'] and ki['gen']!='boom': problems.append(('veranda on a tile house',i))
    if ki['pair']>=0 and LOT_KITS[ki['pair']]['pair']!=i: problems.append(('core pair not mutual',i))
    if min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])<6 and ki['core']!='shared': problems.append(('narrow tong lau without a shared core',i,lots[i]))
for i,ki in enumerate(LOT_KITS):
    if ki and ki['kit']=='lockup' and lots[i][4]!=2: problems.append(('lock-up shop not two storeys',i))
JUNGLE=(-500,464); ICE=(-450,-480)
assert len(RESIDENT_HOMES)==45, len(RESIDENT_HOMES)
nums={b['n'] for b in B}
for who,n in RESIDENT_HOMES.items():
    if n not in nums: problems.append(('home missing',who,n))
for t in TURBINES:
    if math.hypot(t[0]-JUNGLE[0],t[1]-JUNGLE[1])<280 or math.hypot(t[0]-ICE[0],t[1]-ICE[1])<280: problems.append(('turbine near plateau',t))
if problems:
    for p in problems: print('PROBLEM',p)
    sys.exit(1)

def v2r(r): return "Rect2(%g, %g, %g, %g)" % (r[0], r[1], r[2]-r[0], r[3]-r[1])
def q(t): return json.dumps(t, ensure_ascii=False)
out=[]
w=out.append
w("class_name CityPlan")
w("extends RefCounted")
w("")
w("## Moy's single plan (docs/architecture/city.md, section 7, the building")
w("## schedule and the street directory). GENERATED by tools/city_layout.py:")
w("## edit the streets and buildings there and run it, never here. The city")
w("## builder and tools/validate_city_plan.tscn read only this.")
w("##")
w("## World metres, +X east, -Z north (Rect2 x is world x, y is world z).")
w("## Every street meets another street, a square, the Park Ring or the Rim")
w("## Walk at both ends; every building in a street block has a face on a")
w("## street, square or the Rim Walk; the estate's blocks stand in precinct")
w("## gardens. The terrain's CITY_CENTER and CITY_FLAT_RADIUS still describe")
w("## the prototype city and move to these values when the city is rebuilt.")
w("")
w("const CENTER := Vector2(-560.0, 0.0)")
w("## The Rim Walk: the city's bounds. Buildings stay inside BUILT_RADIUS.")
w("const RIM_RADIUS := 200.0")
w("const BUILT_RADIUS := %.1f" % R)
w("const STREET_WIDTHS := {\"main\": 12.0, \"avenue\": 10.0, \"shop\": 8.0, \"lane\": 4.0}")
w("")
w("## Named streets. A street with two segments appears twice under one name.")
w("const STREETS := [")
for name,kind,x0,z0,x1,z1 in STREETS: w("\t{\"name\": %s, \"kind\": %s, \"rect\": %s}," % (q(name),q(kind),v2r((x0,z0,x1,z1))))
w("]")
w("")
w("## Squares and the park.")
w("const OPENS := [")
for name,x0,z0,x1,z1 in OPENS: w("\t{\"name\": %s, \"rect\": %s}," % (q(name),v2r((x0,z0,x1,z1))))
w("]")
w("")
w("## The North Estate's two precincts: blocks stand free in shared gardens.")
w("const PRECINCTS := [")
for pr in PRECINCTS: w("\t[%s]," % ", ".join(v2r(r) for r in pr))
w("]")
w("")
w("## The numbered buildings of the schedule. rect is the footprint; null for")
w("## the giant playground, which the park plan places (section 7b). angle")
w("## turns the footprint about the rect's centre, in degrees, positive")
w("## clockwise on the plan with north up (from +X toward +Z); in Godot that")
w("## is rotation.y = deg_to_rad(-angle). Use corners() for the true outline.")
w("const BUILDINGS := [")
for b in sorted(B,key=lambda b:b['n']):
    w("\t{\"n\": %d, \"name\": %s, \"kind\": %s, \"rect\": %s, \"angle\": %.1f, \"height\": %s, \"form\": %s, \"size\": %s, \"who\": %s}," % (b['n'],q(b['name']),q(b['kind']),v2r(b['r']) if b['r'] else "null",ANGLE.get(b['n'],0),"%.1f" % HEIGHTS[b['n']] if b['n'] in HEIGHTS else "0.0",q(FORMS.get(b['n'],'block')),q(b['h']),q(b['who'])))
w("]")
w("")
w("## Every ordinary building, one per lot: [rect, storeys, block type].")
w("## Fabric lots are street buildings (homes over shops); midrise lots are")
w("## downtown's office and flat blocks round the towers.")
w("const LOTS := [")
for l in lots: w("\t[%s, %d, %s]," % (v2r(l[:4]),l[4],q(l[5])))
w("]")
def kit_gd(k):
    if k is None: return "null"
    return "{" + ", ".join("%s: %s" % (q(a_), ("true" if v is True else "false" if v is False else q(v) if isinstance(v,str) else str(v))) for a_,v in k.items()) + "}"
w("")
w("## Kits, one per lot, in the same order as LOTS (null outside Old Moy and")
w("## the market lanes). Old Moy (moy_tower_house.md): kit (tower or infill),")
w("## storeys, front (n, s, e, w), shop, and for")
w("## tower houses base_kind (stone or earth), base (its storeys), kishk,")
w("## manzar, parapet (pattern 0 to 2), frieze (pattern 0 to 3), polite.")
w("## The market lanes (moy_market_lanes.md): kit tong_lau, gen (boom or")
w("## tile), veranda, corner, colour (0 to 4), signs, roof, core (own or shared),")
w("## pair (the LOTS index sharing the core, or -1), lift.")
w("const LOT_KITS := [")
for k_ in LOT_KITS: w("\t%s," % kit_gd(k_))
w("]")
w("")
w("## The numbered tower houses' kits, by building number.")
w("const BUILDING_KITS := {")
for n_,k_ in sorted(BUILDING_KITS.items()): w("\t%d: %s," % (n_,kit_gd(k_)))
w("}")
w("")
w("## Storey heights for the lots (m).")
w("const STOREY := {\"fabric\": 3.25, \"midrise\": 3.6}")
w("## Crowns above the main roof (m), and parts that rise above a podium.")
w("const CROWNS := {%s}" % ", ".join("%d: %.1f" % (k,v) for k,v in CROWNS.items()))
w("const TOWER_PART := {%s}" % ", ".join("%d: %s" % (k,v2r(v)) for k,v in TOWER_PART.items()))
w("const PODIUM_HEIGHT := {%s}" % ", ".join("%d: %.1f" % (k,v) for k,v in PODIUM_HEIGHT.items()))
w("")
w("## Shared garden courtyards inside blocks.")
w("const COURTS: Array[Rect2] = [")
for c in courts: w("\t%s," % v2r(c))
w("]")
w("")
w("## Where every named resident lives (building number).")
w("const RESIDENT_HOMES := {")
for k,v in RESIDENT_HOMES.items(): w("\t%s: %d," % (q(k),v))
w("}")
w("")
w("## The four wind turbines (tower centres), outside the Rim Walk.")
w("const TURBINES: Array[Vector2] = [")
for t in TURBINES: w("\tVector2(%g, %g)," % t)
w("]")
w("const TURBINE_HUB_HEIGHT := 95.0")
w("const TURBINE_ROTOR_RADIUS := 65.0")
w("")
w("")
w("## A building's true outline: its rect turned by its angle about the rect's")
w("## centre, as four world (x, z) corners.")
w("static func corners(b: Dictionary) -> PackedVector2Array:")
w("\tvar r: Rect2 = b[\"rect\"]")
w("\tvar c := r.get_center()")
w("\tvar h := r.size * 0.5")
w("\tvar a := deg_to_rad(float(b.get(\"angle\", 0.0)))")
w("\tvar out := PackedVector2Array()")
w("\tfor l in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:")
w("\t\tout.append(c + (l as Vector2).rotated(a))")
w("\treturn out")
root=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..')
open(os.path.join(root,'scripts','city_plan.gd'),'w').write("\n".join(out)+"\n")
if '--json' in sys.argv:
    path=sys.argv[sys.argv.index('--json')+1]
    json.dump(dict(streets=STREETS,opens=OPENS,lots=lots,courts=courts,buildings=[dict(b,angle=ANGLE.get(b['n'],0),corners=corners_of(b) if b['r'] else None,height=HEIGHTS.get(b['n'],0),crown=CROWNS.get(b['n']),form=FORMS.get(b['n'],'block'),part=TOWER_PART.get(b['n']),podium=PODIUM_HEIGHT.get(b['n'])) for b in B],storey=STOREY,park=PARK,turbines=TURBINES,precincts=PRECINCTS,estate=ESTATE,lot_kits=LOT_KITS,building_kits=BUILDING_KITS),open(path,'w'))
print('wrote scripts/city_plan.gd:',len(STREETS),'streets,',len(B),'buildings,',len(lots),'lots,',len(courts),'courts')
