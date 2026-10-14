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
 ('Meridian Avenue','main',-391,-6,-318,6),
 ('Meridian North','avenue',-483,-38,-340,-30),
 ('Meridian South','avenue',-483,30,-340,38),
 ('Clock Street','lane',-397,-30,-391,30),
 ('West Street','main',-794,-6,-694,6),
 ('North Street','main',-566,-232,-554,-62),
 ('South Street','main',-566,62,-554,232),
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
b(1,'Grand Hotel',(-483,-98,-431,-38),'civic','atrium block of 12 levels (44 m) round its void; cylinder guest tower of 28 levels (96 m), drum to 108 m (after John Portman)','Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work')
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
 (40,'Battery works',(-816,-11,-794,11),'works','2 storeys','Omar Haddad (flat)'),
 (41,'Recycling works',(-816,16,-798,28),'works','1 storey',''),
 (42,'Water works',(-700,-226,-680,-212),'works','pump house and keeper\'s house','Rafael Ortiz'),
 (43,'Water tower',(-722,-226,-712,-216),'works','35 m',''),
 (44,'Fish tanks',(-668,-250,-648,-234),'works','covered tanks','')]: b(n,name,r,kind,h,who)

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
FH=[6,8,5,9,7,4,6,8]
# downtown's mid-rise mass (2026-10-14, raised so the towers rise out of it rather than over a plain): 18 to 34
# storeys, 65 to 122 m, a third to a half of the towers' height, as round Hong Kong's Central and Tokyo's Marunouchi
MH=[20,26,18,30,24,34,22]
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
HEIGHTS={1:96,2:22,3:22,4:16,5:9,6:4,7:11,8:12,9:4,10:4,12:262,13:180,14:175,15:150,16:22,
 17:91,18:104,19:117,20:130,21:130,22:46,23:6,24:11,25:17,26:20,27:29,28:26,29:20,30:20,31:20,
 32:23,33:9,34:26,35:72,36:42,37:17,38:7,39:6,49:52,50:110,51:8,52:23,53:78,40:8,41:4,42:6,43:35,44:3}
CROWNS={1:108,2:45,3:26,12:280}
## Plan forms: twist (a rounded triangle turning as it rises), screen (round-
## cornered square in a screen), capsule (core with plug-in capsules), dune
## (rippling balconies), atrium (the Grand Hotel: an atrium block with a
## cylinder tower, whose rect is TOWER_PART; see HOTEL), clock (city hall).
FORMS={12:'twist',13:'screen',14:'capsule',15:'dune',1:'atrium',2:'clock'}
## Sub-footprints that rise above their building's podium: the hotel's guest
## tower (the square round its cylinder) and city hall's clock tower.
TOWER_PART={1:(-471,-98,-443,-70),2:(-405,-4,-397,4)}
PODIUM_HEIGHT={1:44}
## The Grand Hotel after John Portman (city.md 8, proposed 2026-10-13), for
## the drawings and the builder. Local metres: x east from the west face, z
## south from the north face, y up from the atrium floor; world = origin + (x, z).
HOTEL={
 'origin':(-483,-98),'size':(52,60),
 'ground':6.5,'mezzanine':5.0,'storey':3.25,'court_levels':12,'top_level':28,
 'court_roof':44.0,'skylight_ridge':48.0,
 # the roof, the lifts, the chandelier and the rain, designed together (city.md 8.4a):
 # the skylight is one pitch of bronze glass falling south, away from the tower: high
 # at +47 along the tower under a band of louvres (+47 to +48, where the stack's warm
 # air leaves) and the tower gutter, low at +44.6 on the leaning front's box gutter
 'skylight':{'high':47.0,'low':44.6,'clerestory':(47.0,48.0),'truss':4.0,'min_pitch':7.0},
 # the void: x range at every level; the north corners' edge; the south
 # galleries' edge at the floor and mezzanine, leaning 'lean' m north a level
 # from level 3 (Hyatt Regency San Francisco)
 'void':{'x':(10,42),'z_north':22,'z_south':48,'lean':0.8},
 'gallery':2.4,'range':10,'south_range':12,
 'forecourt':(0,54,52,60),'entrance_hall':(0,48,52,54),
 'tower':{'c':(26,14),'r':14,'core_r':5.5,'top':96.0,'ribs':40,'rib':(0.6,0.9)},
 'drum':{'r':16,'tank':(96.0,101.0),'lounge':(101.0,105.5),'dome_top':108.0,
          # the tank ring's ribs carry the tower's 40 ribs on up, and the Windrose's fixed
          # glass has a mullion over every rib (its floor turns; the glass does not)
          'ribs':40,'mullions':40},
 # four glass capsules ride in glazed slots let into the tower's south face, from the
 # atrium floor to the drum, inside the tower's outline: no roof ever crosses their
 # path. The slots keep the tower's rhythm: each is two of the ribs' 9-degree bays,
 # centred on a rib that is left out, and framed by the ribs either side, so its
 # clear width is two bays less a rib (3.8 m). Bearings from due south. The tower's
 # face onto the atrium (bearings -54 to 54) is twelve bays: glass, slot, glass, glass,
 # slot, glass either side of the rib at due south that the chandelier's arm leaves by.
 # The capsule's face shows through glass flush with the facade; its doors open into
 # the tower's lobbies
 'lifts':{'bearings':[-45,-18,18,45],'bays':2,'r':1.3,'track':12.3,'slot':3.8,'depth':3.4,'top':101.0},
 'chandelier':{'c':(26,37),'r':4.0,'bottom':15.0,'top':31.0,'tiers':5,'crystals':3000,'lowered':10.0,'load_t':8.0},
 # what the chandelier hangs from: a steel box arm cantilevered from the tower's core,
 # out through the tower's face between the two middle lift slots, under the glass, to
 # a pulley block over the chandelier. Its winch room is inside the tower on level 13,
 # behind the arm, reached from the service core. Four ropes (two hoist, two safety);
 # a handwheel lowers it if the power fails
 'arm':{'root_z':19.5,'tip':(26,37),'bottom':43.2,'depth':(1.4,0.8),'width':1.0,'block':0.8,'winch_level':13,'ropes':4},
 # the rain: the glass sheds south to a box gutter on the front, falling 1:100 to an
 # outlet at each end; the tower's face sheds onto the tower gutter above the louvres,
 # falling east and west round the tower to the ranges' roofs; every pipe runs down
 # inside a pier to the rain cistern under the forecourt, which feeds the runnel and
 # overflows to the street drains and the park's reed pond
 'rain':{'gutter':{'z':(40.0,40.9),'fall':0.01},'outlets':[(8.0,40.4),(44.0,40.4)],'tower_gutter':48.0,
         'cistern':{'rect':(10,54,42,60),'depth':1.6},'storm_mm':50},
 'rock_garden':{'c':(26,37),'r':6.0,'pavilion':(5.0,4.0,4.5)},
 'pod':{'c':(12.5,36),'r':2.5},
 # the double ramp: foot, bend, head on the mezzanine's south gallery
 'ramps':[[(18,38),(13,41),(12,48)],[(34,38),(39,41),(40,48)]],'ramp_width':2.4,'landing':3.0,
 'runnel':[(42,44),(32,45),(20,45),(10,44),(0,44)],
 'skybridge':{'x':(23,29),'z':(60,68)},
 'wind_towers':[(5,24),(5,46)],
}
def _hotel_checks():
    H=HOTEL; st=H['storey']
    lvl=lambda n: H['ground']+H['mezzanine']+(n-3)*st      # floor of level n (n >= 3)
    if abs(lvl(H['court_levels']+1)-H['court_roof'])>0.01: problems.append(('hotel: court roof is not the top of level 12',lvl(13)))
    if abs(lvl(H['top_level']+1)-H['tower']['top'])>0.01: problems.append(('hotel: tower top is not the top of level 28',lvl(29)))
    if HEIGHTS[1]!=H['tower']['top'] or CROWNS[1]!=H['drum']['dome_top'] or PODIUM_HEIGHT[1]!=H['court_roof']:
        problems.append(('hotel: HEIGHTS, CROWNS or PODIUM_HEIGHT disagree with HOTEL',))
    (tx,tz),tr=H['tower']['c'],H['tower']['r']; o=H['origin']
    if (tx-tr,tz-tr,tx+tr,tz+tr)!=(TOWER_PART[1][0]-o[0],TOWER_PART[1][1]-o[1],TOWER_PART[1][2]-o[0],TOWER_PART[1][3]-o[1]):
        problems.append(('hotel: TOWER_PART is not the square round the cylinder',))
    if tx-tr<0 or tx+tr>H['size'][0] or tz-tr<0: problems.append(('hotel: tower off the site',))
    v=H['void']; south=lambda n: v['z_south']-v['lean']*max(0,n-2)
    if south(H['court_levels'])-(tz+tr)<12: problems.append(('hotel: void under 12 m deep at the top',south(12)))
    # every ramp within the world's 32 degrees, its head on the mezzanine's south edge
    for r in H['ramps']:
        L=sum(math.dist(r[i],r[i+1]) for i in range(len(r)-1))
        if math.degrees(math.atan2(H['ground'],L))>32: problems.append(('hotel: ramp steeper than 32 degrees',r))
        if abs(r[-1][1]-v['z_south'])>0.01: problems.append(('hotel: ramp head off the mezzanine',r))
    # the chandelier clears every gallery it hangs beside by 2 m, the tower by
    # 4 m and the lifts by 1.5 m; lowered, it clears the pavilion's roof
    ch=H['chandelier']; (cx,cz),cr=ch['c'],ch['r']
    for n in range(3,H['court_levels']+1):
        if lvl(n)<ch['top'] and lvl(n)+st>ch['bottom']:
            gap=min(cx-v['x'][0],v['x'][1]-cx,south(n)-cz)-cr
            if gap<2: problems.append(('hotel: chandelier within 2 m of level',n,round(gap,2)))
    if math.dist((cx,cz),(tx,tz))-tr-cr<4: problems.append(('hotel: chandelier within 4 m of the tower',))
    if ch['bottom']-ch['lowered']<=H['rock_garden']['pavilion'][2]: problems.append(('hotel: lowered chandelier hits the pavilion',))
    # the lifts: each capsule inside the tower's outline, in a slot opening onto the
    # void, the slots clear of one another
    L_=H['lifts']; bs=sorted(L_['bearings'])
    if L_['track']+L_['r']>tr-0.3: problems.append(('hotel: a capsule stands outside the tower\'s face',))
    for b_ in bs:
        a=math.radians(b_); fx,fz=tx+tr*math.sin(a),tz+tr*math.cos(a)
        if not (v['x'][0]+L_['slot']/2<=fx<=v['x'][1]-L_['slot']/2 and fz>=v['z_north']): problems.append(('hotel: lift slot does not open onto the void',b_))
    # the slots keep the tower's rhythm: each centred on a rib, as wide as its bays less a rib,
    # and the whole slot, framing ribs and all, on the tower's face onto the void
    bay=360/H['tower']['ribs']; bay_m=math.radians(bay)*tr
    if abs(L_['slot']-(L_['bays']*bay_m-H['tower']['rib'][0]))>0.05: problems.append(('hotel: lift slot is not a whole number of the tower\'s bays',L_['slot']))
    for b_ in bs:
        if L_['bays']%2==0 and abs(b_/bay-round(b_/bay))>1e-6: problems.append(('hotel: lift slot not centred on a rib',b_))
        if L_['bays']%2==1 and abs(b_/bay-0.5-round(b_/bay-0.5))>1e-6: problems.append(('hotel: lift slot not centred on a bay',b_))
        e=math.radians(abs(b_)+L_['bays']*bay/2); ex,ez=tx+tr*math.sin(e),tz+tr*math.cos(e)
        if ez<v['z_north'] or not v['x'][0]<=ex<=v['x'][1]: problems.append(('hotel: lift slot\'s outer rib is off the void',b_))
    for k in ('ribs','mullions'):
        if H['drum'][k]%H['tower']['ribs']: problems.append(('hotel: the drum\'s %s do not carry on the tower\'s ribs'%k,H['drum'][k]))
    for a_,b_ in zip(bs,bs[1:]):
        if math.radians(b_-a_)*L_['track']<L_['slot']+0.6: problems.append(('hotel: lift slots too close',a_,b_))
    # the skylight: one pitch, never flatter than glass will shed (7 degrees), and the arm under it
    sk=H['skylight']; zl=south(H['court_levels'])
    zn=lambda x: max(v['z_north'],tz+math.sqrt(max(0,tr*tr-(x-tx)**2)) if abs(x-tx)<tr else v['z_north'])
    x=v['x'][0]
    while x<=v['x'][1]+0.01:
        run=zl-zn(x)
        if run<=0 or math.degrees(math.atan2(sk['high']-sk['low'],run))<sk['min_pitch']: problems.append(('hotel: skylight flatter than glass sheds at x',x))
        x+=sk['truss']
    ar=H['arm']; (ax,az)=ar['tip']
    if abs(ax-cx)>0.3 or abs(az-cz)>0.3: problems.append(('hotel: the arm\'s tip is not over the chandelier',))
    glass_at=lambda x,z: sk['high']-(sk['high']-sk['low'])*(z-zn(x))/(zl-zn(x))
    if glass_at(ax,az)-(ar['bottom']+ar['depth'][1])<0.6: problems.append(('hotel: the arm reaches the glass',))
    for b_ in bs:
        off=abs(L_['track']*math.sin(math.radians(b_)))-L_['slot']/2
        if off<ar['width']/2+0.4: problems.append(('hotel: the arm crosses a lift slot',b_))
    if ar['bottom']-ar['block']-ch['top']<6: problems.append(('hotel: under 6 m of rope above the chandelier',))
    # the rain: the cistern holds a cloudburst on the whole roof
    rn=H['rain']; c=rn['cistern']; vol=(c['rect'][2]-c['rect'][0])*(c['rect'][3]-c['rect'][1])*c['depth']
    need=H['size'][0]*H['size'][1]*rn['storm_mm']/1000
    if vol<need: problems.append(('hotel: the rain cistern holds %.0f m3, under a %d mm cloudburst on the roof (%.0f m3)'%(vol,rn['storm_mm'],need),))
    for ox,oz in rn['outlets']:
        # each outlet at a gutter end, inside the east or west range, so its pipe runs down a pier, not through the atrium
        if not ((v['x'][0]-2.5<=ox<=v['x'][0]-1 or v['x'][1]+1<=ox<=v['x'][1]+2.5) and rn['gutter']['z'][0]<=oz<=rn['gutter']['z'][1]): problems.append(('hotel: a gutter outlet is not at a gutter end inside a range',ox,oz))
_hotel_checks()
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
## The towers' sites (city.md 7c, revised 2026-10-14). No irregular tower takes
## its whole plot: each shaft stands back at least 6 m from every neighbour,
## and its foot is public ground with a life of its own. shaft: the tower's
## footprint (world rect); ground: what stands round it, each a kind and a rect
## (pavilion: one or two storeys, its roof at the Deck's +6.5 m; link: a glass
## bridge at +6.5 m; canopy: a shade lattice about 4 m up; forecourt, garden,
## court, yard: open ground).
TOWER_SITE={
 12:dict(shaft=(-424,-74,-396,-46),ground=[
   ('forecourt',(-431,-46,-389,-38),'the wind garden\'s front on Meridian North: shade trees and benches facing Civic Plaza'),
   ('garden',(-431,-80,-389,-46),'the wind garden: desert grasses that move in the wind, and a ring of small turbines at head height'),
   ('pavilion',(-431,-70,-424,-52),'the lobby\'s glass hall on the hotel side; its roof is the Deck\'s run from the hotel mezzanine'),
   ('link',(-431,-64,-424,-58),'the glass bridge at +6.5 m from the hotel\'s mezzanine into the lobby')]),
 13:dict(shaft=(-474,47,-448,71),ground=[
   ('pavilion',(-483,38,-443,44),'a two-storey run of cafes holding Meridian South; the glass skybridge lands on its roof terrace, the Deck lobby'),
   ('court',(-483,44,-474,78),'the screen court facing the park, shaded by a canopy of the tower\'s own pierced screens'),
   ('canopy',(-483,48,-474,74),'the screen canopy, its panels pierced with Old Moy\'s house marks'),
   ('garden',(-474,71,-443,78),'a planted strip on the neighbours\' side')]),
 14:dict(shaft=(-477,-134,-449,-108),ground=[
   ('yard',(-483,-108,-443,-102),'the makers\' yard on Hotel Lane: benches, bike racks and a skate run Theo uses at lunch'),
   ('court',(-477,-134,-449,-108),'the open ground under the first capsules: workshops and a cafe round the core, the capsules starting at the third floor'),
   ('garden',(-483,-142,-443,-134),'shade trees on the north side'),
   ('garden',(-449,-134,-443,-108),'a planted strip on the east neighbour\'s side')]),
 15:dict(shaft=(-477,110,-451,136),ground=[
   ('forecourt',(-483,102,-443,110),'the residents\' front on Glass Lane'),
   ('court',(-477,110,-451,136),'a two-storey colonnade under the first balconies: the lobby, a nursery and the residents\' room, open to the gardens'),
   ('garden',(-483,110,-477,142),'a shaded garden on Market Lane'),
   ('garden',(-451,110,-443,142),'the residents\' garden: a pergola, a play lawn and the children\'s sand pit'),
   ('canopy',(-451,114,-443,132),'the pergola'),
   ('garden',(-477,136,-451,142),'a planted strip to the south')]),
}
## BLOCK (city.md 7c, 6 below; proposed 2026-10-14): a closed institute that
## looms, said with the architecture and never with a sign. A dark recessed base
## with no windows at eye level and one narrow door off its axis; the five
## storeys above step out over it to the plot line, so the whole mass leans over
## its own pavement; slit windows; a court nobody sees, its glow only showing at
## night; a crown of grounding masts. Precedents: 33 Thomas Street, New York (the
## windowless telephone exchange), Boston City Hall (upper floors looming over
## the base), and the Kunsthaus and bunker tradition of dark mass in a pale city.
BLOCK_FORM=dict(storeys=6,storey=3.6,base=(3.0,6.5),door=(-401,41),court=(-421,50,-403,68),slit=(0.35,3.6),
  colour='blue-black glazed brick, with an azure sheen at a low sun',masts=12,mast=6.0,glow='the court\'s clerestory, azure at night')
TURBINES=[(-310,-200),(-310,200),(-740,-270),(-740,270)]
## The Deck (city.md 6.2 and 6a): the walkway at +6.5 m, after Hong Kong's
## footbridges. Every run has a job: the ring shades the park side of the Park
## Ring and joins every district; each branch ends at a door that is worth
## walking to at +6.5 m. Runs are centrelines (world x, z) with a width; a run
## that ends at a building ends at one of DECK['doors']. Columns stand in pairs
## at its edges, never in a street mouth or a park gate (the line a walker
## crosses on), and the skybridges span their street with none. Ways down are
## ramp towers (the world's 32 degree ramp, two flights of 5.2 m, so a tower
## 8 m across) and glass lifts. The travelators of the first brief are dropped:
## at 12 degrees a 6.5 m rise runs 31 m, more than any square can spare.
DECK={
 'level':6.5,'depth':0.9,'rail':1.1,'col':0.6,'max_span':12.0,
 'runs':[
  # the ring, over the park side of the Park Ring: a 6 m arcade below it, 6 m open street outside it
  dict(name='Park Deck',kind='ring',w=6,pts=[(-628,-53),(-492,-53),(-492,53),(-628,53),(-628,-53)]),
  # the civic walks along Civic Plaza's north and south edges, to city hall's canopies
  dict(name='Civic walk north',kind='walk',w=6,pts=[(-489,-27),(-431,-27)]),
  dict(name='Civic walk south',kind='walk',w=6,pts=[(-489,27),(-431,27)]),
  # the skybridges: the hotel's (HOTEL['skybridge']) and the glass tower's, each across its street
  dict(name='Hotel skybridge',kind='bridge',w=6,pts=[(-457,-30),(-457,-38)]),
  dict(name='Glass skybridge',kind='bridge',w=6,pts=[(-463,30),(-463,38)]),
  # to the library's east-wing door, over Garden Walk's mouth
  dict(name='Library walk',kind='walk',w=6,pts=[(-631,-27),(-648,-27)]),
  # up the east half of North Street to the neighbourhood centre's roof garden
  dict(name='Estate walk',kind='walk',w=6,pts=[(-557,-56),(-557,-121)]),
  # down the east half of South Street, then along Market Square's north edge to the wet market's upper hall
  dict(name='Market walk',kind='walk',w=6,pts=[(-557,56),(-557,125),(-530,125)]),
 ],
 # where the Deck meets a building at +6.5 m: (building, point on its face, what is there)
 'doors':[
  (1,(-457,-38),'the hotel\'s Deck door into the mezzanine gallery'),
  (13,(-463,38),'the glass tower\'s Deck lobby'),
  (2,(-431,-27),'city hall\'s north canopy, along to the north door'),
  (2,(-431,27),'city hall\'s south canopy'),
  (3,(-645,-30),'the library\'s east-wing door to the first gallery'),
  (51,(-554,-120),'the neighbourhood centre\'s roof garden'),
  (33,(-530,125),'the wet market\'s upper hall'),
 ],
 # indoor runs at +6.5 m that carry the Deck through a building
 'through':[(1,12,'the hotel mezzanine\'s east gallery through the party wall to the Windspire\'s lobby')],
 # ramp towers: centre, radius, the side its head opens onto the Deck and the side its foot opens onto the ground
 'ramps':[
  dict(name='North gate',c=(-552,-46),r=4,head='n',foot='w'),
  dict(name='South gate',c=(-568,46),r=4,head='s',foot='e'),
  dict(name='West gate',c=(-621,8),r=4,head='w',foot='n'),
  dict(name='East gate',c=(-499,-8),r=4,head='e',foot='s'),
  dict(name='Civic north',c=(-457,-20),r=4,head='n',foot='s'),
  dict(name='Civic south',c=(-457,20),r=4,head='s',foot='n'),
 ],
 'lifts':[dict(name='Estate Square',c=(-552.3,-112),r=1.6),dict(name='Market Square',c=(-533,129.7),r=1.6)],
 'max_to_way_down':75.0,'min_soffit':5.4,'min_open_beside':4.0,
}
DIRS={'n':(0,-1),'s':(0,1),'e':(1,0),'w':(-1,0)}
def _deck_checks():
    from shapely.geometry import LineString, Point, box as sbox
    from shapely.ops import unary_union
    D=DECK
    if D['level']-D['depth']<D['min_soffit']: problems.append(('deck: soffit too low',))
    ground=unary_union([sbox(*s[2:]) for s in STREETS]+[sbox(*o[1:]) for o in OPENS])
    bldg=[(b_['n'],sbox(*b_['r'])) for b_ in named]+[(None,sbox(*l[:4])) for l in lots]
    park=sbox(*PARK['rect'])
    polys={}
    for run in D['runs']:
        P=LineString(run['pts']).buffer(run['w']/2,cap_style=2,join_style=2); polys[run['name']]=P
        off=P.difference(ground).area
        if off>0.5: problems.append(('deck: run leaves the streets and squares',run['name'],round(off,1)))
        for n_,g in bldg:
            if P.intersection(g).area>0.05: problems.append(('deck: run over a building',run['name'],n_))
        if run['kind']=='bridge':
            ln=LineString(run['pts']).length
            if ln>D['max_span']+2: problems.append(('deck: skybridge span',run['name'],ln))
    # a street the Deck runs along keeps an open strip beside it
    for run in D['runs']:
        if run['kind']=='bridge': continue
        for a,c in zip(run['pts'],run['pts'][1:]):
            along=(a[0]==c[0])
            for s in STREETS:
                r=s[2:]; sw=(r[2]-r[0]) if along else (r[3]-r[1])
                seg=LineString([a,c])
                if seg.intersection(sbox(*r)).length>20 and ((along and r[3]-r[1]>r[2]-r[0]) or (not along and r[2]-r[0]>r[3]-r[1])):
                    if sw-run['w']<D['min_open_beside']-1e-6: problems.append(('deck: no open street beside',run['name'],s[0]))
    for n_,p,what in D['doors']:
        bb=[b_['r'] for b_ in named if b_['n']==n_][0]
        if sbox(*bb).exterior.distance(Point(p))>0.6: problems.append(('deck: door not on its building',n_,p))
        if not any(P.buffer(0.6).contains(Point(p)) for P in polys.values()): problems.append(('deck: door off the Deck',n_,p))
    # ways down: in the park or on a square, clear of the park's features, head on the Deck, foot on a walk or square
    pc=PARK['pond']['c']; prx,prz=PARK['pond']['r']
    from shapely import affinity
    pond=affinity.scale(Point(pc).buffer(1,64),prx,prz)
    feats=[sbox(*PARK['dry_garden']),sbox(*PARK['lawn']),pond]+[Point(t).buffer(3) for t in PARK['wind_trees']]+[Point(t).buffer(2.5) for t in PARK['parasols']]
    walks=unary_union([sbox(*w_) for w_ in PARK['walks']]+[sbox(*s[2:]) for s in STREETS]+[sbox(*o[1:]) for o in OPENS if o[0]!='park'])
    deck=unary_union(list(polys.values()))
    heads=[]
    for t in D['ramps']+D['lifts']:
        C=Point(t['c']).buffer(t['r'],64)
        if C.difference(ground).area>0.5: problems.append(('deck: way down off the ground',t['name']))
        if C.intersection(deck).area>0.05: problems.append(('deck: way down under the Deck',t['name']))
        if C.distance(deck)>0.6: problems.append(('deck: way down does not meet the Deck',t['name']))
        for f in feats:
            if C.buffer(1.2).intersection(f).area>0: problems.append(('deck: way down on a park feature',t['name']))
        for n_,g in bldg:
            if C.intersection(g).area>0: problems.append(('deck: way down on a building',t['name'],n_))
        if 'foot' in t:
            dx,dz=DIRS[t['foot']]; f=Point(t['c'][0]+dx*(t['r']+1.2),t['c'][1]+dz*(t['r']+1.2))
            if not walks.contains(f) or deck.contains(f): problems.append(('deck: ramp foot lands nowhere',t['name']))
            hx,hz=DIRS[t['head']]; h=Point(t['c'][0]+hx*(t['r']+0.5),t['c'][1]+hz*(t['r']+0.5))
            if not deck.buffer(0.1).contains(h): problems.append(('deck: ramp head not on the Deck',t['name']))
        heads.append(Point(t['c']))
    # no point on the Deck more than max_to_way_down from a way down, walking the Deck
    import heapq
    pts=[]; adj={}
    for run in D['runs']:
        line=LineString(run['pts']); n=max(2,int(line.length)+1); ids=[]
        for i in range(n):
            q_=line.interpolate(i/(n-1),normalized=True); pts.append((q_.x,q_.y)); ids.append(len(pts)-1)
        for a,c in zip(ids,ids[1:]): adj.setdefault(a,[]).append((c,line.length/(n-1))); adj.setdefault(c,[]).append((a,line.length/(n-1)))
    for i,p in enumerate(pts):
        for j in range(i+1,len(pts)):
            d=math.hypot(p[0]-pts[j][0],p[1]-pts[j][1])
            if d<3.2: adj.setdefault(i,[]).append((j,d)); adj.setdefault(j,[]).append((i,d))
    dist={}; hq=[]
    for h in heads:
        k=min(range(len(pts)),key=lambda i:h.distance(Point(pts[i])))
        dist[k]=0; heapq.heappush(hq,(0,k))
    while hq:
        d,k=heapq.heappop(hq)
        if d>dist.get(k,1e9): continue
        for j,w_ in adj.get(k,[]):
            if d+w_<dist.get(j,1e9): dist[j]=d+w_; heapq.heappush(hq,(d+w_,j))
    far=max(dist.get(i,1e9) for i in range(len(pts)))
    if far>D['max_to_way_down']: problems.append(('deck: a point is %.0f m from a way down'%far,))
    D['_far']=round(far,1)
    # columns: pairs at the run edges, spaced at most max_span, kept out of street mouths and park gates
    keep=[]  # (the street or walk, runs east-west, its line grown 13 m along its length)
    for r in [s_[2:] for s_ in STREETS]+list(PARK['walks']):
        ew=r[2]-r[0]>r[3]-r[1]
        keep.append((sbox(*r),ew,sbox(r[0]-13,r[1],r[2]+13,r[3]) if ew else sbox(r[0],r[1]-13,r[2],r[3]+13)))
    cols=[]
    for run in D['runs']:
        if run['kind']=='bridge': continue
        for a,c in zip(run['pts'],run['pts'][1:]):
            ux,uz=(c[0]-a[0]),(c[1]-a[1]); L=math.hypot(ux,uz); ux/=L; uz/=L
            mid=Point((a[0]+c[0])/2,(a[1]+c[1])/2); ew=abs(ux)>abs(uz)
            bad=unary_union([g for o,e,g in keep if not (e==ew and o.contains(mid))])
            e_=run['w']/2-0.4
            def at(t,e): return (a[0]+ux*t-uz*e*e_,a[1]+uz*t+ux*e*e_)
            def ok(t): return all(not bad.contains(Point(at(t,e))) and not any(g.buffer(0.05).contains(Point(at(t,e))) for _,g in bldg) for e in (-1,1))
            ts=[i*0.5 for i in range(int(L*2)+1)]
            okt=[t for t in ts if ok(t)]
            if not okt: problems.append(('deck: no room for a column',run['name'])); continue
            placed=[okt[0]]
            on_run=any(Q.buffer(0.6).contains(Point(a)) for k_,Q in polys.items() if k_!=run['name'])
            if placed[0]>(D['max_span'] if on_run else D['max_span']/2): problems.append(('deck: first column too far in',run['name'],placed[0]))
            while placed[-1]<L-0.01:
                nxt=[t for t in okt if placed[-1]<t<=placed[-1]+D['max_span']]
                if L<=placed[-1]+D['max_span'] and L in okt: placed.append(L); break
                if not nxt:
                    later=[t for t in okt if t>placed[-1]]
                    if not later: break
                    problems.append(('deck: column span too long',run['name'],later[0]-placed[-1])); placed.append(later[0]); continue
                placed.append(nxt[-1])
            if L-placed[-1]>D['max_span']/2: problems.append(('deck: last column too far in',run['name'],L-placed[-1]))
            for t in placed:
                for e in (-1,1): cols.append(tuple(round(v,1) for v in at(t,e)))
    D['columns']=sorted(set(cols))
_deck_checks()
def _site_checks():
    from shapely.geometry import box as sbox
    others=[(b_['n'],sbox(*b_['r'])) for b_ in named]+[(None,sbox(*l[:4])) for l in lots]
    for n_,site in TOWER_SITE.items():
        plot=sbox(*[b_ for b_ in named if b_['n']==n_][0]['r']); sh=sbox(*site['shaft'])
        if not plot.contains(sh): problems.append(('tower shaft outside its plot',n_))
        for m_,g in others:
            if m_==n_: continue
            if sh.distance(g)<6-1e-6: problems.append(('tower shaft within 6 m of a neighbour',n_,m_))
        free=plot.difference(sh).area/plot.area
        if free<0.4: problems.append(('tower takes too much of its plot',n_,round(1-free,2)))
        for kind,r,what in site['ground']:
            g=sbox(*r)
            if not plot.buffer(0.01).contains(g): problems.append(('tower ground outside its plot',n_,kind))
            if kind=='pavilion' and g.intersection(sh).area>0.01: problems.append(('pavilion inside the shaft',n_))
        if not any(k_ in ('pavilion','court','yard') for k_,_,_ in site['ground']): problems.append(('tower foot with no life',n_))
    bf=BLOCK_FORM; br=[b_ for b_ in named if b_['n']==16][0]['r']
    if not sbox(*br).buffer(-bf['base'][0]+0.01).contains(sbox(*bf['court'])): problems.append(('BLOCK court not inside its walls',))
    x,z=bf['door']
    if not (abs(z-(br[1]+bf['base'][0]))<0.5 and br[0]<x<br[2]): problems.append(('BLOCK door not on its recessed base front',))
_site_checks()
## The wall and the Wall Line (city.md 6c, proposed 2026-10-14). The Ring Line
## came first: a double-track viaduct round the city's edge, built in the boom.
## As the NMEs rose, the city filled its arches with rammed earth and concrete,
## and the railway became the wall: a plain circle just outside the Rim Walk,
## carrying the trains on its top. Gatehouses, watch posts and the Line House
## (the car shed) project outward, never into the city. The works beyond it
## (battery, recycling and water works, the water tower, the fish tanks) stay
## outside with their own fences, lights and keepers. Centreline in world (x, z).
WALL={
 'height':12.0,'thick':12.0,'parapet':1.2,'r':209.5,
 # on the top, from the city side: inner parapet, two tracks (centres 3.4 m apart), the watch walk, outer parapet
 'track_axis':-2.2,'track_spacing':3.4,'walk':3.6,'min_curve':25.0,
 # gates: the streets that pass through, each with a gatehouse 24 m deep (12 m beyond the outer face) and its station above
 'gates':[dict(name='East Gate',street='Meridian Avenue',axis='x',at=0.0,arch=(10.0,8.0),along=84.0,out=20.0),
          dict(name='North Gate',street='North Street',axis='z',at=-560.0,arch=(10.0,8.0)),
          dict(name='South Gate',street='South Street',axis='z',at=-560.0,arch=(10.0,8.0)),
          dict(name='West Gate',street='West Street',axis='x',at=0.0,arch=(10.0,8.0))],
 'gatehouse':dict(along=44.0,out=12.0),
 # halts between the gates, each on its own bastion over the lane it serves
 'halts':[],
 'platform':(40.0,3.0),'watch_every':120.0,'watch_r':7.0,
 # the watch posts are Xi'an's bastions (mamian): rectangular, 20 m along the wall and 10 m out
 'post':dict(along=20.0,out=10.0,height=14.0),
 # the Ring Line's arches, after Tokyo's gado-shita: only the outer half of each was filled, so the inner half opens on the
 # Rim Walk as a room 5 m deep under a 6.5 m arch; bays of 9 m, the arches kept clear of the gates and the Line House
 'arches':dict(bay=9.0,span=6.5,rise=5.5,depth=5.0),
 # the gate towers: Jiayuguan's tiered towers on the gatehouse's outer corners, in Moy's tile
 'gate_tower':dict(base=7.0,tiers=3,tier=3.2),
 'line':dict(speed=10.0,dwell=20.0,sets_each_way=2,cars=2,car=(15.0,2.65,3.5),power='the wind, from the battery works'),
 # the Line House: a bastion on the wall's outside, toward the water works: the car shed at the top's level over the
 # lines' workshop and the Wall Watch's guardroom. at: degrees round the circle (atan2 of z, x-CX); along and out in metres
 'shed':dict(at=232.0,along=60.0,out=16.0),
}
def _build_wall():
    from shapely.geometry import Polygon, LineString, Point, box as sbox
    from shapely.ops import unary_union, nearest_points
    W_=WALL
    pts=[]
    pts=[(CX+W_['r']*math.cos(math.radians(a_)),W_['r']*math.sin(math.radians(a_))) for a_ in range(0,360)]
    P=Polygon(pts)
    C=LineString(list(P.exterior.coords))
    band=C.buffer(W_['thick']/2,cap_style=2,join_style=1)
    inner=Polygon(P.exterior.coords).buffer(-W_['thick']/2)
    W_['centreline']=[(round(x,2),round(z,2)) for x,z in list(C.simplify(0.05).coords)]
    W_['length']=round(C.length,1)
    # gates: where their street crosses the centreline
    gp=[]
    for g in W_['gates']:
        if g['street']:
            st=[s for s in STREETS if s[0]==g['street']][0]; r=st[2:]
            ax=LineString([((r[0]+r[2])/2,r[1]),((r[0]+r[2])/2,r[3])]) if g['axis']=='z' else LineString([(r[0],(r[1]+r[3])/2),(r[2],(r[1]+r[3])/2)])
            hit=ax.intersection(C)
            g['street_w']=(r[2]-r[0]) if g['axis']=='z' else (r[3]-r[1])
        else:
            ax=LineString([(-1000,g['at']),(-100,g['at'])]) if g['axis']=='x' else LineString([(g['at'],-400),(g['at'],400)])
            hit=ax.intersection(C); g['street_w']=0
        hit=min(list(getattr(hit,'geoms',[hit])),key=lambda p:Point(g['near']).distance(p) if 'near' in g else 0)
        g['p']=(round(hit.x,2),round(hit.y,2)); g['s']=round(C.project(hit),1); gp.append(g)
        if g['street'] and g['arch'][0]<g['street_w']-2.0+1e-6 and g['street_w']>12: problems.append(('wall: gate arch narrower than its street',g['name']))
    for h in W_['halts']:
        if h.get('street'):
            st=[s for s in STREETS if s[0]==h['street']][0]; r=st[2:]
            mx,mz=(r[0]+r[2])/2,(r[1]+r[3])/2
            ax=LineString([(mx,-400),(mx,400)]) if r[3]-r[1]>r[2]-r[0] else LineString([(-1000,mz),(-100,mz)])
            hits=list(getattr(ax.intersection(C),'geoms',[ax.intersection(C)]))
            q=max(hits,key=lambda p:{'s':p.y,'n':-p.y,'e':p.x,'w':-p.x}[h['end']])
        else: q=C.interpolate(C.project(Point(h['near'])))
        h['p']=(round(q.x,2),round(q.y,2)); h['s']=round(C.project(q),1)
    stations=sorted([dict(name=g['name'],s=g['s'],p=g['p'],kind='gate') for g in gp]+[dict(name=h['name'],s=h['s'],p=h['p'],kind='halt') for h in W_['halts']],key=lambda d:d['s'])
    W_['stations']=stations
    for st in stations:  # platforms stand on straight or gently curved wall (radius 150 m or more)
        q0,q1,q2=[C.interpolate((st['s']+d)%C.length) for d in (-W_['platform'][0]/2,0,W_['platform'][0]/2)]
        ax_,az_=q1.x-q0.x,q1.y-q0.y; bx,bz=q2.x-q1.x,q2.y-q1.y; cr=abs(ax_*bz-az_*bx)
        if cr>1e-6 and math.hypot(ax_,az_)*math.hypot(bx,bz)*math.hypot(q2.x-q0.x,q2.y-q0.y)/(2*cr)<150: problems.append(('wall: station on a sharp curve',st['name']))
    L=C.length; gaps=[((stations[(i+1)%len(stations)]['s']-st['s'])%L) for i,st in enumerate(stations)]
    W_['station_gaps']=[round(x) for x in gaps]
    if min(gaps)<120: problems.append(('wall: stations closer than 120 m',min(gaps)))
    if max(gaps)>340: problems.append(('wall: stations further apart than 340 m',max(gaps)))
    # the Line House bastion, as a polygon outward from the outer face
    t=math.radians(W_['shed']['at']); da=W_['shed']['along']/2/W_['r']; r0=W_['r']+W_['thick']/2-0.5; r1=W_['r']+W_['thick']/2+W_['shed']['out']
    shed=Polygon([(CX+rr*math.cos(t+k),rr*math.sin(t+k)) for rr,ks in ((r0,(-da,da)),(r1,(da,-da))) for k in ks])
    W_['shed_poly']=[(round(x,2),round(z,2)) for x,z in shed.exterior.coords]
    # watch posts: evenly round the wall, kept 30 m off every station
    n=int(L//W_['watch_every']); posts=[]
    for i in range(n):
        s=(i+0.5)*L/n
        q=C.interpolate(s)
        if all(min(abs(s-st['s']),L-abs(s-st['s']))>30 for st in stations) and shed.distance(q)>30:
            posts.append((round(q.x,2),round(q.y,2)))
    W_['watch_posts']=posts
    # the arch rooms on the city side, kept 4 m clear of every gatehouse and the Line House
    A=W_['arches']; arches=[]; n_a=int(L//A['bay'])
    for i in range(n_a):
        s_=(i+0.5)*L/n_a; q=C.interpolate(s_)
        if all(Point(g['p']).distance(q)>g.get('along',W_['gatehouse']['along'])/2+4 for g in W_['gates']) and shed.distance(q)>W_['thick']/2+4:
            arches.append(round(s_,1))
    W_['arch_s']=arches
    # the line's curves: radius from three points 10 m apart
    worst=1e9
    for i in range(0,int(L),5):
        p0,p1,p2=[C.interpolate((i+d)%L) for d in (0,10,20)]
        ax_,az_=p1.x-p0.x,p1.y-p0.y; bx,bz=p2.x-p1.x,p2.y-p1.y
        cr=abs(ax_*bz-az_*bx)
        if cr>1e-6:
            R_=math.hypot(ax_,az_)*math.hypot(bx,bz)*math.hypot(p2.x-p0.x,p2.y-p0.y)/(2*cr); worst=min(worst,R_)
    W_['min_radius']=round(worst,1)
    if worst<W_['min_curve']: problems.append(('wall: the line curves tighter than %.0f m'%W_['min_curve'],round(worst,1)))
    # nothing built stands in the wall; every building, lot and work stands inside it
    outward=[shed]+[Point(g['p']).buffer(W_['thick']/2+g.get('out',W_['gatehouse']['out'])+0.1) for g in W_['gates']]
    for b_ in named:
        g=sbox(*b_['r'])
        if g.intersection(band).area>0.01: problems.append(('wall: through a building',b_['n']))
        if b_['kind']=='works':
            # the works stand outside, clear of the wall, its gatehouses and the Line House, behind their own fences
            if inner.intersects(g) or g.distance(band)<6: problems.append(('wall: work not clear outside the wall',b_['n']))
            for o in outward:
                if o.distance(g)<4: problems.append(('wall: work against a gatehouse or the Line House',b_['n']))
        elif not inner.contains(g): problems.append(('wall: building left outside',b_['n']))
    for l in lots:
        g=sbox(*l[:4])
        if g.intersection(band).area>0.01 or not inner.contains(g): problems.append(('wall: lot not inside',l[:4]))
    # the Rim Walk (197 to 203) stays clear of the wall
    rim=Point(CX,0).buffer(203,128).difference(Point(CX,0).buffer(197,128))
    if rim.intersection(band).area>0.5: problems.append(('wall: on the Rim Walk',round(rim.intersection(band).area,1),[tuple(round(v) for v in g.centroid.coords[0]) for g in getattr(rim.intersection(band),'geoms',[rim.intersection(band)])]))
    # streets: a gate street passes through its gate; every other street stops at the Rim Walk (the builder clips it to 203 m)
    gate_streets={g['street'] for g in gp if g['street']}
    W_['clipped']=sorted({s[0] for s in STREETS if s[0] not in gate_streets and sbox(*s[2:]).intersection(band).area>0})
    for g in gp:
        if g['street']:
            st=[s for s in STREETS if s[0]==g['street']][0]; r=st[2:]
            beyond=Point(g['p']).buffer(W_['thick']/2+g.get('out',W_['gatehouse']['out'])+1)
            if not sbox(*r).intersects(beyond.difference(inner).difference(band)): problems.append(('wall: gate street stops short of the gate\'s outer mouth',g['name']))
    # the Deck's ways down and the turbines stay clear
    for t in TURBINES:
        if band.distance(Point(t))<40 or shed.distance(Point(t))<40: problems.append(('wall: too near a turbine',t))
_build_wall()
## The cross lines (city.md 6c, proposed 2026-10-14): elevated, at the Wall
## Line's own level (+12 m), so the ring on the wall and the cross meet on the
## level at the gates. Where a cross line follows the Deck it rides directly
## over it, on the Deck's own columns carried up through it: the Deck is the
## line's lower floor, its stations' concourse, and is shaded by the track.
## Elsewhere the line has its own piers. Short articulated cars take 12 m
## curves, after Lisbon's trams. Main streets (12 m) take double track (6 m);
## Meridian North and South (8 m) take one track each, one way, so the
## Meridian Line divides round city hall and Civic Plaza as the avenues do.
## Old Moy and the civic axis (park to library) stay free of rail.
## Services are directional centrelines in world (x, z); corners are filleted.
CROSS={
 'rail':12.0,'depth':1.2,'r_min':12.0,'double':6.0,'single':3.6,'platform':(30.0,3.0),'min_gap':60.0,
 'clear_over':2.0,  # a building under the line stands at least this far below its soffit
 'cars':dict(cars=2,car=(12.0,2.65,3.4),speed=9.0,dwell=20.0,headway=150),
 'services':[
  dict(line='Spine Line',dir='south',w='double',pts=[(-557,-215),(-557,-53),(-628,-53),(-628,53),(-560,53),(-560,215)]),
  dict(line='Meridian Line',dir='west',w='single',pts=[(-322,34),(-492,34),(-492,-53),(-628,-53),(-628,25)]),
  dict(line='Meridian Line',dir='east',w='single',pts=[(-628,25),(-628,-53),(-515,-53),(-490,-34),(-322,-34)]),
 ],
 # stations: the services that stop, the platform's centre on the line, which sides have platforms, and how people reach it
 'stations':[
  dict(name='North Gate',at=(-557,-200),lines=['Spine Line'],access='the North Gate\'s gatehouse, level with the Wall Line'),
  dict(name='Estate Square',at=(-557,-100),lines=['Spine Line'],access='from the Deck\'s Estate walk below; the Deck\'s glass lift'),
  dict(name='Park North',at=(-588,-53),lines=['Spine Line','Meridian Line'],access='from the Park Deck below; the park\'s north gate tower'),
  dict(name='Park West',at=(-628,0),lines=['Spine Line','Meridian Line'],access='the park\'s west gate tower, rising on to +12 m; the Park Deck and the Library walk'),
  dict(name='Market Square',at=(-560,138),lines=['Spine Line'],access='from the Deck\'s Market walk where it crosses below; the Deck\'s glass lift'),
  dict(name='South Gate',at=(-560,200),lines=['Spine Line'],access='the South Gate\'s gatehouse, level with the Wall Line'),
  dict(name='Civic Plaza',at=(-462,34),toward=(-462,0),lines=['Meridian Line'],access='over the Deck\'s civic walks; the plaza\'s two ramp towers rise on to +12 m'),
  dict(name='Civic Plaza',at=(-462,-34),toward=(-462,0),lines=['Meridian Line'],access=''),
  dict(name='East Gate',at=(-345,34),lines=['Meridian Line'],access='the East Gate\'s south wing, level with the Wall Line'),
  dict(name='East Gate',at=(-345,-34),lines=['Meridian Line'],access='the East Gate\'s north wing'),
 ],
 # where the cross lines join the Wall Line on the level, so their trains reach the Line House
 'junctions':['North Gate','South Gate','East Gate'],
}
def _fillet(pts,R,step=1.0):
    out=[pts[0]]
    for i in range(1,len(pts)-1):
        A,B,C_=pts[i-1],pts[i],pts[i+1]
        ux,uz=A[0]-B[0],A[1]-B[1]; lu=math.hypot(ux,uz); ux/=lu; uz/=lu
        vx,vz=C_[0]-B[0],C_[1]-B[1]; lv=math.hypot(vx,vz); vx/=lv; vz/=lv
        th=math.acos(max(-1,min(1,ux*vx+uz*vz)))
        if abs(th-math.pi)<1e-6: out.append(B); continue
        t=R/math.tan(th/2)
        if t>min(lu,lv)/2+1e-6: problems.append(('cross: no room for a %g m curve'%R,B)); out.append(B); continue
        bx,bz=ux+vx,uz+vz; lb=math.hypot(bx,bz); bx/=lb; bz/=lb
        cx,cz=B[0]+bx*R/math.sin(th/2),B[1]+bz*R/math.sin(th/2)
        p1=(B[0]+ux*t,B[1]+uz*t); p2=(B[0]+vx*t,B[1]+vz*t)
        a1,a2=math.atan2(p1[1]-cz,p1[0]-cx),math.atan2(p2[1]-cz,p2[0]-cx)
        d=(a2-a1+math.pi)%(2*math.pi)-math.pi
        n=max(2,int(abs(d)*R/step))
        out+= [(cx+R*math.cos(a1+d*k/n),cz+R*math.sin(a1+d*k/n)) for k in range(n+1)]
    out.append(pts[-1]); return out
def _cross_checks():
    from shapely.geometry import LineString, Point, box as sbox, Polygon as SP
    from shapely.ops import unary_union
    X=CROSS; soffit=X['rail']-X['depth']
    ground=unary_union([sbox(*s_[2:]) for s_ in STREETS]+[sbox(*o[1:]) for o in OPENS])
    tall=[]
    for b_ in named:
        h=PODIUM_HEIGHT.get(b_['n'],HEIGHTS.get(b_['n'],8))
        tall.append((b_['n'],h,sbox(*b_['r'])))
        if b_['n'] in TOWER_PART: tall.append((b_['n'],HEIGHTS[b_['n']],sbox(*TOWER_PART[b_['n']])))
    for l in lots: tall.append((None,l[4]*STOREY.get(l[5],3.25),sbox(*l[:4])))
    # the Deck's skybridges pass under the line with headroom
    if DECK['level']+2.8+0.25>soffit-1.0: problems.append(('cross: a Deck skybridge too close under the line',))
    wallP=SP(WALL['centreline'])
    lines={}
    for sv in X['services']:
        P=_fillet(sv['pts'],X['r_min']); sv['path']=[(round(x,2),round(z,2)) for x,z in P]
        L=LineString(P); sv['length']=round(L.length,1); w=X[sv['w']]
        env=L.buffer(w/2,cap_style=2,join_style=2)
        # inside the wall, then over streets, squares and the park, or over buildings low enough to pass
        inside_env=env.intersection(wallP)
        for n_,h,g in tall:
            if inside_env.intersection(g).area>0.05 and h>soffit-X['clear_over']: problems.append(('cross: line through a building',sv['line'],sv['dir'],n_,h))
        lines.setdefault(sv['line'],[]).append((sv,L,env))
    # stations: a straight stretch of every service of their lines, platforms clear of tall buildings, spaced along each service
    for sv in X['services']:
        L=LineString(sv['path']); pos=[]
        for st in X['stations']:
            if sv['line'] not in st['lines']: continue
            p=Point(st['at'])
            if L.distance(p)>0.5: continue
            s0=L.project(p); half=X['platform'][0]/2
            if s0-half<0 or s0+half>L.length: problems.append(('cross: platform runs off the line',st['name'],sv['dir'])); continue
            a_,c_=L.interpolate(s0-half),L.interpolate(s0+half)
            if abs(a_.distance(c_)-2*half)>0.05: problems.append(('cross: platform on a curve',st['name'],sv['dir']))
            w=X[sv['w']]
            sl=LineString([a_,c_])
            if 'toward' in st:
                offs=[sl.offset_curve(d) for d in (w/2+X['platform'][1],-(w/2+X['platform'][1]))]
                o=min(offs,key=lambda q:q.distance(Point(st['toward'])))
                seg=sl.buffer(w/2,cap_style=2).union(SP(list(sl.coords)+list(o.coords)[::-1] if Point(o.coords[0]).distance(Point(sl.coords[0]))<Point(o.coords[-1]).distance(Point(sl.coords[0])) else list(sl.coords)+list(o.coords)).buffer(0))
            else: seg=sl.buffer(w/2+X['platform'][1],cap_style=2)
            for n_,h,g in tall:
                if seg.intersection(g).area>0.05 and h>soffit-X['clear_over']: problems.append(('cross: platform into a building',st['name'],n_))
            pos.append((s0,st['name']))
        pos.sort(); sv['stops']=[n for _,n in pos]
        for (a_,na),(c_,nc) in zip(pos,pos[1:]):
            if c_-a_<X['min_gap']: problems.append(('cross: stations too close',sv['line'],na,nc,round(c_-a_,1)))
        for nm in X['junctions']:
            pass
    for st in X['stations']:
        if not any(LineString(sv['path']).distance(Point(st['at']))<0.5 for sv in X['services'] if sv['line'] in st['lines']): problems.append(('cross: station off its line',st['name']))
    # every service ends at the wall or at an interchange with the other cross line
    wall_names={x['name'] for x in WALL['stations']}
    for sv in X['services']:
        for end in (sv['stops'][0],sv['stops'][-1]):
            st=[x for x in X['stations'] if x['name']==end][0]
            if end not in wall_names and len(st['lines'])<2: problems.append(('cross: line ends at no interchange',sv['line'],end))
    # gate junctions: the line reaches the wall's centreline at the gate (on the level)
    for nm in X['junctions']:
        g=[x for x in WALL['gates'] if x['name']==nm][0]
        near=min((LineString(sv['path']).distance(wallP.exterior) for sv in X['services'] if Point(sv['path'][0]).distance(Point(g['p']))<45 or Point(sv['path'][-1]).distance(Point(g['p']))<45),default=1e9)
        if near>0.5: problems.append(('cross: line stops short of the wall at',nm,round(near,1)))
_cross_checks()
if '--wall' in sys.argv:
    print(WALL['length'],WALL['min_radius'],WALL['station_gaps']); [print(st) for st in WALL['stations']]
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
w("")
from gd_plan import lit
w("## The Deck at +6.5 m (city.md 6.2, 6a). runs: centrelines in world (x, z) with")
w("## a width; kind ring, walk or bridge (a skybridge spanning its street, no")
w("## columns). doors: [building, point on its face, what is there]. through:")
w("## indoor runs at +6.5 m [from building, to building, what]. ramps: towers by")
w("## the world's 32 degree ramp, head onto the Deck, foot onto the ground. lifts:")
w("## glass public lifts. columns: pairs at the run edges, out of street mouths and")
w("## park gates. Checked: on streets and squares only, never over a building, no")
w("## point more than max_to_way_down from a ramp or lift (now %.0f m)." % DECK['_far'])
w("const DECK := %s" % lit({k:v for k,v in DECK.items() if not k.startswith('_')}))
w("")
w("## The wall and the Wall Line (city.md 6c): the Ring Line's viaduct, its arches")
w("## filled, round the Rim Walk and the Works Ward. centreline: closed, world (x, z);")
w("## the wall is thick wide, height high, the trains on its top. gates, stations")
w("## (s: metres along the centreline), watch_posts, the car shed. Streets other than")
w("## the gate streets stop at the Rim Walk: the builder clips clipped streets to 203 m.")
w("const WALL := %s" % lit(WALL))
w("")
w("## The cross lines (city.md 6c): elevated at the Wall Line's level. services are")
w("## directional; path is the filleted track centreline. Where a service follows the")
w("## Deck it rides on the Deck's columns, directly above it.")
w("const CROSS := %s" % lit(CROSS))
w("")
w("## The towers' sites: the shaft's footprint and the public ground round it (city.md 7c).")
w("const TOWER_SITE := %s" % lit(TOWER_SITE))
w("## BLOCK's form (city.md 7c): recessed dark base, upper storeys out to the plot line, court, masts.")
w("const BLOCK_FORM := %s" % lit(BLOCK_FORM))
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
    json.dump(dict(streets=STREETS,opens=OPENS,lots=lots,courts=courts,buildings=[dict(b,angle=ANGLE.get(b['n'],0),corners=corners_of(b) if b['r'] else None,height=HEIGHTS.get(b['n'],0),crown=CROWNS.get(b['n']),form=FORMS.get(b['n'],'block'),part=TOWER_PART.get(b['n']),podium=PODIUM_HEIGHT.get(b['n']),site=TOWER_SITE.get(b['n'])) for b in B],hotel=HOTEL,storey=STOREY,park=PARK,turbines=TURBINES,precincts=PRECINCTS,estate=ESTATE,deck={k:v for k,v in DECK.items() if not k.startswith('_')},wall=WALL,cross=CROSS,block_form=BLOCK_FORM,lot_kits=LOT_KITS,building_kits=BUILDING_KITS),open(path,'w'))
print('wrote scripts/city_plan.gd:',len(STREETS),'streets,',len(B),'buildings,',len(lots),'lots,',len(courts),'courts')
