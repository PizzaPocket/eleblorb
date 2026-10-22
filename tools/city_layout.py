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
 ('Meridian Avenue','main',-359,-6,-318,6),
 ('Meridian North','avenue',-483,-38,-340,-30),
 ('Meridian South','avenue',-483,30,-340,38),
 ('West Street','main',-794,-6,-637,6),
 ('North Street','main',-566,-232,-554,-62),
 ('South Street','main',-566,62,-554,232),
 ('Arcade Street','shop',-694,-220,-686,220),
 ('Market Street','shop',-780,114,-487,122),
 ('Tank Lane','lane',-780,-122,-694,-118),
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
OMITTED_STREETS=[dict(name='Cinema Lane',kind='lane',rect=[-734,-220,-730,-122],reason='entire source rectangle lies outside the 203 m Rim Walk clip; no replacement alignment authorized')]
OPENS=[
 ('park',-625,-50,-495,50),
 ('Civic Plaza',-483,-30,-359,30),
 ('Library Square',-686,-30,-637,-6),
 ('Market Square',-590,122,-530,164),
 ('Estate Square',-554,-118,-516,-84),
 ]
B=[]
def b(n,name,r,kind,h,who=''): B.append(dict(n=n,name=name,r=r,kind=kind,h=h,who=who))
NB=lambda: 'homes (no one the hero meets)'
b(1,'Grand Hotel',(-483,-98,-431,-38),'civic','atrium block of 12 levels (44 m) round its void; cylinder guest tower of 28 levels (96 m), drum to 108 m (after John Portman)','Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work')
## (2026-10-17, at the user's direction: city hall moved into the Meridian Arch, section 8b. Revised again the same day:
## the three commercial blocks that briefly stood on the old Civic Plaza hid the Grand Hotel's front, so they and
## Meridian Walk and Hotel Passage are gone, and Civic Plaza runs the whole way from the park to City Hall: CIVIC_SQUARE)
b(3,'Library',(-686,-92,-641,-30),'civic','art deco limestone, renovated; the galleried Great Hall, 22 m, with a heritage room below (section 9)','Ada Fong, Nia Calder, Benji Okoro')
b(4,'Natural history museum',(-637,62,-575,100),'civic','3 storeys, top-lit hall','Dr. Imani Osei (curator)')
b(5,'Moonlight Cinema',(-730,6,-700,34),'civic','2 storeys, built later into the old town; flat above','Leon Duarte (lives above)')
b(6,'Police box',(-652,6,-646,14),'civic','1 storey, back room','Kate Byrne')
b(7,'Clinic',(-712,62,-698,80),'civic','3 storeys; flat above','Dr. Arjun Mehta (lives above)')
b(8,'Primary school',(-664,122,-641,152),'civic','3 storeys, roof playground','Yuki Hayashi (teacher); Lily, Kofi')
b(9,'Tea house',(-618,24,-604,36),'civic','1 storey; flat above and keeper\'s room behind','Old Fu (keeper); Kenji Mori (above)')
b(10,'Park lodge',(-552,41,-542,49),'civic','1 storey','Orin Pike (park keeper)')
b(11,'Giant playground',None,'play','climbing towers 12–20 m','Lily, Kofi')
b(12,'Windspire',(-431,-80,-389,-38),'tower','about 70 storeys, 280 m, on a podium','the Windworks (headquarters, observation deck); its legal department (Priya Raman, Elizabeth Reese, Venn Harlow)')
b(13,'BLOCK tower',(-483,38,-443,78),'tower','about 38 storeys to 150 m, a blade crown to 212 m, windowless (section 7c)','BLOCK\'s headquarters and laboratories; Dr. Vera Kask (director, the top floors)')
b(14,'North tower',(-483,-142,-443,-102),'tower','about 45 storeys, 175 m, on a podium','start-up floors (Theo Park)')
b(15,'South tower',(-483,102,-443,142),'tower','about 40 storeys, 150 m, on a podium','flats over offices; Tanglewire (Dan)')
b(17,'Block 1',(-674,-143,-660,-109),'estate','slab block, 28 storeys, west side of the west court, turned 30° off the grid','Tomas Wren')
b(18,'Block 2',(-547,-184,-511,-166),'estate','slab block, 32 storeys, north side of the east court, turned 30° off the grid','Siti Rahman')
b(19,'Block 3',(-512,-94,-487,-62),'estate','broad point block, 36 storeys, on the Park Ring','Juno Rell (20th floor)')
b(20,'Block 4',(-643,-131,-621,-111),'estate','twin broad point block, 40 storeys, turned 30° off the grid; sky bridge and sky garden at the 26th floor',NB())
b(21,'Block 5',(-615,-147,-593,-127),'estate','twin broad point block, 40 storeys, turned 30° off the grid','Dr. Imani Osei and Kofi')
b(22,'Block 6',(-635,-78,-568,-62),'estate','slab block, 14 storeys, shops in its void deck on the Park Ring',NB())
b(23,'Hawker centre',(-554,-82,-516,-62),'civic','1 storey, open-sided, on the Park Ring and Estate Square','Siti\'s laksa stall')
b(24,'Garden Row',(-660,40,-637,58),'home','3 townhouses, 3 storeys, facing the Park Ring','Teodora Vance; Ada Fong and Sora Ishida; Priya Raman')
b(25,"Sol's café",(-752,34,-737,44),'shop','old tower house, 5 storeys; flat above','Sol Brant')
b(26,'Bakery',(-730,-22,-720,-6),'shop','old tower house, 6 storeys; flats above','Felix Tanaka (above)')
b(27,"Pinestein's building",(-716,-118,-707,-102),'shop','old tower house, 9 storeys; his top-floor flat, antennas and coils on the roof beside its wind tower, where he watches BLOCK (his laboratory is in BLOCK\'s base, 2026-10-18)','Palbert Pinestein (top floor)')
b(28,"Mara's building",(-716,-58,-707,-42),'shop','8 storeys; rooftop studio','Mara Quill')
b(29,"Benji's building",(-686,40,-678,56),'shop','6 storeys','Benji Okoro')
b(30,"Theo's building",(-730,62,-722,78),'shop','6 storeys','Theo Park')
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

## The Well Quarter (city.md 7, Old Moy; revised 2026-10-17 at the user's
## direction). Two blocks of the well town, north and south of West Street, keep
## the roads that were there before the grid: the **Old High Street**, the
## caravan road that ran past the first well and on north-east toward the
## plateau (Clinic Lane now cuts off its southern end), and **Mara's Lane**, a short old branch from it to the
## east. That is all: the boom's grid (West Street, Arcade Street, Tank Lane,
## Clinic Lane, Market Street) was laid round and across them, so the old roads
## meet the grid at odd angles, as Broadway and Greenwich Village's lanes meet
## Manhattan's grid, and Barcelona's old town meets the Eixample. The blocks come
## first: every block is bounded by roads, its houses stand in a perimeter row
## facing them, each on a plot of a real house's width and depth, and the middle
## of the block is shared courtyards (after Dubai's Al Fahidi quarter, whose
## wind-tower houses close round courts behind their lanes). Inside a block
## there are no lanes. The Old High Street is a swing route 6 m wide between
## tall houses, through Cinema Square where the first well stands.
## interiors: the blocks the quarter owns (world rects, cut to the built circle);
## lanes: centrelines (x, z) with a width; squares: polygons; plot: a house's
## depth, its frontage range, and the least area and side a house can stand on.
OLD_TOWN=dict(
 interiors=[('north',(-780,-118,-694,-6)),('south',(-780,6,-694,58)),('cistern',(-780,62,-694,114))],
 lanes=[
  # north of West Street, from the well square to Arcade Street, bending past Mara's building
  dict(name='Old High Street',w=6.0,swing=True,pts=[(-746,-6),(-741,-30),(-729,-50),(-718,-70),(-706,-84),(-694,-90)]),
  # south of the square, between the cinema and Sol's café, down to Clinic Lane, where the grid cut it off
  dict(name='Old High Street (south)',w=6.0,swing=True,pts=[(-735,26),(-733.5,34),(-733.5,44),(-728.5,52),(-726.5,60)]),
  dict(name='Mara\'s Lane',w=5.0,pts=[(-725,-58),(-712,-61.5),(-694,-63)]),
 ],
 squares=[
  dict(name='Cinema Square',well=(-743,20),pts=[(-752,6),(-734,6),(-731,16),(-734,30),(-739,34),(-751,33),(-754,24),(-755,12)]),
 ],
 legacy_max=3,swing_min=(5,16.0),anchor=(12.0,52.0,7.0),
 plot=dict(depth=14.0,w=(6.0,10.0),min_area=30.0,min_side=4.5,convex=0.8),
)
def _old_town_raster():
    from shapely.geometry import LineString, Polygon, Point, box as sbox
    lanes=[LineString(l['pts']).buffer(l['w']/2,cap_style=2,join_style=2) for l in OLD_TOWN['lanes']]
    sq=[Polygon(q['pts']) for q in OLD_TOWN['squares']]
    inner=[sbox(*r) for _,r in OLD_TOWN['interiors']]
    cs=set(); so=set(); si=set()
    for x in range(-800,-680):
        for z in range(-130,116):
            c=Point(x+0.5,z+0.5)
            if any(g.contains(c) for g in lanes): cs.add((x,z))
            elif any(g.contains(c) for g in sq): so.add((x,z))
            elif any(g.contains(c) for g in inner): si.add((x,z))
    return cs,so,si
OT_STREET,OT_OPEN,OT_INNER=_old_town_raster()
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
street|=OT_STREET; opn|=OT_OPEN
# the Well Quarter's insides are not grid blocks: the generator below fills them
def free(p): return inside(*p) and p not in street and p not in opn and p not in OT_INNER
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
 'Bea Ho':35,'Wilfred Ho':35,'Lily Chan':34,'Kofi Osei':21,'Palbert Pinestein':27,'Vera Kask':13,
 'Omar Haddad':40,'Rafael Ortiz':42,
}
## Heights (m, to the main roof) and crowns of the numbered buildings, and
## the plan forms of the towers (city.md 7c, 8): one source for the plan, the
## skyline and the elevations.
HEIGHTS={1:96,3:22,4:16,5:9,6:4,7:11,8:12,9:4,10:4,12:262,13:150,14:175,15:150,16:22,
 17:91,18:104,19:117,20:130,21:130,22:46,23:6,24:11,25:17,26:20,27:29,28:26,29:20,30:20,31:20,
 32:23,33:9,34:26,35:72,36:42,37:17,38:7,39:6,49:52,50:110,51:8,52:23,53:78,40:8,41:4,42:6,43:35,44:3}
CROWNS={1:108,3:26,12:280}
## Plan forms: twist (a rounded triangle turning as it rises), screen (round-
## cornered square in a screen), capsule (core with plug-in capsules), dune
## (rippling balconies), atrium (the Grand Hotel: an atrium block with a
## cylinder tower, whose rect is TOWER_PART; see HOTEL).
FORMS={12:'twist',13:'monolith',14:'capsule',15:'dune',1:'atrium'}
## Sub-footprints that rise above their building's podium: the hotel's guest
## tower (the square round its cylinder) and city hall's clock tower.
TOWER_PART={1:(-471,-98,-443,-70)}
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
 'skybridge':{'x':(-6,0),'z':(46,52)},   # (2026-10-17) west across the Park Ring to the Park Deck; Civic Plaza now open in front
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
## (revised 2026-10-16) The park is shared: the Crossing, the city's station, at
## its centre where the two lines cross; the giant playground moved whole to the
## south-east quarter at 0.55 scale; the dry garden, the pond, the green and the
## tea house's parasols round them; the approved real shade trees serve the park.
PG_C=(-515,31); PG_K=0.55
def _pg(x,z): return (round(PG_C[0]+(x+560)*PG_K,2),round(PG_C[1]+z*PG_K,2))
PARK={
 'rect':(-625,-50,-495,50),
 'walks':[(-625,-3,-495,3),(-563,-50,-557,50)],
 # Allocation/search envelope only; visible curved outline and trail are PARK.kit.dry_garden.
 'dry_garden':(-620,-45,-583,-6),
 # the reed pond (revised 2026-10-18, at the user's direction: in the third pass its water stood 0.4 m above the park's
 # ground, on a bespoke near-opaque shader, so it hovered over its banks and could not be seen into). Water lies below
 # the ground, as water does: its surface 0.3 m under the park, its edge the ellipse r, a shelving bank rising from the
 # waterline to the park's ground at bank_top (times r), a reed shelf round the edge, the bed falling to depth at the
 # middle (bed: [fraction of r, height over the park's ground], from the bank's top to the middle). Built with the
 # world's one water: VillageWorks.water_material() (two-sided, translucent, the same as every village pond), marked a
 # hazard, its surface and depth on the liquid queries; the paving stops at the bank's top.
 'pond':{'c':(-516,-28),'r':(16.5,13),'surface':-0.3,'bank_top':1.15,
         'bed':[[1.15,0.0],[1.0,-0.3],[0.86,-0.65],[0.6,-1.5],[0.3,-2.0],[0.0,-2.1]],
         'water':'VillageWorks.water_material(): the shared two-sided translucent water; CollisionPolicy hazard; meta water_surface_y and water_depth; terrain liquid queries from this surface and bed',
         'bank':'shelving earth under reeds and flat stones, no wall; the paving and the lawn stop at the bank\'s top'},
 'lawn':(-551,22,-535,38),
 'parasols':[(-612,12),(-598,14),(-586,22),(-596,32),(-584,40),(-612,44)],
 'playground':{'c':PG_C,'scale':PG_K,'track':(round(24*PG_K,2),round(28*PG_K,2)),
   'towers':[_pg(x,z)+(h,round(r*PG_K+0.6,2),nm) for x,z,h,r,nm in [(-560,0,20,4.5,'Lookout'),(-548,-7,16,3.5,''),(-574,-4,14,3.2,''),(-560,14,12,3,'')]],
   'perches':[_pg(x,z) for x,z in [(-566,18),(-554,18),(-560,21)]],'perch_height':12,
   'hoops':[list(_pg(-560+(9+i*1.6)*math.cos(-math.pi/2+i*0.75),(9+i*1.6)*math.sin(-math.pi/2+i*0.75))) for i in range(8)]},
 # the park's trees (2026-10-17, replacing the four steel wind trees): from the plant kit (NatureProps), each with a job.
 # kind: round (a ghaf, the desert's shade tree), flowering (a flame tree, Singapore's), palm (a date palm), banyan (one
 # great banyan by the pond, on reclaimed water). c: the trunk; h: the height. Crowns and trunks follow the kit's
 # proportions (TREE_KIT); every crown keeps clear of the Deck, the Crossing Ring, the towers and the high line's piers.
 'trees':[
  # the pond: the banyan on its north-west bank, its crown over the water, the place to sit in shade by the water
  dict(kind='banyan',c=(-530,-40),h=13,job='shade over the pond\'s bank'),
  dict(kind='round',c=(-507,-14),h=9,job='shade on the pond\'s east bank'),
  dict(kind='round',c=(-512,-9),h=8,job='shade on the pond\'s east bank'),
  dict(kind='round',c=(-502,-44),h=9,job='screens the Park Ring from the pond'),
  # the playground: ghafs round its rim, shading the parents' benches
  dict(kind='round',c=(-535,44),h=10,job='shade for the playground\'s benches'),
  dict(kind='round',c=(-501,13),h=9,job='shade for the playground\'s benches'),
  dict(kind='round',c=(-524,13),h=9,job='shade for the playground\'s benches'),
  # the tea house and the chess terrace: flame trees over the tables
  dict(kind='flowering',c=(-600,44),h=9,job='shade over the chess terrace'),
  dict(kind='flowering',c=(-590,26),h=9,job='shade over the parasols'),
  dict(kind='flowering',c=(-618,14),h=9,job='shade at the tea house\'s door'),
  # the dry garden: a loose group of date palms among the rocks and agave
  dict(kind='palm',c=(-610,-36),h=12,job='the dry garden\'s oasis'),
  dict(kind='palm',c=(-602,-41),h=11,job='the dry garden\'s oasis'),
  dict(kind='palm',c=(-616,-42),h=12,job='the dry garden\'s oasis'),
  dict(kind='palm',c=(-614,-26),h=10,job='the dry garden\'s oasis'),
  dict(kind='palm',c=(-598,-29),h=11,job='the dry garden\'s oasis'),
  # the cross walk east and west of the Crossing: an allee of date palms under the high line
  ]+[dict(kind='palm',c=(-560+x_,z_),h=12,job='the cross walk\'s allee under the high line') for x_ in (-52,-40,40,52) for z_ in (-6.5,6.5)],
}
## The plant kit's proportions (scripts/nature_props.gd), as fractions of a tree's height: the clear trunk under the
## crown, and the crown's radius. Used by the checks and the drawings.
TREE_KIT=dict(round=dict(trunk=0.4,crown=0.4),flowering=dict(trunk=0.4,crown=0.4),palm=dict(trunk=0.72,crown=0.3),banyan=dict(trunk=0.42,crown=0.6))
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
 13:dict(shaft=(-475,47,-449,71),ground=[
   ('court',(-483,38,-443,47),'BLOCK\'s forecourt on Meridian South: bare pale paving in full sun, no bench, no tree, and the one door'),
   ('gravel',(-483,47,-475,78),'black gravel, raked every morning, that no one walks on'),
   ('gravel',(-475,71,-443,78),'black gravel on the neighbours\' side')]),
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
## The BLOCK tower's form (city.md 7c, revised 2026-10-16: the BLOCK labs became mid-rise
## real estate, and everything of BLOCK's, Pinestein's sealed lab included, is in the tower).
## BLOCK's silhouette (city.md 7c, revised 2026-10-17 at the user's direction:
## more menacing than a flat top, but its own crown, and drawn inward, never out
## over its neighbours). The shaft rises sheer to shaft_top; above it the four
## faces fold inward to a knife-edge ridge, set close to the plaza face: the
## plaza face rises almost sheer and the back falls away in one long slope, so
## from Civic Plaza the crown is a tall narrowing blade and from the side a
## wedge raised toward the plaza, all inside its own footprint. Its one light is
## a single vertical slit, azure, in the crown's plaza face: an eye with a
## slit pupil. The ridge is canted, off-centre to the west and falling to the
## east, so the blade reads as raised and turned, not a symmetrical obelisk.
## ridge: its insets from the west and east faces and its front and back insets
## from the plaza (north) face; top: the ridge's west and east heights; fins:
## dark ribs continuing the shaft's slits up the folding faces to the ridge.
BLOCK_TOWER=dict(base=(4.0,9.0),door=(-461,47),vents=[0.3,0.55,0.8],vent=(1.4,4.5),slit=(0.35,4.0),masts=0,mast=10.0,
  shaft_top=150.0,crown=dict(top=212.0,top_east=198.0,ridge=dict(x_west=5.0,x_east=10.0,z_front=3.0,z_back=5.0),fins=True),
  eye=dict(face='north',w=1.2,y=(168.0,192.0)),
  colour='blue-black glazed brick with an azure sheen at a low sun',
  crown_note='a crown folded inward to a knife-edge ridge leaning toward Civic Plaza, with one vertical azure slit in its plaza face: the only light')
## Inside the BLOCK tower: package P17 (moy_pkg_P17.md, user, 2026-10-18). The tower's story runs
## through it (user, 2026-10-18: a really simple storyline): the hero climbs the vent hoods from the
## east neighbour, sneaks in through the one open louvre at the 55% ring, rides the lift up to the
## hollow crown, fights the blorb mech there in front of Kask and Pinestein, and rides the lift down to
## the lobby to walk out of the one door. Three places are built: the plant floor behind the louvre,
## the lobby and the crown. Every other storey is solid mass inside the shell, never entered; the lift
## passes them without stopping.
## floors: storeys from the forecourt (L0), shaft_top/floors each; zones: (key, first level, last
## level, what), what each storey is, built or not, levels below 0 under the forecourt; built: the
## zones that are built and entered (the crown is always built: the arena, storey `floors`); core and
## lab: world rects (the lab is not entered in this build); lifts: each one's world (x, z) and stops;
## louvre: the vent ring and face it opens in, and its world coordinate along that face; approach:
## the neighbour the climb starts from (a lot's world rect) and the gap the hero leaps; arena: the
## crown's floor and the glass gallery on its back slope (world z range and floor height).
BLOCK_TOWER['inside']=dict(floors=38,
  zones=[('lab',-2,-1,'Pinestein\'s lab, sealed: a double-height vat hall of synthetic slime, blorb tanks, his bench beside Kask\'s'),
         ('base',0,1,'the lobby: bare and double height, kept by machines; the one door, shut from outside, opens from within'),
         ('stacks',2,10,'the stacks: machine floors, rows of humming cabinets, no people'),
         ('plant',11,11,'plant floor behind the 30% vent ring'),
         ('growing',12,19,'the growing floors: tanks where city blorbs are grown from synthetic slime, pens of new ones'),
         ('way in',20,20,'plant floor behind the 55% vent ring: the way in'),
         ('hangar',21,29,'the hangar: three tall bays where the mech is built and tested, spare glass heads on racks'),
         ('plant',30,30,'plant floor behind the 80% vent ring'),
         ('records',31,34,'the upper stacks: machine-kept records'),
         ('kask',35,37,'Kask\'s floors: her flat, sparse and dark, and the control room under the crown')],
  built=['way in','base'],
  core=(-462,57,-455,64), lab=(-473,49,-451,69),
  lifts=dict(lift=dict(at=(-458.5,60.5),stops=[0,20,38],what='the one lift: the lobby, the way in, the crown; it passes every other storey without stopping')),
  louvre=dict(ring=0.55,face='east',at=55.0),
  approach=dict(rect=(-443,38,-429,58),storeys=34,gap=6.0),
  arena=dict(floor=150.0,gallery=dict(z=(61.0,66.0),y=164.0)))
def _block_checks():
    BT=BLOCK_TOWER; sh=TOWER_SITE[13]['shaft']; C=BT['crown']; rg=C['ridge']; E=BT['eye']
    w_,d_=sh[2]-sh[0],sh[3]-sh[1]
    # inward only: the ridge lies inside the shaft's footprint, so nothing reaches over the neighbours
    if not (0<rg['x_west'] and 0<rg['x_east'] and rg['x_west']+rg['x_east']<w_-4 and 0<=rg['z_front']<rg['z_back']<d_): problems.append(('block: the crown reaches past its shaft',))
    if not (BT['shaft_top']<C['top_east']<C['top']): problems.append(('block: the ridge is not canted',))
    # it leans toward the plaza: the ridge sits in the plaza-side third
    if rg['z_back']>d_/3: problems.append(('block: the crown does not lean toward Civic Plaza',))
    if not (BT['shaft_top']==HEIGHTS[13]<C['top']): problems.append(('block: the crown is out of order',))
    if C['top']>=HEIGHTS[12]: problems.append(('block: the crown outreaches the Windspire',C['top']))
    if not (BT['shaft_top']<E['y'][0]<E['y'][1]<C['top']): problems.append(('block: the eye is not in the crown',))
    # the eye fits on the plaza face's width at its top
    f=(E['y'][1]-BT['shaft_top'])/(C['top_east']-BT['shaft_top'])
    span=w_-(rg['x_west']+rg['x_east'])*f
    if E['w']>span-2.0 or E['y'][1]>=C['top_east']: problems.append(('block: the eye does not fit the crown face',))
    plaza=[o_ for o_ in OPENS if o_[0]=='Civic Plaza'][0]
    if not (E['face']=='north' and plaza[4]<=sh[1]): problems.append(('block: its eye does not look at Civic Plaza',))
    # inside (P17): the zones fill every storey from the lab to the crown, once each
    I=BT['inside']; st=BT['shaft_top']/I['floors']; lv=[]
    for z_ in I['zones']: lv+=list(range(z_[1],z_[2]+1))
    if lv!=list(range(I['zones'][0][1],I['floors'])): problems.append(('block: the inside\'s zones leave a gap or overlap',))
    # each vent ring opens onto a plant floor
    for f in BT['vents']:
        y=f*BT['shaft_top']; z_=[z for z in I['zones'] if z[1]*st<=y<(z[2]+1)*st]
        if not z_ or z_[0][0] not in ('plant','way in'): problems.append(('block: a vent ring has no plant floor behind it',f))
    if I['louvre']['ring'] not in BT['vents']: problems.append(('block: the open louvre is not on a vent ring',))
    if not (sh[1]+3<I['louvre']['at']<sh[3]-3): problems.append(('block: the open louvre is off its face',))
    inside=lambda r: sh[0]<r[0]<r[2]<sh[2] and sh[1]<r[1]<r[3]<sh[3]
    if not (inside(I['core']) and inside(I['lab'])): problems.append(('block: the core or the lab is outside the shaft',))
    # built: only named zones; the way in is the storey the louvre opens onto
    keys=[z[0] for z in I['zones']]
    if any(b not in keys for b in I['built']): problems.append(('block: a built place is not a zone',))
    wz=[z for z in I['zones'] if z[0]=='way in'][0]
    if not (wz[1]*st<=I['louvre']['ring']*BT['shaft_top']<(wz[2]+1)*st): problems.append(('block: the way in is not behind the open louvre',))
    # the lift: a 2.2 m car in the core; it stops only at built storeys (the crown is storey `floors`), and joins the way in to the crown and the lobby
    zone=lambda n: [z for z in I['zones'] if z[1]<=n<=z[2]][0]
    for nm,l in I['lifts'].items():
        lx,lz=l['at']
        if not (I['core'][0]+1.1<lx<I['core'][2]-1.1 and I['core'][1]+1.1<lz<I['core'][3]-1.1): problems.append(('block: a lift is not in the core',nm))
        if any(n!=I['floors'] and zone(n)[0] not in I['built'] for n in l['stops']): problems.append(('block: a lift stops at a storey that is not built',nm))
    stops=set(n for l in I['lifts'].values() for n in l['stops'])
    if not {wz[1],I['floors'],0}<=stops: problems.append(('block: no lift joins the way in, the crown and the lobby',))
    # the climb: the neighbour stands the gap off the face the louvre opens in, and is tall enough to reach the first ring
    A=I['approach']
    if I['louvre']['face']!='east' or abs(A['rect'][0]-sh[2]-A['gap'])>0.01 or A['gap']>7: problems.append(('block: the climb\'s leap is not the planned gap',))
    if not [l for l in lots if tuple(l[:4])==tuple(A['rect']) and l[4]==A['storeys']]: problems.append(('block: the climb\'s neighbour is not a lot',A['rect']))
    if A['storeys']*STOREY['midrise']<BT['vents'][0]*BT['shaft_top']: problems.append(('block: the climb\'s neighbour is lower than the first ring',))
    G=I['arena']['gallery']
    if not (sh[1]+rg['z_back']<G['z'][0]<G['z'][1]<sh[3] and BT['shaft_top']<G['y']<C['top_east']): problems.append(('block: the gallery is outside the crown',))

## Civic Plaza, the grand square (city.md 8a.1, 2026-10-17, at the user's direction): the whole space from the park to
## City Hall, 124 by 60 m between Meridian North and Meridian South, after Washington's National Mall and Tiananmen
## Square. One axis runs from the Park Deck to the Rostrum on City Hall: a long water mirror under the high line, its
## tree piers standing in the water; lawns either side; a cross-axis on the Grand Hotel's door with a fountain in each
## lawn; then an open paved forecourt for gatherings before City Hall, with the City Steps rising to its Rostrum. The
## hotel faces the square across Meridian North with nothing in front of it but lawn and water. Monuments and statues
## are sites only: their subjects are open (world bible, Open threads). Plan rectangles are world (x0, z0, x1, z1).
CIVIC_SQUARE=dict(
  rect=(-483,-30,-359,30), axis=0.0,
  mirror=dict(rect=(-476,-4,-404,4),depth=0.4,why='reclaimed water, recirculated; it doubles the high line and City Hall, and cools the square'),
  walks=dict(axis=(-483,-8,-359,8),edges=[(-483,-30,-359,-24),(-483,24,-359,30)],why='pale stone; the axis walks either side of the water'),
  lawns=[dict(name='north lawn',rect=(-476,-24,-404,-8)),dict(name='south lawn',rect=(-476,8,-404,24))],
  cross_axis=dict(x=(-461,-453),why='the Grand Hotel\'s door at x -457: a walk across each lawn from Meridian North to the water'),
  fountains=[dict(name='hotel fountain',c=(-457,-16),r=4.5),dict(name='south fountain',c=(-457,16),r=4.5)],
  # shade trees in rows along the square's long edges, after the Mall's elms; none in front of the hotel's facade
  tree_rows=[dict(z=-27,x=(-428,-404),every=8.0,kind='round',h=9.0),dict(z=27,x=(-476,-404),every=8.0,kind='round',h=9.0)],
  forecourt=dict(rect=(-404,-30,-359,30),why='open paving before City Hall, where the city gathers to face its Rostrum'),
  monuments=[dict(name='west monument',c=(-480,0),size=(5,10),h=5.0,suggest='a bronze caravan walking east up the axis, for the caravan road the city grew on (subject open)'),
             dict(name='east monument',c=(-398,0),size=(6,6),h=3.0,suggest='a low memorial under the high line at the water\'s end, for the Wall Watch (subject open)')],
  statues=[dict(c=(x,z)) for x in (-472,-440,-424,-408) for z in (-9.5,9.5)],
  flagstaffs=[dict(c=(-375,-10),h=22.0),dict(c=(-375,10),h=22.0)],
)
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
  # the hotel bridge (revised 2026-10-17, with Civic Plaza opened to the park): the civic walk along Meridian Walk is gone
  # with the walk itself, so the square stays open to the sky; the Grand Hotel's mezzanine meets the Park Deck instead,
  # by a short glazed bridge west across the Park Ring
  dict(name='Hotel skybridge',kind='bridge',w=6,pts=[(-489,-49),(-483,-49)]),
  # to the library's east-wing door, over Garden Walk's mouth
  dict(name='Library walk',kind='walk',w=6,pts=[(-631,-27),(-648,-27)]),
  # under the Spine Line from the Park Deck's north and south sides, across the Crossing Ring, to the Crossing's
  # two cross-bridges (revised 2026-10-17: the middle is left open, from the lawn to the sky)
  dict(name='Spine walk north',kind='walk',w=6,pts=[(-560,-50),(-560,-13)]),
  dict(name='Spine walk south',kind='walk',w=6,pts=[(-560,13),(-560,50)]),
  # the Crossing Ring: the station's concourse at the Deck's level, a garden walk round the four towers (CROSSING)
  dict(name='Crossing Ring',kind='ring',w=8,pts=[(round(-560+28.7*math.cos(math.radians(a_)),2),round(28.7*math.sin(math.radians(a_)),2)) for a_ in range(0,361,10)]),
  # the cross-bridges: tower to tower under the Spine's head beams, hung from them, crossing under the Spine's tracks
  dict(name='Crossing bridge north',kind='bridge',w=6,pts=[(-567,-13),(-553,-13)]),
  dict(name='Crossing bridge south',kind='bridge',w=6,pts=[(-567,13),(-553,13)]),
  # up the east half of North Street to the neighbourhood centre's roof garden
  dict(name='Estate walk',kind='walk',w=6,pts=[(-560,-56),(-560,-121)]),
  dict(name='Neighbourhood centre bridge',kind='bridge',w=6,pts=[(-560,-121),(-554,-121)]),
  # down the east half of South Street, then along Market Square's north edge to the wet market's upper hall
  dict(name='Market walk',kind='walk',w=6,pts=[(-560,56),(-560,125),(-530,125)]),
 ],
 # where the Deck meets a building at +6.5 m: (building, point on its face, what is there)
 'doors':[
  (1,(-483,-49),'the hotel\'s Deck door, on its west side, into the mezzanine gallery'),
  (3,(-645,-30),'the library\'s east-wing door to the first gallery'),
  (51,(-554,-120),'the neighbourhood centre\'s roof garden'),
  (33,(-530,125),'the wet market\'s upper hall'),
 ],
 # indoor runs at +6.5 m that carry the Deck through a building
 'through':[(1,12,'the hotel mezzanine\'s east gallery through the party wall to the Windspire\'s lobby')],
 # ramp towers: centre, radius, the side its head opens onto the Deck and the side its foot opens onto the ground
 'ramps':[
  # (the park's north and south gate towers are retired, 2026-10-17: the Deck now runs on the street's centre line
  # over the park walk, and the Crossing's four towers take the park's people between the lawn and the Deck)
  dict(name='West gate',c=(-621,8),r=4,head='w',foot='n'),
  dict(name='East gate',c=(-499,-8),r=4,head='e',foot='s'),
 ],
 # the Crossing's four towers are ways down from the ring and the cross-bridges (CROSSING['towers'])
 'spiral_ways':[(-547.0,-13.0),(-573.0,-13.0),(-547.0,13.0),(-573.0,13.0)],
 # the Deck as a garden walk, after New York's High Line and Singapore's park connectors: planting beds alternate from
 # side to side so a path winds between them; a small tree in a deep planter over every second column pair, where the
 # structure can carry the soil. bed: its width range and its length range; path: the clear width it always leaves.
 'garden':dict(path=3.2,bed=(1.2,2.4),bed_len=(9.0,15.0),gap=3.0,tree_every=2,tree=dict(kind='round',h=6.0),
   planting=['bougainvillea','desert grasses','agave and aloe','coral vine'],keeper='Orin Pike (park keeper)',
   collision='bed edges and planters solid, 0.45 m (a sitting edge); plants decorative'),
 'lifts':[dict(name='Park north gate',c=(-555.4,-46),r=1.6),dict(name='Park south gate',c=(-555.4,46),r=1.6),dict(name='Estate Square',c=(-555.4,-112),r=1.6),dict(name='Market Square',c=(-533,129.7),r=1.6)],
 'max_to_way_down':75.0,'min_soffit':5.4,'min_open_beside':4.0,
 # escalating ramps from a square up to the Deck (revised 2026-10-17 after the first prototype: the 12 degree
 # travelators ran 31 m and stood in the squares as long obstructions; these are escalator pairs at 30 degrees,
 # an up and a down side by side, 11.3 m long, set end-on into the Deck's edge). The park's two wing ramps to
 # the Crossing are gone: the Crossing's towers serve it.
 'escalators':[
  # (revised 2026-10-17) two pairs down from the Park Deck's east side into Civic Plaza, either side of its axis
  dict(name='Civic Plaza north',foot=(-477.7,-14),head=(-489,-14)),
  dict(name='Civic Plaza south',foot=(-477.7,14),head=(-489,14)),
  dict(name='Market Square',foot=(-545,139.3),head=(-545,128)),
  dict(name='Estate Square',foot=(-545.7,-104),head=(-557,-104)),
 ],
 'esc_angle':30.0,'esc_w':3.2,
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
    feats=[sbox(*PARK['dry_garden']),sbox(*PARK['lawn']),pond]+[Point(t['c']).buffer(1.5) for t in PARK['trees']]+[Point(t).buffer(2.5) for t in PARK['parasols']]
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
    heads+=[Point(q) for q in D.get('spiral_ways',[])]
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
        # bridges span; the Crossing Ring stands on the Crossing's own supports (CROSSING); the Park Deck has columns
        if run['kind']=='bridge' or run['name']=='Crossing Ring': continue
        for a,c in zip(run['pts'],run['pts'][1:]):
            ux,uz=(c[0]-a[0]),(c[1]-a[1]); L=math.hypot(ux,uz); ux/=L; uz/=L
            mid=Point((a[0]+c[0])/2,(a[1]+c[1])/2); ew=abs(ux)>abs(uz)
            bad=unary_union([g for o,e,g in keep if not (e==ew and o.buffer(0.5).contains(mid))])
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
    # inside the Crossing the Deck stands on the Crossing's own supports (its towers and ring supports), not the rhythm
    cc=Point(CROSSING['c'])
    cols=[q for q in cols if cc.distance(Point(q))>CROSSING['ring'][1]+0.5]+[tuple(q) for q in CROSSING['_ring_supports']]
    D['columns']=sorted(set(cols))
    # escalating ramps: the run their 12 degree slope needs, foot on open ground, head end-on at the Deck's edge
    need=D['level']/math.tan(math.radians(D['esc_angle']))
    for e in D['escalators']:
        (fx,fz),(hx,hz)=e['foot'],e['head']; run=math.hypot(hx-fx,hz-fz)
        if run<need-0.5: problems.append(('deck: escalating ramp too short for its rise',e['name'],round(run,1),round(need,1)))
        g=LineString([e['foot'],e['head']]).buffer(D['esc_w']/2,cap_style=2)
        if g.difference(ground).area>0.5: problems.append(('deck: escalating ramp off the squares',e['name']))
        for n_,bg in bldg:
            if g.intersection(bg).area>0.05: problems.append(('deck: escalating ramp on a building',e['name'],n_))
        if deck.distance(Point(e['head']))>0.6: problems.append(('deck: escalating ramp does not reach the Deck',e['name']))
        if deck.buffer(-0.5).contains(Point(e['foot'])): problems.append(('deck: escalating ramp foot under the Deck',e['name']))
        for t in D['ramps']+D['lifts']:
            if g.distance(Point(t['c']))<t['r']+1.0: problems.append(('deck: escalating ramp against a tower or lift',e['name'],t['name']))
        e['run']=round(run,1)
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
_site_checks()
## The wall and the Wall Line (city.md 6c, proposed 2026-10-14). The Ring Line
## came first: a double-track viaduct round the city's edge, built in the boom.
def market_lane_xy(x,z):   # the market lanes' extent, out to the wall (market_lane() stops at the Rim Walk)
    return x<=-487 and (z>=114 or (z>62 and x>-641))
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
 'gates':[dict(name='East Gate',street='Meridian Avenue',axis='x',at=0.0,arch=(24.0,10.0),along=60.0,out=5.0,building='arch'),
          dict(name='North Gate',street='North Street',axis='z',at=-560.0,arch=(10.0,8.0)),
          dict(name='South Gate',street='South Street',axis='z',at=-560.0,arch=(10.0,8.0)),
          dict(name='West Gate',street='West Street',axis='x',at=0.0,arch=(20.0,10.0),along=52.0,out=7.0,building='towers')],
 'gatehouse':dict(along=44.0,out=12.0),
 # halts between the gates, each on its own bastion over the lane it serves
 'halts':[],
 'platform':(40.0,3.0),'watch_every':120.0,'watch_r':7.0,
 # the watch posts are Xi'an's bastions (mamian): rectangular, 20 m along the wall and 10 m out
 'post':dict(along=20.0,out=10.0,height=14.0),
 # the Ring Line's arches, after Tokyo's gado-shita: only the outer half of each was filled, so the inner half opens on the
 # Rim Walk as a room 5 m deep under a 6.5 m arch; bays of 9 m, the arches kept clear of the gates and the Line House
 'arches':dict(bay=9.0,span=6.5,rise=5.5,depth=5.0),
 # the Arches: the reopened run on the market lanes' south edge (the venue for the fight club and the rave)
 'venue':dict(name='the Arches',s=(254.0,300.0),min_bays=5,depth=10.0,
              nights=dict(fight='Tuesday and Friday: the fight club, a ring in the middle bay, a crowd standing round it; the fighting blorbs fight here',
                          rave='Saturday: the rave, from late till dawn, lights and music through the whole run'),
              program='one long vaulted hall: a ring that is struck on rave nights, a bar in the east bay, a booth in the west; on other days shut, its shutters down',
              after='the railway-arch clubs and boxing gyms under London\'s viaducts; Tokyo\'s gado-shita'),
 # the gate towers: Jiayuguan's tiered towers on the gatehouse's outer corners, in Moy's tile
 'gate_tower':dict(base=7.0,tiers=3,tier=3.2),
 'rail':13.2,  # the Wall Line's rail head: the wall's top (12 m) and its 1.2 m trackbed
 'line':dict(speed=10.0,dwell=12.0,sets_each_way=3,cars=3,car=(9.6,2.65,3.6),power='the wind, from the battery works'),
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
    # the Arches (proposed 2026-10-18, at the user's direction: a rundown space for an underground fight club and a night
    # rave). A run of the Ring Line's old arches on the market lanes' south edge, between Market Lane's foot and the South
    # Gate, reopened right through: the rammed earth dug out of the outer halves and the party walls between bays broken
    # through, so the arches make one long vaulted hall under the Wall Line, 10 m deep, its outer skin left whole. The
    # Wall Line's trains, the night Watch train among them, rumble overhead. Its door opens on the Rim Walk. Fight
    # nights and rave nights are different nights of the week; on other days it is shut and looks it.
    V_=W_['venue']; vb=[a_ for a_ in arches if V_['s'][0]<=a_<=V_['s'][1]]
    V_['bays']=vb; V_['door']=[round(C.interpolate(vb[len(vb)//2]).x,2),round(C.interpolate(vb[len(vb)//2]).y,2)]
    if len(vb)<V_['min_bays']: problems.append(('wall: the Arches lose bays to a gate or the Line House',len(vb)))
    for a_ in vb:
        q=C.interpolate(a_)
        if any(Point(p_).distance(q)<W_['post']['along']/2+V_['depth'] for p_ in posts): problems.append(('wall: the Arches against a watch post',a_))
        if any(min(abs(a_-st['s']),L-abs(a_-st['s']))<W_['gatehouse']['along']/2+6 for st in stations): problems.append(('wall: the Arches in a station\'s gatehouse',a_))
        if not market_lane_xy(q.x,q.y): problems.append(('wall: the Arches outside the market lanes',a_))
    if V_['depth']>W_['thick']-1.5: problems.append(('wall: the Arches dug through the wall\'s outer skin',))
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
## The cross lines (city.md 6c; revised 2026-10-17 after the first playable
## prototype, at the user's direction). Two straight, level lines; no track
## climbs anywhere in Moy. The Spine Line runs north to south down the middle of
## North Street, the park and South Street at the Wall Line's own rail height
## (+13.2 m), and ends at a terminus just inside the wall at each gate, its
## platforms meeting the Wall Line's inner platform on the level: the two lines
## never cross or join, and changing between them is a few steps. (The first
## prototype found the old line 3 m off the street's centre, so its trains
## brushed the frontage; and its gate flyover climbed at 29%.) The Meridian Line
## is the high line (+36 m): through the Timekeeper's open centre over city hall,
## over the Crossing, between the East Gate's arch and the West Gate's towers, on
## tree piers three Spine bays apart (36 m), set out from the Crossing, with one
## longer bridge over city hall. Services are track centrelines in world (x, z);
## rail is the rail head's height; tracks run 1.5 m either side of the line.
CROSS={
 'depth':1.2,'r_min':12.0,'double':6.0,'track':1.5,'platform':(30.0,3.0),'min_gap':60.0,'clear_over':2.0,'car_h':3.6,
 'cars':dict(cars=2,car=(9.6,2.65,3.6),speed=9.0,dwell=8.0,headway=60),
 'services':[
  dict(line='Spine Line',w='double',rail=13.2,bay=12.0,pts=[(-560,-200),(-560,200)],
       structure='portal frames: the Deck\'s paired columns carried up through it, with a crossbeam under the track; 12 m bay; buffer stops at both ends, just inside the wall'),
  dict(line='Meridian Line',w='double',rail=36.0,pts=[(-336,0),(-792,0)],
       piers=[-722,-686,-650,-614,-506,-470,-434,-392],span=36.0,max_span=42.0,
       structure='tree piers: one round-square stem 2.4 m across in the middle of the street, branching at +28 m into a Y that carries twin steel box girders; 36 m spans, one 42 m bridge over city hall; the West Gate\'s tower carries its west end; at the Crossing its four towers carry it on two head beams'),
 ],
 'stations':[
  dict(name='North Gate',at=(-560,-184),lines=['Spine Line'],deck=False,mid=7.1,interchange='Wall Line',access='the Spine\'s north terminus just inside the wall: its platforms run on, level, onto the Wall Line\'s inner platform at the North Gate; escalator pairs under both platforms from the street'),
  dict(name='Estate Square',at=(-560,-100),lines=['Spine Line'],deck=True,access='over the Deck\'s Estate walk: escalator pairs under both platforms, from the street by way of the Deck'),
  dict(name='The Crossing',at=(-560,0),lines=['Spine Line','Meridian Line'],deck=True,access='the Crossing at the park\'s centre: its four garden towers join the lawn, the ring, the Spine\'s platforms and the high line\'s'),
  dict(name='Market Square',at=(-560,124),lines=['Spine Line'],deck=True,access='over Market Street and the square\'s north edge, where the Deck\'s Market walk runs below: escalator pairs under both platforms'),
  dict(name='South Gate',at=(-560,184),lines=['Spine Line'],deck=False,mid=7.1,interchange='Wall Line',access='the Spine\'s south terminus just inside the wall, level with the Wall Line\'s inner platform at the South Gate'),
  dict(name='East Gate',at=(-351,0),lines=['Meridian Line'],deck=False,access='the Meridian Arch, which is the East Gate: its lower bridge holds the platforms, over the Wall Line\'s station'),
  dict(name='West Gate',at=(-771,0),lines=['Meridian Line'],deck=False,access='the West Gate\'s twin towers: the bridge between them holds the platforms, over the Wall Line\'s station'),
 ],
 # no junctions: every line keeps its own tracks; changes happen on platforms
 'junctions':[],
 # escalators in station cores and stacks: pairs (an up and a down side by side) at 30 degrees, flights of at most 7.2 m
 'esc':dict(angle=30.0,max_rise=7.2,w=3.2),
}
## Platforms and boarding (city.md 6f, 2026-10-17): every platform's floor is the
## car's floor, 1.0 m above the rail head, so boarding is level; its edge stands
## 1.4 m from the track's centre, 7.5 cm from the car's side. Platforms are 3 m
## wide, one beside each track, under a canopy 3.2 m up where nothing else shades
## them. The train stops with its doors at marks on the platform.
PLATFORMS=dict(floor=1.0,edge=1.4,width=3.0,canopy=3.2,
  boarding='level: the platform is the car\'s floor; the gap is 7.5 cm; doors open for the whole stop, and the train stops at marks')
## Escalators (city.md 6f): moving ramps without steps, always in up-and-down
## pairs. Three ways to stack them: a pair (one level), a scissor (pairs stacked
## in a crisscross, each level reversing, both flows on every flight), and a
## double helix (an up spiral and a down spiral wound together round one eye,
## after the double-helix stairs of Chambord and the Vatican and the trunk
## spirals of the Plant Kingdom), each with a glass lift beside it or in its eye (the Crossing's towers wind theirs round a steel trunk, the lift beside).
ESCALATORS=dict(pair=dict(angle=30.0,tread=1.2,w=3.2,max_rise=8.0),
  scissor=dict(angle=30.0,w=3.2,max_rise=7.2,landing=1.5),
  helix=dict(angle=30.0,eye=1.4,band=2.6,hands=2,min_headroom=2.6,deck=0.9,landing=50.0),
  # every flight's section, straight or spiral (2026-10-18, at the user's direction: in the third prototype pass the
  # helices' undersides were invisible and had no collision from below). An escalator is a closed box: the moving
  # treads on top, the return belt inside, solid skirts at its sides, and a hard stainless soffit underneath that hides
  # the return and is seen from below. Top, skirts and soffit are all visible both ways they face out, and the top and
  # the soffit both collide (a closed convex piece per segment), so nothing passes up through a flight from beneath.
  section=dict(depth=0.9,treads='the moving surface on top, 0.4 m treads, in the lane\'s direction',
               return_belt='inside the box, never seen', skirts='solid brushed stainless, the box\'s sides',
               soffit='a hard brushed-stainless soffit closing the box underneath, its face down',
               collision='closed: the top and the soffit both solid, one convex piece per segment'),
  # the Spine stations' straight pairs (iteration 3): two narrow (0.8 m step) escalators side by side, 2.8 m overall,
  # a 2 m landing between flights and a 2.5 m clear runout at the foot
  station=dict(angle=30.0,w=2.8,landing=2.0,runout=2.5),
  # (user, 2026-10-17: "have you ever seen an escalator without moving railings?") every lane, straight or spiral, has a
  # moving handrail on BOTH sides, moving with the treads, on a clear glass balustrade; at each end the handrail runs on
  # past the incline over the landing (the newel), so a rider is on the flat before letting go. Between the up and the
  # down lane of a pair stand two balustrades, one for each lane, with a decking strip between them.
  handrail=dict(height=0.95,section=(0.09,0.07),newel=0.9,balustrade='clear toughened glass',material='black rubber over steel',
                moves='at the treads\' speed, in the lane\'s direction'))
## The Moy car (city.md 6e, user 2026-10-17): one short car for every line, built
## entirely of SuperEggs, so the trains belong to the same soft-cornered world as
## everything else. Short cars (9.6 m) so a train is two or three of them: they
## take the short platforms and frequent service of a small city; no line joins another,
## and short, frequent trains suit a small city. Every part is a SuperEgg in the
## car's frame (x along the car, y up from the rail head, z across): semi-axes,
## centre and its exponents (top: the plan shape and the upper half; bottom: the
## lower half), as superegg.gd builds them. consists: cars per train and the
## livery's colour for each line.
TRAIN=dict(
  name='the Moy car',car=(9.6,2.65,3.6),gangway=0.8,bogie_at=3.2,
  # boarding (2026-10-17): the floor is 1.0 m above the rail head, level with every platform; two doors a side per
  # car, each 1.4 m wide and 2.1 m tall, open for the whole stop; 2.3 m clear inside, 2.4 m wide
  floor=1.0,doors=dict(per_side=2,at=2.4,w=1.4,h=2.1),inside=(2.3,2.4),
  parts=[
    dict(name='body',semi=(4.8,1.4,1.325),c=(0,2.0,0),eps=(3.4,5.5),mat='cream glazed ceramic over an aluminium frame'),
    dict(name='glazing',semi=(4.64,0.6,1.338),c=(0,2.4,0),eps=(3.4,3.4),mat='a dark panoramic window band wrapping round both ends'),
    dict(name='livery',semi=(4.82,0.16,1.338),c=(0,1.35,0),eps=(3.4,3.4),mat='a band of the line\'s colour'),
    dict(name='battery pod',semi=(1.8,0.16,0.8),c=(0,3.44,0),eps=(5.5,5.5),mat='the roof battery, charged from the wind at the battery works'),
    dict(name='bogie',semi=(1.0,0.3,1.05),c=(3.2,0.35,0),eps=(5.5,5.5),mirror_x=True,mat='dark steel'),
    dict(name='lamp',semi=(0.14,0.14,0.14),c=(4.6,1.15,0.7),eps=(2.0,2.0),mirror_z=True,ends_only=True,mat='a warm lamp, lit at the train\'s ends'),
  ],
  gangway_part=dict(semi=(0.45,1.2,1.0),c=(0,2.0,0),eps=(5.5,5.5),mat='a dark bellows between cars'),
  consists={'Wall Line':dict(cars=3,colour='ochre',why='the ring is the commute, round the whole city'),
            'Spine Line':dict(cars=2,colour='teal',why='short runs over the Deck, gate to gate'),
            'Meridian Line':dict(cars=2,colour='violet',why='the high line: few stops, a ride for the view')},
  swing=0.6,
)
def _train_checks():
    T=TRAIN; L,Wd,H=T['car']
    if (WALL['line']['car'],CROSS['cars']['car'])!=(T['car'],T['car']): problems.append(('train: a line not using the Moy car',))
    if WALL['line']['cars']!=T['consists']['Wall Line']['cars'] or CROSS['cars']['cars']!=max(T['consists'][k]['cars'] for k in ('Spine Line','Meridian Line')): problems.append(('train: the lines\' car counts disagree with the consists',))
    for line,cn in T['consists'].items():
        n=cn['cars']
        if n not in (2,3): problems.append(('train: not two or three cars',line,n))
        length=n*L+(n-1)*T['gangway']; plat=WALL['platform'][0] if line=='Wall Line' else CROSS['platform'][0]
        if length>plat-4.0: problems.append(('train: longer than its platform allows',line,round(length,1),plat))
    # retain a compact shared car envelope for station platforms and the Wall Line's curves
    r=CROSS['r_min']; b=T['bogie_at']
    mid=b*b/(2*r); end=((L/2)**2-b*b)/(2*r)
    if max(mid,end)>T['swing']: problems.append(('train: the car swings too far on a %g m curve'%r,round(mid,2),round(end,2)))
    # every part stays inside the car's envelope, and every part is a SuperEgg no squarer than superegg.gd's flat
    for p_ in T['parts']+[T['gangway_part']]:
        sx,sy,sz=p_['semi']; cx_,cy_,cz_=p_['c']
        if abs(cx_)+sx>L/2+0.05 and p_ is not T['gangway_part']: problems.append(('train: a part past the car\'s ends',p_.get('name')))
        if abs(cz_)+sz>Wd/2+0.05 or cy_+sy>H+0.01 or cy_-sy<-0.01: problems.append(('train: a part outside the car\'s section',p_.get('name')))
        if not all(2.0<=e<=5.5 for e in p_['eps']): problems.append(('train: an exponent outside superegg.gd\'s range',p_.get('name')))
    T['_swing']=(round(mid,2),round(end,2))
_train_checks()
## Station cores: lifts and switchback escalating ramps, linking every level a
## station has. levels: heights served; c and size: the core's footprint (world).
## Revised 2026-10-17 (user): open air, as Singapore uses escalators even in
## open structures. A core is an open steel frame, not a glass box: its
## escalating ramps climb in switchback flights under light canopies, open to
## the breeze and planted at their edges; only the glass lift shafts beside it
## are enclosed. enclosure and canopy say so; lift: the shafts' size, beside
## the frame's long side.
## The Crossing (city.md 7a; revised 2026-10-17, plan iteration 3, at the user's direction). Where the Spine (+13.2)
## and the high line (+36) cross over the park's centre. Designed from what people do there:
## - every transfer is between one Spine platform (+14.2, east or west of the Spine) and one high-line platform (+37,
##   north or south of the Meridian). So there are four garden towers, one in each quarter, in the corner where a
##   Spine platform and a high-line platform pass each other: each joins the lawn (0), the concourse (+6.5), its
##   Spine platform and its high-line platform, by a double-helix escalator inside and a glass lift on its inner
##   corner, which opens straight onto both platforms. Any change of line is one tower, up or down.
## - the towers are the Crossing's structure: four great columns, each a steel trunk inside a ring of twelve ribs, carrying
##   the Spine and the high line on head beams between them (no other columns stand under either line here), the
##   cross-bridges hung from the Spine's head beams, the ring's inner edge, and the roof. Their ribs carry a steel mesh
##   that climbers cover: a living wall wrapped round each tower, after Singapore's Supertrees and WOHA's Oasia.
## - the concourse at the Deck's level is the station's mezzanine: the Crossing Ring, a garden walk round the four
##   towers (the Deck's Spine walks join it from north and south), and two cross-bridges, tower to tower, crossing
##   under the Spine's tracks, so both Spine platforms and all four towers are joined below the trains. The middle is
##   left open from the lawn to the sky.
## - one roof, a louvred table on the four towers at +41: it shelters the high line's platforms and the towers' tops and
##   shades the middle; its rain runs down the trunks to a rain garden round the towers' feet. The halo of the earlier
##   plan is gone (it sheltered nothing anyone waited on), and so are the 48 slender columns and the spirals' posts.
## towers: centre offsets from c (both axes); trunk, helix band, gallery and the rib ring's radius; the lift beside it.
## ring: inner and outer radius (a box girder ring_depth deep, spanning between supports at most ring_max_span).
CROSSING=dict(c=(-560,0),deck=6.5,ring=(24.7,32.7),ring_depth=1.6,ring_max_span=22.0,
  tower=dict(offset=13.0,trunk=1.2,gallery=1.8,ribs=8,rib=0.44,hoop=0.16,hoop_every=4.2,lift=1.3,beam_depth=1.6,mesh='stainless steel mesh between the ribs, coral vine and bougainvillea climbing it from planters at every gallery'),
  roof=dict(y=41.0,half=22.0,n=4.0,th=0.6,rim=1.4,material='pale timber louvres over glass, a planted rim of desert grasses',drain='down the four trunks to the rain garden'),
  canopy=dict(material='pale timber louvres over glass, as the roof'),
  material='steel towers under climbers; pale timber louvres over glass for every roof and canopy',
  program='the concourse: the information desk, the lost-and-found, kiosks and water fountains along the ring, between its beds',
  garden=dict(ring='beds on both edges of the ring, the path winding between them; small ghafs in deep planters over the ring\'s eight supports',
              towers='coral vine and bougainvillea up each tower\'s mesh from planters at every gallery',
              lawn='a rain garden of reeds and desert grasses round the towers\' feet, fed by the roof',
              roof='desert grasses on the roof\'s rim'),
  # the clock (2026-10-17, at the user's direction, replacing the Timekeeper over the old city hall): a glass dome on the
  # roof, its drum a superellipse in plan (the roof's shape, so its four sides are nearly flat) with a ring clock set
  # flush in each side facing north, south, east and west, and a glass cupola above; a great bell hangs from the
  # cupola's crown. Each clock is a ring clock like the Timekeeper: a hollow centre, the hour ring, the minute ring
  # outside it and a fixed bezel, each moving ring carrying a lit arrow, minute ticks on the bezel. It keeps the game's
  # time, so the dial and the bell agree. (The seconds bead is gone, 2026-10-17, at the user's direction.)
  # Revised 2026-10-17, at the user's direction: no posts and no ring beam (they read as a cage). Drum and cupola are one
  # glass shell on a fine triangulated grid of slender white members, after the Queen Elizabeth II Great Court at the
  # British Museum: every pane a triangle, the grid's lines sweeping from the near-square base up to a small crown ring.
  # lattice: panes round the base, the rows' height on the shell, the members' section. Each clock's hollow centre is an
  # open eye through the glass (eye: its radius, the sill's height from the clock's centre, the bronze sleeve lining it):
  # a way in and out for anyone who can climb, glide or fly, and a balcony onto the street it faces.
  dome=dict(drum=dict(half=20.0,n=4.0,h=17.0),cupola=dict(h=11.0),
    glass='one shell of clear glass, drum and cupola together, on a triangulated grid of slender white steel members; no posts, no ring beam; lit from within at night',
    lattice=dict(around=72,row=2.2,member=0.07,crown=3.0,after='the Queen Elizabeth II Great Court, British Museum (Foster, 2000)',
                 material='white-painted steel, every pane a triangle; the grid sweeps from the square-ish base up to the crown ring the bell hangs from'),
    clocks=dict(bearings=[0,90,180,270],centre=8.5,rings=[('hour',3.0,5.0),('minute',5.0,7.0),('bezel',7.0,8.0)],proud=0.3,
      markers=dict(hour=dict(arc=22.0,shape='arrow'),minute=dict(arc=12.0,shape='arrow')),marks=dict(hour=0.35,quarter=0.8,minute=dict(w=0.12,len=0.4)),
      eye=dict(r=2.85,sill=-2.4,sleeve=0.12,open='no glass, no guard: a way through for climbers, gliders and fliers'),time='game'),
    # the Clock Room (2026-10-17, at the user's direction): the dome's floor, the roof's top, is a public room under the
    # glass and the bell, a destination reached on purpose rather than a stop on the way. The helices end at the high
    # line, so everyone gets off at the station; every way into the room is one of its designed openings:
    # - the arrival wells: at the middle of each high-line platform, under the clock, the platform widens into a landing
    #   on its outer side (widening: its depth); from it two escalator pairs, one either side of the axis (at arrive_x),
    #   climb through glass-guarded wells in the floor into the room, arriving by the glass under a clock's eye;
    # - the lift lanterns: the four tower lifts run on through the roof to the room, each arriving in a glass lantern
    #   (lantern: its height over the floor) whose door faces the bell;
    # - the clock eyes: open, for those who can fly or glide, and only for them. (Revised 2026-10-18, at the user's
    #   direction: the escalators that rose from under the bell to a landing behind each eye are gone. An eye is not a
    #   place for ordinary people to be carried up to: it would be a ledge to fall from. A flier lands on its sill.)
    # rose: the round bronze inlay under the bell; guard: the glass round every well.
    room=dict(name='the Clock Room',widening=2.6,arrive_x=(2.4,5.6),runoff=2.5,lantern=3.4,rose=3.6,
      guard=dict(height=1.1,material='clear toughened glass on a bronze shoe, a bronze handrail on top'),
      program='a public room under the glass: beds of desert grasses along the glass, benches round the wells, the bell overhead and the backs of the four clocks turning high on the walls, their open eyes showing the sky',
      floor='pale terrazzo, the roof\'s top; a bronze compass rose inlaid under the bell, its four points toward the four clocks'),
    bell=dict(mouth=4.4,height=4.6,crown_gap=1.0,material='bronze',
      rings=[dict(at=5.0,name='the dawn bell',pattern='three strokes, three times, then nine (after the Angelus)'),
             dict(at=12.0,name='the noon bell',pattern='twelve strokes'),
             dict(at=19.5,name='the evening bell',pattern='three strokes, three times, then nine, half an hour before sunset (after the Angelus and the old curfew bell)')],
      why='sunrise in the game is 5:00 and sunset 20:00 (day_night_cycle.gd); a bell every hour would ring every real minute')),
  towers=[],cores=[])
def _crossing_layout():
    C=CROSSING; T=C['tower']; H=ESCALATORS['helix']; cx,cz=C['c']
    band0=H['eye']; band1=band0+H['band']; gal=band1+T['gallery']; drum=gal+0.2
    T['band']=(band0,band1); T['gallery_r']=(band1,gal); T['drum']=round(drum,2)
    # P1 (2026-10-19): the gallery stands clear of the helix's band. Its inner guard is 0.12 m boxes on 10-degree chords
    # about rail_r; nothing of the gallery or its guard comes inside gallery_clear. The lawn stands below the ways-out floor.
    T['rail_r']=4.1; T['gallery_clear']=4.02; C['lawn_y']=0.04
    C['towers']=[]
    for nm,sx,sz in (('north-east',1,-1),('north-west',-1,-1),('south-east',1,1),('south-west',-1,1)):
        tc=(cx+sx*T['offset'],cz+sz*T['offset']); d=drum+T['lift']+0.1
        lv_=[0,DECK['level'],13.2+PLATFORMS['floor'],36.0+PLATFORMS['floor']]   # the helices end at the high line: everyone gets off at the station
        # each hand: a flat landing at every level it serves (the rider steps off onto it, then sideways onto the gallery),
        # then a climb to the next level at the helix's angle; the down hand is the same path half a turn round. Angles in
        # degrees, 0 east, 90 south, increasing as the hand climbs; the up hand starts facing out of the Crossing.
        turn=2*math.pi*((band0+band1)/2)*math.tan(math.radians(H['angle']))
        a0=math.degrees(math.atan2(sz,sx)); hands=[]
        for hand in (0,1):
            a=a0+180*hand; prof=[]
            for k,y in enumerate(lv_):
                prof.append([round(a,2),round(a+H['landing'],2),y,y]); a+=H['landing']
                if k+1<len(lv_): d_=(lv_[k+1]-y)/turn*360; prof.append([round(a,2),round(a+d_,2),y,lv_[k+1]]); a+=d_
            hands.append(dict(hand='up' if hand==0 else 'down',profile=prof))
        C['towers'].append(dict(name=nm,c=tc,levels=lv_,hands=hands,
            spine_platform='east' if sx>0 else 'west',high_platform='north' if sz<0 else 'south',
            opens={str(DECK['level']):['the ring','the cross-bridge'],str(round(13.2+PLATFORMS['floor'],1)):180 if sx>0 else 0,str(36.0+PLATFORMS['floor']):90 if sz<0 else 270},
            lift=dict(c=(round(tc[0]-sx*d/math.sqrt(2),2),round(tc[1]-sz*d/math.sqrt(2),2)),r=T['lift']),r=(band0,band1)))
    # the rib cage's openings and hoops (2026-10-18, at the user's direction, after the third prototype pass: the
    # hoops, a ring every 4.1 m whatever the levels, crossed the ways out at head height, and with twelve ribs a rib
    # stood in the middle of each diagonal way out to the ring). Eight ribs, at 22.5 + 45k degrees, so every way out
    # (all at multiples of 45 degrees) is in the middle of a bay; hoops only where nobody walks out: never from a
    # level's floor to 2.8 m over it, at most hoop_every apart elsewhere.
    for TW in C['towers']:
        tx, tz = TW['c']; sx = math.copysign(1, tx - cx); sz = math.copysign(1, tz - cz)
        # (revised 2026-10-18, P1's second fix review) the inner corner is the lift's: no way out faces it. At the Deck
        # the ring (outward) and the cross-bridge; on the lawn, outward and the two sides that face the open middle.
        ways = [(DECK['level'], math.degrees(math.atan2(sz, sx))), (DECK['level'], math.degrees(math.atan2(0, -sx))),
                (round(13.2 + PLATFORMS['floor'], 2), 180.0 if sx > 0 else 0.0), (36.0 + PLATFORMS['floor'], 90.0 if sz < 0 else 270.0),
                (0.0, math.degrees(math.atan2(sz, sx))), (0.0, math.degrees(math.atan2(0, -sx))), (0.0, math.degrees(math.atan2(-sz, 0)))]
        TW['ways_out'] = [dict(y=y, bearing=round(b % 360, 2), width=2.4, clear=2.8) for y, b in ways]
        lv_ = sorted(set(TW['levels'])); bands = [(y, y + 2.8) for y in lv_]
        hoops = []; tops = [b_[1] for b_ in bands]; bots = [b_[0] - 0.25 for b_ in bands[1:]] + [C['roof']['y'] - 0.3]
        for lo, hi in zip(tops, bots):
            if hi - lo < 0.3: continue
            n_ = max(1, math.ceil((hi - lo) / T['hoop_every']))
            hoops += [round(lo + (hi - lo) * k / n_, 2) for k in range(n_ + 1)]
        TW['hoops'] = sorted(set(hoops))
    # the ring's supports: the four towers, a pair of Deck columns where the Spine walks cross it (north and south),
    # and a pair either side of the cross walk east and west, clear of the walk
    rm=(C['ring'][0]+C['ring'][1])/2; e=3.0-0.4
    C['_ring_supports']=[(round(cx+sd*e,1),round(cz+sn*27.5,1)) for sn in (-1,1) for sd in (-1,1)]+\
                        [(round(cx+sn*27.5,1),round(cz+sd*3.6,1)) for sn in (-1,1) for sd in (-1,1)]
    C['_ring_r']=rm
_crossing_layout()
## The Meridian Arch is the East Gate (city.md 8b, revised 2026-10-16): a loop
## after Beijing's CCTV headquarters whose two legs straddle the wall at the gate.
## Meridian Avenue passes under it through a 24 m opening; the Wall Line runs
## through the legs at +12 m with its station between them; the high line ends on
## the lower bridge at +36 m, directly above, crossing the Wall Line at right
## angles; the top bridge, cantilevered toward the city, holds the council chamber and the Wall Watch's
## command room. Revised 2026-10-17: on each leg's court face an open cascade
## of escalating ramps climbs the diagrid under glass canopies, after the
## Centre Pompidou's and Singapore's open-air station escalators, from the
## station hall on Meridian Court to the Wall Line, the high line and the sky
## garden on the lower bridge's roof; the Watch reaches its room by its own lift.
ARCH=dict(legs=[(-363.5,-30,-341.5,-12),(-363.5,12,-341.5,30)],lower=(32.0,42.0),top=(58.0,72.0),cantilever=12.0,
  opening=24.0,wall_line=12.0,
  # (2026-10-17) the open cascades are retired: their flights overran their 16 m cores and ran into each other. The
  # city front is ARCH['front'] (_arch_front): the City Steps, the Rostrum, two scissor tubes and the lifts.
  cores=[],
  # the Wall Line's train hall: a void through both legs at +12 m (v: across the wall, outward positive, from the wall's
  # centreline; y: floor and ceiling), holding both tracks and the station's platform on the outer side
  train_hall=dict(v=(-9.0,5.5),y=(12.0,21.0)),
  program='City Hall (2026-10-17, at the user\'s direction): its public hall at the street, joined to the station hall; the Wall Line\'s station at +12 m and the high line\'s at +36 m; the city\'s offices in the legs; the council chamber and the mayor\'s office in the top bridge\'s cantilever, looking down the civic axis over Civic Plaza to the park; the Wall Watch\'s command room in the top bridge\'s east end',
  skin='a diagrid of pale ceramic-clad steel over glass')
## The West Gate's towers (city.md 8b, revised 2026-10-16): the same idea at the
## west, smaller: two towers straddling the wall either side of West Street, the
## Wall Line through them at +12 m, the high line's west station on the bridge
## between them at +36 m, a siding for its trains beyond.
WEST_GATE=dict(towers=[(-782,-26,-757,-10),(-782,10,-757,26)],bridge=(32.0,42.0),top=44.0,train_hall=dict(v=(-9.0,5.5),y=(12.0,21.0)),
  cores=[dict(name='north tower',c=(-778.8,-18),size=(6.4,15.6),levels=[0,14.2,37],lifts=2,enclosure='open loggia',canopy=3.2,lift=(2.6,2.6)),
         dict(name='south tower',c=(-778.8,18),size=(6.4,15.6),levels=[0,14.2,37],lifts=2,enclosure='open loggia',canopy=3.2,lift=(2.6,2.6))])
## Green infrastructure (city.md 6d, user 2026-10-17): after Singapore's City in
## a Garden, every line, station and civic structure carries its own planting,
## on Moy's terms: a desert palette that the reclaimed water can afford, drip-fed
## at night from a "green main" that rides in every viaduct. palette: the only
## kinds used on the infrastructure. Each element names its planting, where it
## stands, what it is after, who keeps it and how it collides; the numbers are
## what the drawings and the model build.
GREEN=dict(
  palette=['bougainvillea','coral vine','ghaf','date palm','agave and aloe','desert grasses'],
  water='reclaimed water from the works, polished in the park\'s reed pond, in a green main inside every viaduct; drip lines, watered at night',
  elements=[
    dict(name='Spine troughs',on='the Spine Line',planting=['bougainvillea'],trough=(0.9,1.2),bloom_every=6.0,
         where='a planter trough hung on each edge of the viaduct, bougainvillea spilling over it',after='Singapore\'s planted flyover edges',
         keeper='Kade Morrow (city works)',collision='the trough is part of the viaduct\'s solid edge; the foliage is decorative'),
    dict(name='Spine frames',on='the Spine Line',planting=['coral vine'],
         where='coral vine on a steel mesh up each portal frame\'s columns',after='the greened columns under Singapore\'s viaducts',
         keeper='Kade Morrow (city works)',collision='the mesh is part of the column; the vine is decorative'),
    dict(name='High line sleeves',on='the Meridian Line',planting=['coral vine'],sleeve=(2.0,26.0),
         where='a stainless mesh sleeve round each tree pier\'s stem, coral vine climbing it to the Y',after='WOHA\'s Oasia Hotel Downtown (its red mesh and creepers) and the Supertrees',
         keeper='Kade Morrow (city works)',collision='the sleeve is part of the pier (blocking); the vine is decorative'),
    dict(name='High line troughs',on='the Meridian Line',planting=['bougainvillea'],trough=(0.9,1.2),bloom_every=9.0,
         where='troughs on both edges of the high line, so it reads from the street as a green line across the sky',after='Singapore\'s planted flyover edges',
         keeper='Kade Morrow (city works)',collision='part of the viaduct\'s solid edge; foliage decorative'),
    dict(name='The Deck',on='the Deck',planting=['bougainvillea','desert grasses','agave and aloe','ghaf'],
         where='a garden walk (DECK[\'garden\']): beds alternate from side to side so the path winds between them, small ghafs in deep planters over every second column pair, bougainvillea spilling over the outer edges: the Deck is Moy\'s park connector, a shaded green walk from every square to the park and the stations',after='New York\'s High Line and Singapore\'s Park Connector Network',
         keeper='Orin Pike (park keeper)',collision='bed edges and planters solid (a 0.45 m sitting edge); plants decorative'),
    dict(name='The Crossing',on='the Crossing\'s towers, ring and roof',planting=['coral vine','bougainvillea','desert grasses','ghaf'],
         where='climbers up each tower\'s mesh from planters at every gallery, so the four towers read as living columns; the ring a garden walk with small ghafs over its supports; a rain garden of reeds and grasses round the towers\' feet fed by the roof; grasses on the roof\'s rim',after='the Supertrees, WOHA\'s Oasia Hotel Downtown and Singapore\'s ABC Waters rain gardens (Bishan–Ang Mo Kio Park)',
         keeper='Orin Pike (park keeper)',collision='the towers\' mesh is part of the tower (blocking); planters solid; plants decorative'),
    dict(name='Station cores',on='the station cores',planting=['coral vine'],
         where='planters along the open escalating ramps\' outer edges and at every landing, coral vine trailing down the frame and shading the flights below',after='Singapore\'s planted open-air station escalators and Skyrise Greenery',
         keeper='Kade Morrow (city works)',collision='the planters are the flights\' solid edges; the vine is decorative'),
    dict(name='The arch',on='the Meridian Arch',planting=['ghaf','bougainvillea','agave and aloe'],terraces=[18.0,48.0],roof=True,
         where='sky terraces cut into the legs\' east faces at +18 and +48 m, each with a ghaf tree greeting the desert road (the court faces carry the escalator cascades); the lower bridge\'s roof a public sky garden over the high line\'s station, looking down the civic axis',after='WOHA\'s Parkroyal on Pickering (its sky gardens) and Singapore\'s LUSH rule that a building gives back the green its site took',
         keeper='the city (Kade Morrow); the sky garden open from the station',collision='terrace floors and the roof garden are landings; trees solid trunks, crowns decorative'),
    dict(name='The West Gate',on='the West Gate',planting=['date palm','agave and aloe','desert grasses'],roof=True,
         where='the bridge\'s roof is Old Moy\'s community garden: date palms, herb and vegetable beds on drip, a shade pergola; the towers\' roofs planted with agave and aloe',after='WOHA\'s Kampung Admiralty (its rooftop community farm over a public building)',
         keeper='Old Moy\'s residents, with Orin Pike',collision='beds\' edges and the pergola solid; plants decorative'),
    dict(name='The Rim Corridor',on='the Rim Walk',planting=['ghaf','desert grasses','bougainvillea'],
         where='the Ring Line\'s old service road at the wall\'s inner foot, kept as a green walk all the way round: ghaf shade, desert grasses, bougainvillea on the wall\'s arches',after='Singapore\'s Rail Corridor, a railway kept as a 24 km green walk',
         keeper='Orin Pike (park keeper)',collision='trees solid; grasses and climbers decorative'),
  ])
def _green_checks():
    pal=set(GREEN['palette'])
    if len(pal)>6: problems.append(('green: more than six kinds on the infrastructure',len(pal)))
    for e in GREEN['elements']:
        for k in ('where','after','keeper','collision'):
            if not e.get(k): problems.append(('green: an element without its %s'%k,e['name']))
        for sp in e['planting']:
            if sp not in pal: problems.append(('green: a plant outside the palette',e['name'],sp))
    for e in GREEN['elements']:
        if 'sleeve' in e and not e['sleeve'][1]<=28.0: problems.append(('green: the sleeve climbs past the pier\'s Y',e['sleeve']))
        if 'terraces' in e and not all(ARCH['legs'] and 0<t<ARCH['lower'][0] or ARCH['lower'][1]<t<ARCH['top'][0] for t in e['terraces']): problems.append(('green: an arch terrace in a bridge',e['terraces']))
_green_checks()
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
    X=CROSS
    tall=[]
    for b_ in named:
        tall.append((b_['n'],PODIUM_HEIGHT.get(b_['n'],HEIGHTS.get(b_['n'],8)),sbox(*b_['r'])))
        if b_['n'] in TOWER_PART: tall.append((b_['n'],HEIGHTS[b_['n']],sbox(*TOWER_PART[b_['n']])))
    for l in lots: tall.append((None,l[4]*STOREY.get(l[5],3.25),sbox(*l[:4])))
    wallP=SP(WALL['centreline'])
    if DECK['level']+2.8+0.25>min(sv['rail'] for sv in X['services'])-X['depth']-1.0: problems.append(('cross: a Deck skybridge too close under a line',))
    for sv in X['services']:
        P=sv['pts']; L=LineString(P); sv['path']=[tuple(p_) for p_ in P]; sv['length']=round(L.length,1)
        if len(P)!=2: problems.append(('cross: a line that is not straight',sv['line']))
        soffit=sv['rail']-X['depth']; w=X[sv['w']]
        env=L.buffer(w/2,cap_style=2).intersection(wallP)
        for n_,h,g in tall:
            if env.intersection(g).area>0.05 and h>soffit-X['clear_over']: problems.append(('cross: line through a building',sv['line'],n_,h))
        # stations on the line, spaced, platforms clear of tall buildings
        pos=[]
        for st in X['stations']:
            if sv['line'] not in st['lines']: continue
            p_=Point(st['at'])
            if L.distance(p_)>0.5: problems.append(('cross: station off its line',st['name'],sv['line'])); continue
            s0=L.project(p_); half=X['platform'][0]/2
            if s0-half<-0.01 or s0+half>L.length+0.01: problems.append(('cross: platform runs off the line',st['name']))
            seg=LineString([L.interpolate(max(0,s0-half)),L.interpolate(min(L.length,s0+half))]).buffer(w/2+X['platform'][1],cap_style=2).intersection(wallP)
            for n_,h,g in tall:
                if seg.intersection(g).area>0.05 and h>soffit-X['clear_over']: problems.append(('cross: platform into a building',st['name'],n_))
            # every Spine station but the Crossing (which has its towers), revised 2026-10-17 (iteration 3): an escalator pair
            # per platform, straight, in line with the platform beyond its end toward the city's centre, landing on the
            # platform's end. It stands in the 2.8 m lane between the viaduct's deck and the platform's outer edge, so it
            # never surfaces through the 3 m platform. Over the Deck one flight rises from the Deck (its foot on an apron
            # joining the Deck walk); at the gates two flights rise from the street with a landing between. The Spine's
            # frames and planter troughs keep out of the lanes (sv['frames'], below).
            if sv['line']=='Spine Line' and st['name']!='The Crossing':
                ES=ESCALATORS['station']; plat=round(sv['rail']+PLATFORMS['floor'],2); deck=bool(st.get('deck'))
                if deck and not any(LineString(r_['pts']).buffer(r_['w']/2).contains(p_) for r_ in DECK['runs']): problems.append(('cross: no Deck under a Deck station',st['name']))
                ux,uz=(L.coords[-1][0]-L.coords[0][0])/L.length,(L.coords[-1][1]-L.coords[0][1])/L.length
                e=-1 if (st['at'][0]-CX)*ux+st['at'][1]*uz>0 else 1          # along the line toward the city's centre
                half=X['platform'][0]/2; ex,ez=st['at'][0]+ux*e*half,st['at'][1]+uz*e*half
                lane0=X['double']/2+0.1; lane1=X['track']+PLATFORMS['edge']+PLATFORMS['width']
                if abs(lane1-lane0-ES['w'])>0.01: problems.append(('cross: the station escalator lane is not its pair\'s width',round(lane1-lane0,2)))
                pairs=[(DECK['level'],plat)] if deck else [(0.0,round(plat/2,2)),(round(plat/2,2),plat)]
                st['_access']=[]
                for sd in (1,-1):
                    off=sd*(lane0+lane1)/2; at=lambda t_: [round(ex+ux*e*t_-uz*off,2),round(ez+uz*e*t_+ux*off,2)]
                    fl=[]; t_=0.0
                    for a_,b_ in reversed(pairs):
                        run=(b_-a_)/math.tan(math.radians(ES['angle'])); fl.append(dict(foot=at(t_+run)+[a_],head=at(t_)+[b_],w=ES['w'])); t_+=run+ES['landing']
                    span=round(t_-ES['landing']+ES['runout'],2)
                    acc=dict(side='east' if sd*(-uz)>0 or sd*ux>0 else 'west',flights=fl[::-1],lane=[round(lane0,2),round(lane1,2)],span=span,end=[round(ex,2),round(ez,2)],dir=[ux*e,uz*e])
                    if deck: acc['apron']=dict(c=at(t_-ES['landing']+ES['runout']/2)[:2],size=[ES['w']+0.1,ES['runout']],y=DECK['level'],joins='the Deck walk')
                    else: acc['runout']=dict(c=at(t_-ES['landing']+ES['runout']/2)[:2],size=[ES['w'],ES['runout']],y=0.0,on='the street')
                    st['_access'].append(acc)
                    g=LineString([at(0)[:2],at(span)[:2]]).buffer(ES['w']/2,cap_style=2)
                    for n_,h,g2 in tall:
                        if g.intersection(g2).area>0.05: problems.append(('cross: a station escalator on a building',st['name'],n_))
                    for lt in lots:
                        if g.intersection(sbox(*lt[:4])).area>0.05: problems.append(('cross: a station escalator on a lot',st['name']))
                    if deck:
                        ap=Point(acc['apron']['c']).buffer(ES['runout'],cap_style=3)
                        if min(LineString(r_['pts']).buffer(r_['w']/2).distance(ap) for r_ in DECK['runs'])>0.2: problems.append(('cross: a station escalator\'s foot off the Deck',st['name']))
            pos.append((s0,st['name']))
        pos.sort(); sv['stops']=[n for _,n in pos]
        for (a_,na),(c_,nc) in zip(pos,pos[1:]):
            if c_-a_<X['min_gap']: problems.append(('cross: stations too close',sv['line'],na,nc,round(c_-a_,1)))
    sp,me=[sv for sv in X['services'] if sv['line']=='Spine Line'][0],[sv for sv in X['services'] if sv['line']=='Meridian Line'][0]
    # the two lines cross at different levels, with the Meridian's structure clear over the Spine's trains
    if me['rail']-X['depth']-(sp['rail']+X['car_h']+0.6)<2.0: problems.append(('cross: the Meridian Line too low over the Spine',))
    cross_pt=LineString(sp['pts']).intersection(LineString(me['pts']))
    if cross_pt.is_empty or Point(CROSSING['c']).distance(cross_pt)>1.0: problems.append(('cross: the lines do not cross at the Crossing',))
    # no track climbs: every line is level along its whole length
    for sv in X['services']:
        if 'profile' in sv: problems.append(('cross: a line that climbs',sv['line']))
    # the Spine ends inside the wall at each gate: its platforms meet the Wall Line's inner platform on the level, a few
    # steps apart, and its trains (and their buffer stops) stay clear of the Wall Line's platform and tracks
    WLr=WALL['r']+WALL['track_axis']-WALL['track_spacing']/2   # the Wall Line's inner track
    inner_plat=WLr-PLATFORMS['edge']-PLATFORMS['width']           # the inner edge of its inner platform
    if abs(sp['rail']-WALL['rail'])>0.01: problems.append(('cross: the Spine is not level with the Wall Line',sp['rail'],WALL['rail']))
    for nm in ('North Gate','South Gate'):
        st=[x for x in X['stations'] if x['name']==nm][0]
        gate=[x for x in WALL['gates'] if x['name']==nm][0]
        end=min(sp['pts'],key=lambda q:math.hypot(q[0]-gate['p'][0],q[1]-gate['p'][1]))
        plat_end=math.hypot(st['at'][0]-CX,st['at'][1])+X['platform'][0]/2
        gap=inner_plat-plat_end
        if not (0.5<=gap<=4.0): problems.append(('cross: the Spine terminus does not meet the Wall Line platform',nm,round(gap,2)))
        if math.hypot(end[0]-CX,end[1])+1.0>inner_plat: problems.append(('cross: the Spine\'s buffer stop reaches the Wall Line platform',nm))
        if abs(st['at'][0]-gate['p'][0])>4: problems.append(('cross: the Spine terminus is not at its gate',nm))
        st['_interchange']=dict(gap=round(gap,2),level=round(sp['rail']+PLATFORMS['floor'],2))
    # the high line's piers: in the street or a square, never on a building, the Spine or a station; spans to rhythm
    ml=LineString(me['pts']); pz=me['pts'][0][1]; xs=sorted(me['piers'])
    for x in xs:
        q=Point(x,pz)
        for n_,h,g in tall:
            if g.distance(q)<1.4: problems.append(('cross: a high-line pier on a building',x,n_))
        if abs(x-sp['pts'][0][0])<4: problems.append(('cross: a high-line pier on the Spine',x))
    ends=[min(lg[0] for lg in WEST_GATE['towers']),max(lg[2] for lg in WEST_GATE['towers']),min(lg[0] for lg in ARCH['legs'])]
    # at the Crossing the line rests on its towers' two head beams instead of piers
    cx_=CROSSING['c'][0]; bear=[cx_-CROSSING['tower']['offset'],cx_+CROSSING['tower']['offset']]; me['bearers']=bear
    seq=[WEST_GATE['towers'][0][2]]+sorted(xs+bear)+[ARCH['legs'][0][0]]
    spans=[round(b-a,1) for a,b in zip(seq,seq[1:])]
    me['spans']=spans
    if max(spans)>me['max_span']+0.01: problems.append(('cross: a high-line span too long',max(spans)))
    away=[sp_ for a_,b_,sp_ in zip(seq,seq[1:],spans) if not (bear[0]-50<=a_<=bear[1]+50 and bear[0]-50<=b_<=bear[1]+50)]
    regular=[sp_ for sp_ in away if abs(sp_-me['span'])<0.01]
    if len(regular)<len(away)*0.6: problems.append(('cross: the high line\'s piers keep no rhythm',spans))
    # set out from the Crossing: the nearest piers stand a span and a half from its centre, so the grid runs on through it
    if not any(abs(x-(cx_-1.5*me['span']))<0.01 for x in xs) or not any(abs(x-(cx_+1.5*me['span']))<0.01 for x in xs): problems.append(('cross: the piers are not set out from the Crossing',))
    if any(abs(x-cx_)<CROSSING['ring'][1]+2 for x in xs): problems.append(('cross: a high-line pier inside the Crossing',))
    # the East Gate is the arch: legs straddle the wall clear of the avenue and the line; it holds both stations
    A=ARCH; av=[s_ for s_ in STREETS if s_[0]=='Meridian Avenue'][0]
    for lg in A['legs']:
        g=sbox(*lg)
        if not g.intersects(wallP.exterior): problems.append(('arch: a leg that does not straddle the wall',lg))
        if g.intersects(sbox(*av[2:])): problems.append(('arch: a leg on Meridian Avenue',lg))
        if g.distance(LineString(me['pts']))<X['double']/2+2: problems.append(('arch: a leg against the high line',lg))
        for n_,h,g2 in tall:
            if g.intersection(g2).area>0.05: problems.append(('arch: a leg on a building',lg,n_))
    if A['legs'][1][1]-A['legs'][0][3]<A['opening']-0.01: problems.append(('arch: the gate opening is narrower than asked',))
    if not (A['lower'][0]<me['rail']-X['depth'] and me['rail']+X['car_h']<A['lower'][1]): problems.append(('arch: the lower bridge does not hold the high line',))
    st=[x for x in X['stations'] if x['name']=='East Gate'][0]
    if not (A['legs'][0][0]<=st['at'][0]<=A['legs'][0][2]): problems.append(('arch: the high line\'s station is not between the legs',))
    if wallP.exterior.distance(Point(st['at']))>8: problems.append(('arch: the station is not over the wall',))
    W=WEST_GATE; st=[x for x in X['stations'] if x['name']=='West Gate'][0]
    for tw in W['towers']:
        g=sbox(*tw)
        if not g.intersects(wallP.exterior): problems.append(('west gate: a tower that does not straddle the wall',tw))
        if g.intersects(sbox(*[s_ for s_ in STREETS if s_[0]=='West Street'][0][2:])): problems.append(('west gate: a tower on West Street',tw))
        for n_,h,g2 in tall:
            if g.distance(g2)<3: problems.append(('west gate: a tower against a building',tw,n_))
    if not (W['bridge'][0]<me['rail']-X['depth'] and me['rail']+X['car_h']<W['bridge'][1]): problems.append(('west gate: the bridge does not hold the high line',))
    if not (W['towers'][0][0]-6<=st['at'][0]<=W['towers'][0][2]+6): problems.append(('west gate: the station is not between the towers',))
    # the Wall Line runs through the gate buildings in a train hall: for each leg or tower, the hall is a straight void set
    # on the wall's centreline at the leg's middle; along the leg's whole length the cars on both tracks and the outer
    # platform must clear its sides by 0.5 m, its ceiling must clear the cars by 3 m, and the piers beside it stay 1 m thick
    WL=WALL; cw=WL['line']['car'][1]/2
    need=(WL['track_axis']-WL['track_spacing']/2-PLATFORMS['edge']-PLATFORMS['width'], WL['track_axis']+WL['track_spacing']/2+PLATFORMS['edge']+PLATFORMS['width'])
    for host,legs,sg in (('arch',ARCH['legs'],1),('west gate',WEST_GATE['towers'],-1)):
        # the hall follows the wall's curve through the leg, so it holds the tracks and both platforms at every point
        H_=(ARCH if host=='arch' else WEST_GATE)['train_hall']; xs=[]; arcs=[]
        if need[0]<H_['v'][0]+0.5 or need[1]>H_['v'][1]-0.5: problems.append(('%s: the Wall Line fouls its train hall'%host,need,H_['v']))
        for lg in legs:
            cx_=lambda z: CX+sg*math.sqrt(WL['r']**2-z**2)
            zs=[lg[1]+(lg[3]-lg[1])*k/8 for k in range(9)]
            a0=[(round(cx_(z)+sg*H_['v'][0],2),round(z,2)) for z in zs]; a1=[(round(cx_(z)+sg*H_['v'][1],2),round(z,2)) for z in zs]
            arcs.append(a0+a1[::-1]); xx=[q[0] for q in a0+a1]; xs.append([min(xx),max(xx)])
            if min(xx)-lg[0]<1.0 or lg[2]-max(xx)<1.0: problems.append(('%s: a pier beside the train hall too thin'%host,lg,round(min(xx)-lg[0],2),round(lg[2]-max(xx),2)))
        if H_['y'][1]-(WL['rail']+WL['line']['car'][2])<3.0 or H_['y'][0]>WL['height']: problems.append(('%s: the train hall too low'%host,))
        H_['x']=xs; H_['arcs']=arcs
    # every station core links all its levels with lifts and with escalating ramps in flights the angle allows
    E=X['esc']
    for host,cores in (('arch',A['cores']),('west gate',W['cores'])):
        for c in cores:
            lv=sorted(c['levels']); flights=[]
            for a_,b_ in zip(lv,lv[1:]):
                n=max(1,math.ceil((b_-a_)/E['max_rise']-1e-9)); rise=(b_-a_)/n; run=rise/math.tan(math.radians(E['angle']))
                flights+=[(a_+k*rise,a_+(k+1)*rise,round(run,2)) for k in range(n)]
            c['flights']=flights
            if max(f[2] for f in flights)+3.0>c['size'][1]+0.01: problems.append(('station: a core too short for its flights',host,c['name']))
            if c.get('lifts',0)<1: problems.append(('station: a core without a lift',host,c['name']))
            g=sbox(c['c'][0]-c['size'][0]/2,c['c'][1]-c['size'][1]/2,c['c'][0]+c['size'][0]/2,c['c'][1]+c['size'][1]/2)
            for sv in X['services']:
                if g.distance(LineString(sv['pts']))<X['double']/2+X['platform'][1]+0.5 and host=='crossing': problems.append(('station: a core against a line',host,c['name'],sv['line']))
            if host=='arch':
                # the cascade stands against its leg's court face, in Meridian Court, clear of the avenue
                if not any(sbox(*lg).distance(g)<0.6 and not sbox(*lg).buffer(-0.01).intersects(g) for lg in A['legs']): problems.append(('arch: a cascade not against its leg',c['name']))
                ct=[o for o in OPENS if o[0]=='Civic Plaza'][0]
                if not sbox(*ct[1:]).contains(g): problems.append(('arch: a cascade outside Civic Plaza',c['name']))
            if c.get('enclosure') not in ('open frame','open cascade','open loggia'): problems.append(('station: an enclosed core',host,c['name']))
            for hx in ((ARCH if host=='arch' else WEST_GATE if host=='west gate' else {}).get('train_hall',{}).get('x') or []):
                if g.intersects(sbox(hx[0],-300,hx[1],300)) and host!='crossing' and any(sbox(*lg).intersects(g) for lg in (ARCH['legs'] if host=='arch' else WEST_GATE['towers'])): problems.append(('station: a core in the train hall',host,c['name']))
            if host=='west gate' and not any(sbox(*tw).contains(g) for tw in W['towers']): problems.append(('west gate: a core outside its tower',c['name']))
    # the Crossing (city.md 7a, iteration 3): four garden towers, each a double helix round a steel trunk, galleries at
    # its levels, a rib ring with climbers outside, a glass lift on its inner corner; they carry both lines, the ring and
    # the roof. Checked: headroom between the helix's hands; each tower a short bridge from its Spine platform and its
    # high-line platform and clear of both lines' decks; the lift opening straight onto both platforms; head beams with
    # headroom over the concourse and under each line; the ring clear round the towers and spanning within its limit;
    # the roof clear over the high line's trains and covering its platforms and the towers; everything in the park and
    # off its features
    C=CROSSING; T=C['tower']; H=ESCALATORS['helix']; rm=H['eye']+H['band']/2
    turn=2*math.pi*rm*math.tan(math.radians(H['angle']))
    if turn/H['hands']-H['deck']<H['min_headroom']: problems.append(('crossing: a tower\'s helix without headroom between its hands',round(turn/H['hands']-H['deck'],2)))
    # with its landings: at every bearing, every pair of band surfaces stacked one over another (both hands, every turn)
    # leaves the headroom, and every landing is long enough to step off onto (2 m at the band's middle)
    if math.radians(H['landing'])*rm<2.0: problems.append(('crossing: a helix landing too short to step off',))
    worst=1e9
    for TW in C['towers']:
        for deg in range(0,360):
            ys=[]
            for hd in TW['hands']:
                for a0_,a1_,y0_,y1_ in hd['profile']:
                    for k_ in range(-2,8):
                        ang=deg+360*k_
                        if a0_<=ang<=a1_: ys.append(y0_+(y1_-y0_)*(ang-a0_)/((a1_-a0_) or 1))
            ys=sorted(set(round(y_,3) for y_ in ys))
            for lo,hi in zip(ys,ys[1:]): worst=min(worst,hi-lo-H['deck'])
        tops=[hd['profile'][-1][3] for hd in TW['hands']]; bots=[hd['profile'][0][2] for hd in TW['hands']]
        for hd in TW['hands']:
            if [p_[2] for p_ in hd['profile'] if p_[2]==p_[3]]!=TW['levels']: problems.append(('crossing: a helix hand without a landing at every level',TW['name'],hd['hand']))
    C['_helix_headroom']=round(worst,2)
    if worst<H['min_headroom']: problems.append(('crossing: the helix\'s hands too close where they pass',round(worst,2)))
    if H['eye']<T['trunk']+0.15: problems.append(('crossing: the helix rubs the trunk',))
    cx0,cz0=C['c']; spx=sp['pts'][0][0]; mez=me['pts'][0][1]
    plat_in=X['track']+PLATFORMS['edge']; plat_out=plat_in+PLATFORMS['width']; half_len=X['platform'][0]/2
    deck_half=X['double']/2+0.9   # the viaduct with its planted troughs
    sp_fl=sp['rail']+PLATFORMS['floor']; me_fl=me['rail']+PLATFORMS['floor']
    for TW in C['towers']:
        tx,tz=TW['c']; dr=T['drum']; nm=TW['name']
        bx=abs(tx-spx)-dr-plat_out; bz=abs(tz-mez)-dr-plat_out
        if not (0.5<=bx<=2.0): problems.append(('crossing: a tower not a short bridge from its Spine platform',nm,round(bx,2)))
        if not (0.5<=bz<=2.0): problems.append(('crossing: a tower not a short bridge from its high-line platform',nm,round(bz,2)))
        if abs(tz-cz0)-0.0>half_len or abs(tx-cx0)>half_len: problems.append(('crossing: a tower beyond its platforms\' ends',nm))
        if abs(tx-spx)-dr<deck_half or abs(tz-mez)-dr<deck_half: problems.append(('crossing: a tower against a line\'s deck',nm))
        lx,lz=TW['lift']['c']; lr=TW['lift']['r']
        for gap in (abs(lx-spx)-lr-plat_out,abs(lz-mez)-lr-plat_out):
            if not (0.3<=gap<=1.2): problems.append(('crossing: a lift that does not open onto both platforms',nm,round(gap,2)))
        if math.hypot(lx-tx,lz-tz)<dr+lr: problems.append(('crossing: a lift inside its tower',nm))
        if sorted(TW['levels'])!=[0,DECK['level'],sp_fl,me_fl]: problems.append(('crossing: a tower misses a level',nm,TW['levels']))
        TW['turns']=round(max(TW['levels'])/turn,2); TW['rise_per_turn']=round(turn,2)
        # every way out passes clear: no rib in it, no hoop across it
        for w_ in TW['ways_out']:
            half_deg = math.degrees((w_['width'] / 2 + T['rib'] / 2 + 0.1) / T['drum'])
            for k_ in range(T['ribs']):
                rb = (k_ + 0.5) * 360 / T['ribs']
                if abs((rb - w_['bearing'] + 180) % 360 - 180) < half_deg: problems.append(('crossing: a rib in a way out of a tower', nm, w_['y'], w_['bearing']))
            for h_ in TW['hoops']:
                if w_['y'] - 0.2 < h_ < w_['y'] + w_['clear']: problems.append(('crossing: a hoop across a way out of a tower', nm, w_['y'], h_))
            # nor the tower's lift: the way's centre line passes the shaft with the way's half-width and 0.2 m to spare
            ab = math.radians(w_['bearing']); ux, uz = math.cos(ab), math.sin(ab)
            along = (lx - tx) * ux + (lz - tz) * uz; perp = abs(-(lx - tx) * uz + (lz - tz) * ux)
            if along > 0 and perp < lr + w_['width'] / 2 + 0.2: problems.append(('crossing: a tower\'s lift in a way out', nm, w_['y'], w_['bearing']))
        gaps_ = [b_ - a_ for a_, b_ in zip(TW['hoops'], TW['hoops'][1:])]
        if TW['hoops'][0] > 3.2 or max(gaps_) > 6.0 + 0.01: problems.append(('crossing: the hoops too far apart to carry the mesh', nm, max(gaps_)))
        if math.hypot(tx-cx0,tz-cz0)+dr>C['ring'][0]-0.1 or math.hypot(tx-cx0,tz-cz0)+dr<C['ring'][0]-0.8: problems.append(('crossing: a tower does not meet the ring\'s inner edge',nm))
        for x in me['piers']:
            if math.hypot(tx-x,tz-mez)<dr+3: problems.append(('crossing: a tower against a pier',nm,x))
    # head beams: the Spine's (east-west, under its deck) clear over the concourse; the high line's (north-south) under its girders
    sb_top=sp['rail']-X['depth']; sb_bot=sb_top-T['beam_depth']
    if sb_bot-DECK['level']<3.0: problems.append(('crossing: no headroom under the Spine\'s head beam',round(sb_bot-DECK['level'],2)))
    mb_top=me['rail']-X['depth']-2.2; mb_bot=mb_top-2.0
    if mb_bot<sp_fl+PLATFORMS['canopy']+1.0: problems.append(('crossing: the high line\'s head beam over the Spine\'s platforms',))
    C['_beams']=dict(spine=dict(z=[cz0-T['offset'],cz0+T['offset']],y=(round(sb_bot,2),round(sb_top,2))),high=dict(x=[cx0-T['offset'],cx0+T['offset']],y=(round(mb_bot,2),round(mb_top,2))))
    # the Spine across the Crossing: from the head beams to the ring's supports, and between the head beams
    zs=sorted([q[1] for q in C['_ring_supports'] if abs(q[0]-spx)<4]+C['_beams']['spine']['z'])
    if max(b_-a_ for a_,b_ in zip(zs,zs[1:]))>30.0: problems.append(('crossing: a Spine span too long',zs))
    # the Spine's portal frames, recorded (iteration 3): every 12 m along the line, except where the Deck runs beneath (its
    # columns carry the line there), inside the Crossing (its towers do), close to the wall (its gatehouses do), and in a
    # station escalator's lane, where the frame moves just past the lane's far end; spans between supports at most 30 m
    spP=sp.get('path',sp['pts']); spl=LineString(spP); deckP=[LineString(r_['pts']).buffer(r_['w']/2+1.2) for r_ in DECK['runs']]
    lanes=[]
    for st in X['stations']:
        for acc in st.get('_access',[]):
            (ex_,ez_),(dx_,dz_)=acc['end'],acc['dir']; g_=LineString([(ex_,ez_),(ex_+dx_*acc['span'],ez_+dz_*acc['span'])]).buffer(4.0,cap_style=2)
            lanes.append((g_,(ex_+dx_*(acc['span']+0.6),ez_+dz_*(acc['span']+0.6))))
            lanes.append((g_,(ex_-dx_*0.6,ez_-dz_*0.6)))          # and one just under the platform's end
    fixed=[]
    for ln in lanes:
        q=Point(ln[1])
        if not any(g.contains(q) for g in deckP) and not any(Point(f_).distance(q)<3 for f_ in fixed): fixed.append([round(q.x,2),round(q.y,2)])
    frames=list(fixed); t_=6.0
    while t_<spl.length:
        q=spl.interpolate(t_); t_+=sp['bay']
        if any(g.contains(q) for g in deckP) or q.distance(Point(C['c']))<C['ring'][1]+1 or abs(math.hypot(q.x-CX,q.y)-WALL['r'])<WALL['thick']/2+20: continue
        if any(ln[0].contains(q) for ln in lanes) or any(Point(f_).distance(q)<4 for f_ in fixed): continue
        frames.append([round(q.x,2),round(q.y,2)])
    sp['frames']=sorted(frames,key=lambda f_: f_[1])
    for f_ in sp['frames']:
        for ln in lanes:
            if ln[0].buffer(-3.0).distance(Point(f_))<0.6: problems.append(('cross: a Spine frame in a station escalator\'s lane',f_))
    # the ring: round the towers, spanning between its supports (the towers on the diagonals and the column pairs)
    ang=sorted([math.degrees(math.atan2(q[1]-cz0,q[0]-cx0))%360 for q in C['_ring_supports']]+[45,135,225,315])
    rr=C['_ring_r']; gaps=[(b_-a_)%360 for a_,b_ in zip(ang,ang[1:]+[ang[0]+360])]
    C['_ring_spans']=sorted(set(round(math.radians(g_)*rr,1) for g_ in gaps if g_>3))
    if max(C['_ring_spans'])>C['ring_max_span']: problems.append(('crossing: a ring span too long',C['_ring_spans']))
    for q in C['_ring_supports']:
        if not (C['ring'][0]<math.hypot(q[0]-cx0,q[1]-cz0)<C['ring'][1]): problems.append(('crossing: a ring support off the ring',q))
    # the roof: over the high line's trains, covering its platforms and the towers
    R=C['roof']
    if R['y']<me['rail']+X['car_h']+1.0: problems.append(('crossing: the roof on the high line\'s trains',))
    se=lambda x,z: (abs(x)/R['half'])**R['n']+(abs(z)/R['half'])**R['n']
    for TW in C['towers']:
        dx,dz=TW['c'][0]-cx0,TW['c'][1]-cz0; u=T['drum']/math.sqrt(2)
        if se(abs(dx)+u,abs(dz)+u)>1.0: problems.append(('crossing: the roof does not cover a tower',TW['name']))
    if se(half_len,plat_out)>1.0: problems.append(('crossing: the roof does not cover the high line\'s platforms',))
    # the dome stands on the roof inside its edge; each clock fits its side of the drum; the bell hangs clear inside
    Dm=C['dome']; dr_=Dm['drum']; ck=Dm['clocks']; base=R['y']+R['th']; Dm['base']=round(base,2)
    if dr_['half']>R['half']-R['rim']-0.5 or dr_['n']!=R['n']: problems.append(('crossing: the dome does not sit on the roof',))
    R1=ck['rings'][-1][2]
    if ck['centre']-R1<0.4 or ck['centre']+R1>dr_['h']-0.4: problems.append(('crossing: a clock does not fit the drum\'s height',))
    flat=dr_['half']*(1-0.5**(1/dr_['n']))      # how far the drum's side bows back at a clock's edge, roughly
    if R1>dr_['half']*0.6: problems.append(('crossing: a clock too wide for the drum\'s flat side',))
    if ck['rings'][0][1]<2.5: problems.append(('crossing: the clock\'s hollow centre too small to read as a ring',))
    if max(m['arc'] for m in ck['markers'].values())>=30: problems.append(('crossing: a clock arrow spans an hour mark',))
    top=base+dr_['h']+Dm['cupola']['h']; bl=Dm['bell']; Dm['top']=round(top,2); bl['bottom']=round(top-bl['crown_gap']-bl['height'],2)
    if bl['bottom']<base+dr_['h']+0.5 or bl['mouth']/2>dr_['half']*0.5: problems.append(('crossing: the bell does not hang clear inside the cupola',))
    if sorted(r_['at'] for r_ in bl['rings'])!=[r_['at'] for r_ in bl['rings']]: problems.append(('crossing: the bell\'s rings out of order',))
    # in the park, off its pond, playground and buildings; the supports off its walks and gardens
    ring=Point(C['c']).buffer(C['ring'][1],64).difference(Point(C['c']).buffer(C['ring'][0],64))
    if not sbox(*PARK['rect']).contains(ring): problems.append(('crossing: the ring leaves the park',))
    from shapely import affinity
    pc=PARK['pond']['c']; pond=affinity.scale(Point(pc).buffer(1,64),*PARK['pond']['r'])
    PD=PARK['pond']; bed_=PD['bed']
    if abs(bed_[0][0]-PD['bank_top'])>1e-6 or abs(bed_[0][1])>1e-6: problems.append(('park: the pond\'s bank does not meet the ground at its top',))
    if not any(abs(f-1.0)<1e-6 and abs(y-PD['surface'])<1e-6 for f,y in bed_): problems.append(('park: the pond\'s waterline is not at its edge',))
    if PD['surface']>-0.15: problems.append(('park: the pond\'s water stands at or above its banks',PD['surface']))
    if any(b_[1]<a_[1]-1e-6 or b_[0]>a_[0] for a_,b_ in zip(bed_,bed_[1:])) and any(b_[1]>a_[1] for a_,b_ in zip(bed_,bed_[1:])): problems.append(('park: the pond\'s bed rises toward its middle',))
    bank_g=affinity.scale(Point(pc).buffer(1,64),PD['r'][0]*PD['bank_top'],PD['r'][1]*PD['bank_top'])
    for w_ in PARK['walks']:
        if sbox(*w_).intersects(bank_g): problems.append(('park: a walk on the pond\'s bank',w_))
    for t_ in PARK.get('trees',[]):
        if bank_g.contains(Point(t_['c'])): problems.append(('park: a tree in the pond or on its bank',t_['c']))
    pg=PARK['playground']; play=Point(pg['c']).buffer(pg['track'][1],64)
    for nm,g in [('pond',pond),('playground',play)]+[('park building',sbox(*[b_ for b_ in named if b_['n']==n_][0]['r'])) for n_ in (9,10)]:
        if ring.intersection(g).area>0: problems.append(('crossing: the ring over the',nm))
    for q in C['_ring_supports']:
        for nm,g in [('walk',unary_union([sbox(*w_) for w_ in PARK['walks']])),('dry garden',sbox(*PARK['dry_garden'])),('lawn',sbox(*PARK['lawn'])),('pond',pond)]:
            if g.contains(Point(q)) and not (nm=='walk' and abs(q[0]-spx)<3.01): problems.append(('crossing: a ring support in the',nm,q))
    for TW in C['towers']:
        g=Point(TW['c']).buffer(T['drum'])
        for nm,f in [('lawn',sbox(*PARK['lawn'])),('dry garden',sbox(*PARK['dry_garden'])),('pond',pond),('walk',unary_union([sbox(*w_) for w_ in PARK['walks']]))]:
            if g.intersection(f).area>0: problems.append(('crossing: a tower on the',nm,TW['name']))
    if abs(C['deck']-DECK['level'])>0.01: problems.append(('crossing: the ring is not at the Deck\'s level',))
    if not sbox(*PARK['rect']).buffer(-1).contains(play): problems.append(('park: the playground leaves the park',))
    for n_ in (9,10):
        g=sbox(*[b_ for b_ in named if b_['n']==n_][0]['r'])
        for nm,f in [('playground',play),('pond',pond),('lawn',sbox(*PARK['lawn'])),('dry garden',sbox(*PARK['dry_garden']))]+[('walk',sbox(*w_)) for w_ in PARK['walks']]:
            if g.intersection(f).area>0: problems.append(('park: a park building on the',nm,n_))
    for t in pg['towers']:
        if pond.distance(Point(t[:2]))<t[3]+1 or sbox(*PARK['lawn']).distance(Point(t[:2]))<t[3]: problems.append(('park: a playground tower on the pond or the lawn',t))
    # the park's trees: trunks off the walks, the pond, the playground, the lawn and the buildings; crowns clear of the
    # Deck (inside the park by the crown and 1.5 m), the Crossing Ring and its towers, the high line's piers, and each other
    walks_=unary_union([sbox(*w_) for w_ in PARK['walks']]); prk=sbox(*PARK['rect'])
    for k,t in enumerate(PARK['trees']):
        K=TREE_KIT[t['kind']]; cr=K['crown']*t['h']; q=Point(t['c']); t['crown']=round(cr,2); t['trunk_h']=round(K['trunk']*t['h'],2)
        if walks_.distance(q)<1.0: problems.append(('park: a tree on a walk',t['c']))
        if pond.contains(q) or play.distance(q)<cr*0.5 or sbox(*PARK['lawn']).distance(q)<1.0: problems.append(('park: a tree on the pond, the playground or the lawn',t['c']))
        for n_ in (9,10):
            if sbox(*[b_ for b_ in named if b_['n']==n_][0]['r']).distance(q)<cr: problems.append(('park: a tree over a park building',t['c'],n_))
        if not prk.buffer(-(cr+1.5)).contains(q): problems.append(('park: a tree\'s crown into the Deck',t['c']))
        d=q.distance(Point(C['c']))
        if C['ring'][0]-cr-1.0<d<C['ring'][1]+cr+1.0: problems.append(('park: a tree\'s crown into the Crossing Ring',t['c'],round(d,1)))
        if d<C['ring'][0]: problems.append(('park: a tree inside the Crossing',t['c']))
        for x in me['piers']:
            if q.distance(Point(x,mez))<cr*0.5+1.5: problems.append(('park: a tree against a high-line pier',t['c'],x))
        for u in PARK['trees'][k+1:]:
            if q.distance(Point(u['c']))<0.6*(cr+TREE_KIT[u['kind']]['crown']*u['h']): problems.append(('park: trees crowded',t['c'],u['c']))
        for pr in PARK['parasols']:
            if q.distance(Point(pr))<2.5: problems.append(('park: a tree on a parasol',t['c']))
## City Hall's city front (city.md 8b.1, 2026-10-17, at the user's direction). A civic seat wants a calm, symmetrical
## front with one place to stand before the city; the station wants short, legible ways to every platform. So:
## - the Rostrum: a balcony across the whole west front at the Wall Line's level (+14.2), over the gate's opening, where
##   the city is addressed (after the Gate of Heavenly Peace); it is also the Wall Line's inner platform concourse;
## - the City Steps: before each leg a broad stair between an up and a down escalator, from the square to the Rostrum;
## - on each leg's face a glazed scissor: flights alternate between two bands side by side, so no flight ever runs under
##   or into another, and every flight is a pair (up and down side by side); it climbs to the high line's platforms
##   (+37) and the sky garden on the lower bridge (+43), with a landing at +21.8 that crosses over the Wall Line's
##   tracks inside the leg and down to its outer platform;
## - a glass lift on each leg's inner face, and one in each leg's east side for the outer platform.
## Mirror images, north and south of the axis.
def _arch_front():
    A=ARCH; F=A['legs'][0][0]; zi=A['legs'][1][1]; zo=A['legs'][1][3]
    pf=WALL['rail']+PLATFORMS['floor']; hl=CROSS['services'][1]['rail']+PLATFORMS['floor']; sky=A['lower'][1]+1.0
    WL=WALL; cxw=lambda z: CX+math.sqrt(WL['r']**2-z**2)
    v_in=WL['track_axis']-WL['track_spacing']/2-PLATFORMS['edge']           # the inner platform's track edge
    plat_w=lambda z: cxw(z)+v_in-PLATFORMS['width']                          # its west edge
    plat_out=lambda z: (cxw(z)+WL['track_axis']+WL['track_spacing']/2+PLATFORMS['edge'], cxw(z)+WL['track_axis']+WL['track_spacing']/2+PLATFORMS['edge']+PLATFORMS['width'])
    pw=ESCALATORS['station']['w']; gap=0.4
    bandA=(F-pw,F); bandB=(F-2*pw-gap,F-pw-gap)
    z0,z1=zi+1.5,zo-1.5; levels=[pf,round(pf+(hl-pf)/3,2),round(pf+2*(hl-pf)/3,2),hl]
    rostrum=dict(y=pf,x=(round(F-7.0,2),F),z=(-zo,zo),opening_x=(F,round(min(plat_w(z) for z in (-zi,0,zi)),2)),
                 bay=dict(c=(round(F-7.0,2),0.0),r=3.0),portals=[round(z1-3.0,2),round(z1-0.5,2)])
    legs=[]
    for sgn,name in ((-1,'north'),(1,'south')):
        S=lambda z: round(sgn*z,2)
        flights=[dict(name='F1',band='A',y=(levels[0],levels[1]),z=(S(z0),S(z1))),
                 dict(name='F2',band='B',y=(levels[1],levels[2]),z=(S(z1),S(z0))),
                 dict(name='F3',band='A',y=(levels[2],levels[3]),z=(S(z0),S(z1))),
                 dict(name='F4',band='A',y=(hl,sky),z=(S(z0),S(z0+(sky-hl)/((levels[1]-levels[0])/(z1-z0)))))]
        galleries=[dict(name='G21',band='AB',y=levels[1],z=(S(z1),S(zo)),to='over the tracks to the outer platform'),
                   dict(name='G29',band='AB',y=levels[2],z=(S(zi),S(z0)),to='the turn'),
                   dict(name='G37',band='B',y=hl,z=(S(zo),S(zi)),to='the high line platform\'s west end'),
                   dict(name='G43',band='B',y=sky,z=(S(abs(flights[3]['z'][1])+1.5),S(zi)),to='the sky garden on the lower bridge\'s roof'),
                   # the landings between flights in band A, each joined across to the band B gallery beside it: F3 arrives
                   # on L37o and its riders cross to G37; F4 leaves from L37i; F4 arrives on L43 and crosses to G43
                   dict(name='L37o',band='AB',y=hl,z=(S(z1),S(zo)),to='F3\'s head, across to G37'),
                   dict(name='L37i',band='AB',y=hl,z=(S(zi),S(z0)),to='F4\'s foot, from G37'),
                   dict(name='L43',band='AB',y=sky,z=(S(abs(flights[3]['z'][1])),S(abs(flights[3]['z'][1])+2.5)),to='F4\'s head, across to G43')]
        ex=(-345.0,round(-345.0+pw,2))
        over=dict(y=levels[1],x=(F,ex[1]),z=(S(z1-1.5),S(zo-0.5)))
        outer=dict(name='outer pair',x=ex,y=(levels[1],pf),z=(S(z1),S(z0)),lands=round(plat_out(sgn*z0)[1],2))
        # the lifts (revised 2026-10-17: every stop now opens onto a deck): the front lift stands in front of the face in
        # line with the tubes, one flanking each side of the gate's opening, its door onto the tubes' inner ends; the
        # outer lift at the walk over the tracks' east end, down to the outer platform's landing and the ground
        lifts=[dict(name='front lift',c=(round((bandB[0]+bandA[1])/2,2),S(zi-1.6)),size=2.6,stops=[0.0,pf,hl,sky],door=sgn),
               dict(name='outer lift',c=(round(ex[1]+1.6,2),S(zo-1.75)),size=2.6,stops=[0.0,pf,levels[1]],door='w')]
        # the outer pair's foot: a platform-side landing inside the leg, between the outer platform and the pair
        outer_landing=dict(y=pf,x=(round(plat_out(sgn*z0)[1],2),ex[1]),z=(S(zi),S(zo)))
        # the City Steps: an escalator on each side of a broad stair, in two flights with a shared half-landing
        run=(pf/2)/math.tan(math.radians(ESCALATORS['station']['angle'])); land=ESCALATORS['station']['landing']
        head=rostrum['x'][0]; foot=round(head-2*run-land,2)
        steps=dict(z=S(21.0),width=7.8,head=head,foot=foot,half=(round(head-run-land,2),round(head-run,2)),half_y=round(pf/2,2),
                   lanes=[dict(kind='up escalator',z=S(21.0+3.2)),dict(kind='stair',z=S(21.0),w=4.4),dict(kind='down escalator',z=S(21.0-3.2))])
        legs.append(dict(side=name,flights=flights,galleries=galleries,over_tracks=over,outer=outer,outer_landing=outer_landing,lifts=lifts,steps=steps))
    # the guards (2026-10-17, at the user's direction): clear glass on every open edge of every landing, gallery, the
    # Rostrum, the walk over the tracks and the Steps' half-landings, open only where a flight, a stair, a lift door, a
    # platform or the leg's face meets it. Worked out as each level's decks together, less those meetings.
    from shapely.geometry import box as sbox, Point, LineString, MultiLineString
    from shapely.ops import unary_union, linemerge
    bx={'A':bandA,'B':bandB,'AB':(bandB[0],bandA[1])}
    guards=[]; gap_max=0.0
    def zz(a,b): return (min(a,b),max(a,b))
    for L in legs:
        decks={}
        for g in L['galleries']:
            z_=zz(*g['z']); decks.setdefault(g['y'],[]).append(sbox(bx[g['band']][0],z_[0],bx[g['band']][1],z_[1]))
        T_=L['over_tracks']; z_=zz(*T_['z']); decks.setdefault(T_['y'],[]).append(sbox(T_['x'][0],z_[0],T_['x'][1],z_[1]))
        st=L['steps']; decks.setdefault(st['half_y'],[]).append(sbox(st['half'][0],st['z']-st['width']/2,st['half'][1],st['z']+st['width']/2))
        OL=L['outer_landing']; z_=zz(*OL['z']); decks.setdefault(OL['y'],[]).append(sbox(OL['x'][0],z_[0],OL['x'][1],z_[1]))
        pass
        # where people go on and off: each flight's ends, the Steps' flights, the lifts' doors, the face, the platforms
        ways=[]
        for f_ in L['flights']+[dict(band=None,x=L['outer']['x'],y=L['outer']['y'],z=L['outer']['z'])]:
            xb=bx[f_['band']] if f_.get('band') else f_['x']
            for zq,yq in ((f_['z'][0],f_['y'][0]),(f_['z'][1],f_['y'][1])): ways.append((yq,LineString([(xb[0],zq),(xb[1],zq)]).buffer(0.05)))
        # the outer pair leaves the walk over the tracks across the walk's near edge: its guard opens there (2026-10-19:
        # the run along that edge was unbroken, so the glass stood in the belt's path and cut the walk off from the pair)
        zo0,zo1=L['outer']['z']; xo0,xo1=L['outer']['x']; ze=min(T_['z'],key=lambda v:abs(v-zo1)); xe=xo0+(xo1-xo0)*((ze-zo0)/(zo1-zo0))
        ways.append((T_['y'],LineString([(xe-1.3,ze),(xe+1.3,ze)]).buffer(0.05)))
        ways.append((st['half_y'],LineString([(st['half'][0],st['z']-st['width']/2),(st['half'][0],st['z']+st['width']/2)]).buffer(0.05)))
        ways.append((st['half_y'],LineString([(st['half'][1],st['z']-st['width']/2),(st['half'][1],st['z']+st['width']/2)]).buffer(0.05)))
        def door_of(lf):
            x_,z_=lf['c']; h_=lf['size']/2
            if lf['door']=='w': return Point(x_-h_-0.6,z_),LineString([(x_-h_,z_-1.0),(x_-h_,z_+1.0)])
            return Point(x_,z_+lf['door']*(h_+0.6)),LineString([(x_-1.0,z_+lf['door']*h_),(x_+1.0,z_+lf['door']*h_)])
        for lf in L['lifts']:
            for yq in lf['stops']: ways.append((yq,door_of(lf)[1].buffer(0.35)))
        # the outer landing meets the outer platform along its whole west edge
        platline=LineString([(OL['x'][0],-200),(OL['x'][0],200)]).buffer(0.05); ways.append((OL['y'],platline))
        face=LineString([(F,-200),(F,200)]).buffer(0.05)
        for y_,ds in decks.items():
            U=unary_union(ds); edge=U.boundary.difference(face)
            # the walk over the tracks meets the outer platform's stair head and the gallery at its ends
            if abs(y_-L['over_tracks']['y'])<0.01: edge=edge.difference(LineString([(T_['x'][1],-200),(T_['x'][1],200)]).buffer(0.05))
            for yq,wg in ways:
                if abs(yq-y_)<0.01: edge=edge.difference(wg)
            for ln in (getattr(edge,'geoms',None) or [edge]):
                if ln.is_empty or ln.length<0.05: continue
                guards.append(dict(side=L['side'],y=round(y_,2),pts=[[round(x,2),round(z,2)] for x,z in ln.coords]))
            # an opening is never wider than the way through it (a flight's band, a lift door, the Steps' width)
            for hole in (getattr(U.boundary.difference(edge),'geoms',None) or [U.boundary.difference(edge)]):
                if not hole.is_empty and not hole.intersects(face) and not (abs(y_-OL['y'])<0.01 and hole.within(platline.buffer(0.1))): gap_max=max(gap_max,hole.length)
        # every flight ends on a deck: step off its head onto one, step onto its foot from one (2026-10-17: F3 and F4 had none)
        ro_deck=[sbox(rostrum['x'][0],rostrum['z'][0],F,rostrum['z'][1])]
        for f_ in L['flights']+[dict(name='outer pair',band=None,x=L['outer']['x'],y=L['outer']['y'],z=L['outer']['z'])]:
            xb=bx[f_['band']] if f_.get('band') else f_['x']; xm=(xb[0]+xb[1])/2; d_=1 if f_['z'][1]>f_['z'][0] else -1
            for zq,yq,beyond in ((f_['z'][0],f_['y'][0],-d_),(f_['z'][1],f_['y'][1],d_)):
                here=decks.get(yq,[])+(ro_deck if abs(yq-pf)<0.01 else [])
                if not any(dk.buffer(0.05).contains(Point(xm,zq+beyond*0.5)) for dk in here): problems.append(('arch front: a flight ends with no deck',L['side'],f_['name'],yq))
        # every lift stop opens onto a deck (the ground and the Rostrum included)
        for lf in L['lifts']:
            door=door_of(lf)[0]
            for yq in lf['stops']:
                if yq<0.01: continue
                here=decks.get(yq,[])+([sbox(rostrum['x'][0],rostrum['z'][0],rostrum['opening_x'][1],rostrum['z'][1])] if abs(yq-pf)<0.01 else [])
                if not any(d.buffer(0.3).contains(door) for d in here): problems.append(('arch front: a lift stop with no deck at its door',L['side'],lf['name'],yq))
    # the Rostrum: its front, its two ends and the edges of its deck across the opening, less the Steps' heads and the bay
    Rz=rostrum['z']; ro_=unary_union([sbox(rostrum['x'][0],Rz[0],F,Rz[1]),Point(rostrum['bay']['c']).buffer(rostrum['bay']['r']),sbox(F,-12,rostrum['opening_x'][1],12)])
    edge=ro_.boundary.difference(LineString([(F,-200),(F,-12)]).buffer(0.05)).difference(LineString([(F,12),(F,200)]).buffer(0.05))
    edge=edge.difference(LineString([(rostrum['opening_x'][1],-13),(rostrum['opening_x'][1],13)]).buffer(0.05))
    for zl in (-12,12): edge=edge.difference(LineString([(F,zl),(F+30,zl)]).buffer(0.05))     # the legs' inner faces
    for L in legs:
        for lf in L['lifts'][:1]: edge=edge.difference(Point(lf['c']).buffer(lf['size']/2*1.5))   # the front lift passes through
    for L in legs:
        st=L['steps']; edge=edge.difference(LineString([(rostrum['x'][0],st['z']-st['width']/2),(rostrum['x'][0],st['z']+st['width']/2)]).buffer(0.08))
    for ln in (getattr(edge,'geoms',None) or [edge]):
        if not ln.is_empty and ln.length>0.05: guards.append(dict(side='rostrum',y=pf,pts=[[round(x,2),round(z,2)] for x,z in ln.simplify(0.02).coords]))
    if gap_max>max(L['steps']['width'] for L in legs)+0.3: problems.append(('arch front: an opening in a guard wider than the way through it',round(gap_max,2)))
    A['front_guard']=dict(height=1.1,material='clear toughened glass on a bronze shoe, a bronze handrail on top',runs=guards)
    A['front']=dict(rostrum=rostrum,bands=dict(A=bandA,B=bandB),levels=levels,sky=sky,legs=legs,
                    bridge_x=(round(F-6.5,2),-332.0),east_concourse=dict(x=(-336.0,-332.0),y=hl),
                    material='glazed tubes in the legs\' pale ceramic diagrid; the Rostrum and the Steps in pale stone; lifts in glass')
    # ------------------------------------------------ checks
    H=A['train_hall']; P=problems
    for L in legs:
        for f_ in L['flights']:
            run_=abs(f_['z'][1]-f_['z'][0]); rise=f_['y'][1]-f_['y'][0]; ang=math.degrees(math.atan2(rise,run_))
            if ang>30.0+1e-6: P.append(('arch front: a flight too steep',L['side'],f_['name'],round(ang,1)))
            if rise>ESCALATORS['pair']['max_rise']+1e-6: P.append(('arch front: a flight rises too far',L['side'],f_['name']))
            if not (zi-0.01<=min(abs(v) for v in f_['z']) and max(abs(v) for v in f_['z'])<=zo+0.01): P.append(('arch front: a flight off its leg\'s face',L['side'],f_['name']))
        # in each band, anything stacked over anything else leaves 2.6 m (the deck 0.5 m deep)
        items=[]
        for f_ in L['flights']: items.append((f_['band'],f_['z'],f_['y'][0],f_['y'][1]))
        for g in L['galleries']:
            for bd in g['band']: items.append((bd,g['z'],g['y'],g['y']))
        def hz(it,z):
            za,zb=it[1]; t=(z-za)/((zb-za) or 1); return it[2]+(it[3]-it[2])*min(1,max(0,t))
        worst=1e9
        for i in range(len(items)):
            for j in range(len(items)):
                if i==j or items[i][0]!=items[j][0]: continue
                lo_=max(min(items[i][1]),min(items[j][1])); hi_=min(max(items[i][1]),max(items[j][1]))
                if hi_-lo_<0.6: continue
                for k in range(11):
                    z=lo_+(hi_-lo_)*k/10; a_,b_=hz(items[i],z),hz(items[j],z)
                    if a_>b_+0.01: worst=min(worst,a_-b_-0.5)
        L['_headroom']=round(worst,2)
        if worst<ESCALATORS['helix']['min_headroom']: P.append(('arch front: a flight or landing over another without headroom',L['side'],round(worst,2)))
        if L['over_tracks']['y']-0.8<H['y'][1]: P.append(('arch front: the crossing over the tracks cuts the train hall',L['side']))
        for lf in L['lifts']:
            if abs(lf['c'][1])-lf['size']/2<6.5: P.append(('arch front: a lift in the avenue',L['side'],lf['name']))
        st=L['steps']
        if st['foot']<CIVIC_SQUARE['forecourt']['rect'][0]: P.append(('arch front: the City Steps run past the forecourt',L['side'],st['foot']))
        if abs(st['z'])-st['width']/2<12.0: P.append(('arch front: the City Steps in the gate\'s opening',L['side']))
        for fs in CIVIC_SQUARE['flagstaffs']:
            if abs(fs['c'][1]-st['z'])<st['width']/2+1.0 and st['foot']<=fs['c'][0]<=st['head']: P.append(('arch front: a flagstaff on the steps',))
    if abs(rostrum['y']-pf)>1e-6: P.append(('arch front: the Rostrum is not level with the Wall Line\'s platform',))
    if rostrum['opening_x'][1]-rostrum['opening_x'][0]<1.0: P.append(('arch front: the Rostrum does not reach the inner platform',))
    # the high line's platforms (at the station, 30 m long) begin within the bridge's west extension, where G37 lands
    st_=[x for x in CROSS['stations'] if x['name']=='East Gate'][0]; pw_end=st_['at'][0]-CROSS['platform'][0]/2
    if not (A['front']['bridge_x'][0]<=pw_end<=F): P.append(('arch front: the high line platforms\' west ends are not at the tubes',pw_end))
    if A['front']['bridge_x'][1]<st_['at'][0]+CROSS['platform'][0]/2+3.0: P.append(('arch front: no concourse beyond the buffer stops',))

## the square's checks: every element inside it and off the high line's pier stems; the hotel's front left open (nothing
## taller than a lawn between its facade and the water, but the fountain); and every Crossing tower's helix band clear
## of the head beams (a beam ends at the tower's drum; nothing structural enters the band, user 2026-10-17)
def _square_checks():
    from shapely.geometry import box as sbox, Point
    Q=CIVIC_SQUARE; R=sbox(*Q['rect']); me=CROSS['services'][1]; P=problems
    if [o for o in OPENS if o[0]=='Civic Plaza'][0][1:]!=Q['rect']: P.append(('square: Civic Plaza and the square disagree',))
    stems=[Point(x,0) for x in me['piers'] if Q['rect'][0]<=x<=Q['rect'][2]]
    things=[('mirror',sbox(*Q['mirror']['rect']))]+[(l['name'],sbox(*l['rect'])) for l in Q['lawns']]+\
           [(f['name'],Point(f['c']).buffer(f['r'])) for f in Q['fountains']]+[(m['name'],sbox(m['c'][0]-m['size'][0]/2,m['c'][1]-m['size'][1]/2,m['c'][0]+m['size'][0]/2,m['c'][1]+m['size'][1]/2)) for m in Q['monuments']]+\
           [('statue',Point(t['c']).buffer(1.2)) for t in Q['statues']]+[('flagstaff',Point(f['c']).buffer(0.6)) for f in Q['flagstaffs']]
    for n_,g in things:
        if not R.contains(g): P.append(('square: outside the square',n_))
        for st in stems:
            if n_!='mirror' and g.distance(st)<3.0: P.append(('square: against a high-line pier',n_))
    for n_,g in things:
        for b_ in B:
            if b_['r'] and g.intersects(sbox(*b_['r'])): P.append(('square: on a building',n_,b_['n']))
    hotel=[b_ for b_ in B if b_['n']==1][0]['r']
    front=sbox(hotel[0],Q['rect'][1],hotel[2],-8)
    for row in Q['tree_rows']:
        for k in range(int((row['x'][1]-row['x'][0])/row['every'])+1):
            if front.contains(Point(row['x'][0]+k*row['every'],row['z'])): P.append(('square: a tree in front of the hotel',))
    for t in Q['statues']:
        if any(sbox(*l['rect']).buffer(-0.5).contains(Point(t['c'])) for l in Q['lawns']) is False and not any(sbox(*l['rect']).contains(Point(t['c'])) for l in Q['lawns']): P.append(('square: a statue off its lawn',t['c']))
    # the Crossing's head beams stop at the drums: no beam inside any tower's band (radius band[1] + gallery)
    C=CROSSING; T=C['tower']; cx,cz=C['c']; sp=CROSS['services'][0]
    for TW in C['towers']:
        tx,tz=TW['c']
        for zb in C['_beams']['spine']['z']:
            end=T['offset']-T['drum']+0.4   # the beam reaches 0.4 m into the drum's ring girder
            for xe in (cx-end,cx+end):
                if abs(zb-tz)<0.8 and math.hypot(xe-tx,zb-tz)<T['band'][1]+0.3: P.append(('crossing: a head beam inside a helix',TW['name']))
        for xb in C['_beams']['high']['x']:
            end=T['offset']-T['drum']+0.4
            for ze in (cz-end,cz+end):
                if abs(xb-tx)<0.9 and math.hypot(xb-tx,ze-tz)<T['band'][1]+0.3: P.append(('crossing: a head beam inside a helix',TW['name']))
    C['_beam_clear']=round(T['offset']-(T['offset']-T['drum']+0.4)-T['band'][1],2)

## The Clock Room (city.md 7a): its openings laid out from the dome, the platforms and the towers' lifts, then checked:
## every way in arrives on the floor with a clear landing and a guard round its well; no opening fouls another.
def _clock_room():
    from shapely.geometry import box as sbox, Point, Polygon
    C=CROSSING; Dm=C['dome']; Rm=Dm['room']; dr_=Dm['drum']; ck=Dm['clocks']; ey=ck['eye']; R=C['roof']; P=problems
    cx,cz=C['c']; X=CROSS; me=X['services'][1]; base=R['y']+R['th']; me_fl=me['rail']+PLATFORMS['floor']
    E=ESCALATORS['pair']; tn=math.tan(math.radians(E['angle'])); w=E['w']; ro=Rm['runoff']
    plat_out=X['track']+PLATFORMS['edge']+PLATFORMS['width']; half_len=X['platform'][0]/2
    se=[(dr_['half']*math.copysign(abs(math.cos(a))**(2/dr_['n']),math.cos(a)),dr_['half']*math.copysign(abs(math.sin(a))**(2/dr_['n']),math.sin(a))) for a in [i/360*2*math.pi for i in range(360)]]
    inside=Polygon([(cx+x,cz+z) for x,z in se]); glass_in=inside.buffer(-0.3)
    sill=round(base+ck['centre']+ey['sill'],2); Dm['base']=round(base,2)
    # the eyes: a sill wide and tall enough to stand in, inside the hour ring (which turns round it, never across it)
    chord=2*math.sqrt(max(0,ey['r']**2-ey['sill']**2)); head=ey['r']-ey['sill']
    ey['sill_y']=sill; ey['chord']=round(chord,2); ey['headroom']=round(head,2)
    if chord<2.4 or head<2.6: P.append(('clock room: an eye too small to pass through',round(chord,2),round(head,2)))
    if ey['r']+ey['sleeve']>ck['rings'][0][1]+0.01: P.append(('clock room: an eye\'s sleeve under the turning hour ring',))
    w=E['w']; ro=Rm['runoff']; opens=[]
    # the arrival wells: from each platform's widening, two pairs either side of the axis, up through the floor
    a_rise=base-me_fl; a_run=a_rise/tn
    if a_rise>E['max_rise']: P.append(('clock room: an arrival rises too far for one flight',round(a_rise,2)))
    arrivals=[]; wid=[]
    for sz in (-1,1):
        z_w=(cz+sz*plat_out,cz+sz*(plat_out+Rm['widening']))
        xs=[x for lo,hi in [Rm['arrive_x']] for x in (lo,hi)]
        wd=[round(cx-xs[1]-0.3,2),round(min(z_w),2),round(cx+xs[1]+0.3,2),round(max(z_w),2)]; wid.append(dict(side='north' if sz<0 else 'south',rect=wd,y=me_fl))
        for sx in (-1,1):
            xm=round(cx+sx*(xs[0]+xs[1])/2,2); zf=cz+sz*(plat_out+Rm['widening']); zh=zf+sz*a_run
            # the well: the floor is open wherever a rider on the flight would have less than 2.6 m under it
            z_open=zf+sz*max(0.0,(R['y']-2.6-me_fl))/tn
            well=[round(xm-w/2-0.2,2),round(min(z_open,zh),2),round(xm+w/2+0.2,2),round(max(z_open,zh),2)]
            arrivals.append(dict(side='north' if sz<0 else 'south',foot=(xm,round(zf,2)),head=(xm,round(zh,2)),y=(me_fl,round(base,2)),well=well,
                                 arrive=[round(xm-w/2,2),round(min(zh,zh+sz*ro),2),round(xm+w/2,2),round(max(zh,zh+sz*ro),2)]))
            opens.append(('arrival %s %s'%('n' if sz<0 else 's','e' if sx>0 else 'w'),sbox(*well)))
            if not glass_in.contains(sbox(*arrivals[-1]['arrive'])): P.append(('clock room: an arrival lands against the glass',arrivals[-1]['side']))
    # the lifts: on to the room, a lantern each, its door facing the bell
    lifts=[]
    for TW in C['towers']:
        lx,lz=TW['lift']['c']; lr=TW['lift']['r']; d=math.hypot(cx-lx,cz-lz); door=(round(lx+(cx-lx)/d*(lr+1.5),2),round(lz+(cz-lz)/d*(lr+1.5),2))
        lifts.append(dict(tower=TW['name'],c=(lx,lz),r=lr,stops=[0,round(13.2+PLATFORMS['floor'],2),me_fl,round(base,2)],door=door,top=round(base+Rm['lantern'],2)))
        opens.append(('lantern '+TW['name'],Point(lx,lz).buffer(lr+0.2).union(Point(door).buffer(1.2))))
        if not glass_in.contains(Point(lx,lz).buffer(lr+1.5)): P.append(('clock room: a lift lantern against the glass',TW['name']))
    # no opening fouls another; each stands on the floor inside the glass
    for i in range(len(opens)):
        for j in range(i+1,len(opens)):
            if opens[i][1].distance(opens[j][1])<0.5: P.append(('clock room: two openings foul each other',opens[i][0],opens[j][0],round(opens[i][1].distance(opens[j][1]),2)))
    # an eye is reached only by flying: nothing walkable or rideable rises to it (2026-10-18)
    for a in arrivals:
        if a['y'][1] > sill - 2.0: P.append(('clock room: an escalator rises toward an eye',))
    # the arrivals climb in the open between the towers, off their drums, lifts and bridges, and the widenings off the line
    for a in arrivals:
        ln=sbox(a['foot'][0]-w/2,min(a['foot'][1],a['head'][1]),a['foot'][0]+w/2,max(a['foot'][1],a['head'][1]))
        for TW in C['towers']:
            if ln.distance(Point(TW['c']))<C['tower']['drum']+0.5: P.append(('clock room: an arrival against a tower',TW['name']))
            if ln.distance(Point(TW['lift']['c']))<TW['lift']['r']+0.5: P.append(('clock room: an arrival against a lift',TW['name']))
    for wd in wid:
        r_=wd['rect']
        if abs(r_[0]-cx)>half_len or abs(r_[2]-cx)>half_len: P.append(('clock room: a widening past its platform',wd['side']))
        for TW in C['towers']:
            if sbox(*r_).distance(Point(TW['lift']['c']))<TW['lift']['r']+0.3 or sbox(*r_).distance(Point(TW['c']))<C['tower']['drum']+0.3: P.append(('clock room: a widening against a tower',wd['side']))
    if Dm['bell']['bottom']<base+2.6+1.0: P.append(('clock room: the bell hangs too low over the room',))
    Rm.update(sill=sill,arrivals=arrivals,widenings=wid,lifts=lifts,
              entries=['four escalator pairs from the high line\'s platforms, up through the arrival wells','the four tower lifts, to their lanterns','the four clock eyes, for fliers and gliders only'])

_block_checks()
_cross_checks()
_clock_room()
_arch_front()
_square_checks()
_deck_checks()
def _spine_spans():
    # the Spine's supports in order (its frames, the Deck's columns where it rides the Deck, the Crossing's head beams):
    # no span longer than 31 m (a gate's escalator lane needs 30.3 m; the Crossing's middle span is 26 m)
    sp=[sv for sv in CROSS['services'] if sv['line']=='Spine Line'][0]; x0=sp['pts'][0][0]
    sup=sorted(set([f_[1] for f_ in sp['frames']]+[round(c_[1],1) for c_ in DECK['columns'] if abs(c_[0]-x0)<4.5]+CROSSING['_beams']['spine']['z']))
    sup=[z_ for z_ in sup if abs(math.hypot(x0-CX,z_)-WALL['r'])>=WALL['thick']/2+20]
    gaps=[round(b_-a_,1) for a_,b_ in zip(sup,sup[1:])]; sp['_max_span']=max(gaps)
    if max(gaps)>31.0: problems.append(('cross: a Spine span too long between its frames',max(gaps),sup))
_spine_spans()
## The planting and the Deck's parapets, laid out exactly (2026-10-17, plan iteration 3), so a builder places every bed,
## tree, shrub, reed clump, rock, agave and parapet at a recorded point rather than re-deriving a rule:
## - DECK['parapets']: [x0, z0, x1, z1, height, kind]: each run's edges, left open wherever anything walkable meets the
##   edge (another run, a tower's gallery, a ramp tower, a lift, an escalator's head, a building's Deck door);
##   kind 'rail' (a 1.1 m railing) or 'glass' (a bridge's glass side);
## - DECK['beds']: the garden walk's beds (DECK['garden']), each a centreline (pts, 1 m apart) and a width, alternating
##   sides so a path of at least garden.path stays clear; DECK['trees']: a small ghaf in every second bed 1.8 m wide or
##   more, never within 6 m of the Spine (its deck is 5.5 m over the Deck) or 4 m of a Crossing tower;
## - PARK['shrubs'], ['reeds'], ['rocks'], ['agave']: the park's small planting; CROSSING['climbers']: the towers'
##   climber panels (tower, the bay's bearing in degrees, from y0 to y1); CROSSING['rain_gardens'].
def _planting():
    from shapely.geometry import Point, LineString, box as sbox
    D=DECK; G=D['garden']; C=CROSSING; T=C['tower']; runs=D['runs']; lines=[LineString(r['pts']) for r in runs]
    def on_run(x,z,skip,inset=0.0):
        q=Point(x,z); return any(k!=skip and lines[k].distance(q)<runs[k]['w']/2-inset for k in range(len(runs)))
    def walkable(x,z,skip):
        return (on_run(x,z,skip,-0.05) or any(math.hypot(x-t['c'][0],z-t['c'][1])<T['drum']+0.7 for t in C['towers'])
            or any(math.hypot(x-t['c'][0],z-t['c'][1])<t['r']+0.8 for t in D['ramps']+D['lifts'])
            or any(math.hypot(x-e['head'][0],z-e['head'][1])<2.6 for e in D.get('escalators',[]))
            or any(math.hypot(x-p_[0],z-p_[1])<2.8 for _,p_,_ in D['doors']))
    sp=[sv for sv in CROSS['services'] if sv['line']=='Spine Line'][0]; spl=LineString(sp.get('path',sp['pts']))
    R2=lambda v: round(v,2)
    parapets=[]; beds=[]; trees=[]; bedno=0
    for k,r in enumerate(runs):
        pts=r['pts']; w=r['w']; ring=r['kind']=='ring'; ext=w/2 if ring else 0.0
        low=r['name'].startswith('Crossing bridge'); kind='glass' if r['kind']=='bridge' else 'rail'
        h=(1.3 if low else 2.8) if r['kind']=='bridge' else D['rail']
        segs=[LineString([pts[j-1],pts[j]]) for j in range(1,len(pts))]
        for i in range(1,len(pts)):
            a,b=pts[i-1],pts[i]; L=math.hypot(b[0]-a[0],b[1]-a[1])
            if L<0.01: continue
            ux,uz=(b[0]-a[0])/L,(b[1]-a[1])/L
            at=lambda t,o: (a[0]+ux*t-uz*o,a[1]+uz*t+ux*o)
            for e in (-1,1):
                run0=[None]
                def flush(t1):
                    if run0[0] is not None and t1-run0[0]>0.05:
                        p0=at(run0[0],e*(w/2-0.1)); p1=at(t1,e*(w/2-0.1)); parapets.append([R2(p0[0]),R2(p0[1]),R2(p1[0]),R2(p1[1]),h,kind])
                    run0[0]=None
                t=-ext
                while t<L+ext-1e-6:
                    tm=t+0.25; px,pz=at(tm,e*(w/2-0.1)); qx,qz=at(tm,e*(w/2+0.7))
                    inown=any(j!=i-1 and segs[j].distance(Point(px,pz))<w/2-0.2 for j in range(len(segs)))
                    if walkable(qx,qz,k) or inown or on_run(px,pz,k,0.2): flush(t)
                    elif run0[0] is None: run0[0]=t
                    t+=0.5
                flush(L+ext)
        if r['kind']=='bridge': continue
        cum=[0.0]
        for j in range(1,len(pts)): cum.append(cum[-1]+math.hypot(pts[j][0]-pts[j-1][0],pts[j][1]-pts[j-1][1]))
        total=cum[-1]
        def along(sx,o):
            sx=(sx%total) if ring else max(0.0,min(total,sx)); j=1
            while j<len(cum)-1 and cum[j]<sx: j+=1
            a,b=pts[j-1],pts[j]; L=(cum[j]-cum[j-1]) or 1.0; f=(sx-cum[j-1])/L; ux,uz=(b[0]-a[0])/L,(b[1]-a[1])/L
            return (a[0]+(b[0]-a[0])*f-uz*o,a[1]+(b[1]-a[1])*f+ux*o)
        t=0.0 if ring else 1.5
        while t<total-(0.0 if ring else 3.0):
            n=bedno; bedno+=1
            ln=G['bed_len'][0]+((n*3)%7)/6*(G['bed_len'][1]-G['bed_len'][0]); bw=G['bed'][0]+((n*5)%4)/3*(G['bed'][1]-G['bed'][0])
            side=1 if n%2 else -1; l=min(ln,total-t-G['gap']) if ring else min(ln,total-1.5-t); o=side*(w/2-bw/2-0.15)
            ok=l>4 and w-bw>=G['path']-1e-6; u=0.0
            while ok and u<=l:
                px,pz=along(t+u,o); qx,qz=along(t+u,side*(w/2+0.7))
                if walkable(qx,qz,k) or on_run(px,pz,k,-1.0): ok=False
                u+=1.0
            if ok:
                cl=[along(t+u_,o) for u_ in [x_*1.0 for x_ in range(int(l))]]+[along(t+l,o)]
                beds.append(dict(run=r['name'],w=R2(bw),pts=[[R2(x),R2(z)] for x,z in cl]))
                cx,cz=along(t+l/2,o)
                if bw>=1.8 and n%G['tree_every']==0 and spl.distance(Point(cx,cz))>=6 and not any(math.hypot(cx-t_['c'][0],cz-t_['c'][1])<T['drum']+4 for t_ in C['towers']):
                    trees.append(dict(kind=G['tree']['kind'],c=[R2(cx),R2(cz)],y=round(D['level']+0.45,2),h=G['tree']['h'],bed=len(beds)-1))
            t+=l+G['gap']
    D['parapets']=parapets; D['beds']=beds; D['trees']=trees
    # a Deck tree's crown clears every building beside it, and a bed never takes the path below its minimum
    tk=TREE_KIT[G['tree']['kind']]; cr=tk['crown']*G['tree']['h']
    for t_ in trees:
        for b_ in named:
            if b_['r'] and sbox(*b_['r']).distance(Point(t_['c']))<cr*0.8 and HEIGHTS.get(b_['n'],0)>D['level']: problems.append(('deck: a tree\'s crown into a building',t_['c'],b_['n']))
    # the park's small planting: shrubs along its edge (clear of its walks and the ramp towers and lifts), reed clumps
    # and flat stones round the pond, rocks and agave in the dry garden, and the towers' climbers and rain gardens
    P=PARK; px0,pz0,px1,pz1=P['rect']; shrubs=[]
    def shrub(x,z):
        if any(w_[0]-1.5<x<w_[2]+1.5 and w_[1]-1.5<z<w_[3]+1.5 for w_ in P['walks']): return
        if any(math.hypot(x-t['c'][0],z-t['c'][1])<t['r']+2 for t in D['ramps']+D['lifts']): return
        shrubs.append([R2(x),R2(z)])
    x=px0+5
    while x<=px1-5: shrub(x,pz0+1.5); shrub(x,pz1-1.5); x+=6
    z=pz0+6
    while z<=pz1-6: shrub(px0+1.5,z); shrub(px1-1.5,z); z+=6
    P['shrubs']=shrubs
    (pcx,pcz),(rx,rz)=P['pond']['c'],P['pond']['r']; reeds=[]; rocks=[]
    for k in range(40):
        a=k/40*2*math.pi; j=1.0+0.06*((k*7)%3)
        if k%9==4: rocks.append(dict(c=[R2(pcx+rx*j*math.cos(a)),R2(pcz+rz*j*math.sin(a))],half=[1.1,0.25,0.8],role='a flat stone at the water\'s edge')); continue
        if k%5==0: continue
        reeds.append(dict(c=[R2(pcx+(rx*j-0.1)*math.cos(a)),R2(pcz+(rz*j-0.1)*math.sin(a))],stems=3,h=round(1.6+0.4*(k%3),2)))
    dg=P['dry_garden']; agave=[]
    for k in range(18):
        x=dg[0]+2+((k*37)%100)/100*(dg[2]-dg[0]-4); z=dg[1]+2+((k*61)%100)/100*(dg[3]-dg[1]-4); big=k%4==0
        if any(math.hypot(t['c'][0]-x,t['c'][1]-z)<2.5 for t in P['trees']): continue
        if k%3==1: agave.append([R2(x),R2(z)])
        else:
            rocks.append(dict(c=[R2(x),R2(z)],half=[2.2,1.1,1.6] if big else [1.0,0.55,0.8],role='a boulder'))
            if big:
                for dx,dz in ((2.4,0.8),(-1.8,1.6),(0.6,-2.2)): rocks.append(dict(c=[R2(x+dx),R2(z+dz)],half=[0.6,0.35,0.5],role='a stone'))
    P['reeds']=reeds; P['rocks']=rocks; P['agave']=agave
    climbers=[]; gardens=[]; lv=[0]+[y for y in C['towers'][0]['levels'] if 0<y<C['roof']['y']]; bayA=2*math.pi/T['ribs']; cx0,cz0=C['c']
    for ti,t_ in enumerate(C['towers']):
        tx,tz=t_['c']; sx=math.copysign(1,tx-cx0); sz=math.copysign(1,tz-cz0)
        opens=[(w_['y'],math.radians(w_['bearing'])) for w_ in t_['ways_out']]
        for k in range(T['ribs']):
            ac=k*bayA
            for m,y in enumerate(lv):
                y0=y+(0.5 if m else 0.0); nxt=lv[m+1] if m+1<len(lv) else C['roof']['y']; grow=(nxt-y0)*(0.45+0.45*(((k*7+m*3)%5)/4))
                if any(abs(y_-y)<0.1 and abs(math.atan2(math.sin(ac-b_),math.cos(ac-b_)))<bayA*0.75 for y_,b_ in opens): continue
                if (k+m)%3==2: continue
                climbers.append([ti,round(math.degrees(ac),1),R2(y0),R2(y0+grow)])
        # the rain garden is a ring round the drum's foot (never inside it: the helix lands on the lawn there), cut by a
        # paved path along each way out on the lawn, and clear of the lift; no reed in a path or against the lift
        paths=[w_['bearing'] for w_ in t_['ways_out'] if w_['y']==0]; pw=t_['ways_out'][0]['width']; lx,lz=t_['lift']['c']; lr=t_['lift']['r']
        def _clear(x,z):
            if math.hypot(x-lx,z-lz)<lr+0.6: return False
            for b_ in paths:
                ux,uz=math.cos(math.radians(b_)),math.sin(math.radians(b_))
                if (x-tx)*ux+(z-tz)*uz>0 and abs(-(x-tx)*uz+(z-tz)*ux)<pw/2+0.4: return False
            return True
        rd=[[R2(tx+(T['drum']+1.2+(q%3)*0.7)*math.cos(q/14*2*math.pi+0.2)),R2(tz+(T['drum']+1.2+(q%3)*0.7)*math.sin(q/14*2*math.pi+0.2)),round(1.4+(q%2)*0.6,2)] for q in range(14) if q%7!=3]
        gardens.append(dict(c=list(t_['c']),r_in=T['drum'],r=round(T['drum']+3.5,2),paths=paths,path_width=pw,lift_clear=round(lr+0.3,2),
                            reeds=[q for q in rd if _clear(q[0],q[1])]))
    C['climbers']=climbers; C['rain_gardens']=gardens
_planting()
for _g in CROSSING['rain_gardens']:
    if _g['r_in']<CROSSING['tower']['drum'] or len(_g['reeds'])<6: problems.append(('crossing: a rain garden inside its drum, or bare of reeds',_g['c']))
    if len(_g['paths'])!=3: problems.append(('crossing: a rain garden without a path for each way out on the lawn',_g['c']))
_T=CROSSING['tower']
if _T['rail_r']*math.cos(math.pi/36)-0.06<_T['gallery_clear'] or _T['gallery_clear']<_T['band'][1]: problems.append(('crossing: the gallery or its rail stands inside the helix band',_T['rail_r']))
if not 0.0<=CROSSING['lawn_y']<0.05: problems.append(('crossing: the lawn stands at or above the ways-out floor',CROSSING['lawn_y']))
## The timetable (city.md 6g, 2026-10-17, at the user's direction). A clock-face
## service: on every line a train every 60 real seconds, which in the game's
## clock (one real second is one game minute) is a train every hour, on the same
## minute of every hour. Stops are 8 s at ordinary stations and 12 s at the
## interchanges (both gates of the Spine, both gates of the Meridian, the
## Crossing); the shuttles' turnaround at each terminus takes up the slack so a
## round trip is a whole number of headways. Lines run from 5:00 to midnight;
## through the night the Wall Line keeps one train each way, the Watch train.
## The offsets set a pulse: the Spine's southbound and the Meridian's westbound
## trains stand together at the Crossing on the hour, and the Wall Line's trains
## each way meet the Spine's at the North Gate. Derived: each line's circuit
## (events per stop, relative to a train's start), its trains, their offsets,
## and the minute past the hour each train leaves each stop.
TIMETABLE=dict(clock='one real second is one game minute; a game day is 24 real minutes',
  headway=60.0,service=dict(start=5,end=24,night=dict(line='Wall Line',trains_each_way=1,name='the Watch train')),
  dwell=dict(ordinary=8.0,interchange=12.0,terminus_min=12.0),
  interchanges=['The Crossing','North Gate','South Gate','East Gate','West Gate'],
  pulse=dict(at='The Crossing',lines=[('Spine Line','south'),('Meridian Line','west')],wall_meets=('North Gate','Spine Line')))
def _timetable():
    from shapely.geometry import LineString, Point
    TT=TIMETABLE; H=TT['headway']; D=TT['dwell']; lines={}
    dw=lambda nm: D['interchange'] if nm in TT['interchanges'] else D['ordinary']
    for sv in CROSS['services']:
        line=sv['line']; v=CROSS['cars']['speed']; Ls=LineString(sv['pts'])
        stops=sorted((round(Ls.project(Point(st['at'])),2),st['name']) for st in CROSS['stations'] if line in st['lines'])
        run=(stops[-1][0]-stops[0][0])/v; mid=sum(dw(nm) for _,nm in stops[1:-1])
        n=math.ceil((2*run+2*mid+2*D['terminus_min'])/H-1e-9); T=(n*H-2*run-2*mid)/2
        if T<D['terminus_min']-1e-6: problems.append(('timetable: a terminus turnaround too short',line,T))
        if T>=H: problems.append(('timetable: two trains at a terminus at once',line,T))
        ev=[]; t=0.0
        dirs=('south','north') if line=='Spine Line' else ('west','east')
        for leg,order in enumerate((stops,stops[::-1])):
            for k,(s0,nm) in enumerate(order):
                if k: t+=abs(s0-order[k-1][0])/v
                arr=t; d_=T if k==len(order)-1 else (0.0 if k==0 else dw(nm))
                if k==0 and leg==0: arr=t
                t+=d_ if k else 0.0
                ev.append(dict(stop=nm,s=s0,dir=dirs[leg],arr=round(arr,2),dep=round(t,2),kind='start' if k==0 else ('end' if k==len(order)-1 else 'stop')))
        # the first event's dwell is the turnaround at the start terminus, at the circuit's end
        ev[0]['arr']=round(n*H-T,2) if False else ev[0]['arr']
        lines[line]=dict(kind='shuttle',speed=v,trains=n,circuit=n*H,turnaround=round(T,2),events=ev,length=round(Ls.length,1),cars=TRAIN['consists'][line]['cars'])
    WL=WALL; v=WL['line']['speed']; Lw=WL['length']
    for dname,sgn in (('inner',1),('outer',-1)):
        st=sorted(((x['s'] if sgn>0 else (Lw-x['s'])%Lw),x['name']) for x in WL['stations'])
        run=Lw/v; dws=[dw(nm) for _,nm in st]; n=math.ceil((run+sum(dws))/H-1e-9); pad=n*H-run-sum(dws)
        ev=[]; t=0.0
        for k,(s0,nm) in enumerate(st):
            if k: t+=(s0-st[k-1][0])/v
            arr=t; t+=dws[k]+(pad if k==0 else 0.0)
            ev.append(dict(stop=nm,s=round(s0 if sgn>0 else (Lw-s0)%Lw,2),dir=dname,arr=round(arr,2),dep=round(t,2),kind='stop'))
        lines['Wall Line '+dname]=dict(kind='loop',dir=sgn,speed=v,trains=n,circuit=n*H,pad=round(pad,2),events=ev,length=round(Lw,1),cars=TRAIN['consists']['Wall Line']['cars'])
    # offsets: the pulse at the Crossing, then the Wall Line's trains meeting the Spine's at the North Gate
    def first(line,stop,dir_=None,key='arr'):
        return [e[key] for e in lines[line]['events'] if e['stop']==stop and (dir_ is None or e['dir']==dir_)][0]
    off={}
    for line,dir_ in TT['pulse']['lines']:
        e=[e for e in lines[line]['events'] if e['stop']==TT['pulse']['at'] and e['dir']==dir_][0]
        off[line]=round((-(e['arr']+e['dep'])/2)%H,2)
    # the Wall Line's trains stand at the gate in the middle of the Spine's turnaround there, so both changes are short
    g,ln=TT['pulse']['wall_meets']; e_end=[e for e in lines[ln]['events'] if e['stop']==g and e['kind']=='end'][0]
    mid_=((e_end['arr']+e_end['dep'])/2+off[ln])%H
    for d_ in ('inner','outer'):
        e=[e for e in lines['Wall Line '+d_]['events'] if e['stop']==g][0]
        off['Wall Line '+d_]=round((mid_-(e['arr']+e['dep'])/2)%H,2)
    for k,L_ in lines.items():
        L_['offset']=off[k]
        # the minute past the hour each stop's departures leave (one per hour, one per headway in real seconds)
        L_['minutes']=[dict(stop=e['stop'],dir=e['dir'],minute=int(math.floor((e['dep']+off[k])%H))%60) for e in L_['events'] if e['kind']!='end']
    # each line's train fits its platforms; interchange waits at the gates and the Crossing
    for k,L_ in lines.items():
        base='Wall Line' if k.startswith('Wall') else k
        n_=TRAIN['consists'][base]['cars']; length=n_*TRAIN['car'][0]+(n_-1)*TRAIN['gangway']
        plat=WALL['platform'][0] if base=='Wall Line' else CROSS['platform'][0]
        if length>plat-4: problems.append(('timetable: a train longer than its platforms',k))
    TT['lines']=lines
    waits=[]
    for a_,b_,stop in (('Wall Line inner','Spine Line','North Gate'),('Wall Line outer','Spine Line','South Gate'),('Spine Line','Wall Line inner','North Gate'),('Spine Line','Wall Line outer','North Gate'),('Spine Line','Wall Line inner','South Gate'),('Spine Line','Wall Line outer','South Gate'),('Spine Line','Meridian Line','The Crossing'),('Meridian Line','Spine Line','The Crossing'),('Meridian Line','Wall Line inner','East Gate'),('Meridian Line','Wall Line inner','West Gate')):
        A_=[(e['arr']+off[a_])%H for e in lines[a_]['events'] if e['stop']==stop and e['kind']!='start']; B_=[(e['dep']+off[b_])%H for e in lines[b_]['events'] if e['stop']==stop and e['kind']!='end']
        if not A_ or not B_: continue
        w=min((b2-a2-1.0)%H for a2 in A_ for b2 in B_)
        waits.append(dict(stop=stop,arrive=a_,leave=b_,wait=round(w,1)))
    TT['waits']=waits
    if max(L_['trains'] for L_ in lines.values())>6: problems.append(('timetable: more trains than a small city runs on one line',))
_timetable()
## The launch site (city.md 12, proposed 2026-10-17 at the user's direction): the
## way to the Space Kingdom. The ASAN launch vehicle (the spacecraft of the Demo
## World, scripts/demo_spaceship.gd) stands on a pad in the open desert north-east
## of Moy, between the Ice plateau and the main plateau's cliff, far enough from
## the wall, the turbines and the Ice plateau's slope for a launch. It is not part
## of the city: it keeps its own security, like the works outside the wall.
## How it stands up: it is built lying down, as in the Demo World, in the
## horizontal integration hangar, rolled out on a strongback along the erector
## rails and raised through 90 degrees about a hinge at the launch mount (after
## the Falcon 9's transporter-erector and the Soyuz's rail erector); in the game,
## the same ship node under a parent turned -90 degrees about its own X axis, so
## its nose (+Z) points up and its doorway (+X) faces the launch tower.
## Its boosters are strap-ons that separate in flight and fly back to land on the
## two landing zones (after the Falcon Heavy's side boosters), so the concept reads
## on the ground: folded landing legs and grid fins on the boosters, empty landing
## pads before a launch, boosters standing on them after.
## World (x, z) in metres; heights above the desert floor (the basin datum).
## ship: the Demo World ship's parts (half-extents along its own X, Y, Z, from
## demo_spaceship.gd) for the drawings; the stack's heights are derived.
LAUNCH_SITE=dict(
  name='the ASAN launch complex',pad=(-250.0,-580.0),
  mount=dict(half=(15.0,15.0),deck=8.0,trench=dict(to=(-250.0,-660.0),w=14.0,note='the flame trench under the mount runs north, away from the tower, the hangar and Moy')),
  ship=dict(core=(11.0,11.0,35.0),cockpit=dict(c=(0,-1.3,43.0),half=(11.0,4.8,7.5)),
            boosters=[dict(c=(-6.0,sd*12.0,-6.0),half=(4.6,4.6,24.0),nose=dict(c=(-6.0,sd*12.0,20.0),half=(4.0,4.0,6.0)),bell=dict(c=(-6.0,sd*12.0,-32.0),half=(3.6,3.6,3.4))) for sd in (-1,1)],
            bells=[dict(c=(bx,by,-38.0),half=(3.2,3.2,4.0)) for bx in (-4.2,4.2) for by in (-4.2,4.2)],
            skirt=dict(c=(0,0,-34.0),half=(11.3,11.3,3.0)),door=dict(z=-6.0,up=-1.0,half=(6.5,5.0)),clearance=2.0),
  # the launch tower on the doorway's side, its crew access arm swinging out to the door; a lift inside
  tower=dict(half=(6.0,6.0),height=118.0,mast=12.0,gap=12.0,arm=dict(w=3.0),lift=True),
  # the horizontal integration hangar and the erector rails out to the mount (the strongback rolls the ship out lying down)
  hangar=dict(c=(-250.0,-380.0),half=(22.0,50.0),height=34.0,door='north'),
  rails=dict(gauge=12.0),
  blockhouse=dict(c=(-205.0,-430.0),half=(12.0,8.0),height=6.0,note='the firing room behind an earth blast bank, its windows facing the pad'),
  landing_zones=[dict(name='LZ-1',c=(-150.0,-720.0),r=25.0),dict(name='LZ-2',c=(-345.0,-705.0),r=25.0)],
  fence=dict(pts=[(-300,-320),(-180,-320),(-110,-780),(-390,-780),(-395,-700),(-290,-600),(-285,-480),(-300,-320)],gate=(-200,-320),note='its own security, like the works'),
  track=dict(pts=[(-560,-215),(-560,-260),(-420,-310),(-200,-320)],w=8.0,note='an unpaved service track from the North Gate to the site\'s gate'),
  clear=dict(wall=300.0,turbines=220.0,plateau_slope=50.0,world_edge=120.0,village=300.0,pads=150.0),
  boarding=dict(sequence=['the service track from the North Gate to the site gate','the gate (its condition: open)','the tower lift to the crew access arm','the doorway: boarding is a seated launch, the cabin deck being vertical on the pad','the countdown and ignition (the four core bells and both boosters)','lift-off and the roll','booster separation; the boosters relight, fly back and land on LZ-1 and LZ-2','core flight; fade to the Space Kingdom, where the ship flies level, as in the Demo World, without its boosters'],
    conditions='open (city.md 12; the owner to decide)'),
)
def _launch_checks():
    from shapely.geometry import Point, Polygon, LineString, box as sbox
    L=LAUNCH_SITE; S=L['ship']; px,pz=L['pad']; P=Point(L['pad'])
    # the stack's heights: the core's bells clear the mount deck; the ship's origin, nose, door and booster bells follow
    bell_bottom=min(b['c'][2]-b['half'][2] for b in S['bells'])
    origin=L['mount']['deck']+S['clearance']-bell_bottom
    nose=origin+S['cockpit']['c'][2]+S['cockpit']['half'][2]
    door=origin+S['door']['z']
    bb=min(b['bell']['c'][2]-b['bell']['half'][2] for b in S['boosters'])+origin
    L['stack']=dict(origin=round(origin,2),nose=round(nose,2),door=round(door,2),booster_bells=round(bb,2),rotation='-90 degrees about the ship\'s X axis: nose up, doorway toward the tower (+x)')
    if bb<L['mount']['deck']+1.0: problems.append(('launch: a booster bell below the mount deck',bb))
    if L['tower']['height']<nose+6: problems.append(('launch: the tower shorter than the stack',L['tower']['height'],nose))
    # the tower stands on the doorway's side (+x), its arm reaching the door
    tx=px+S['core'][0]+L['tower']['gap']+L['tower']['half'][0]; L['tower']['c']=(round(tx,2),pz)
    if L['tower']['gap']<6 or L['tower']['gap']>16: problems.append(('launch: the crew arm\'s span',L['tower']['gap']))
    # clearances: the wall, the turbines, the plateaus' slopes, the world's edge, the Chinese village; the landing zones from the pad
    C=L['clear']
    if math.hypot(px-CX,pz)-(WALL['r']+WALL['thick']/2)<C['wall']: problems.append(('launch: too near the wall',))
    for t in TURBINES:
        if math.hypot(px-t[0],pz-t[1])<C['turbines']: problems.append(('launch: too near a turbine',t))
    for nm,c,r in (('main plateau',(0,0),245+20),('Ice plateau',(-450,-480),72+13+68),('Jungle plateau',(-500,464),70+14+70)):
        for q in [L['pad'],L['hangar']['c']]+[z_['c'] for z_ in L['landing_zones']]:
            if math.hypot(q[0]-c[0],q[1]-c[1])<r+C['plateau_slope']: problems.append(('launch: on or near the %s\'s slope'%nm,q))
        # the fence keeps off the slope itself
        if Polygon(L['fence']['pts']).exterior.distance(Point(c))<r+10 or Polygon(L['fence']['pts']).contains(Point(c)): problems.append(('launch: the fence on the %s\'s slope'%nm,))
    for q in [L['pad']]+[z_['c'] for z_ in L['landing_zones']]:
        if math.hypot(*q)>910-C['world_edge']: problems.append(('launch: too near the world\'s edge',q))
    if math.hypot(px-250,pz+650)<C['village']: problems.append(('launch: too near the Chinese village',))
    for z_ in L['landing_zones']:
        if math.hypot(z_['c'][0]-px,z_['c'][1]-pz)<C['pads']: problems.append(('launch: a landing zone too near the pad',z_['name']))
    # everything inside the fence; the rails run straight from the hangar door to the mount
    fence=Polygon(L['fence']['pts'])
    hg=L['hangar']; hb=sbox(hg['c'][0]-hg['half'][0],hg['c'][1]-hg['half'][1],hg['c'][0]+hg['half'][0],hg['c'][1]+hg['half'][1])
    for nm,g in (('pad',P.buffer(max(L['mount']['half']))),('hangar',hb),('tower',Point(L['tower']['c']).buffer(8)),('blockhouse',Point(L['blockhouse']['c']).buffer(12)))+tuple((z_['name'],Point(z_['c']).buffer(z_['r'])) for z_ in L['landing_zones']):
        if not fence.contains(g): problems.append(('launch: outside the fence',nm))
    if abs(hg['c'][0]-px)>0.01: problems.append(('launch: the erector rails do not run straight to the mount',))
    L['rails']['pts']=[(px,hg['c'][1]-hg['half'][1]),(px,pz+L['mount']['half'][1])]
    # the blockhouse stands back from the pad behind its bank, nearer than the hangar is not required, but not under the stack's fall
    if P.distance(Point(L['blockhouse']['c']))<nose*1.2: problems.append(('launch: the firing room within the stack\'s fall',))
    if P.distance(hb)<nose*1.2: problems.append(('launch: the hangar within the stack\'s fall',))
    tr=LineString(L['track']['pts'])
    if tr.distance(Point(L['fence']['gate']))>0.5: problems.append(('launch: the track misses the gate',))
_launch_checks()
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
    if best: return (best[2],best[3])
    # a lot that touches no street faces the Rim Walk when it stands at the city's edge (P3 review, 2026-10-18)
    sides={'n':((x0+x1)/2,z0),'s':((x0+x1)/2,z1),'w':(x0,(z0+z1)/2),'e':(x1,(z0+z1)/2)}
    d_,sd=min((abs(math.hypot(px-CX,pz)-200.0),k) for k,(px,pz) in sides.items())
    return (sd,'rim') if d_<=6.0 else (None,None)
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
# the Helmsmith (38): Gideon Hale's shop on Lamp Lane's south side (revised 2026-10-18, at the user's direction: a
# proper shop, not a lock-up). A walk-in shop floor the full width of the house, its wide entrance on the lane, the
# counter across the room and his helms on the back wall; his workshop behind, seen through the doorway; his home
# upstairs. The live game's legacy shop on Civic Plaza moves here in P3 (moy_pkg_P3.md 2a); P13k finishes it.
BUILDING_KITS[38]={'kit':'shop','storeys':2,'front':'n','shop':True,'colour':3,'signs':1,'counter':True,
                   'shop_floor':{'h':4.0,'depth':8.0,'entrance':3.0},'workshop':'back','home':'above',
                   'accents':['teal','coral','gold'],'display':'catalogue'}
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
## The Well Quarter's tower houses. The ground the lanes and squares leave is
## split into plots the way old towns divided: each block is cut across its
## long side, again and again, until every plot is a house-sized piece (at most
## 130 m2 and 13 m across), each cut a little off the middle. A plot with a
## front on a lane, a square or a street is a house, turned to that front; a plot
## with none is a family's back yard or light well.
def _old_town_houses():
    # blocks first: each block (the ground between roads) gets a perimeter row of houses along every road it fronts,
    # the old roads and the square first so their houses face them, the grid streets after; plots are cut square to
    # the frontage at a house's width; what is left in the middle is the block's courtyards
    from shapely.geometry import LineString, Polygon, Point, MultiLineString, box as sbox
    from shapely.ops import unary_union, split, linemerge
    OT=OLD_TOWN; PL=OT['plot']
    circle=Point(CX,0).buffer(R,128)
    inner=unary_union([sbox(*r) for _,r in OT['interiors']]).intersection(circle)
    lanes=[(l,LineString(l['pts']).buffer(l['w']/2,cap_style=2,join_style=2)) for l in OT['lanes']]
    sqs=[(q,Polygon(q['pts'])) for q in OT['squares']]
    fixed=unary_union([sbox(*b_['r']) for b_ in named]+[sbox(*l[:4]) for l in lots])
    open_=unary_union([g for _,g in lanes]+[g for _,g in sqs])
    ground=inner.difference(open_).difference(fixed)
    def hsh(x,z): return (int(abs(x)*73856093) ^ int(abs(z)*19349663)) & 0xffff
    fronts=[(q['name'],True,g) for q,g in sqs]+[(l['name'],l.get('swing',False),g) for l,g in sorted(lanes,key=lambda t:-t[0]['w'])]+[(s_[0],False,sbox(*s_[2:])) for s_ in STREETS]
    # last, the Rim Walk: the promenade inside the wall, which the houses at the city's edge face as old towns face their wall road
    fronts.append(('Rim Walk',False,Point(CX,0).buffer(203,128).difference(Point(CX,0).buffer(197,128))))
    def parts(g): return [q for q in (g.geoms if hasattr(g,'geoms') else [g]) if q.geom_type=='Polygon' and q.area>0.5]
    def ok(g):
        r=g.minimum_rotated_rectangle; c=list(r.exterior.coords)
        side=min(math.hypot(c[1][0]-c[0][0],c[1][1]-c[0][1]),math.hypot(c[2][0]-c[1][0],c[2][1]-c[1][1]))
        return g.area>=PL['min_area'] and side>=PL['min_side'] and g.area/g.convex_hull.area>=PL['convex']
    houses=[]; yards=[]; placed=None
    for blk in parts(ground):
        taken=Polygon(); plots=[]
        for nm,sw,fg in fronts:
            fr=blk.boundary.intersection(fg.buffer(0.3))
            if fr.is_empty: continue
            ls=linemerge(fr) if fr.geom_type in ('MultiLineString','GeometryCollection') else fr
            for Lf in (ls.geoms if hasattr(ls,'geoms') else [ls]):
                if Lf.geom_type!='LineString' or Lf.length<PL['w'][0]: continue
                band=blk.difference(taken).intersection(Lf.buffer(PL['depth'],cap_style=2,join_style=2))
                if band.area<1: continue
                # cut lines square to the frontage, at house widths that vary along the street
                n=max(1,round(Lf.length/((PL['w'][0]+PL['w'][1])/2))); cuts=[]; acc=0.0
                ws=[PL['w'][0]+(hsh(*Lf.interpolate(k/n,normalized=True).coords[0])%100)/100*(PL['w'][1]-PL['w'][0]) for k in range(n)]
                k_=Lf.length/sum(ws)
                for w_ in ws[:-1]:
                    acc+=w_*k_; p0=Lf.interpolate(max(0,acc-0.5)); p1=Lf.interpolate(min(Lf.length,acc+0.5))
                    tx,tz=p1.x-p0.x,p1.y-p0.y; tl=math.hypot(tx,tz) or 1; nx,nz=-tz/tl,tx/tl; pc=Lf.interpolate(acc)
                    cuts.append(LineString([(pc.x-nx*(PL['depth']+2),pc.y-nz*(PL['depth']+2)),(pc.x+nx*(PL['depth']+2),pc.y+nz*(PL['depth']+2))]))
                pcs=parts(band)
                for cl in cuts:
                    nxt=[]
                    for g in pcs: nxt+=parts(split(g,cl)) if g.intersects(cl) else [g]
                    pcs=nxt
                plots+=[dict(g=g,front=nm,swing=sw) for g in pcs]
                taken=taken.union(band)
        # slivers and awkward corners join the neighbour they share most wall with
        changed=True
        while changed:
            changed=False
            for a in sorted(plots,key=lambda d:d['g'].area):
                if ok(a['g']): continue
                nb=[(b2['g'].buffer(0.05).intersection(a['g'].boundary).length,b2) for b2 in plots if b2 is not a]
                nb=[t for t in nb if t[0]>1.0]
                if nb:
                    b2=max(nb,key=lambda t:t[0])[1]; u=unary_union([b2['g'].buffer(0.05),a['g'].buffer(0.05)]).buffer(-0.05)
                    if u.geom_type=='Polygon' and (ok(u) or not ok(b2['g'])): b2['g']=u; plots.remove(a); changed=True; break
            if not changed: break
        for d in plots:
            g=d['g']
            if not ok(g): yards.append(g); continue
            h=hsh(g.centroid.x,g.centroid.y); st=4+h%6
            if d['swing']: st=max(st,OT['swing_min'][0]+1)
            poly=g.simplify(0.05)
            if placed: poly=poly.difference(placed)   # simplifying can nudge a shared wall into the neighbour
            if poly.geom_type!='Polygon': poly=max(parts(poly),key=lambda q:q.area)
            placed=poly if placed is None else placed.union(poly)
            houses.append(dict(corners=[(round(x,2),round(z,2)) for x,z in list(poly.exterior.coords)[:-1]],storeys=st,front=d['front'],area=round(poly.area,1)))
        yards+=parts(blk.difference(taken))
    OT['_yards']=[[(round(x,2),round(z,2)) for x,z in list(y.exterior.coords)[:-1]] for y in yards if y.geom_type=='Polygon']
    return houses,inner,lanes,sqs
OLD_HOUSES,_ot_inner,_ot_lanes,_ot_sqs=_old_town_houses()
def _old_town_checks():
    from shapely.geometry import LineString, Polygon, Point, box as sbox
    from shapely.ops import unary_union
    OT=OLD_TOWN; polys=[Polygon(h['corners']) for h in OLD_HOUSES]
    if len(OLD_HOUSES)<30: problems.append(('old town: too few houses',len(OLD_HOUSES)))
    for h in OLD_HOUSES:
        if h['area']<OT['plot']['min_area']: problems.append(('old town: a house too small to stand',h['area']))
    for i,p_ in enumerate(polys):
        for j in range(i+1,len(polys)):
            if p_.intersection(polys[j]).area>0.05: problems.append(('old town: houses overlap',i,j))
    # a few legacy roads, each running through from road to road (no dead ends), and through no building
    if len(OT['lanes'])>OT['legacy_max']: problems.append(('old town: too many legacy roads',len(OT['lanes'])))
    streets=unary_union([sbox(*s_[2:]) for s_ in STREETS])
    others=lambda nm: unary_union([g for l,g in _ot_lanes if l['name']!=nm]+[g for _,g in _ot_sqs])
    built=unary_union([sbox(*b_['r']) for b_ in named]+[sbox(*l[:4]) for l in lots])
    for l,g in _ot_lanes:
        if l.get('dead_end'): problems.append(('old town: a dead-end lane',l['name']))
        for end in (l['pts'][0],l['pts'][-1]):
            if streets.distance(Point(end))>0.6 and others(l['name']).distance(Point(end))>0.6: problems.append(('old town: a lane ends at nothing',l['name'],end))
        if g.intersection(built).area>0.1: problems.append(('old town: a lane through a building',l['name']))
    # every house is a buildable plot: big enough, wide enough, near-convex, and fronting a road
    PL=OT['plot']
    for h in OLD_HOUSES:
        g=Polygon(h['corners']); r=g.minimum_rotated_rectangle; c=list(r.exterior.coords)
        side=min(math.hypot(c[1][0]-c[0][0],c[1][1]-c[0][1]),math.hypot(c[2][0]-c[1][0],c[2][1]-c[1][1]))
        if g.area<PL['min_area'] or side<PL['min_side']-0.05 or g.area/g.convex_hull.area<PL['convex']-0.01: problems.append(('old town: an unbuildable plot',h['front'],round(g.area,1),round(side,1)))
        if not h['front']: problems.append(('old town: a house with no front',))
    # every named building inside the quarter fronts a lane, a square or a grid street
    open_=unary_union([g for _,g in _ot_lanes]+[g for _,g in _ot_sqs])|streets
    for b_ in named:
        g=sbox(*b_['r'])
        if g.intersects(_ot_inner) and g.distance(open_)>1.0: problems.append(('old town: a named building with no front',b_['n']))
    # dense, as the well town was: houses cover most of the ground the lanes and squares leave
    free_=_ot_inner.difference(open_).difference(unary_union([sbox(*b_['r']) for b_ in named]+[sbox(*l[:4]) for l in lots]))
    cover=unary_union(polys).intersection(free_).area/free_.area
    OLD_TOWN['_cover']=round(cover,2)
    if cover<0.55: problems.append(('old town: too open, houses cover only',round(cover,2)))
    # the swing route: 6 m between tall houses, with anchors in rope reach all the way along
    tall=[(Polygon(h['corners']),h['storeys']*STOREY['fabric']) for h in OLD_HOUSES]+[(sbox(*b_['r']),HEIGHTS.get(b_['n'],8)) for b_ in named]+[(sbox(*l[:4]),l[4]*STOREY.get(l[5],3.25)) for l in lots]
    a0,a1,above=OT['anchor']
    for l,g in _ot_lanes:
        if not l.get('swing'): continue
        if l['w']<6: problems.append(('old town: a swing lane narrower than 6 m',l['name']))
        line=LineString(l['pts'])
        for k in range(0,int(line.length)+1,4):
            q=line.interpolate(k); n_=sum(1 for g2,hh in tall if hh>=OT['swing_min'][1] and a0<=g2.distance(q)<=a1 and hh>=above+2)
            if n_<3: problems.append(('old town: no swing anchors at',l['name'],k)); break
        # walls: along both edges, at least three quarters of the frontage is 16 m or taller (the mouths may be lower)
        tot=hi=0
        for sd in (1,-1):
            e=line.offset_curve(sd*(l['w']/2+0.4))
            for k in range(0,int(e.length)+1,2):
                q=e.interpolate(k); near=[hh for g2,hh in tall if g2.distance(q)<1.2]
                if near: tot+=1; hi+=max(near)>=OT['swing_min'][1]
        if tot and hi/tot<0.75: problems.append(('old town: the swing route is not walled tall enough',l['name'],round(hi/tot,2)))
_old_town_checks()
OLD_TOWN['_lane_polys']=[[(round(x,2),round(z,2)) for x,z in list(g.exterior.coords)[:-1]] for _,g in _ot_lanes]
for h in OLD_HOUSES:
    xs=[c[0] for c in h['corners']]; zs=[c[1] for c in h['corners']]
    k=kit_for((int(min(xs)),int(min(zs)),int(max(xs)),int(max(zs))),h['storeys'])
    k['front']='lane'; h['kit']=k
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
# (P3 review, 2026-10-18) a pair shares one door, so their fronts must lie on one line; a house under 4 m across is
# too narrow even for half a core, and one shallower than the core (5.8 m) plus a 4 m room has no space for a ramp
# core at all: it takes a lift on its back face instead, as Old Moy's pencil infill does (SMALL_DEPTH; MARKET_HOUSE)
SMALL_DEPTH=5.8+4.0
dims=lambda i: (min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1]),max(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1]))
fline=lambda i,f: {'n':lots[i][1],'s':lots[i][3],'w':lots[i][0],'e':lots[i][2]}[f]
pairable=lambda i: dims(i)[0]>=4.0 and dims(i)[1]>=SMALL_DEPTH
for i in sorted(TL,key=lambda i: min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])):
    ki=LOT_KITS[i]
    if ki['pair']>=0 or not narrow(i) or not pairable(i): continue
    best=None
    for j in TL:
        kj=LOT_KITS[j]
        if j==i or kj['pair']>=0 or kj['front']!=ki['front'] or not pairable(j) or fline(i,ki['front'])!=fline(j,kj['front']): continue
        w_=party_wall(lots[i],lots[j],ki['front'])
        if w_>=5 and (best is None or w_>best[0]): best=(w_,j)
    if best:
        j=best[1]; ki['pair']=j; LOT_KITS[j]['pair']=i; ki['core']=LOT_KITS[j]['core']='shared'
# a sliver under 4 m, or one under 6 m with no neighbour to share a core, becomes a two-storey lock-up shop: a shop
# below and its store or a small flat above, reached by the shop's own ladder ramp (moy_market_lanes.md 3); a
# house too shallow for a ramp core keeps its height and takes a lift
for i in TL:
    ki=LOT_KITS[i]; w_,d_=dims(i)
    if ki['core']=='shared': continue
    if w_<4.0 or (w_<6.0 and d_>=SMALL_DEPTH):
        LOT_KITS[i]={'kit':'lockup','storeys':2,'front':ki['front'],'shop':True,'colour':ki['colour'],'signs':ki['signs']}
        lots[i]=lots[i][:4]+(2,)+lots[i][5:]
    elif d_<SMALL_DEPTH:
        ki['core']='lift'; ki['lift']=True
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
    if min(lots[i][2]-lots[i][0],lots[i][3]-lots[i][1])<6 and ki['core']=='own': problems.append(('narrow tong lau with a core of its own',i,lots[i]))
for i,ki in enumerate(LOT_KITS):
    if ki and ki['kit']=='lockup' and lots[i][4]!=2: problems.append(('lock-up shop not two storeys',i))
## Old Moy, package P4 (docs/architecture/moy_pkg_P4.md, 2026-10-18). The tower house kit's
## numbers (moy_tower_house.md 3), every house's kit fitted to its true width, the face it
## turns to its road, the courtyards and their ways in, the roof route's ramps and the first well.
TOWER_HOUSE=dict(
  storey=3.25, plinth=0.9,
  wall=dict(earth=0.9,earth_top_min=0.5,stone=0.7,brick=0.45),
  lift=0.65, batter=1.5, corner_exp=4.0, horn=0.08,         # earth: zabur lifts, the batter in degrees; the base's plan one superellipse
  cornice=dict(h=0.5,out=0.3),                               # the white band over an earth base
  frieze=dict(h=0.35,out=0.08,kinds=['zigzag','chevron chain','roundels','dentils']),
  parapet=dict(h=1.2,merlon=(0.6,0.5),horn=0.5,patterns=3),
  kiosk=dict(w=3.4,d=3.0,h=2.6), wind_tower=dict(w=2.2,d=1.4,h=4.5,mouth='w'),
  manzar=dict(w=5.0,d=6.0,h=3.0),
  light=dict(w=0.6,h=0.8), window=dict(w=1.0,h=1.6,sill=0.9,fan=0.5), mafraj=dict(w=1.6,h=1.0,sill=0.4),
  door=dict(w=1.2,h=2.4), shopfront=dict(w=(2.4,3.2),h=2.8), kishk=dict(w=1.2,h=1.6,d=0.6),
  core=dict(w=3.4,l=5.8), holds_max=2.4, infill_below=6.0,
  passage=dict(w=2.4,h=3.0), court_min=25.0, ramp=dict(w=1.2,max_deg=32.0,min_wall=6.5),
  pocket=dict(open_min=4.0,gate=1.4,wall=2.4,tree_area=12.0),
)
## The tower house's parts and joins (P4, 2026-10-18, at the user's direction): every visible piece of the kit, its
## shape and how it meets its neighbours, decided here so the build follows one schedule and the model draws the
## same one. shape: egg (SuperEgg.build_part: semi-axes, eps top and bottom), clipped (SuperEgg.build_clipped_part:
## an egg cut by the planes its join names, every cut capped), profile (a superellipse outline extruded, exponent n),
## wall (a SolidModel solid of the outline with its openings punched), punched (a SolidModel profile cutter through a
## wall: exponent n; glazing derived from the same cutter) or box (only with a reason). semi: half-sizes in metres
## (x along the face, y up, z out from it), or 'fit' where the plot sets them. A seated part's centre is on its seat
## and its upper half is kept, so its height is semi y; a part against a wall is centred on the wall face and its outer
## half kept, so it stands out by semi z. col: solid, landing, decorative, open.
## role: what it is, which sets how square it must be.
TH_PARTS=[
 # the body
 dict(id='plinth',what='basalt courses at the street',shape='profile',n=4.0,semi='fit',h=0.9,out=0.05,mat='basalt',col='landing',role='course'),
 dict(id='stone_wall',what='the stone base, plumb',shape='wall',semi='fit',mat='stone',col='solid',role='wall'),
 dict(id='ashlar_band',what='pale ashlar bands across the stone base',shape='clipped',semi=('fit',0.11,0.04),eps=(5.5,5.5),mat='ashlar',col='landing',role='band',join='band_chain'),
 dict(id='earth_lift',what='one rammed-earth lift; its plan one superellipse (exponent corner_exp), stepping in by the batter',shape='profile',n=4.0,semi='fit',h=0.65,mat='earth',col='solid',role='course',join='lift_stack'),
 dict(id='lift_horn',what='a lift end turned up at a rounded corner (the climbable corner)',shape='clipped',semi=(0.18,0.08,0.14),eps=(3.0,5.5),mat='earth',col='landing',role='trim',join='seated'),
 dict(id='cornice',what='the white gypsum band over an earth base, square like the brick above it',shape='clipped',semi=('fit',0.25,0.3),eps=(5.5,5.5),mat='gypsum',col='landing',role='band',join='band_chain'),
 dict(id='brick_wall',what='the brick storeys, plumb on the outline',shape='wall',semi='fit',mat='brick',col='solid',role='wall'),
 dict(id='frieze',what='gypsum frieze at each brick floor (pattern in relief, decorative)',shape='clipped',semi=('fit',0.175,0.08),eps=(5.5,5.5),mat='gypsum',col='landing',role='band',join='band_chain'),
 dict(id='latrine_shaft',what='the plastered service chute on a side or back face',shape='clipped',semi=(0.55,'fit',0.45),eps=(3.0,3.0),mat='gypsum',col='solid',role='shaft',join='against_wall'),
 dict(id='drainpipe',what='white drainpipe from a roof spout',shape='egg',semi=(0.06,'fit',0.06),eps=(2.0,2.0),mat='gypsum',col='decorative',role='pipe'),
 dict(id='mizab',what='roof spout through the parapet',shape='clipped',semi=(0.08,0.08,0.35),eps=(3.0,3.0),mat='gypsum',col='decorative',role='trim',join='against_wall'),
 # openings
 dict(id='light',what='small square light in a base',shape='punched',n=4.0,semi=(0.3,0.4,'wall'),mat='glass_dark',col='solid',role='opening',join='punched'),
 dict(id='window',what='tall brick-storey window under its qamariya',shape='punched',n=6.0,semi=(0.5,0.8,'wall'),head=dict(shape='half',r=0.5),mat='glass',col='solid',role='opening',join='punched'),
 dict(id='surround',what='the white gypsum outline round a window, door or qamariya: its opening\'s own outline grown by ring',shape='punched',n=6.0,semi=(0.62,0.92,0.05),ring=0.12,mat='gypsum',col='decorative',role='trim',join='punched'),
 dict(id='qamariya',what='the fanlight: coloured glass in the half-round head',shape='punched',n=2.0,semi=(0.5,0.5,'wall'),half=True,mat='glass_colour',col='solid',role='opening',join='punched'),
 dict(id='sill',what='window sill, proud of the wall: a hold',shape='clipped',semi=(0.6,0.06,0.12),eps=(5.5,5.5),mat='gypsum',col='landing',role='sill',join='against_wall'),
 dict(id='mafraj_window',what='the top floor\'s low wide window',shape='punched',n=6.0,semi=(0.8,0.5,'wall'),mat='glass',col='solid',role='opening',join='punched'),
 dict(id='door_opening',what='the house door\'s opening: the door leaf\'s own silhouette with its clearance, flat at the floor',shape='punched',outline='door_leaf',clear=0.015,semi=(0.6,1.2,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='door_leaf',what='the carved door, one leaf on one hinge, painted blue, green or ochre (as world_door.gd builds a door)',shape='clipped',semi=(0.585,1.41,0.025),centre=0.97,eps=(5.5,4.0),mat='door',col='solid',role='leaf',join='floor_cut'),
 dict(id='house_mark',what='the painted house mark over the door',shape='decal',semi=(0.3,0.3,0.0),mat='paint',col='decorative',role='paint'),
 dict(id='shop_opening',what='the shopfront cut later into the base: the closed shutters\' silhouette with its clearance, flat at the floor',shape='punched',outline='shutter_set',clear=0.02,semi=(1.4,1.4,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='lintel',what='timber lintel over the shopfront',shape='clipped',semi=(1.6,0.11,0.16),eps=(5.5,5.5),mat='timber',col='landing',role='beam',join='against_wall'),
 dict(id='shutter_leaf',what='one leaf of the folding shopfront shutters',shape='clipped',semi=(0.345,1.61,0.03),centre=1.17,eps=(5.5,5.5),mat='timber',col='solid',role='leaf',join='shutter_set'),
 dict(id='kishk',what='the box window: a white box on the brick storeys',shape='clipped',semi=(0.6,0.8,0.6),eps=(5.5,5.5),mat='gypsum',col='landing',role='box_window',join='against_wall'),
 dict(id='kishk_bracket',what='a bracket under the kishk',shape='clipped',semi=(0.1,0.3,0.55),eps=(3.0,5.5),mat='gypsum',col='landing',role='bracket',join='against_wall'),
 dict(id='lattice',what='the kishk\'s latticed panels',shape='decal',semi=(0.5,0.6,0.0),mat='timber',col='decorative',role='paint'),
 # the top
 dict(id='parapet',what='the parapet wall round the roof',shape='wall',semi='fit',h=0.7,mat='brick',col='landing',role='wall'),
 dict(id='merlon',what='a merlon on the parapet (pattern 0 to 2)',shape='clipped',semi=(0.3,0.5,0.22),eps=(5.5,5.5),mat='brick',col='landing',role='merlon',join='seated'),
 dict(id='horn',what='a whitewashed horn at a parapet corner',shape='clipped',semi=(0.25,0.5,0.25),eps=(3.0,5.5),mat='gypsum',col='landing',role='trim',join='seated'),
 dict(id='parapet_post',what='a post closing a parapet end at a ramp\'s gap',shape='clipped',semi=(0.25,1.2,0.25),eps=(5.5,5.5),mat='brick',col='landing',role='post',join='seated'),
 dict(id='roof',what='the roof terrace',shape='box',semi='fit',mat='plaster',col='landing',role='slab',reason='a floor fills to the walls: a rounded slab would leave open corners'),
 dict(id='kiosk',what='the kiosk over the core, where the ramp arrives on the roof',shape='wall',semi=(1.7,1.3,1.5),mat='brick',col='landing',role='wall'),
 dict(id='kiosk_door',what='the kiosk\'s door onto the terrace, one leaf',shape='clipped',semi=(0.435,1.21,0.025),centre=0.77,eps=(5.5,4.0),mat='door',col='solid',role='leaf',join='floor_cut'),
 dict(id='wind_shaft',what='the wind tower\'s shaft',shape='clipped',semi=(1.1,4.5,0.7),eps=(5.5,5.5),mat='gypsum',col='solid',role='shaft',join='seated'),
 dict(id='wind_mouth',what='the catcher\'s mouth, turned to the west wind',shape='punched',n=4.0,semi=(0.5,0.7,'wall'),mat='shadow',col='open',role='opening',join='punched'),
 dict(id='wind_cap',what='one slab of the wind tower\'s pitched cap',shape='clipped',semi=(0.75,0.12,0.85),eps=(5.5,5.5),mat='gypsum',col='landing',role='slab',join='cap_ridge'),
 dict(id='manzar',what='the rooftop room, qamariya windows on three sides',shape='wall',semi=(2.5,1.5,3.0),mat='gypsum',col='landing',role='wall'),
 # the quarter's ground
 dict(id='ramp',what='the timber roof ramp, a storey up along a party wall',shape='clipped',semi=(0.6,0.07,'fit'),eps=(5.5,5.5),mat='timber',col='landing',role='slab',join='ramp_ends'),
 dict(id='ramp_rail',what='the ramp\'s side rail',shape='clipped',semi=(0.04,0.45,'fit'),eps=(5.5,5.5),mat='timber',col='solid',role='rail',join='ramp_ends'),
 dict(id='passage_arch',what='a court passage\'s opening, at both ends, flat at the floor',shape='punched',n=2.5,semi=(1.2,1.5,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='passage_lamp',what='the lamp inside a passage',shape='egg',semi=(0.15,0.2,0.15),eps=(2.0,2.0),mat='lamp',col='decorative',role='lamp'),
 dict(id='bench',what='a pocket\'s bench seat',shape='egg',semi=(0.8,0.06,0.22),eps=(5.5,5.5),mat='timber',col='landing',role='slab'),
 dict(id='bench_leg',what='a bench leg',shape='clipped',semi=(0.06,0.4,0.18),eps=(5.5,5.5),mat='timber',col='solid',role='post',join='seated'),
 dict(id='pot',what='a planted pot',shape='clipped',semi=(0.28,0.5,0.28),eps=(2.6,3.0),mat='terracotta',col='solid',role='vessel',join='seated'),
 dict(id='yard_wall',what='a family yard\'s wall',shape='wall',semi='fit',h=2.4,mat='earth',col='solid',role='wall'),
 dict(id='gate_post',what='a post at each side of the yard\'s open gateway',shape='clipped',semi=(0.22,2.6,0.22),eps=(5.5,5.5),mat='earth',col='landing',role='post',join='seated'),
 dict(id='well_head',what='the first well\'s head',shape='clipped',semi=(1.1,0.8,1.1),eps=(3.0,5.5),mat='stone',col='landing',role='vessel',join='seated'),
 dict(id='well_lid',what='its stone lid',shape='clipped',semi=(1.05,0.1,1.05),eps=(3.0,5.5),mat='basalt',col='landing',role='lid',join='seated'),
 dict(id='trough',what='the stone trough, hollowed',shape='clipped',semi=(0.4,0.6,1.6),eps=(5.5,5.5),mat='stone',col='landing',role='vessel',join='seated',hollow=0.08),
 dict(id='ghaf_trunk',what='the old ghaf\'s trunk',shape='clipped',semi=(0.45,3.8,0.45),eps=(2.0,2.4),mat='bark',col='solid',role='trunk',join='seated'),
 dict(id='ghaf_crown',what='the ghaf\'s crown, a cluster of soft eggs',shape='egg',semi=(2.8,1.5,2.8),eps=(2.2,2.6),mat='leaf',col='decorative',role='crown'),
]
## The joins: each names its kind and the parts it holds together. split: one parent egg the size of the closed
## opening, cut by planes into leaves that hinge at their outer edges, so shut they make the parent again. meet: two
## slabs run through one shared plane and both cut at it. chain: each piece cut at the plane it shares with the next
## (a corner's bisector, a roof's top), so a run reads as one form. seated: an egg cut flat where it stands on or
## against a surface and capped there, never buried whole. punched: a SolidModel cutter through a wall; glazing and
## the gypsum ring come from the same cutter.
TH_JOINS=[
 dict(id='floor_cut',kind='seated',parts=['door_leaf','kiosk_door','shutter_leaf'],plane='the floor under the leaf',rule='as world_door.gd: the leaf\'s egg reaches below the floor and is cut flat at it, so its bottom stands square on the threshold and its top keeps its soft shoulders; one leaf on one hinge, on the side that swings clear'),
 dict(id='shutter_set',kind='split',parts=['shutter_leaf'],parent=(1.38,1.61,0.03),centre=1.17,eps=(5.5,5.5),cuts=[(1,0,0,-0.69),(1,0,0,0.0),(1,0,0,0.69)],hinge='outer',rule='four leaves from one parent, cut at the floor too (floor_cut); they fold back in pairs to each jamb'),
 dict(id='cap_ridge',kind='meet',parts=['wind_cap','wind_cap'],plane='the vertical plane through the ridge',rule='both slabs run past the ridge and are cut at it; their cut faces meet on one line, the profile the same both sides'),
 dict(id='band_chain',kind='chain',parts=['ashlar_band','cornice','frieze'],plane='the bisector of each corner of the outline',rule='each face\'s run is cut at both corners\' bisectors; neighbouring runs meet on one mitre line, same height and same profile'),
 dict(id='on_surface',kind='placed',parts=['light','window','surround','qamariya','mafraj_window','sill','door_opening','shop_opening','kishk','kishk_bracket','mizab','lintel'],plane='the face as it is at that height',rule='on the wall\'s real surface at its height (the earth\'s superellipse, stepped in by the batter), turned to that surface\'s normal, and only where the surface is flat to 3 cm across the piece'),
 dict(id='lift_stack',kind='chain',parts=['earth_lift'],plane='each lift\'s top',rule='each lift stands on the one below on one horizontal plane; the batter shows as a step of tan(batter) x lift'),
 dict(id='ramp_ends',kind='chain',parts=['ramp','ramp_rail'],plane='the lower roof\'s top at the foot; the higher roof\'s top at the head, through the parapet gap',rule='cut at both roofs\' planes from the same datum (the storey): flush at both ends, no ledge'),
 dict(id='seated',kind='seated',parts=['lift_horn','merlon','horn','parapet_post','bench_leg','pot','gate_post','well_head','well_lid','trough','ghaf_trunk','wind_shaft'],plane='the top of what it stands on',rule='cut flat at that plane and capped; the cut face sits on it, no gap, no buried half'),
 dict(id='against_wall',kind='seated',parts=['latrine_shaft','mizab','sill','lintel','kishk','kishk_bracket'],plane='the wall\'s outer face',rule='cut at the wall face and capped; it stands proud of the wall by its depth, nothing sunk into the wall'),
 dict(id='punched',kind='punched',parts=['light','window','surround','qamariya','mafraj_window','door_opening','shop_opening','wind_mouth','passage_arch'],plane='through the wall',rule='one closed cutter per opening; a doorway or shopfront is its leaves\' own silhouette (outline) grown by its clearance, so frame and door are one shape; an opening that reaches the floor (floor) is flat there; the glass is the cutter intersected with the wall, the gypsum ring the cutter grown by its ring less the cutter'),
]
TOWER_HOUSE['parts']=TH_PARTS; TOWER_HOUSE['joins']=TH_JOINS
SHAPES=('egg','clipped','profile','wall','punched','box','decal','arch','facet')
SQUARE=('post','rail','slab','beam','sill','merlon','band','leaf','box_window','course')
def parts_checks(tag,PARTS,JOINS):
    # the rules every kit's schedule keeps: known shapes and joins, square members square, every clipped part cut by
    # a join, every opening drawn from a part that exists, a collision class on everything
    ids={p['id'] for p in PARTS}; jids={j['id'] for j in JOINS}
    if len(ids)<len(PARTS): problems.append((tag+' parts: an id used twice',))
    for p in PARTS:
        if p['shape'] not in SHAPES: problems.append((tag+' parts: unknown shape',p['id']))
        if p['shape'] in ('box','facet') and not p.get('reason'): problems.append((tag+' parts: a box or a facet with no reason',p['id']))
        if p['shape'] in ('egg','clipped'):
            if min(p['eps'])<2.0: problems.append((tag+' parts: an egg below exponent 2 pinches',p['id']))
            # a leaf cut at the floor keeps world_door.gd's softer lower exponent: its lower half is cut away
            if p['role'] in SQUARE and (p['eps'][0] if any(j['id']=='floor_cut' and p['id'] in j['parts'] for j in JOINS) else min(p['eps']))<5.0: problems.append((tag+' parts: a square member not square enough',p['id']))
        if p['shape']=='clipped' and not any(p['id'] in j['parts'] for j in JOINS): problems.append((tag+' parts: a clipped part with no join to cut it',p['id']))
        if p.get('join') and p['join'] not in jids: problems.append((tag+' parts: a part names a missing join',p['id']))
        if p['shape']=='punched' and not p.get('outline') and p['n']<2.0: problems.append((tag+' parts: an opening below exponent 2',p['id']))
        if p.get('outline') and p['outline'] not in ids and p['outline'] not in jids: problems.append((tag+' parts: an opening drawn from a missing part',p['id']))
        if p['col'] not in ('solid','landing','decorative','open'): problems.append((tag+' parts: no collision class',p['id']))
    for j in JOINS:
        if j['kind'] not in ('split','meet','chain','seated','punched','placed'): problems.append((tag+' joins: unknown kind',j['id']))
        for q in j['parts']:
            if q not in ids: problems.append((tag+' joins: a join names a missing part',j['id'],q))
        if j['kind']=='split' and j['cuts']:
            # the leaves rebuild the parent: n cuts make n+1 leaves of the part's width
            leaf=[p for p in PARTS if p['id']==j['parts'][0]][0]
            ax=[k for k in range(3) if j['cuts'][0][k]][0]
            if abs((len(j['cuts'])+1)*leaf['semi'][ax]-j['parent'][ax])>0.01: problems.append((tag+' joins: the leaves do not make the parent',j['id']))
    P_={p['id']:p for p in PARTS}
    for p in PARTS:
        # an opening drawn from a leaf: the leaf reaches below the floor to be cut there, and the opening is its height
        # (less a hairline) and its width (plus the clearance)
        o=p.get('outline'); lf=P_.get(o) or next((j for j in JOINS if j['id']==o),None)
        if not o or lf is None or p['shape']!='punched' or p.get('ring'): continue
        semi=lf.get('semi',lf.get('parent'))
        if lf['centre']-semi[1]>-0.1: problems.append((tag+' parts: a leaf does not reach below the floor to be cut',o))
        if isinstance(p['semi'][1],(int,float)) and abs(lf['centre']+semi[1]-(2*p['semi'][1]-0.02))>0.01: problems.append((tag+' parts: a leaf not the height of its opening',o,p['id']))
        if isinstance(p['semi'][0],(int,float)) and abs(semi[0]-(p['semi'][0]-p['clear']))>0.01: problems.append((tag+' parts: a leaf not the width of its opening',o,p['id']))
        if not p.get('floor'): problems.append((tag+' parts: an opening closed by a leaf not flat at the floor',p['id']))
def _th_parts_checks():
    parts_checks('tower',TH_PARTS,TH_JOINS)
    # the openings and members agree with the kit's numbers
    P_={p['id']:p for p in TH_PARTS}
    for p in TH_PARTS:
        if p['shape']=='punched' and p['id'] in ('door_opening','shop_opening','passage_arch') and not p.get('floor'): problems.append(('tower parts: an opening to the floor not flat at it',p['id']))
    sh=[j for j in TH_JOINS if j['id']=='shutter_set'][0]
    if abs(sh['centre']+sh['parent'][1]-(2*P_['shop_opening']['semi'][1]-0.02))>0.01 or sh['centre']-sh['parent'][1]>-0.1: problems.append(('tower joins: the shutters do not fill the shopfront to the floor',))
    win=[p for p in TH_PARTS if p['id']=='window'][0]
    if abs(2*win['semi'][0]-TOWER_HOUSE['window']['w'])>0.01 or abs(2*win['semi'][1]-TOWER_HOUSE['window']['h'])>0.01: problems.append(('tower parts: the window out of step with TOWER_HOUSE',))
    door=[p for p in TH_PARTS if p['id']=='door_opening'][0]
    if abs(2*door['semi'][0]-TOWER_HOUSE['door']['w'])>0.01 or abs(2*door['semi'][1]-TOWER_HOUSE['door']['h'])>0.01: problems.append(('tower parts: the door out of step with TOWER_HOUSE',))
    shaft=[p for p in TH_PARTS if p['id']=='wind_shaft'][0]
    if abs(shaft['semi'][1]-TOWER_HOUSE['wind_tower']['h'])>0.01: problems.append(('tower parts: the wind shaft out of step with TOWER_HOUSE',))
    k_=[p for p in TH_PARTS if p['id']=='kishk'][0]
    if abs(k_['semi'][2]-TOWER_HOUSE['kishk']['d'])>0.01 or abs(2*k_['semi'][0]-TOWER_HOUSE['kishk']['w'])>0.01: problems.append(('tower parts: the kishk out of step with TOWER_HOUSE',))
    m_=[p for p in TH_PARTS if p['id']=='merlon'][0]
    if abs(m_['semi'][1]-TOWER_HOUSE['parapet']['merlon'][1])>0.01 or abs(2*m_['semi'][0]-TOWER_HOUSE['parapet']['merlon'][0])>0.01: problems.append(('tower parts: the merlon out of step with TOWER_HOUSE',))
    pp=[p for p in TH_PARTS if p['id']=='parapet'][0]
    if abs(pp['h']+m_['semi'][1]-TOWER_HOUSE['parapet']['h'])>0.01: problems.append(('tower parts: parapet and merlon do not make the parapet height',))
_th_parts_checks()
def _p4():
    from shapely.geometry import LineString, Polygon, Point, box as sbox
    from shapely.ops import unary_union, nearest_points
    TH=TOWER_HOUSE; S_=TH['storey']
    # the kit's own numbers hold together
    if TH['core']['w']+2*TH['wall']['earth']>TH['infill_below']: problems.append(('tower house: the core does not fit inside earth walls',))
    if abs(TH['lift']*5-S_)>0.01: problems.append(('tower house: five lifts do not make a storey',))
    W_=TH['window']; holds=[0.0,W_['sill'],W_['sill']+W_['h']+W_['fan'],S_]
    if max(b_-a_ for a_,b_ in zip(holds,holds[1:]))>TH['holds_max']: problems.append(('tower house: holds too far apart up a brick face',))
    if TH['wall']['earth']-4*S_*math.tan(math.radians(TH['batter']))<TH['wall']['earth_top_min']: problems.append(('tower house: the batter eats the earth wall',))
    if TH['ramp']['min_wall']<S_/math.tan(math.radians(TH['ramp']['max_deg'])): problems.append(('tower house: a roof ramp cannot climb a storey along its wall',))
    def msides(g):
        r=g.minimum_rotated_rectangle; c=list(r.exterior.coords)
        a=math.hypot(c[1][0]-c[0][0],c[1][1]-c[0][1]); b_=math.hypot(c[2][0]-c[1][0],c[2][1]-c[1][1]); return min(a,b_),max(a,b_)
    def hsh(x,z): return (int(abs(x)*2654435761) ^ int(abs(z)*40503)) & 0xffff
    # the later pencil infill: P3's tile house, plumb and tiled, with a lift for a core
    def infill(storeys,front,shop,h):
        return {'kit':'infill','storeys':storeys,'front':front,'shop':shop,'gen':'tile','veranda':False,'corner':False,
                'colour':h%5,'signs':h%2,'roof':'tanks','core':'own','pair':-1,'lift':True}
    for i,ki in enumerate(LOT_KITS):
        if ki and ki['kit']=='infill':
            l=lots[i]; LOT_KITS[i]=infill(ki['storeys'],ki['front'],ki['shop'],hsh((l[0]+l[2])/2,(l[1]+l[3])/2))
    # the Well Quarter's houses: each one's face to its road, and its kit fitted to its true (turned) width
    fronts={q['name']:g for q,g in _ot_sqs}; fronts.update({l['name']:g for l,g in _ot_lanes})
    fronts.update({s_[0]:sbox(*s_[2:]) for s_ in STREETS}); fronts['Rim Walk']=Point(CX,0).buffer(203,128).difference(Point(CX,0).buffer(197,128))
    kind={s_[0]:s_[1] for s_ in STREETS}
    # the small slots between houses (revised 2026-10-18, at the user's direction: no blank blocks). A yard under
    # court_min is: a sliver under 1 m (left by rounding the plots), folded into the house beside it, or into the
    # paving where it meets a road and no old house; a slot with no real opening on a road, folded into the
    # neighbouring house, which grows by it; a slot open to a road, kept open as a pocket off the lane (a bench, pots,
    # a small tree) or, where its opening is narrow, a family's walled yard with an open gateway. Nothing is filled.
    roads0=unary_union(list(fronts.values()))
    def msides0(g):
        r=g.minimum_rotated_rectangle; c=list(r.exterior.coords)
        return min(math.dist(c[0],c[1]),math.dist(c[1],c[2]))
    def fold(g):
        best=None
        for i,h in enumerate(OLD_HOUSES):
            hg=Polygon(h['corners'])
            if hg.distance(g)>0.3: continue
            wall=g.buffer(0.3).intersection(hg.exterior).length
            if wall<0.5: continue
            u=unary_union([hg.buffer(0.02,join_style=2),g.buffer(0.02,join_style=2)]).buffer(-0.02,join_style=2).simplify(0.05)
            if u.geom_type!='Polygon': continue
            if any(Polygon(o['corners']).intersection(u).area>0.05 for j,o in enumerate(OLD_HOUSES) if j!=i): continue
            if best is None or wall>best[0]: best=(wall,i,u)
        if not best: return False
        h=OLD_HOUSES[best[1]]; h['corners']=[(round(x,2),round(z,2)) for x,z in list(best[2].exterior.coords)[:-1]]; h['area']=round(best[2].area,1)
        return True
    pockets=[]; small=[]
    for y in OLD_TOWN['_yards']:
        g=Polygon(y)
        if not g.is_valid: g=g.buffer(0)   # a few yards' outlines touch themselves; mend them rather than skip them
        for q in (g.geoms if hasattr(g,'geoms') else [g]):
            if 0.5<=q.area<TH['court_min']: small.append(q)
    for g in sorted(small,key=lambda q:q.area):
        on_road=g.exterior.intersection(roads0.buffer(0.4)); rl=on_road.length; wd=msides0(g)
        pts=[(round(x,2),round(z,2)) for x,z in list(g.exterior.coords)[:-1]]
        if wd<1.0:
            if fold(g): continue
            if rl>0: pockets.append(dict(kind='paving',pts=pts,area=round(g.area,1))); continue
        elif rl<TH['pocket']['gate']+0.2:
            if fold(g): continue
            # no house to take it: a narrow alcove off the road, open, paved, a few pots
            if rl>=1.0: pockets.append(dict(kind='alcove',pts=pts,area=round(g.area,1),road=round(rl,1))); continue
        else:
            seg=on_road if on_road.geom_type=='LineString' else max(on_road.geoms,key=lambda q:q.length)
            m=seg.interpolate(0.5,normalized=True)
            k_='pocket' if rl>=TH['pocket']['open_min'] else 'yard'
            pk=dict(kind=k_,pts=pts,area=round(g.area,1),road=round(rl,1),gate=(round(m.x,2),round(m.y,2)))
            if k_=='pocket': pk['tree']=g.area>=TH['pocket']['tree_area'] and wd>=3.0
            else: pk['gate_w']=TH['pocket']['gate']
            pockets.append(pk); continue
        problems.append(('old town: a slot left as a blank block',round(g.area,1),pts[0]))
    OLD_TOWN['_pockets']=pockets
    def face(cs,fg):
        n=len(cs); out=[]
        for k in range(n):
            e=LineString([cs[k],cs[(k+1)%n]]); on=e.intersection(fg.buffer(1.0)).length
            if on>=TH['door']['w']+1.2: out.append((on,k))
        return max(out) if out else None
    for i,h in enumerate(OLD_HOUSES):
        g=Polygon(h['corners'])
        # its door is on the road it was cut from; where that frontage was lost to a corner, on the longest
        # face it has on another road; a house with no face on any road is a court house, its door on its court
        f=face(h['corners'],fronts[h['front']]); door=h['front']
        if not f:
            alt=[(face(h['corners'],fg),nm) for nm,fg in fronts.items()]; alt=[t for t in alt if t[0]]
            if alt: f,door=max(alt)
        if f: h['front_edge']=f[1]; h['door']=door
        else: h['front_edge']=-1; h['door']='court'
        cx_,cz_=g.centroid.x,g.centroid.y; hh=hsh(cx_,cz_); fr=h['door']
        old_road=fr in ('Cinema Square','Old High Street','Old High Street (south)')
        shop=fr=='Cinema Square' or (old_road and hh%5<3) or kind.get(fr) in ('main','shop')
        polite=old_road or kind.get(fr) in ('main','shop')
        if msides(g)[0]<TH['infill_below']: h['kit']=infill(h['storeys'],'lane',shop,hh)
        else: h['kit'].update(shop=shop,polite=polite)
    # every tower house is at least the core's width inside its walls
    for i,h in enumerate(OLD_HOUSES):
        if h['kit']['kit']=='tower' and msides(Polygon(h['corners']))[0]<TH['infill_below']-0.01: problems.append(('old town: a tower house too narrow for its core',i))
    # everything built in Old Moy, as (key, polygon, height in m)
    built=[(('old',i),Polygon(h['corners']),h['storeys']*S_) for i,h in enumerate(OLD_HOUSES)]
    built+=[(('lot',i),sbox(*lots[i][:4]),lots[i][4]*STOREY[lots[i][5]]) for i,k_ in enumerate(LOT_KITS) if k_ and k_['kit'] in ('tower','infill')]
    built+=[(('bldg',b_['n']),sbox(*b_['r']),HEIGHTS.get(b_['n'],8)) for b_ in named if b_['r'][2]<=-637 and b_['r'][0]>=-790]
    kit_of=lambda key: OLD_HOUSES[key[1]]['kit'] if key[0]=='old' else LOT_KITS[key[1]] if key[0]=='lot' else BUILDING_KITS.get(key[1])
    roads=unary_union(list(fronts.values()))
    # the courtyards: a yard of at least court_min is a court, open to the sky, reached from a road by a covered
    # passage through one house's ground floor (a sabat), unless it opens on a road itself; a smaller yard is a
    # light well, built up solid to its lowest neighbour's roof so no one can drop into a slot with no way out
    courts=[]; wells=[]
    for y in OLD_TOWN['_yards']:
        g=Polygon(y)
        if not g.is_valid: g=max((g.buffer(0).geoms if hasattr(g.buffer(0),'geoms') else [g.buffer(0)]),key=lambda q:q.area); y=[(round(x,2),round(z,2)) for x,z in list(g.exterior.coords)[:-1]]
        if g.area<0.5: continue
        nb=[(key,pg,ht) for key,pg,ht in built if pg.distance(g)<0.3]
        if g.area<TH['court_min']: continue
        c=dict(pts=y,area=round(g.area,1))
        if g.exterior.intersection(roads.buffer(0.6)).length>=TH['passage']['w']: c['open']=True; courts.append(c); continue
        best=None
        for key,pg,ht in nb:
            if key[0]!='old' or OLD_HOUSES[key[1]]['kit']['kit']!='tower' or OLD_HOUSES[key[1]]['front_edge']<0: continue
            wall=g.buffer(0.3).intersection(pg.exterior)
            if wall.length<TH['passage']['w']+0.6: continue
            a=wall.interpolate(0.5,normalized=True) if wall.geom_type=='LineString' else max(wall.geoms,key=lambda q:q.length).interpolate(0.5,normalized=True)
            hc=OLD_HOUSES[key[1]]['corners']; k=OLD_HOUSES[key[1]]['front_edge']; fe=LineString([hc[k],hc[(k+1)%len(hc)]])
            b_=fe.interpolate(fe.project(a)); ln=LineString([a,b_])
            # the passage must stay inside its house, clear of its corners
            if ln.buffer(TH['passage']['w']/2,cap_style=2).difference(pg.buffer(0.35)).area>0.5: continue
            if best is None or ln.length<best[0]: best=(ln.length,key[1],a,b_)
        if best: c['passage']=dict(house=best[1],court=(round(best[2].x,2),round(best[2].y,2)),road=(round(best[3].x,2),round(best[3].y,2)),w=TH['passage']['w'],h=TH['passage']['h'])
        else: problems.append(('old town: a court with no way in',round(g.area,1),y[0]))
        courts.append(c)
    # a house with no face on a road opens on the court behind it; one with no court either is reached through
    # its neighbour's house, as the oldest back houses were (P4 builds no interiors, so only its door shows)
    for i,h in enumerate(OLD_HOUSES):
        if h['door']!='court': continue
        g=Polygon(h['corners']); ok_=[k for k,c in enumerate(courts) if Polygon(c['pts']).buffer(0.3).intersection(g.exterior).length>=TH['door']['w']+1.2]
        if ok_: h['court']=ok_[0]
        else: h['door']='through'
    for c in courts:
        if 'passage' in c and OLD_HOUSES[c['passage']['house']]['storeys']<2: problems.append(('old town: a passage under a one-storey house',))
    # the roof route: two touching houses one storey apart get a timber ramp up along their party wall
    links=[]
    for a_ in range(len(built)):
        for b2 in range(a_+1,len(built)):
            (ka,pa,ha),(kb,pb,hb)=built[a_],built[b2]
            if not (kit_of(ka) and kit_of(kb)): continue
            if abs(abs(ha-hb)-S_)>0.05: continue
            wall=pa.buffer(0.15).intersection(pb.buffer(0.15)).minimum_rotated_rectangle
            cs=list(wall.exterior.coords) if wall.geom_type=='Polygon' else []
            if len(cs)<4: continue
            e=sorted([(math.dist(cs[k],cs[k+1]),cs[k],cs[k+1]) for k in range(4)])[-1]
            if e[0]<TH['ramp']['min_wall']: continue
            lo,hi=((ka,pa,ha),(kb,pb,hb)) if ha<hb else ((kb,pb,hb),(ka,pa,ha))
            # the ramp lies on the lower roof beside the wall, one ramp width in, foot at one end, head at the other
            (x0,z0),(x1,z1)=e[1],e[2]; L_=e[0]; ux,uz=(x1-x0)/L_,(z1-z0)/L_
            off=TH['ramp']['w']/2+0.5
            for sd in (1,-1):
                px,pz=-uz*sd*off,ux*sd*off; mid=Point((x0+x1)/2+px,(z0+z1)/2+pz)
                if lo[1].buffer(-0.3).contains(mid): break
            else: continue
            run=S_/math.tan(math.radians(TH['ramp']['max_deg'])); m0=(L_-run)/2
            foot=(round(x0+ux*m0+px,2),round(z0+uz*m0+pz,2)); head=(round(x0+ux*(m0+run)+px,2),round(z0+uz*(m0+run)+pz,2))
            if not (lo[1].buffer(-0.2).contains(Point(foot)) and lo[1].buffer(-0.2).contains(Point(head))): continue
            links.append(dict(low=list(lo[0]),high=list(hi[0]),foot=foot,head=head,y=(round(lo[2],2),round(hi[2],2)),w=TH['ramp']['w']))
    # the first well on Cinema Square: the capped well head, its stone trough and the oldest shade tree in the city
    sq=[q for q in OLD_TOWN['squares'] if q['name']=='Cinema Square'][0]; sg=Polygon(sq['pts']); wx,wz=sq['well']
    sq['first_well']=dict(head=dict(c=(wx,wz),r=1.1,h=0.8,cap='a stone lid, chained'),trough=dict(c=(wx+2.6,wz),l=3.2,w=0.8,h=0.6,along='z'),
                          tree=dict(kind='round',c=(wx-3.5,wz+4.0),h=14.0,job='the oldest shade tree in the city, over the well'))
    fw=sq['first_well']; lanes_=unary_union([g for _,g in _ot_lanes])
    for nm,(px,pz),clear in (('well',fw['head']['c'],1.5),('trough',fw['trough']['c'],2.0),('tree',fw['tree']['c'],1.5)):
        if not sg.buffer(-clear).contains(Point(px,pz)): problems.append(('the first well: the %s too near the square\'s edge'%nm,))
        if lanes_.distance(Point(px,pz))<clear: problems.append(('the first well: the %s in the Old High Street'%nm,))
    if math.dist(fw['tree']['c'],fw['head']['c'])>TREE_KIT['round']['crown']*fw['tree']['h']+1: problems.append(('the first well: its tree does not shade it',))
    OLD_TOWN['_courts']=courts; OLD_TOWN['_roof_links']=links
_p4()
## The market lanes, package P3 (docs/architecture/moy_pkg_P3.md, revised 2026-10-18). The tong lau kit's
## numbers (moy_market_lanes.md 3), each house's door, the ways into every walled court in the city, Arcade
## Street's roof, and Lamp Lane's lanterns and night-market stalls.
MARKET_HOUSE=dict(
  storey=3.25, plinth=0.6, parapet=1.1, wall=0.25,
  palette=['jade','ochre','coral','cornflower','cream'],
  boom=dict(veranda=dict(col=0.5,out=2.4,rail=1.0),balcony=dict(d=0.6,rail=1.0),window=dict(w=1.0,h=2.2),shutter=0.5),
  tile=dict(canopy=dict(d=1.5,y=3.6,t=0.2),balcony=dict(d=1.2,rail=1.05,first=2),window=dict(w=2.0,h=1.4,sill=0.9),corner_exp=4.0,lift=dict(w=1.9,d=1.9)),
  lockup=dict(shutter_h=2.8),
  core=dict(w=3.4,l=5.8,room=4.0), door=dict(w=1.2,h=2.4), shop=dict(h=3.0,depth=1.5), fanlight=0.4,
  sign=dict(w=0.9,h=0.7,gap=0.25,y=4.2,out=1.3), holds_max=2.4,
  passage=dict(w=2.4,h=3.0),
  arcade=dict(h=9.0,arch_every=6.0,arch=dict(w=0.3,d=0.25),panel=0.04,end_clear=3.0),
  lamp=dict(lantern_every=4.0,lantern_y=4.6,stall=dict(w=2.4,d=1.0,h=2.2),stall_every=7.5,door_clear=1.5,walk_min=2.6),
)
## The market house's parts and joins (moy_pkg_P3.md 2b): every piece of a boom house, a tile house, a lock-up, the
## Helmsmith's shop and the streets they make, and how each meets the next. The same vocabulary as TH_PARTS; arch is
## a half superellipse of exponent n spanning a street (semi: half the span, the rise, and the rib's half-depth),
## swept with a section of the part's own size.
MH_PARTS=[
 # the body
 dict(id='plinth',what='the grey-tile plinth at the street, on the house\'s outline',shape='profile',n=4.0,semi='fit',h=0.6,out=0.03,mat='tile_grey',col='landing',role='course'),
 dict(id='house_wall',what='the house, plumb on its outline: a rectangle, or on a corner lot with that corner a superellipse quarter (corner_exp) the full height; rendered (boom) or mosaic tile (tile) in its palette colour',shape='wall',semi='fit',mat='front',col='solid',role='wall'),
 dict(id='parapet',what='the parapet round the roof',shape='wall',semi='fit',h=1.04,mat='front',col='landing',role='wall'),
 dict(id='coping',what='the coping along the parapet\'s top, on its outer face',shape='clipped',semi=('fit',0.06,0.12),eps=(5.5,5.5),mat='tile_grey',col='landing',role='band',join='band_chain'),
 dict(id='roof',what='the roof',shape='box',semi='fit',mat='plaster',col='landing',role='slab',reason='a floor fills to the walls: a rounded slab would leave open corners'),
 # the boom house\'s front
 dict(id='veranda_col',what='a square veranda column, the full height, at the veranda\'s outer edge',shape='clipped',semi=(0.25,'fit',0.25),eps=(5.5,5.5),mat='render_pale',col='solid',role='post',join='col_ends'),
 dict(id='veranda_floor',what='a veranda floor at each storey and the walkway\'s roof, out to the columns\' outer faces',shape='clipped',semi=('fit',0.125,2.4),eps=(5.5,5.5),mat='slab',col='landing',role='slab',join='against_wall'),
 dict(id='veranda_handrail',what='the timber balustrade\'s handrail between columns',shape='clipped',semi=('fit',0.05,0.06),eps=(5.5,5.5),mat='timber',col='landing',role='rail',join='rail_bays'),
 dict(id='baluster',what='a timber baluster, floor to handrail',shape='clipped',semi=(0.03,'fit',0.03),eps=(5.5,5.5),mat='timber',col='solid',role='post',join='col_ends'),
 dict(id='balcony',what='the boom house\'s shallow balcony where it has no veranda',shape='clipped',semi=('fit',0.09,0.6),eps=(5.5,5.5),mat='slab',col='landing',role='slab',join='against_wall'),
 dict(id='french_window',what='a French window: the leaves\' own silhouette with its clearance, flat at its storey\'s floor',shape='punched',outline='french_set',clear=0.015,semi=(0.5,1.1,'wall'),floor=True,mat='glass_dark',col='solid',role='opening',join='punched'),
 dict(id='french_leaf',what='one glazed leaf of a French window',shape='clipped',semi=(0.2425,1.31,0.03),centre=0.87,eps=(5.5,4.0),mat='glass_frame',col='solid',role='leaf',join='french_set'),
 dict(id='window_shutter',what='one timber shutter of a French window; shut, the pair is the opening\'s own outline; open, each lies flat on the wall beside it',shape='clipped',semi=(0.25,1.325,0.025),centre=0.87,eps=(5.5,4.0),mat='shutter',col='solid',role='leaf',join='shutter_pair'),
 # the tile house\'s front
 dict(id='canopy',what='the cantilevered canopy over the shopfront',shape='clipped',semi=('fit',0.1,1.5),eps=(5.5,5.5),mat='slab',col='landing',role='slab',join='party_cut'),
 dict(id='tile_balcony',what='a cantilevered balcony on each storey from the second (balcony.first); the first storey\'s is the canopy',shape='clipped',semi=('fit',0.09,1.2),eps=(5.5,5.5),mat='slab',col='landing',role='slab',join='corner_wrap'),
 dict(id='corner_balcony',what='the balcony round a rounded corner: the corner\'s own superellipse quarter, grown by the balcony\'s depth',shape='profile',n=4.0,semi='fit',h=0.18,mat='slab',col='landing',role='slab',join='corner_wrap'),
 dict(id='balcony_rail',what='a steel rail\'s top bar along a balcony\'s edge (boom and tile)',shape='clipped',semi=('fit',0.03,0.03),eps=(5.5,5.5),mat='rail',col='landing',role='rail',join='rail_bays'),
 dict(id='rail_post',what='a steel rail post, slab to top bar, at the ends and every 1.2 m',shape='clipped',semi=(0.025,'fit',0.025),eps=(5.5,5.5),mat='rail',col='solid',role='post',join='col_ends'),
 dict(id='rail_infill',what='the rail\'s bars between posts',shape='decal',semi=('fit','fit',0.0),mat='rail',col='decorative',role='paint'),
 dict(id='steel_window',what='a wide steel window behind a balcony',shape='punched',n=6.0,semi=(1.0,0.7,'wall'),mat='glass_steel',col='solid',role='opening',join='punched'),
 dict(id='window_bars',what='its steel glazing bars',shape='decal',semi=(1.0,0.7,0.0),mat='rail',col='decorative',role='paint'),
 dict(id='lift_shaft',what='the glass lift shaft on the back face, against the core, a storey above the roof',shape='clipped',semi=(0.95,'fit',1.9),eps=(5.5,5.5),mat='glass',col='solid',role='shaft',join='against_wall'),
 # the ground floor
 dict(id='door_opening',what='the house door\'s opening: the leaf\'s own silhouette with its clearance, flat at the floor',shape='punched',outline='door_leaf',clear=0.015,semi=(0.6,1.2,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='door_leaf',what='the house door, one leaf on one hinge (as world_door.gd builds a door); a pair\'s one door straddles their party wall',shape='clipped',semi=(0.585,1.41,0.03),centre=0.97,eps=(5.5,4.0),mat='door',col='solid',role='leaf',join='floor_cut'),
 dict(id='door_surround',what='the grey-tile frame round the door: its opening\'s outline grown by ring',shape='punched',outline='door_leaf',ring=0.15,semi=(0.75,1.35,0.04),mat='tile_grey',col='decorative',role='trim',join='punched'),
 dict(id='fanlight',what='the lit fanlight over the door, above its frame',shape='punched',n=6.0,semi=(0.6,0.2,'wall'),mat='fanlight',col='solid',role='opening',join='punched'),
 dict(id='shop_opening',what='the shopfront, the rest of the ground floor\'s front: the roll shutter\'s own silhouette with its clearance, flat at the floor; glazed by day, the dressed window behind',shape='punched',outline='roll_shutter',clear=0.02,semi=('fit',1.5,'wall'),floor=True,mat='shop',col='solid',role='opening',join='punched'),
 dict(id='roll_shutter',what='the shopfront\'s roll shutter, down at night, rolled into its box by day',shape='clipped',semi=('fit',1.79,0.03),centre=1.19,eps=(5.5,5.5),mat='shutter_steel',col='solid',role='leaf',join='floor_cut'),
 dict(id='shutter_box',what='the roll shutter\'s box over the shopfront (a hold)',shape='clipped',semi=('fit',0.18,0.22),eps=(5.5,5.5),mat='shutter_steel',col='landing',role='beam',join='against_wall'),
 dict(id='shop_shelf',what='a shelf at the back of the dressed shop window',shape='clipped',semi=('fit',0.03,0.2),eps=(5.5,5.5),mat='timber',col='decorative',role='slab',join='against_wall'),
 dict(id='goods',what='goods on the shelves, by the trade, in plain shapes',shape='egg',semi=(0.15,0.15,0.12),eps=(2.5,3.0),mat='goods',col='decorative',role='goods'),
 # the lock-up
 dict(id='lockup_opening',what='a lock-up\'s whole front: the shutter\'s own silhouette with its clearance, flat at the floor',shape='punched',outline='lockup_shutter',clear=0.02,semi=('fit',1.4,'wall'),floor=True,mat='shop',col='solid',role='opening',join='punched'),
 dict(id='lockup_shutter',what='the lock-up\'s roll shutter',shape='clipped',semi=('fit',1.69,0.03),centre=1.09,eps=(5.5,5.5),mat='shutter_steel',col='solid',role='leaf',join='floor_cut'),
 dict(id='lockup_window',what='the small window over a lock-up',shape='punched',n=6.0,semi=(0.5,0.4,'wall'),mat='glass_steel',col='solid',role='opening',join='punched'),
 # the signs
 dict(id='sign',what='a picture sign on the front (its frame solid)',shape='clipped',semi=(0.45,0.35,0.06),eps=(5.5,5.5),mat='sign',col='solid',role='slab',join='against_wall'),
 dict(id='sign_picture',what='the sign\'s picture, never lettered',shape='decal',semi=(0.3,0.25,0.0),mat='paint',col='decorative',role='paint'),
 dict(id='blade_bracket',what='the steel arm a blade sign hangs from, out over the lane (a swing anchor)',shape='clipped',semi=(0.03,0.03,1.3),eps=(5.5,5.5),mat='rail',col='solid',role='beam',join='against_wall'),
 dict(id='blade_sign',what='the blade sign, hung under its arm',shape='clipped',semi=(0.05,1.1,0.6),eps=(5.5,5.5),mat='sign',col='solid',role='slab',join='hung'),
 # the roof
 dict(id='water_tank',what='a water tank',shape='clipped',semi=(0.9,1.6,0.9),eps=(3.0,5.5),mat='tank',col='landing',role='vessel',join='seated'),
 dict(id='laundry_post',what='a laundry frame\'s post',shape='clipped',semi=(0.04,1.8,0.04),eps=(5.5,5.5),mat='rail',col='solid',role='post',join='seated'),
 dict(id='laundry',what='laundry on the lines',shape='decal',semi=('fit',0.35,0.0),mat='laundry',col='decorative',role='paint'),
 dict(id='greenhouse',what='a rooftop greenhouse',shape='clipped',semi=('fit',2.4,1.5),eps=(5.5,5.5),mat='glass',col='landing',role='slab',join='seated'),
 dict(id='planter',what='a roof garden\'s planter bed',shape='clipped',semi=('fit',0.6,1.5),eps=(5.5,5.5),mat='planter',col='landing',role='slab',join='seated'),
 dict(id='roof_plant',what='a plant in a bed or a pot',shape='egg',semi=(0.35,0.4,0.35),eps=(2.2,2.6),mat='leaf',col='decorative',role='crown'),
 # the streets they make
 dict(id='arcade_post',what='a post at the street\'s edge carrying an arch',shape='clipped',semi=(0.15,'fit',0.125),eps=(5.5,5.5),mat='steel',col='solid',role='post',join='col_ends'),
 dict(id='arcade_arch',what='a steel arch over Arcade Street',shape='arch',n=2.5,semi=('fit','fit',0.125),section=(0.15,0.15),mat='steel',col='landing',role='rib',join='arcade_bays'),
 dict(id='arcade_panel',what='a translucent panel between two arches',shape='arch',n=2.5,semi=('fit','fit','fit'),section=(0.02,),mat='panel',col='solid',role='shell',join='arcade_bays'),
 dict(id='lantern',what='a lantern on a string across Lamp Lane',shape='egg',semi=(0.15,0.2,0.15),eps=(2.0,2.0),mat='lantern',col='decorative',role='lamp'),
 dict(id='lantern_string',what='the string, house to house',shape='decal',semi=('fit',0.0,0.0),mat='string',col='decorative',role='paint'),
 dict(id='stall_table',what='a night-market stall\'s table',shape='clipped',semi=(1.2,0.9,0.5),eps=(5.5,5.5),mat='stall',col='landing',role='slab',join='seated'),
 dict(id='stall_post',what='an awning post at a stall\'s corner',shape='clipped',semi=(0.04,'fit',0.04),eps=(5.5,5.5),mat='stall',col='solid',role='post',join='col_ends'),
 dict(id='awning',what='a stall\'s awning (a bounce)',shape='clipped',semi=(1.3,0.05,0.7),eps=(5.5,5.5),mat='awning',col='landing',role='slab',join='seated'),
 dict(id='passage_arch',what='a court passage\'s opening, at both ends, flat at the floor',shape='punched',n=2.5,semi=(1.2,1.5,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='passage_lamp',what='the lamp inside a passage',shape='egg',semi=(0.15,0.2,0.15),eps=(2.0,2.0),mat='lamp',col='decorative',role='lamp'),
 dict(id='bench',what='a court\'s bench seat',shape='egg',semi=(0.8,0.06,0.22),eps=(5.5,5.5),mat='timber',col='landing',role='slab'),
 dict(id='bench_leg',what='a bench leg',shape='clipped',semi=(0.06,0.4,0.18),eps=(5.5,5.5),mat='timber',col='solid',role='post',join='seated'),
 dict(id='pot',what='a planted pot',shape='clipped',semi=(0.28,0.5,0.28),eps=(2.6,3.0),mat='terracotta',col='solid',role='vessel',join='seated'),
 dict(id='washing_line',what='a court\'s washing line and its washing',shape='decal',semi=('fit',0.35,0.0),mat='laundry',col='decorative',role='paint'),
 # the Helmsmith\'s shop (BUILDING_KITS[38])
 dict(id='entrance',what='the shop\'s wide open entrance, no door, no threshold, flat at the floor',shape='punched',n=6.0,semi=(1.5,1.6,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='shop_glazing',what='the glazed front either side of the entrance, over a teal stall riser',shape='punched',n=6.0,semi=('fit',1.4,'wall'),mat='shop',col='solid',role='opening',join='punched'),
 dict(id='counter',what='the counter across the room',shape='clipped',semi=('fit',1.0,0.35),eps=(5.5,5.5),mat='timber',col='landing',role='slab',join='seated'),
 dict(id='counter_top',what='its gold top',shape='clipped',semi=('fit',0.06,0.37),eps=(5.5,5.5),mat='gold',col='landing',role='slab',join='seated'),
 dict(id='display_shelf',what='a shelf of the back wall\'s display',shape='clipped',semi=('fit',0.04,0.18),eps=(5.5,5.5),mat='timber',col='solid',role='slab',join='against_wall'),
 dict(id='helm_stand',what='a stand for a helm either side of the room',shape='clipped',semi=(0.06,1.4,0.06),eps=(5.5,5.5),mat='timber',col='solid',role='post',join='seated'),
 dict(id='workshop_door',what='the doorway behind the counter into his workshop, open, flat at the floor',shape='punched',n=6.0,semi=(0.7,1.2,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched'),
 dict(id='shop_lamp',what='a pendant lamp over the shop floor',shape='egg',semi=(0.25,0.2,0.25),eps=(2.2,3.0),mat='lamp',col='decorative',role='lamp'),
]
MH_JOINS=[
 dict(id='floor_cut',kind='seated',parts=['door_leaf','french_leaf','window_shutter','roll_shutter','lockup_shutter'],plane='the floor under the leaf (the street, or a French window\'s storey)',rule='as world_door.gd: the leaf\'s egg reaches below the floor and is cut flat at it, so its bottom stands square on the threshold and its top keeps its soft shoulders; a door is one leaf on one hinge'),
 dict(id='french_set',kind='split',parts=['french_leaf'],parent=(0.485,1.31,0.03),centre=0.87,eps=(5.5,4.0),cuts=[(1,0,0,0.0)],hinge='outer',rule='two glazed leaves from one parent, cut at the floor too; they open inward'),
 dict(id='shutter_pair',kind='split',parts=['window_shutter'],parent=(0.5,1.325,0.025),centre=0.87,eps=(5.5,4.0),cuts=[(1,0,0,0.0)],hinge='outer',rule='shut, the two shutters are the French window\'s own outline (its leaves\' silhouette grown by the clearance); open, each folds flat to the wall beside the opening'),
 dict(id='band_chain',kind='chain',parts=['coping'],plane='the bisector of each corner of the outline (on a rounded corner, of each step of the curve)',rule='each face\'s run is cut at both corners\' bisectors and at the wall face; neighbouring runs meet on one mitre line, same height and same profile'),
 dict(id='party_cut',kind='chain',parts=['canopy','veranda_floor'],plane='the party wall\'s plane at each end of the front',rule='the piece runs past both party walls and is cut at them, so neighbouring canopies and veranda walkways meet flush; at a row\'s end the cut is capped'),
 dict(id='corner_wrap',kind='chain',parts=['tile_balcony','corner_balcony'],plane='each end of the corner\'s curve, square to the face',rule='on a rounded corner, each face\'s straight balcony is cut where the curve begins and the curved balcony runs between those cuts at the same depth, height and thickness'),
 dict(id='balcony_ends',kind='chain',parts=['balcony','tile_balcony'],plane='each end of the balcony, square to the face: 0.3 m (boom) or 0.2 m (tile) in from a party wall, or where a rounded corner\'s curve begins',rule='the slab runs past both ends and is cut square there and capped, so its rail posts stand on its corners'),
 dict(id='rail_bays',kind='chain',parts=['veranda_handrail','balcony_rail'],plane='the faces of the columns or posts at each end of a bay',rule='each bay\'s rail is cut at the faces of what carries it; it runs into the column with no gap and no overlap'),
 dict(id='col_ends',kind='chain',parts=['veranda_col','baluster','rail_post','arcade_post','stall_post','lift_shaft'],plane='what it stands on, and the underside of what it carries',rule='cut flat at both ends and capped: a column stands on the pavement and stops under the top veranda floor; a baluster or rail post stands on its floor and stops under its rail; an arcade post stops at the arch\'s springing; a stall post under the awning; a lift shaft stands on the ground'),
 dict(id='seated',kind='seated',parts=['water_tank','laundry_post','greenhouse','planter','bench_leg','pot','stall_table','awning','counter','counter_top','helm_stand'],plane='the top of what it stands on',rule='cut flat at that plane and capped; the cut face sits on it, no gap, no buried half'),
 dict(id='hung',kind='seated',parts=['blade_sign'],plane='the underside of its bracket',rule='its centre on the bracket\'s underside, its lower half kept (so it hangs its semi y), cut flat there and capped; its outer edge inside the bracket\'s end, its bottom clear above the canopy'),
 dict(id='against_wall',kind='seated',parts=['veranda_floor','balcony','tile_balcony','canopy','lift_shaft','shutter_box','shop_shelf','sign','blade_bracket','display_shelf'],plane='the wall\'s outer face',rule='cut at the wall face and capped; it stands proud of the wall by its depth, nothing sunk into the wall'),
 dict(id='arcade_bays',kind='chain',parts=['arcade_arch','arcade_panel'],plane='each arch\'s middle plane; the posts\' tops',rule='each panel spans from one arch\'s middle plane to the next and is cut at both, so the roof reads as one vault; each arch is cut at its posts\' tops and springs from them flush'),
 dict(id='on_surface',kind='placed',parts=['steel_window','french_window','door_opening','door_surround','fanlight','shop_opening','sign','blade_bracket','shutter_box'],plane='the face as it is',rule='only on a flat run of a face; the rounded corner carries only the balconies, the coping and the plinth'),
 dict(id='punched',kind='punched',parts=['french_window','steel_window','door_opening','door_surround','fanlight','shop_opening','lockup_opening','lockup_window','passage_arch','entrance','shop_glazing','workshop_door'],plane='through the wall',rule='one closed cutter per opening; a doorway, a French window or a shopfront is its leaves\' own silhouette (outline) grown by its clearance, so frame and leaf are one shape; an opening that reaches the floor (floor) is flat there; the glass is the cutter intersected with the wall, a ring the cutter grown by its ring less the cutter'),
]
MARKET_HOUSE['parts']=MH_PARTS; MARKET_HOUSE['joins']=MH_JOINS
def _mh_parts_checks():
    parts_checks('market',MH_PARTS,MH_JOINS)
    P_={p['id']:p for p in MH_PARTS}; J_={j['id']:j for j in MH_JOINS}; MH=MARKET_HOUSE
    def off(nm,a,b):
        if abs(a-b)>0.01: problems.append(('market parts: %s out of step with MARKET_HOUSE'%nm,a,b))
    off('the door width',2*P_['door_opening']['semi'][0],MH['door']['w']); off('the door height',2*P_['door_opening']['semi'][1],MH['door']['h'])
    off('the fanlight',2*P_['fanlight']['semi'][1],MH['fanlight']); off('the fanlight width',2*P_['fanlight']['semi'][0],MH['door']['w'])
    off('the surround',P_['door_surround']['semi'][0]-P_['door_surround']['ring'],P_['door_opening']['semi'][0])
    off('the French window width',2*P_['french_window']['semi'][0],MH['boom']['window']['w']); off('the French window height',2*P_['french_window']['semi'][1],MH['boom']['window']['h'])
    sp=J_['shutter_pair']; off('the shutter width',2*P_['window_shutter']['semi'][0],MH['boom']['shutter'])
    fs=J_['french_set']; off('the shutters shut, against the window\'s outline',sp['parent'][0],fs['parent'][0]+P_['french_window']['clear']); off('the shutters\' top',sp['centre']+sp['parent'][1],fs['centre']+fs['parent'][1]+P_['french_window']['clear'])
    off('the steel window width',2*P_['steel_window']['semi'][0],MH['tile']['window']['w']); off('the steel window height',2*P_['steel_window']['semi'][1],MH['tile']['window']['h'])
    off('the shop height',2*P_['shop_opening']['semi'][1],MH['shop']['h']); off('the lock-up shutter',2*P_['lockup_opening']['semi'][1],MH['lockup']['shutter_h'])
    off('the canopy depth',P_['canopy']['semi'][2],MH['tile']['canopy']['d']); off('the canopy thickness',2*P_['canopy']['semi'][1],MH['tile']['canopy']['t'])
    off('the tile balcony',P_['tile_balcony']['semi'][2],MH['tile']['balcony']['d']);
    cy,ct=MH['tile']['canopy']['y'],MH['tile']['canopy']['t']
    if cy-ct/2<MH['shop']['h']+2*P_['shutter_box']['semi'][1]: problems.append(('market parts: the canopy foul of the shopfront and its shutter box',))
    if cy+ct/2>MH['tile']['balcony']['first']*MH['storey']-P_['tile_balcony']['semi'][1]-0.3: problems.append(('market parts: the canopy foul of the first balcony',))
    if cy<(MH['tile']['balcony']['first']-1)*MH['storey']: problems.append(('market parts: a storey with neither balcony nor canopy',))
    off('the boom balcony',P_['balcony']['semi'][2],MH['boom']['balcony']['d'])
    off('the veranda column',2*P_['veranda_col']['semi'][0],MH['boom']['veranda']['col']); off('the veranda floor',P_['veranda_floor']['semi'][2],MH['boom']['veranda']['out'])
    off('the lift width',2*P_['lift_shaft']['semi'][0],MH['tile']['lift']['w']); off('the lift depth',P_['lift_shaft']['semi'][2],MH['tile']['lift']['d'])
    off('the sign width',2*P_['sign']['semi'][0],MH['sign']['w']); off('the sign height',2*P_['sign']['semi'][1],MH['sign']['h']); off('the blade\'s reach',P_['blade_bracket']['semi'][2],MH['sign']['out'])
    if 2*P_['blade_sign']['semi'][2]>MH['sign']['out']: problems.append(('market parts: the blade sign longer than its bracket',))
    if P_['blade_sign']['semi'][1]<MH['sign']['h']: problems.append(('market parts: the blade sign shorter than a front sign',))
    off('the parapet',P_['parapet']['h']+P_['coping']['semi'][1],MH['parapet']); off('the plinth',P_['plinth']['h'],MH['plinth'])
    off('the arcade arch',2*P_['arcade_post']['semi'][0],MH['arcade']['arch']['w']); off('the arcade post depth',2*P_['arcade_post']['semi'][2],MH['arcade']['arch']['d'])
    off('the stall width',2*P_['stall_table']['semi'][0],MH['lamp']['stall']['w']); off('the stall depth',2*P_['stall_table']['semi'][2],MH['lamp']['stall']['d'])
    off('the passage width',2*P_['passage_arch']['semi'][0],MH['passage']['w']); off('the passage height',2*P_['passage_arch']['semi'][1],MH['passage']['h'])
    hk=BUILDING_KITS[38]['shop_floor']; off('the Helmsmith\'s entrance',2*P_['entrance']['semi'][0],hk['entrance'])
    if 2*P_['entrance']['semi'][1]>hk['h']-0.5: problems.append(('market parts: the Helmsmith\'s entrance too tall for his shop floor',))
    if P_['counter']['semi'][1]+P_['counter_top']['semi'][1]*2>1.2: problems.append(('market parts: the counter too tall to serve over',))
_mh_parts_checks()
## The BLOCK tower's parts and joins (package P17, 2026-10-18, at the user's direction): every visible piece of the tower's
## outside, the climb to it, the three places inside, the lift, and the blorb mech, its shape and how it meets its
## neighbours, decided here so the build follows one schedule and the model draws the same one. The vocabulary is the
## tower house's (TH_PARTS), with one more shape: facet (a flat plate on three or four stated corners, for the folds of the
## crown, where two planes must meet on a straight edge and an egg would leave a gap). Tower frame: origin the shaft's
## centre on the forecourt, x east, y up, z south (the plaza face is z -12); semi is half-sizes (across the face, up, out of
## it) in metres; 'fit' is what the plan's numbers set. g: the place the part belongs to. col: solid, landing, decorative,
## open. Where a part repeats, `where` says how, from BLOCK_TOWER['sched'].
_SH=TOWER_SITE[13]['shaft']; _OX,_OZ=(_SH[0]+_SH[2])/2,(_SH[1]+_SH[3])/2
_BW,_BD=_SH[2]-_SH[0],_SH[3]-_SH[1]
_CR=BLOCK_TOWER['crown']; _RG=_CR['ridge']
_XW=-_BW/2+_RG['x_west']; _XE=_BW/2-_RG['x_east']; _ZF=-_BD/2+_RG['z_front']; _ZB=-_BD/2+_RG['z_back']
_TOP=BLOCK_TOWER['shaft_top']
## the crown's corners in the tower frame: the shaft's four top corners and the ridge's four ends
BT_PT=dict(NW=(-_BW/2,_TOP,-_BD/2),NE=(_BW/2,_TOP,-_BD/2),SE=(_BW/2,_TOP,_BD/2),SW=(-_BW/2,_TOP,_BD/2),
           Wf=(_XW,_CR['top'],_ZF),Wb=(_XW,_CR['top'],_ZB),Ef=(_XE,_CR['top_east'],_ZF),Eb=(_XE,_CR['top_east'],_ZB))
BLOCK_TOWER['sched']=dict(
  frame=dict(origin=(_OX,_OZ),shaft=(_BW,_BD)),
  wall=1.0, base_wall=1.2, crown_t=0.5,
  door=dict(w=2.2,h=3.0,hinge='west',swing='out'),
  hood=dict(w=4.5,h=1.3,out=1.4,ns=[-9.75,-3.25,3.25,9.75],ew=[-4.0,4.0]),
  louvre=dict(w=2.4,h=2.2,sill=79.0,sill_w=3.0,sill_out=1.2),
  # what the hero's jump clears: apex = jump_velocity^2 / (2 g), g = 9.8 x JUMP_GRAVITY_SCALE; reach = apex time x move_speed
  hop=dict(rise=1.2,leap=2.2,apex=11.3**2/(2*9.8*4.8),reach=2*11.3/(9.8*4.8)*6.0),
  fire=dict(rise=7.5,run=12.5,flights=6,ramp_w=1.5,landing_z=2.4,landing_out=2.4,z_south=-4.0,rail_h=1.1,post_every=2.5),
  bracket=dict(w=0.9,t=0.18,out=0.7,first=46.2,step=1.2,count=29,z=0.5),
  slit=dict(at=[-10.0,-6.0,-2.0,2.0,6.0,10.0],w=0.35),
  inside=dict(
    floors=dict(lobby=0.0,way_in=79.0,crown=150.0),
    lobby=dict(inner=(15.6,13.6),clear=7.8,slab=0.4),
    plant=dict(inner=(24.0,22.0),clear=3.6,slab=0.3),
    arena=dict(inner=(24.0,22.0),slab=0.7),
    core=dict(rect=(0.0,-2.0,7.0,5.0),top=156.0),
    lift=dict(at=(3.5,1.5),cavity=3.6,stops=[0.0,79.0,150.0],car=dict(outer=3.2,clear=2.4,floor=0.28,wall=0.12,roof=0.12),door=dict(w=1.5,h=2.4)),
    gallery=dict(x=(-8.6,8.6),z=(2.0,7.0),y=164.0,glass_h=2.8,glass_bays=4),
    stair=dict(w=2.0,rise=0.2,run=0.29,treads=35,a=dict(x=-10.4,z0=2.0,y0=150.0),landing=dict(x=(-11.4,-6.6),z=(-10.4,-8.15),y=157.0),b=dict(x=-7.6,z0=-8.15,y0=157.0)),
    stations=dict(hero=(3.5,150.0,-4.0),boss=(7.0,150.0,-8.0),kask=(1.0,164.0,3.4),pinestein=(3.6,164.0,3.4))))
BT_PARTS=[
 # ---- the body
 dict(g='body',id='base_wall',what='the base, 18 by 16 m, set back 4 m from the shaft and 9 m high: the lobby\'s walls, the door punched in the plaza face',shape='wall',semi=(9.0,4.5,8.0),t=1.2,mat='base_tile',col='solid',role='wall',where='plan 18 x 16 about the shaft\'s centre, y 0 to 9'),
 dict(g='body',id='base_post',what='a pilaster at each corner of the base, the full height, cut flat at the forecourt and under the shaft',shape='clipped',semi=(0.45,'fit',0.45),eps=(5.5,5.5),mat='base_tile',col='solid',role='post',join='col_ends',where='four, centred on the base\'s corners (x 9, z 8)'),
 dict(g='body',id='shaft_wall',what='the shaft: blue-black glazed brick, 26 by 24 m, sheer from 9 to 150 m, hanging 4 m over the base; its underside (the soffit) is a built face over the forecourt',shape='wall',semi=(13.0,70.5,12.0),t=1.0,mat='brick_blue',col='solid',role='wall',where='plan 26 x 24, y 9 to 150; the louvre punched in the east face; one wall thick, the storeys behind it solid mass'),
 dict(g='body',id='corner_post',what='a pilaster at each corner of the shaft, the full height, cut flat at the soffit and at the crown\'s springing',shape='clipped',semi=(0.5,'fit',0.5),eps=(5.5,5.5),mat='brick_blue_dark',col='solid',role='post',join='col_ends',where='four, centred on the shaft\'s corners (x 13, z 12), y 9 to 150'),
 dict(g='body',id='shaft_slit',what='a hairline slit course, every 4 m across each face, from the soffit to the crown (the crown\'s continue it)',shape='decal',semi=(0.175,'fit',0.0),mat='slit_dark',col='decorative',role='paint',where='six a face at x or z of -10, -6, -2, 2, 6, 10; 24 in all'),
 dict(g='body',id='vent_hood',what='a vent hood, 4.5 m wide, 1.3 m deep and 1.4 m proud, its top a flat landing at the ring\'s height; the climber\'s only holds on the tower',shape='clipped',semi=(2.25,0.65,1.4),eps=(5.5,5.5),mat='hood_ceramic',col='landing',role='slab',join='against_wall',where='three rings at 45, 82.5 and 120 m (the top of each hood at the ring); a ring has 4 on the plaza face and 4 on the back (x -9.75, -3.25, 3.25, 9.75) and 2 on each side (z -4, 4): 36'),
 dict(g='body',id='vent_grille',what='the grille under a hood, painted',shape='decal',semi=(1.9,0.5,0.0),mat='slit_dark',col='decorative',role='paint',where='one under each hood but the open louvre\'s'),
 # ---- the openings
 dict(g='openings',id='door_opening',what='the one door\'s opening in the base\'s plaza face: the leaf\'s own silhouette with its clearance, flat at the forecourt',shape='punched',outline='door_leaf',clear=0.015,semi=(1.1,1.5,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched',at=(1.0,0.0,-8.0),where='x +1 (the plan\'s door, world x -461), in the base wall 4 m behind the shaft\'s face'),
 dict(g='openings',id='door_leaf',what='the one door, one leaf on one hinge as world_door.gd builds it, black steel; shut and bare from outside, it opens outward from the lobby after the fight',shape='clipped',semi=(1.085,1.71,0.025),centre=1.27,eps=(5.5,4.0),mat='door_black',col='solid',role='leaf',join='floor_cut',hinge='west jamb',swing='outward, 78 degrees'),
 dict(g='openings',id='door_surround',what='the steel ring round the door: the opening\'s outline grown by its ring',shape='punched',outline='door_opening',ring=0.14,semi=(1.24,1.64,0.05),floor=True,mat='steel_dark',col='decorative',role='trim',join='punched'),
 dict(g='openings',id='louvre_opening',what='the open louvre\'s opening in the east face: its leaves\' own silhouette with the clearance, flat at the plant floor, a hood above its head',shape='punched',outline='louvre_set',clear=0.015,semi=(1.2,1.1,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched',at=(13.0,79.0,-4.0),where='east face, z -4 (the plan\'s world z 55), y 79.0 to 81.2'),
 dict(g='openings',id='louvre_leaf',what='one louvred shutter of the open louvre, thrown back flat on the wall beside the opening, lit warm',shape='clipped',semi=(0.5925,1.31,0.03),centre=0.87,eps=(5.5,4.0),mat='louvre_warm',col='solid',role='leaf',join='floor_cut',where='two, hinged at the outer jambs'),
 dict(g='openings',id='louvre_slats',what='the slats in each louvre leaf, in relief',shape='decal',semi=(0.5,1.0,0.0),mat='louvre_warm',col='decorative',role='paint'),
 dict(g='openings',id='louvre_surround',what='the steel ring round the louvre\'s opening',shape='punched',outline='louvre_opening',ring=0.12,semi=(1.32,1.22,0.05),floor=True,mat='steel_dark',col='decorative',role='trim',join='punched'),
 dict(g='openings',id='louvre_sill',what='the ledge in front of the opening, flush with the plant floor inside: where the climb arrives',shape='clipped',semi=(1.5,0.08,1.2),eps=(5.5,5.5),mat='hood_ceramic',col='landing',role='sill',join='against_wall',at=(13.0,79.0,-4.0),top=79.0),
 dict(g='openings',id='eye_slit',what='the eye: one azure slit in the crown\'s plaza facet, 1.2 by 24 m, the cutter through the shell; its glass is the cutter intersected with the shell',shape='punched',n=8.0,semi=(0.6,12.0,'wall'),mat='azure',col='solid',role='opening',join='punched',at=(-2.5,180.0,-10.548),where='in facet crown_n1, centred between y 168 and 192, x on the ridge\'s middle'),
 dict(g='openings',id='eye_surround',what='the steel ring round the eye',shape='punched',outline='eye_slit',ring=0.1,semi=(0.7,12.1,0.04),mat='steel_dark',col='decorative',role='trim',join='punched'),
 # ---- the crown
 dict(g='crown',id='crown_n1',what='the plaza face, the west and bigger half: shaft top edge NW-NE to the ridge\'s west end; carries the eye',shape='facet',pts=('NW','NE','Wf'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='folded planes meet on straight edges; an egg would round them and open a gap'),
 dict(g='crown',id='crown_n2',what='the plaza face, the east half',shape='facet',pts=('NE','Ef','Wf'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_s1',what='the back slope, the east and bigger half: the one long slope the gallery hangs from',shape='facet',pts=('SE','SW','Wb'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_s2',what='the back slope, the ridge end',shape='facet',pts=('SE','Wb','Eb'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_w',what='the west face: a plane through the shaft\'s west edge and the ridge\'s west end',shape='facet',pts=('SW','NW','Wf','Wb'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_e',what='the east face: a plane through the shaft\'s east edge and the ridge\'s east end',shape='facet',pts=('NE','SE','Eb','Ef'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_ridge',what='the ridge: a 2 m flat on the cant, 212 m at the west end, 198 m at the east',shape='facet',pts=('Wf','Ef','Eb','Wb'),t=0.5,mat='crown_dark',col='solid',role='facet',join='crown_fold',reason='as crown_n1'),
 dict(g='crown',id='crown_slit',what='the shaft\'s slits continued up the plaza and back faces to the ridge, converging, in relief',shape='decal',semi=(0.175,'fit',0.0),mat='slit_dark',col='decorative',role='paint',where='six on each of the plaza and back faces; each runs from its slit at the springing to the ridge at the same fraction of the ridge\'s length'),
 dict(g='crown',id='crown_rib',what='a rib on the inside of the plaza and back faces, under each slit, seen from the arena',shape='clipped',semi=(0.15,'fit',0.18),eps=(5.5,5.5),mat='crown_rib',col='landing',role='post',join='rib_ends',where='six on each of those faces'),
 # ---- the climb
 dict(g='climb',id='fire_ramp',what='a flight of the fire escape on the east neighbour\'s west face: 12.5 m long, 7.5 m up (31 degrees), 1.5 m wide, alternating north and south',shape='clipped',semi=(0.75,0.08,'fit'),eps=(5.5,5.5),mat='steel_galv',col='landing',role='slab',join='ramp_ends',where='six flights, y 0 to 45; the first starts on the ground at z -5.2 and climbs north'),
 dict(g='climb',id='fire_landing',what='a landing of the fire escape, the balcony of the brief: 2.4 along the face and 2.4 out of it, its top at 7.5, 15 ... 45 m',shape='clipped',semi=(1.2,0.07,2.4),eps=(5.5,5.5),mat='steel_galv',col='landing',role='slab',join='against_wall',where='six, at the north end for odd flights\' tops and the south end for even; the sixth at y 45, z -4, level with the 30% ring'),
 dict(g='climb',id='fire_post',what='a rail post on the fire escape, every 2.5 m along the ramps and at the landings\' corners',shape='clipped',semi=(0.03,'fit',0.03),eps=(5.5,5.5),mat='steel_galv',col='solid',role='post',join='col_ends',where='along the outer edge of each ramp and landing'),
 dict(g='climb',id='fire_rail',what='the top bar of the fire escape\'s rail, 1.1 m up, between posts',shape='clipped',semi=('fit',0.03,0.03),eps=(5.5,5.5),mat='steel_galv',col='landing',role='rail',join='rail_bays',where='along the outer edge of each ramp and landing, open at the sixth landing\'s tower edge (the leap)'),
 dict(g='climb',id='rail_bracket',what='a bracket of the window-cleaning rail on the tower\'s east face, between the two hoods: a hold every 1.2 m, alternating either side of the face\'s middle',shape='clipped',semi=(0.45,0.09,0.7),eps=(5.5,5.5),mat='steel_dark',col='landing',role='slab',join='against_wall',where='29 on the east face, tops at y 46.2 + 1.2 n (to 79.8), z +/- 0.5 alternately'),
 dict(g='climb',id='rail_bar',what='the rail itself, a bar up the face behind the brackets',shape='clipped',semi=(0.05,'fit',0.05),eps=(5.5,5.5),mat='steel_dark',col='decorative',role='post',join='col_ends',where='one, z 0, y 45 to 80, 0.25 m proud'),
 # ---- the lobby
 dict(g='lobby',id='lobby_floor',what='the lobby floor, bare dark stone, flush with the forecourt',shape='box',semi=(7.8,0.2,6.8),mat='lobby_stone',col='solid',role='slab',reason='a floor fills to the walls: a rounded slab would leave open corners',top=0.0),
 dict(g='lobby',id='lobby_ceiling',what='the lobby\'s ceiling, 7.8 m up: double height',shape='box',semi=(7.8,0.2,6.8),mat='lobby_dark',col='solid',role='slab',reason='as lobby_floor',top=8.2),
 dict(g='lobby',id='lobby_strip',what='a ceiling light strip, cold white',shape='egg',semi=(2.0,0.05,0.12),eps=(5.5,5.5),mat='lamp_cold',col='decorative',role='lamp',where='four, in two rows at z -3 and 3, x -4 and 4, under the ceiling'),
 dict(g='lobby',id='door_bar',what='the push bar across the door\'s inside face',shape='clipped',semi=(0.7,0.03,0.03),eps=(5.5,5.5),mat='steel_dark',col='decorative',role='rail',join='against_wall',where='one, 1.0 m up the door\'s inside face'),
 # ---- the lift
 dict(g='lift',id='core_wall',what='the services core, 7 by 7 m, from the pit (0.5 m under the lobby floor) up through every storey to 156 m, the lift\'s shaft cut through it and a landing door punched at each stop',shape='wall',semi=(3.5,78.25,3.5),mat='core_concrete',col='solid',role='wall',where='x 0 to 7, z -2 to 5, y -0.5 to 156; seen in the lobby, the way in and the arena'),
 dict(g='lift',id='lift_cavity',what='the lift shaft: one closed cutter, 3.6 m square, from the pit to 154 m, the core closed above it',shape='punched',n=12.0,semi=(1.8,77.25,1.8),mat='shadow',col='open',role='opening',join='punched',at=(3.5,76.75,1.5)),
 dict(g='lift',id='lift_landing',what='a landing door\'s opening in the core\'s plaza face: the leaf\'s own silhouette with its clearance, flat at the floor',shape='punched',outline='lift_door_leaf',clear=0.015,semi=(0.75,1.2,'wall'),floor=True,mat='shadow',col='open',role='opening',join='punched',where='three: the lobby (y 0), the way in (y 79.0), the arena (y 150), at x 3.5 on the core\'s north face (z -2)'),
 dict(g='lift',id='lift_door_leaf',what='a landing door, one leaf on one hinge, thrown open into the landing while the car is at it',shape='clipped',semi=(0.735,1.41,0.025),centre=0.97,eps=(5.5,4.0),mat='door_black',col='solid',role='leaf',join='floor_cut',hinge='east jamb',swing='outward, 78 degrees'),
 dict(g='lift',id='lift_surround',what='the steel ring round a landing door',shape='punched',outline='lift_landing',ring=0.1,semi=(0.85,1.3,0.04),floor=True,mat='steel_dark',col='decorative',role='trim',join='punched'),
 dict(g='lift',id='car_floor',what='the car\'s floor, 3.2 m square, its top on the landing\'s floor',shape='box',semi=(1.6,0.14,1.6),mat='car_steel',col='solid',role='slab',reason='a floor fills to the walls',top=0.0),
 dict(g='lift',id='car_wall',what='a wall of the open-fronted car (west, east, back), 2.4 m clear, cut flat at floor and roof',shape='clipped',semi=(0.06,'fit',1.6),eps=(5.5,5.5),mat='car_steel',col='solid',role='slab',join='car_ends',where='three, on the car\'s west, east and south sides'),
 dict(g='lift',id='car_roof',what='the car\'s roof',shape='box',semi=(1.6,0.06,1.6),mat='car_steel',col='solid',role='slab',reason='a roof fills to the walls',top=2.52),
 dict(g='lift',id='car_panel',what='the call panel on the car\'s east wall, where "Up" and "Down" are offered',shape='clipped',semi=(0.2,0.3,0.04),eps=(5.5,5.5),mat='lamp_cold',col='decorative',role='slab',join='against_wall',where='one, 1.1 m up the east wall'),
 dict(g='lift',id='car_lamp',what='the car\'s ceiling lamp',shape='egg',semi=(0.3,0.05,0.3),eps=(2.2,3.0),mat='lamp_cold',col='decorative',role='lamp'),
 # ---- the way in
 dict(g='plant',id='plant_floor',what='the plant floor, 24 by 22 m, its top at 79.0, the lift cavity open through it',shape='box',semi=(12.0,0.15,11.0),mat='plant_steel',col='solid',role='slab',reason='a floor fills to the walls',top=79.0),
 dict(g='plant',id='plant_ceiling',what='the plant\'s ceiling, 3.6 m clear above the floor',shape='box',semi=(12.0,0.15,11.0),mat='lobby_dark',col='solid',role='slab',reason='as plant_floor',top=82.9),
 dict(g='plant',id='plant_fan',what='a wall fan, a disc 2.6 m across, running slowly',shape='clipped',semi=(1.3,1.3,0.25),eps=(2.0,2.0),mat='fan_grey',col='solid',role='disc',join='against_wall',where='ten: four on each of the north and south walls at x -9, -3, 3, 9 and two on the east wall at z -9 and 5, their centres 1.6 m up'),
 dict(g='plant',id='plant_duct',what='a duct block on the floor, a low landing',shape='clipped',semi=(1.1,0.5,1.5),eps=(5.5,5.5),mat='duct_grey',col='landing',role='slab',join='seated',where='four, at (x, z) = (-8, -6), (-4, -6), (-8, 6), (-4, 6)'),
 dict(g='plant',id='plant_pipe',what='an overhead pipe, 18 m long, under the ceiling',shape='clipped',semi=(9.0,0.22,0.22),eps=(5.5,5.5),mat='duct_grey',col='solid',role='beam',join='pipe_ends',where='one, x -9 to 9, z 7, y 82.0'),
 dict(g='plant',id='plant_lamp',what='a warm pendant over the floor, the louvre\'s colour',shape='egg',semi=(0.25,0.2,0.25),eps=(2.2,3.0),mat='louvre_warm',col='decorative',role='lamp',where='three, at z -8, 0, 8 on x -6'),
 # ---- the arena
 dict(g='arena',id='arena_floor',what='the arena floor, 24 by 22 m at 150.0, the lift cavity open through it',shape='box',semi=(12.0,0.35,11.0),mat='arena_stone',col='solid',role='slab',reason='a floor fills to the walls',top=150.0),
 dict(g='arena',id='gallery_floor',what='the gallery floor, on the back slope, 164 m up, running into the shell behind',shape='box',semi=(8.6,0.15,2.5),mat='plant_steel',col='landing',role='slab',reason='a floor fills to the walls; its back is cut by the shell',top=164.0),
 dict(g='arena',id='gallery_glass',what='the gallery\'s glass, facing the arena, floor to rail, in bays between posts',shape='clipped',semi=(2.15,1.4,0.04),eps=(5.5,5.5),mat='glass',col='solid',role='slab',join='glass_bays',where='four, x -8.6 to 8.6 at z 2'),
 dict(g='arena',id='gallery_post',what='a post of the gallery\'s front',shape='clipped',semi=(0.06,'fit',0.06),eps=(5.5,5.5),mat='steel_dark',col='solid',role='post',join='col_ends',where='five, at the bays\' ends'),
 dict(g='arena',id='gallery_rail',what='the gallery\'s top rail over the glass, 2.8 m up',shape='clipped',semi=('fit',0.04,0.05),eps=(5.5,5.5),mat='steel_dark',col='landing',role='rail',join='rail_bays'),
 dict(g='arena',id='stair_tread',what='a tread of the gallery stair, 0.2 up and 0.29 along, a solid step 0.4 deep',shape='clipped',semi=(1.0,0.2,0.145),eps=(5.5,5.5),mat='plant_steel',col='landing',role='slab',join='stair_run',where='two flights of 35 (A along the west wall going north from the floor, B back going south to the gallery)'),
 dict(g='arena',id='stair_landing',what='the stair\'s turn, 4.8 by 2.25 m at 157 m',shape='box',semi=(2.4,0.2,1.125),mat='plant_steel',col='landing',role='slab',reason='a floor fills to the walls',top=157.0),
 dict(g='arena',id='stair_post',what='a post of the stair\'s rails, every 2.5 m',shape='clipped',semi=(0.04,'fit',0.04),eps=(5.5,5.5),mat='steel_dark',col='solid',role='post',join='col_ends',where='along A\'s east side, both sides of B, the landing\'s east edge'),
 dict(g='arena',id='stair_rail',what='the stair\'s handrail, 1.0 m above the nosing, between posts',shape='clipped',semi=('fit',0.03,0.03),eps=(5.5,5.5),mat='steel_dark',col='landing',role='rail',join='rail_bays'),
]
## ---- the mech: built on the hero's own rig, every joint his x 1.05. at: a joint (the left; the right mirrors in x) and an
## offset in the mech's metres; a tube runs from one joint (+ offset) to another and is cut flat at both, the ball of the
## joint covering the cut. The hero's hands, feet and head are his own SuperEggs at the mech's scale.
BT_MECH=dict(
  scale=1.05,
  joints=dict(leg=(0.0985,0.9025,0.0),knee=(0.1135,0.466,0.0),ankle=(0.1275,0.067,0.0),arm=(0.2195,1.4915,0.0),elbow=(0.2605,1.2,0.0),
              wrist=(0.298,0.9365,0.0),hand=(0.304,0.8915,0.0),neck=(0.0,1.5865,0.0),hips=(0.0,0.988,-0.0025),chest=(0.0,1.444,0.0),head_centre=(0.0,1.746,0.0)),
  hero=dict(head=(0.126,0.150,0.120),hand=(0.061,0.0645,0.033),foot=(0.07,0.0435,0.1295),foot_off=(0.0005,-0.0105,0.0455),height=1.896),
  # the game's exported city-blorb chest (hero scale), the shell the shoulder pads must stay inside
  chest_blorb=dict(c=(0.0,1.425,0.0),semi=(0.292,0.19,0.205)),
  seam=0.014, plates_pad=0.08, chest_h=0.15,
  head_cut='glass where z > 0.02 + 0.85 x (max(0, -y) / 0.62)^3, in the head\'s own frame normalized to its half-sizes (x, y, z each over its semi); one curve: along the crown\'s front half it is the plane z = 0.02, below the temples it sweeps forward and down and closes at the chin',
  hinge='at the crown: (0, head centre y + 0.96 x semi y, head centre z - 0.01), swinging up and forward 72 degrees',
  pilot_inset=0.87, eye_w=0.04,
  capsule=dict(r=0.28,h=1.99),
  suit='worn through BlorbSuitController on the mech\'s pivot map, suit_rig_scale 1.05; the head blorb over the helmet')
BT_PARTS+=[
 # legs (each side)
 dict(g='mech',id='hip_ball',what='the hip actuator',shape='egg',semi=(0.05,0.05,0.05),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='leg',off=(0,0,0),mirror=True),
 dict(g='mech',id='thigh',what='the thigh, a slim tube joint to joint, cut flat at both joints',shape='clipped',semi=(0.04,'fit',0.04),eps=(3.0,3.0),ext=0.01,mat='metal_black',col='decorative',role='limb',join='socket_cut',tube=(('leg',(0,0,0)),('knee',(0,0,0))),mirror=True),
 dict(g='mech',id='knee_ball',what='the knee actuator',shape='egg',semi=(0.043,0.043,0.043),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='knee',off=(0,0,0),mirror=True),
 dict(g='mech',id='knee_ring',what='a band of light round the knee: a thin round lens a little wider than the ball, so only its rim shows',shape='egg',semi=(0.047,0.0045,0.047),eps=(2.0,2.0),mat='blorb_light',col='decorative',role='ring',on='knee',off=(0,0,0),axis='x',mirror=True),
 dict(g='mech',id='shin',what='the shin, a tube knee to ankle, cut flat at both',shape='clipped',semi=(0.034,'fit',0.034),eps=(3.0,3.0),ext=0.01,mat='metal_black',col='decorative',role='limb',join='socket_cut',tube=(('knee',(0,0,0)),('ankle',(0,0,0))),mirror=True),
 dict(g='mech',id='shin_piston',what='a slim piston behind each shin, a rod from the knee\'s back to the ankle\'s',shape='egg',semi=(0.011,'fit',0.011),eps=(3.0,3.0),mat='metal_black',col='decorative',role='limb',tube=(('knee',(0,-0.07,-0.05)),('ankle',(0,0.09,-0.04))),mirror=True),
 dict(g='mech',id='ankle_ball',what='the ankle actuator, grown to cover the shin\'s cut',shape='egg',semi=(0.037,0.037,0.037),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='ankle',off=(0,0,0),mirror=True),
 dict(g='mech',id='foot',what='the hero\'s own foot at the mech\'s scale, solid, black',shape='egg',semi=(0.0735,0.0457,0.136),eps=(3.0,3.0),mat='metal_black',col='decorative',role='foot',on='ankle',off=(0.0005,-0.011,0.0478),yaw=7.0,mirror=True),
 # torso
 dict(g='mech',id='pelvis',what='the pelvis, the hero\'s hip volume as a plate, its top on the abdomen\'s foot',shape='clipped',semi=(0.15,0.07,0.095),eps=(5.5,5.5),mat='metal_black',col='decorative',role='plate',join='torso_stack',on='hips',off=(0,0.01,0.0026)),
 dict(g='mech',id='abdomen_lower',what='the lower armoured plate of the robot abdomen, cut at the seam',shape='clipped',semi=(0.14,0.0627,0.095),eps=(5.5,5.5),mat='metal_black',col='decorative',role='plate',join='torso_stack',on='hips',off=(0,0.1387,0.0026)),
 dict(g='mech',id='abdomen_light',what='the band of light between the two plates, recessed in the seam',shape='egg',semi=(0.128,0.01,0.086),eps=(5.5,5.5),mat='blorb_light',col='decorative',role='band',on='hips',off=(0,0.2044,0.0026)),
 dict(g='mech',id='abdomen_upper',what='the upper armoured plate, cut at the seam and under the chest',shape='clipped',semi=(0.155,0.0627,0.1),eps=(5.5,5.5),mat='metal_black',col='decorative',role='plate',join='torso_stack',on='hips',off=(0,0.2701,0.0026)),
 dict(g='mech',id='chest',what='the chest, soft above and flat below, its foot on the upper plate',shape='clipped',semi=(0.18,0.15,0.105),eps=(3.0,5.5),mat='metal_black',col='decorative',role='plate',join='torso_stack',on='chest',off=(0,0,0)),
 dict(g='mech',id='chest_plate',what='the bright steel plate on the chest, the only bright metal',shape='egg',semi=(0.13,0.1,0.02),eps=(5.5,5.5),mat='steel_bright',col='decorative',role='plate',on='chest',off=(0,0.01,0.092)),
 dict(g='mech',id='chest_slit',what='a vertical slit of light down the chest plate',shape='egg',semi=(0.008,0.07,0.005),eps=(5.5,5.5),mat='blorb_light',col='decorative',role='band',on='chest',off=(0,0.01,0.113)),
 # arms
 dict(g='mech',id='shoulder_ball',what='the shoulder actuator, under its shell',shape='egg',semi=(0.044,0.044,0.044),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='arm',off=(0,0,0),mirror=True),
 dict(g='mech',id='shoulder_ring',what='a band of light round the shoulder: a thin round lens (rim radius 0.048) a little wider than the ball, under the shell, its rim showing at the shell\'s lower edge',shape='egg',semi=(0.048,0.0045,0.048),eps=(2.0,2.0),mat='blorb_light',col='decorative',role='ring',on='arm',off=(0,0,0),axis='x',mirror=True),
 dict(g='mech',id='shoulder_shell',what='the shoulder shell: a rounded cover over the shoulder joint, tilted 18 degrees down toward the arm, cut flat under the joint\'s centre so the arm leaves from beneath it, and inside the blorb chest\'s surface',shape='clipped',semi=(0.066,0.06,0.066),eps=(2.4,2.4),mat='metal_black',col='decorative',role='shell',join='shoulder_seat',on='arm',off=(-0.02,-0.005,0.0),tilt=18.0,cut=-0.02,mirror=True),
 dict(g='mech',id='upper_arm',what='the upper arm, a tube shoulder to elbow, cut flat at both',shape='clipped',semi=(0.03,'fit',0.03),eps=(3.0,3.0),ext=0.01,mat='metal_black',col='decorative',role='limb',join='socket_cut',tube=(('arm',(0,0,0)),('elbow',(0,0,0))),mirror=True),
 dict(g='mech',id='elbow_ball',what='the elbow actuator',shape='egg',semi=(0.036,0.036,0.036),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='elbow',off=(0,0,0),mirror=True),
 dict(g='mech',id='forearm',what='the forearm, a tube elbow to wrist, cut flat at both',shape='clipped',semi=(0.027,'fit',0.027),eps=(3.0,3.0),ext=0.005,mat='metal_black',col='decorative',role='limb',join='socket_cut',tube=(('elbow',(0,0,0)),('wrist',(0,0,0))),mirror=True),
 dict(g='mech',id='wrist_ball',what='the wrist actuator, grown to cover the forearm\'s cut',shape='egg',semi=(0.03,0.03,0.03),eps=(2.0,2.0),mat='metal_black',col='decorative',role='ball',on='wrist',off=(0,0,0),mirror=True),
 dict(g='mech',id='hand',what='the hero\'s own hand at the mech\'s scale: solid, no fingers, black',shape='egg',semi=(0.064,0.0677,0.0347),eps=(3.0,3.0),mat='metal_black',col='decorative',role='hand',on='hand',off=(0,0,0),yaw=-97.0,mirror=True),
 # neck and head
 dict(g='mech',id='neck',what='a slim column on the neck joint, no collar',shape='egg',semi=(0.026,0.035,0.026),eps=(3.0,3.0),mat='metal_black',col='decorative',role='limb',on='neck',off=(0,0.005,-0.005)),
 dict(g='mech',id='neck_ring',what='a band of light round the neck',shape='egg',semi=(0.03,0.0045,0.03),eps=(2.0,2.0),mat='blorb_light',col='decorative',role='ring',on='neck',off=(0,0.01,-0.005),axis='y'),
 dict(g='mech',id='head_shell',what='the hero\'s head shape at the mech\'s scale, the black shell: the back half, the jaw and the whole underside of the chin, behind the one line',shape='egg',semi=(0.1323,0.1575,0.126),eps=(2.5,2.5),mat='metal_black',col='decorative',role='head',join='head_split',on='head_centre',off=(0,0,0)),
 dict(g='mech',id='head_visor',what='the glass visor: the same head shape, the front of the one line (crown\'s front half, temples, face, the front of the chin); it hinges at the crown',shape='egg',semi=(0.1323,0.1575,0.126),eps=(2.5,2.5),mat='visor_glass',col='decorative',role='head',join='head_split',on='head_centre',off=(0,0,0)),
 dict(g='mech',id='pilot_body',what='the pilot: the head shape inset to 0.87 inside the shell; a city blorb glows, Blorbus does not',shape='egg',semi=(0.1151,0.137,0.1096),eps=(2.5,2.5),mat='blorb_body',col='decorative',role='pilot',join='pilot_seat',on='head_centre',off=(0,0,0)),
 dict(g='mech',id='pilot_eye',what='one of the game\'s own blorb eyes on the pilot\'s skin, about 0.04 m wide, lying flat on it (turned to the skin\'s normal), coloured by blorb.gd\'s rule, front standing inside the shell',shape='egg',semi=(0.02,0.022,0.012),eps=(2.5,2.5),mat='blorb_eye',col='decorative',role='pilot',join='pilot_seat',on='head_centre',off=(0.045,0.018,0.1),mirror=True),
 dict(g='mech',id='pilot_core',what='the pilot\'s glowing core (a city blorb\'s only)',shape='egg',semi=(0.03,0.03,0.03),eps=(2.0,2.0),mat='blorb_core',col='decorative',role='pilot',join='pilot_seat',on='head_centre',off=(0,0.02,-0.04)),
]
BT_JOINS=[
 dict(id='floor_cut',kind='seated',parts=['door_leaf','lift_door_leaf','louvre_leaf'],plane='the floor under the leaf',rule='as world_door.gd: the leaf\'s egg reaches below the floor and is cut flat at it, so its bottom stands square on the threshold and its top keeps its soft shoulders; one leaf on one hinge (the louvre\'s two are a pair)'),
 dict(id='louvre_set',kind='split',parts=['louvre_leaf'],parent=(1.185,1.31,0.03),centre=0.87,eps=(5.5,4.0),cuts=[(1,0,0,0.0)],hinge='outer',rule='two louvred leaves from one parent the size of the closed opening, cut at the floor too; they are thrown back flat on the wall either side'),
 dict(id='crown_fold',kind='meet',parts=['crown_n1','crown_n2','crown_s1','crown_s2','crown_w','crown_e','crown_ridge'],plane='the mitre plane of each shared edge; the springing plane y = 150 under the facets',rule='the plaza and back faces are warped quadrilaterals, so each is two plates on one named diagonal (plaza NE-Wf, back SE-Wb); every plate is cut at the plane it shares with its neighbour, so the edges meet on straight lines with no gap, no overlap and no ledge; the eye lies wholly inside crown_n1'),
 dict(id='col_ends',kind='chain',parts=['base_post','corner_post','fire_post','gallery_post','stair_post','rail_bar'],plane='what it stands on, and what it carries',rule='cut flat at both ends and capped: a base post from the forecourt to the soffit, a corner post from the soffit to the springing, a rail post from its floor to under its rail'),
 dict(id='rail_bays',kind='chain',parts=['fire_rail','gallery_rail','stair_rail'],plane='the faces of the posts at each end of a bay',rule='each bay\'s rail is cut at the faces of what carries it, with no gap and no overlap'),
 dict(id='ramp_ends',kind='chain',parts=['fire_ramp'],plane='the landing\'s edge at each end of a flight',rule='a flight is cut at the planes of the two landings it joins, from the same datum (7.5 m a flight): flush at both ends, no ledge'),
 dict(id='stair_run',kind='chain',parts=['stair_tread'],plane='each tread\'s front and back planes',rule='a step every 0.29 m along and 0.2 m up; the first tread\'s top is 0.2 above the arena floor, the last of flight B is flush with the gallery floor, the last of A flush with the landing'),
 dict(id='glass_bays',kind='chain',parts=['gallery_glass'],plane='the post faces',rule='each pane spans post to post and is cut at both'),
 dict(id='rib_ends',kind='chain',parts=['crown_rib'],plane='the arena floor\'s plane and the ridge facet\'s plane',rule='each rib runs on its facet from the springing to the ridge, cut at both and capped'),
 dict(id='pipe_ends',kind='chain',parts=['plant_pipe'],plane='the walls\' inner faces',rule='cut at the west and east inner faces and capped'),
 dict(id='car_ends',kind='chain',parts=['car_wall'],plane='the car\'s floor top and roof underside',rule='cut flat at both and capped; the three walls stand on the floor and stop under the roof'),
 dict(id='seated',kind='seated',parts=['plant_duct'],plane='the top of what it stands on',rule='cut flat at that plane and capped; no gap, no buried half'),
 dict(id='against_wall',kind='seated',parts=['vent_hood','louvre_sill','fire_landing','rail_bracket','door_bar','car_panel','plant_fan'],plane='the wall\'s outer (or inner) face',rule='cut at the wall face and capped; it stands proud of the wall by its depth, nothing sunk into the wall'),
 dict(id='on_surface',kind='placed',parts=['door_opening','louvre_opening','eye_slit','lift_landing','vent_hood','rail_bracket'],plane='the face as it is',rule='only on a flat run of a face; the corner posts and the facets\' edges carry nothing'),
 dict(id='punched',kind='punched',parts=['door_opening','door_surround','louvre_opening','louvre_surround','eye_slit','eye_surround','lift_cavity','lift_landing','lift_surround'],plane='through the wall',rule='one closed cutter per opening; a doorway is its leaves\' own silhouette (outline) grown by its clearance, so frame and leaf are one shape; an opening that reaches the floor (floor) is flat there; the glass is the cutter intersected with the wall, the ring the cutter grown by its ring less the cutter'),
 # the mech
 dict(id='socket_cut',kind='chain',parts=['thigh','shin','upper_arm','forearm'],plane='the plane through each joint\'s centre, square to the limb',rule='a limb tube is cut flat at both joint centres and capped; the actuator ball at the joint (at least 1.05 x the tube\'s radius) covers the cut, so no cap and no gap shows'),
 dict(id='torso_stack',kind='chain',parts=['pelvis','abdomen_lower','abdomen_upper','chest'],plane='the pelvis top (hips + 0.08), the seam\'s two planes (0.014 apart, about the stack\'s middle), the chest\'s foot (chest - 0.15)',rule='each plate is cut flat at the planes it shares with its neighbour; the band of light fills the seam; the stack is flush from the pelvis to the chest'),
 dict(id='shoulder_seat',kind='seated',parts=['shoulder_shell'],plane='the plane under the pad, tilted with it',rule='the shell covers the shoulder joint: the actuator ball and its ring of light above the cut plane lie inside the shell (at 0.97 of its surface), and the shell is cut flat and capped at that plane so the arm leaves from under it; it lies inside the blorb chest\'s surface (the chest blorb\'s ellipsoid at 1.01), so with the suit on only the blorb shows'),
 dict(id='head_split',kind='split',parts=['head_shell','head_visor'],parent=(0.1323,0.1575,0.126),centre=1.8333,eps=(2.5,2.5),cuts=[],curve='one smooth curve, no chin line',hinge='the visor at the crown',rule='both are the one head egg; the visor keeps the front of the curve, the shell the rest; the curve is BLOCK_TOWER.mech.head_cut: it runs over the crown\'s front half as a plane, sweeps down and forward below the temples and closes at the chin, a single line all the way round; the shell is closed behind the glass and the visor is cut and capped along the same line'),
 dict(id='pilot_seat',kind='placed',parts=['pilot_body','pilot_eye','pilot_core'],plane='the head\'s centre',rule='the pilot is the head shape inset to 0.87 so that it and its eyes stay inside the shell; the eyes are the game\'s blorb eye meshes, moved onto the pilot\'s skin and set in the skin\'s own frame so each lies flat and upright on it (its thin axis on the skin\'s normal where it sits, its long axis along the skin\'s up; the free blorb\'s pitch and roll dropped), each with a millimetre to spare'),
]
BLOCK_TOWER['mech']=BT_MECH
BLOCK_TOWER['parts']=BT_PARTS; BLOCK_TOWER['joins']=BT_JOINS
def _bt_parts_checks():
    parts_checks('block',BT_PARTS,BT_JOINS)
    P_={p['id']:p for p in BT_PARTS}; J_={j['id']:j for j in BT_JOINS}; BT=BLOCK_TOWER; S=BT['sched']; SI=S['inside']; I=BT['inside']; M=BT['mech']
    def off(nm,a,b,tol=0.011):
        if abs(a-b)>tol: problems.append(('block parts: %s out of step'%nm,a,b))
    ST=_TOP/I['floors']; sub=lambda a,b: tuple(x-y for x,y in zip(a,b))
    # the parts are placed on something
    for g in ('body','openings','crown','climb','lobby','lift','plant','arena','mech'):
        if not [p for p in BT_PARTS if p['g']==g]: problems.append(('block parts: no part in',g))
    # ---- the body
    base=BT['base']; bw=P_['base_wall']
    off('the base\'s setback',_BW/2-bw['semi'][0],base[0]); off('the base\'s setback (depth)',_BD/2-bw['semi'][2],base[0]); off('the base\'s height',2*bw['semi'][1],base[1])
    sw=P_['shaft_wall']
    off('the shaft\'s width',2*sw['semi'][0],_BW); off('the shaft\'s depth',2*sw['semi'][2],_BD); off('the shaft\'s height',2*sw['semi'][1],_TOP-base[1])
    if bw['t']<S['wall'] or sw['t']!=S['wall']: problems.append(('block parts: the walls out of step with the schedule\'s thickness',))
    # ---- the door: in the base wall, 4 m behind the plan's door line, in the base's span, one leaf
    d=P_['door_opening']; D_=S['door']
    off('the door\'s width',2*d['semi'][0],D_['w']); off('the door\'s height',2*d['semi'][1],D_['h'])
    off('the door\'s x',d['at'][0],BT['door'][0]-_OX); off('the door\'s depth',d['at'][2],-(_BD/2-base[0])); off('the plan\'s door line',BT['door'][1],_SH[1])
    if abs(d['at'][0])+D_['w']/2+0.6>bw['semi'][0]: problems.append(('block parts: the door too near the base\'s corner',))
    # ---- the hoods: on the ring heights, in the face, clear of the corner posts and of each other, the east pair either side of the rail
    h=S['hood']; hd=P_['vent_hood']
    off('the hood\'s width',2*hd['semi'][0],h['w']); off('the hood\'s height',2*hd['semi'][1],h['h']); off('the hood\'s projection',hd['semi'][2],h['out'])
    off('the hood against BLOCK_TOWER.vent (projection)',h['out'],BT['vent'][0]); off('the hood against BLOCK_TOWER.vent (width)',h['w'],BT['vent'][1])
    for lst,half,nm in ((h['ns'],_BW/2,'plaza and back'),(h['ew'],_BD/2,'side')):
        if max(abs(c) for c in lst)+h['w']/2>half-1.0: problems.append(('block parts: a hood too near a corner post on the',nm))
        if any(b-a<h['w']+1.0 for a,b in zip(lst,lst[1:])): problems.append(('block parts: hoods too close on the',nm))
    lz=I['louvre']['at']-_OZ
    if lz not in h['ew']: problems.append(('block parts: the open louvre is not under an east hood',lz))
    # ---- the open louvre
    L=S['louvre']; lo=P_['louvre_opening']
    off('the louvre\'s width',2*lo['semi'][0],L['w']); off('the louvre\'s height',2*lo['semi'][1],L['h'])
    ring=I['louvre']['ring']*_TOP
    off('the louvre\'s hood bottom on its head',ring-h['h'],L['sill']+L['h']); off('the louvre\'s sill on the plant floor',L['sill'],SI['floors']['way_in'])
    off('the sill\'s top',P_['louvre_sill']['top'],L['sill']); off('the sill\'s width',2*P_['louvre_sill']['semi'][0],L['sill_w']); off('the sill\'s projection',P_['louvre_sill']['semi'][2],L['sill_out'])
    if L['sill_w']<L['w']: problems.append(('block parts: the sill narrower than the opening',))
    # ---- the crown: facets on the plan's corners, the planes true, the eye in one plate
    import math as _m
    def sub3(a,b): return (a[0]-b[0],a[1]-b[1],a[2]-b[2])
    def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
    def dot(a,b): return sum(x*y for x,y in zip(a,b))
    for p in BT_PARTS:
        if p['shape']!='facet': continue
        pts=[BT_PT[k] for k in p['pts']]
        if len(pts)==4:
            n=cross(sub3(pts[1],pts[0]),sub3(pts[2],pts[0])); ln=_m.sqrt(dot(n,n)); dist=abs(dot(n,sub3(pts[3],pts[0])))/ln
            if dist>0.01: problems.append(('block parts: a crown plate not flat',p['id'],round(dist,3)))
        if p['t']!=S['crown_t']: problems.append(('block parts: a crown plate not the schedule\'s thickness',p['id']))
    for nm,quad in (('plaza',('NW','NE','Ef','Wf')),('back',('SE','SW','Wb','Eb'))):
        pts=[BT_PT[k] for k in quad]; n=cross(sub3(pts[1],pts[0]),sub3(pts[2],pts[0]))
        if abs(dot(n,sub3(pts[3],pts[0])))/_m.sqrt(dot(n,n))<0.05: problems.append(('block parts: the %s face is flat and needs no split'%nm,))
    # every crown plate's edge is shared by exactly one other plate or lies on the springing / the ridge's ends
    edges={}
    for p in BT_PARTS:
        if p['shape']!='facet': continue
        ks=p['pts']
        for a,b in zip(ks,ks[1:]+ks[:1]): edges.setdefault(frozenset((a,b)),[]).append(p['id'])
    for e,ids in edges.items():
        if len(ids)==2: continue
        a,b=sorted(e)
        on_spring=BT_PT[a][1]==_TOP and BT_PT[b][1]==_TOP; on_end=a[0]=='W' and b[0]=='W' or a[0]=='E' and b[0]=='E'
        if not (len(ids)==1 and (on_spring or on_end or {a,b}<={'Wf','Ef','Eb','Wb'})): problems.append(('block parts: a crown edge with no neighbour',sorted(e),ids))
    # the eye: wholly inside crown_n1, as a cutter of the BLOCK_TOWER.eye numbers
    E_=BT['eye']; ey=P_['eye_slit']; ex=(_XW+_XE)/2
    off('the eye\'s height',2*ey['semi'][1],E_['y'][1]-E_['y'][0]); off('the eye\'s width',2*ey['semi'][0],E_['w']); off('the eye\'s centre',ey['at'][1],(E_['y'][0]+E_['y'][1])/2); off('the eye\'s x',ey['at'][0],ex)
    tri=[BT_PT[k] for k in P_['crown_n1']['pts']]
    def inside_tri(x,y):
        (x0,y0,_),(x1,y1,_),(x2,y2,_)=tri; d=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
        a=((y1-y2)*(x-x2)+(x2-x1)*(y-y2))/d; b=((y2-y0)*(x-x2)+(x0-x2)*(y-y2))/d
        return a>=0 and b>=0 and 1-a-b>=0
    for x_ in (ex-E_['w']/2,ex+E_['w']/2):
        for y_ in E_['y']:
            if not inside_tri(x_,y_): problems.append(('block parts: the eye leaves crown_n1',x_,y_))
    pn=cross(sub3(tri[1],tri[0]),sub3(tri[2],tri[0])); zface=lambda y: tri[0][2]-(pn[1]*(y-tri[0][1]))/pn[2]
    off('the eye\'s depth on its plate',ey['at'][2],zface(ey['at'][1]),0.02)
    # ---- the climb: every hop within the hero's jump
    hop=S['hop']; F_=S['fire']; Br=S['bracket']; ring0=BT['vents'][0]*_TOP
    if hop['rise']>0.9*hop['apex']: problems.append(('block parts: a hop higher than the hero\'s jump clears',hop['rise'],hop['apex']))
    if hop['leap']>0.8*hop['reach']: problems.append(('block parts: a leap longer than the hero\'s jump reaches',hop['leap'],hop['reach']))
    if F_['rise']>F_['run']*_m.tan(_m.radians(TOWER_HOUSE['ramp']['max_deg'])): problems.append(('block parts: a fire escape flight steeper than the world\'s ramps',))
    off('the fire escape\'s rise to the first ring',F_['flights']*F_['rise'],ring0)
    A=I['approach']; xface=A['rect'][0]-_OX
    off('the leap across the gap',(xface-F_['landing_out'])-(_BW/2+h['out']),hop['leap'],0.011)
    off('the sixth landing level with the ring',F_['flights']*F_['rise'],BT['vents'][0]*_TOP)
    zs=F_['z_south']; south_end=zs+F_['landing_z']/2; north_end=zs-F_['landing_z']/2-F_['run']-F_['landing_z']
    if south_end>A['rect'][3]-_OZ-0.5 or north_end<A['rect'][1]-_OZ+0.5: problems.append(('block parts: the fire escape runs off the neighbour\'s face',north_end,south_end))
    if abs(zs-lz)>0.01: problems.append(('block parts: the sixth landing not in front of the east hood',zs,lz))
    if not (h['ew'][0]-h['w']/2<=zs-F_['landing_z']/2 and zs+F_['landing_z']/2<=h['ew'][0]+h['w']/2): problems.append(('block parts: the sixth landing not within the hood\'s width',))
    off('the fire landing\'s depth',P_['fire_landing']['semi'][2],F_['landing_out']); off('the fire landing\'s length',2*P_['fire_landing']['semi'][0],F_['landing_z'])
    off('the fire ramp\'s width',2*P_['fire_ramp']['semi'][0],F_['ramp_w'])
    if F_['landing_out']+0.5>xface-(_BW/2+h['out']): pass
    off('the first bracket one hop above the ring',Br['first'],ring0+hop['rise']); off('the brackets\' step',Br['step'],hop['rise'])
    last=Br['first']+(Br['count']-1)*Br['step']
    if not (L['sill']+0.5<=last<=ring-h['h']-0.2): problems.append(('block parts: the last bracket not a short step from the sill',last))
    if Br['out']>h['out']: problems.append(('block parts: a bracket proud of the hoods',))
    if abs(h['ew'][0]+h['w']/2-(-Br['z']-Br['w']/2))<0.3 or (h['ew'][1]-h['w']/2)-(Br['z']+Br['w']/2)<0.3: problems.append(('block parts: a bracket too close to a hood',))
    off('the bracket\'s width',2*P_['rail_bracket']['semi'][0],Br['w']); off('the bracket\'s projection',P_['rail_bracket']['semi'][2],Br['out'])
    # ---- the slits sit across every face at the plan's spacing
    sl=S['slit']['at']
    if any(abs(b-a-BT['slit'][1])>1e-6 for a,b in zip(sl,sl[1:])): problems.append(('block parts: the slits not at BLOCK_TOWER.slit\'s spacing',))
    off('the slit\'s width',2*P_['shaft_slit']['semi'][0],BT['slit'][0])
    # ---- inside
    fl=SI['floors']; zn={z[0]:z for z in I['zones']}
    off('the crown floor',fl['crown'],I['floors']*ST)
    wz=zn['way in']
    if not ((wz[1]*ST-0.1)<=fl['way_in']<=((wz[2]+1)*ST)): problems.append(('block parts: the way-in floor outside its storey',fl['way_in']))
    pl=SI['plant']; off('the plant ceiling',P_['plant_ceiling']['top']-2*P_['plant_ceiling']['semi'][1]-fl['way_in'],pl['clear'],0.0111)
    if P_['plant_ceiling']['top']>(wz[2]+1)*ST+0.02: problems.append(('block parts: the plant\'s ceiling through the storey above',))
    off('the plant floor',P_['plant_floor']['top'],fl['way_in']); off('the plant\'s width',2*P_['plant_floor']['semi'][0],_BW-2*S['wall']); off('the plant\'s depth',2*P_['plant_floor']['semi'][2],_BD-2*S['wall'])
    lb=SI['lobby']; off('the lobby\'s width',2*P_['lobby_floor']['semi'][0],2*bw['semi'][0]-2*bw['t']); off('the lobby\'s depth',2*P_['lobby_floor']['semi'][2],2*bw['semi'][2]-2*bw['t'])
    off('the lobby\'s clear height',P_['lobby_ceiling']['top']-2*P_['lobby_ceiling']['semi'][1],lb['clear'])
    if P_['lobby_ceiling']['top']>base[1]: problems.append(('block parts: the lobby\'s ceiling through the base\'s roof',))
    off('the arena floor',P_['arena_floor']['top'],fl['crown']); off('the arena\'s width',2*P_['arena_floor']['semi'][0],_BW-2*S['wall']); off('the arena\'s depth',2*P_['arena_floor']['semi'][2],_BD-2*S['wall'])
    c=SI['core']['rect']; wc=(I['core'][0]-_OX,I['core'][1]-_OZ,I['core'][2]-_OX,I['core'][3]-_OZ)
    if any(abs(a-b)>0.011 for a,b in zip(c,wc)): problems.append(('block parts: the core out of step with BLOCK_TOWER.inside.core',c,wc))
    lf=I['lifts']['lift']; lat=(lf['at'][0]-_OX,lf['at'][1]-_OZ); LF=SI['lift']
    if any(abs(a-b)>0.011 for a,b in zip(lat,LF['at'])): problems.append(('block parts: the lift out of step with BLOCK_TOWER.inside',lat,LF['at']))
    if any(abs(a-n*ST)>0.1 for a,n in zip(LF['stops'],lf['stops'])): problems.append(('block parts: the lift\'s stops off the storeys',))
    if abs(LF['stops'][1]-fl['way_in'])>0.011 or LF['stops'][2]!=fl['crown'] or LF['stops'][0]!=fl['lobby']: problems.append(('block parts: the lift\'s stops off the floors',))
    if (c[2]-c[0]-LF['cavity'])/2<1.0 or (c[3]-c[1]-LF['cavity'])/2<1.0: problems.append(('block parts: the core\'s wall round the lift under 1 m',))
    if abs((c[0]+c[2])/2-LF['at'][0])>0.01 or abs((c[1]+c[3])/2-LF['at'][1])>0.01: problems.append(('block parts: the lift not centred in the core',))
    off('the cavity\'s width',2*P_['lift_cavity']['semi'][0],LF['cavity']); off('the cavity\'s depth',2*P_['lift_cavity']['semi'][2],LF['cavity'])
    car=LF['car']
    if car['outer']>LF['cavity']-0.2: problems.append(('block parts: the car without 0.1 m each side',))
    off('the car\'s floor',2*P_['car_floor']['semi'][0],car['outer']); off('the car\'s roof',P_['car_roof']['top'],car['clear']+car['roof']+0.0)
    if car['clear']<LF['door']['h']: problems.append(('block parts: the car lower than its doors',))
    ll=P_['lift_landing']; off('the landing door\'s width',2*ll['semi'][0],LF['door']['w']); off('the landing door\'s height',2*ll['semi'][1],LF['door']['h'])
    if c[0]>lb['inner'][0]/2 or c[2]>lb['inner'][0]/2 or abs(c[1])>lb['inner'][1]/2 or abs(c[3])>lb['inner'][1]/2: problems.append(('block parts: the core outside the lobby',))
    # the gallery on the back slope: the plan's place, a stair of true steps, and headroom under the shell
    G=I['arena']['gallery']; GG=SI['gallery']
    off('the gallery\'s near edge',GG['z'][0],G['z'][0]-_OZ); off('the gallery\'s far edge',GG['z'][1],G['z'][1]-_OZ); off('the gallery\'s height',GG['y'],G['y']); off('the gallery floor',P_['gallery_floor']['top'],GG['y'])
    off('the gallery\'s depth',2*P_['gallery_floor']['semi'][2],GG['z'][1]-GG['z'][0]); off('the gallery\'s width',2*P_['gallery_floor']['semi'][0],GG['x'][1]-GG['x'][0])
    off('the glass\'s height',2*P_['gallery_glass']['semi'][1],GG['glass_h']); off('the glass bays',GG['glass_bays']*2*P_['gallery_glass']['semi'][0],GG['x'][1]-GG['x'][0])
    sp=[BT_PT[k] for k in ('SE','SW','Wb')]; nn=cross(sub3(sp[1],sp[0]),sub3(sp[2],sp[0]))
    if nn[2]<0: nn=tuple(-v for v in nn)
    ln=_m.sqrt(dot(nn,nn)); cn=dot(nn,sp[0])-S['crown_t']*ln
    roof=lambda z: (cn-nn[2]*z)/nn[1]
    if roof(GG['z'][0]+4.0)-GG['y']<2.2: problems.append(('block parts: no headroom on the gallery\'s standing ground',roof(GG['z'][0]+4.0)-GG['y']))
    if roof(GG['z'][0])-GG['y']<GG['glass_h']+1.0: problems.append(('block parts: no room for the glass under the shell',))
    st=SI['stair']
    off('flight A reaches the landing',fl['crown']+st['treads']*st['rise'],st['landing']['y']); off('flight B reaches the gallery',st['landing']['y']+st['treads']*st['rise'],GG['y'])
    off('flight A\'s run',st['a']['z0']-st['treads']*st['run'],st['landing']['z'][1]); off('flight B\'s run',st['b']['z0']+st['treads']*st['run'],GG['z'][0])
    off('flight B starts where the landing ends',st['b']['z0'],st['landing']['z'][1])
    if _m.degrees(_m.atan2(st['rise'],st['run']))>42: problems.append(('block parts: the stair steeper than 42 degrees',))
    if not (st['landing']['x'][0]<=st['a']['x']-st['w']/2 and st['b']['x']+st['w']/2<=st['landing']['x'][1]): problems.append(('block parts: the landing does not carry both flights',))
    if st['landing']['x'][0]<-(_BW/2-S['wall'])+0.3: problems.append(('block parts: the stair in the wall',))
    if not (-(_BD/2-S['wall'])<=st['landing']['z'][0]): problems.append(('block parts: the landing through the north wall',))
    if st['b']['x']-st['w']/2<=st['a']['x']+st['w']/2: problems.append(('block parts: the two flights overlap',))
    off('the tread\'s depth',2*P_['stair_tread']['semi'][2],st['run'],0.011); off('the tread\'s width',2*P_['stair_tread']['semi'][0],st['w'])
    off('the landing\'s width',2*P_['stair_landing']['semi'][0],st['landing']['x'][1]-st['landing']['x'][0]); off('the landing\'s depth',2*P_['stair_landing']['semi'][2],st['landing']['z'][1]-st['landing']['z'][0]); off('the landing\'s top',P_['stair_landing']['top'],st['landing']['y'])
    stn=SI['stations']
    if not (stn['hero'][2]<c[1]-1.0 and stn['boss'][2]<c[1]-1.0): problems.append(('block parts: a station not in front of the lift',))
    if stn['kask'][1]!=GG['y'] or stn['pinestein'][1]!=GG['y'] or not (GG['z'][0]<stn['kask'][2]<GG['z'][1]): problems.append(('block parts: Kask or Pinestein off the gallery',))
    # ---- the mech: the hero's joints x 1.05, thin metal limbs, balls that cover the cuts, a head under the doors
    MS=M['scale']; Jn={k:tuple(v*MS for v in vv) for k,vv in M['joints'].items()}
    hc=Jn['head_centre']; top=hc[1]+M['hero']['head'][1]*MS
    if top>2.0 or top>2.2-0.1: problems.append(('block parts: the mech too tall for the hero\'s doors',top))
    if M['capsule']['h']<top-0.005: problems.append(('block parts: the mech\'s capsule shorter than the mech',))
    for k in ('head_shell','head_visor'):
        for a,b in zip(P_[k]['semi'],M['hero']['head']):
            if abs(a-b*MS)>0.0005: problems.append(('block parts: the head out of step with the hero\'s',k))
    for a,b in zip(P_['pilot_body']['semi'],P_['head_shell']['semi']):
        if abs(a-b*M['pilot_inset'])>0.0006: problems.append(('block parts: the pilot is not the head inset',))
    for a,b in zip(P_['hand']['semi'],M['hero']['hand']):
        if abs(a-b*MS)>0.0006: problems.append(('block parts: the hand out of step with the hero\'s',))
    for a,b in zip(P_['foot']['semi'],M['hero']['foot']):
        if abs(a-b*MS)>0.0006: problems.append(('block parts: the foot out of step with the hero\'s',))
    balls={'leg':'hip_ball','knee':'knee_ball','ankle':'ankle_ball','arm':'shoulder_ball','elbow':'elbow_ball','wrist':'wrist_ball'}
    for p in BT_PARTS:
        if p['g']!='mech': continue
        if not ('on' in p or 'tube' in p): problems.append(('block parts: a mech part with no place',p['id']))
        for key in [p['on']] if 'on' in p else [t[0] for t in p['tube']]:
            if key not in Jn: problems.append(('block parts: a mech part on a joint the hero does not have',p['id'],key))
        if p['join']=='socket_cut' if 'join' in p else False:
            r=p['semi'][0]
            for end in p['tube']:
                bl=P_[balls[end[0]]]['semi'][0]
                if bl<1.05*r: problems.append(('block parts: a ball does not cover its limb\'s cut',p['id'],end[0]))
            a,b=p['tube']; length=_m.dist(tuple(x+o for x,o in zip(Jn[a[0]],a[1])),tuple(x+o for x,o in zip(Jn[b[0]],b[1])))
            if length<0.1: problems.append(('block parts: a limb tube too short',p['id']))
    hipY=Jn['hips'][1]; chestY=Jn['chest'][1]; s0=hipY+M['plates_pad']; s1=chestY-M['chest_h']; ay=(s1-s0-M['seam'])/4+0.004
    off('the abdomen plates',P_['abdomen_lower']['semi'][1],ay,0.0011); off('the upper plate',P_['abdomen_upper']['semi'][1],ay,0.0011)
    off('the pelvis meets the stack',hipY+P_['pelvis']['off'][1]+P_['pelvis']['semi'][1],s0,0.0011)
    off('the chest meets the stack',chestY-P_['chest']['semi'][1],s1,0.0011)
    off('the lower plate\'s place',hipY+P_['abdomen_lower']['off'][1],s0+ay-0.004,0.0011); off('the upper plate\'s place',hipY+P_['abdomen_upper']['off'][1],s1-ay+0.004,0.0011)
    off('the band of light in the seam',hipY+P_['abdomen_light']['off'][1],(s0+s1)/2,0.0011)
    off('the chest',P_['chest']['semi'][1],M['chest_h'])
    # the shoulder shell covers the joint (ball and ring above its cut inside it) and lies inside the blorb chest's surface
    cb=M['chest_blorb']; bc=tuple(v*MS for v in cb['c']); bs=tuple(v*MS for v in cb['semi']); sh_=P_['shoulder_shell']
    ar=Jn['arm']; ctr=(ar[0]+sh_['off'][0],ar[1]+sh_['off'][1],ar[2]+sh_['off'][2]); tl=_m.radians(sh_['tilt']); worst=0.0
    pw=lambda v,e: (_m.copysign(abs(v)**(2/e),v) if v else 0.0)
    e=sh_['eps'][0]; a_,b_,c_=sh_['semi']
    for i in range(-20,21):
        for j in range(40):
            eta=_m.pi/2*i/20; om=2*_m.pi*j/40
            x=a_*pw(_m.cos(eta),e)*pw(_m.sin(om),e); y=max(b_*pw(_m.sin(eta),e),sh_['cut']); z=c_*pw(_m.cos(eta),e)*pw(_m.cos(om),e)
            xr=x*_m.cos(tl)+y*_m.sin(tl); yr=-x*_m.sin(tl)+y*_m.cos(tl)
            q=((ctr[0]+xr-bc[0])/bs[0],(ctr[1]+yr-bc[1])/bs[1],(ctr[2]+z-bc[2])/bs[2]); worst=max(worst,_m.sqrt(dot(q,q)))
    if worst>1.01: problems.append(('block parts: the shoulder shell leaves the blorb chest',round(worst,3)))
    rb=P_['shoulder_ball']['semi'][0]; rr=P_['shoulder_ring']['semi'][0]; cover=0.0
    pts=[(rb*_m.cos(t_)*_m.cos(f_),rb*_m.sin(t_),rb*_m.cos(t_)*_m.sin(f_)) for t_ in [_m.pi*k/20 for k in range(-10,11)] for f_ in [2*_m.pi*k/24 for k in range(24)]]
    pts+=[(dx,rr*_m.cos(f_),rr*_m.sin(f_)) for f_ in [2*_m.pi*k/48 for k in range(48)] for dx in (-0.0045,0.0045)]
    for px,py,pz in pts:
        d=(-sh_['off'][0]+px,-sh_['off'][1]+py,-sh_['off'][2]+pz)
        lx=d[0]*_m.cos(tl)-d[1]*_m.sin(tl); ly=d[0]*_m.sin(tl)+d[1]*_m.cos(tl)
        if ly<sh_['cut']: continue
        cover=max(cover,(abs(lx/a_)**e+abs(ly/b_)**e+abs(pz/c_)**e)**(1/e))
    if cover>0.97: problems.append(('block parts: the shoulder shell does not cover the joint',round(cover,3)))
    if rb<1.05*P_['upper_arm']['semi'][0]: problems.append(('block parts: the shoulder ball does not cover the upper arm\'s cut',))
    if sh_['semi'][0]*2>0.15 or sh_['semi'][1]*2>0.13: problems.append(('block parts: the shoulder shell too big',))
_bt_parts_checks()
def _p3():
    from shapely.geometry import LineString, Point, Polygon, box as sbox
    from shapely.ops import unary_union
    MH=MARKET_HOUSE; S_=MH['storey']
    # the kit's own numbers hold together
    for nm,step in (('boom veranda',MH['boom']['veranda']['rail']),('boom balcony',MH['boom']['balcony']['rail']),('tile balcony',MH['tile']['balcony']['rail'])):
        if max(step,S_-step)>MH['holds_max']: problems.append(('market house: holds too far apart up a %s'%nm,))
    if MH['tile']['canopy']['y']>MH['holds_max']+1.5: problems.append(('market house: the canopy beyond a bounce from the street',))
    if MH['sign']['y']<MH['tile']['canopy']['y']+MH['tile']['canopy']['t']+0.3: problems.append(('market house: blade signs foul the canopy',))
    ML=[i for i,k in enumerate(LOT_KITS) if k and k['kit'] in ('tong_lau','lockup')]
    hsh=lambda a,b: (int(abs(a)*2654435761) ^ int(abs(b)*40503)) & 0xffff
    def front_line(r,f):
        x0,z0,x1,z1=r
        return {'n':((x0,z0),(x1,z0)),'s':((x1,z1),(x0,z1)),'w':((x0,z1),(x0,z0)),'e':((x1,z0),(x1,z1))}[f]
    # every house has a front on a street, a square or the Rim Walk
    for i in ML:
        if LOT_KITS[i]['front'] is None or front_of(tuple(int(v) for v in lots[i][:4]))[0] is None: problems.append(('market house: no street to face',i))
    # each house's door: a pair's one shared door straddles the party wall at the front; a house with its own core
    # has its door at one end of its front, the shop filling the rest; a lock-up is all shutter, no house door
    for i in ML:
        k=LOT_KITS[i]; r=tuple(lots[i][:4]); a,b_=front_line(r,k['front']); L_=math.dist(a,b_); ux,uz=(b_[0]-a[0])/L_,(b_[1]-a[1])/L_
        if k['kit']=='lockup': k['door']=None; continue
        if k['core']=='shared':
            j=k['pair']; rj=lots[j][:4]
            if k['front'] in 'ns': px=r[2] if abs(r[2]-rj[0])<0.01 else r[0]; pt=(px,a[1])
            else: pz=r[3] if abs(r[3]-rj[1])<0.01 else r[1]; pt=(a[0],pz)
        else:
            t=MH['door']['w']/2+0.5; t=t if hsh(*a)%2 else L_-t; pt=(a[0]+ux*t,a[1]+uz*t)
        k['door']=(round(pt[0],2),round(pt[1],2))
    for i in ML:
        k=LOT_KITS[i]
        if k.get('core')=='shared' and LOT_KITS[k['pair']]['door']!=k['door']: problems.append(('market house: a core pair without one shared door',i))
        w_,d_=dims(i)
        if k.get('core') in ('shared','own') and d_<MH['core']['l']+MH['core']['room']: problems.append(('market house: too shallow for its ramp core',i))
        if k.get('core')=='shared' and w_<4.0: problems.append(('market house: too narrow for half a core',i))
        if k['kit']=='tong_lau' and w_<6.0 and k.get('core')=='own': problems.append(('market house: under 6 m with a core of its own',i))
    if abs(SMALL_DEPTH-(MH['core']['l']+MH['core']['room']))>0.01: problems.append(('market house: SMALL_DEPTH out of step with MARKET_HOUSE',))
    # blade signs on the lanes: some houses hang one sign out over the lane, never two within 4 m
    lanes={s_[0]:s_ for s_ in STREETS if s_[1]=='lane'}
    blades=[]
    for i in ML:
        k=LOT_KITS[i]
        if k['kit']!='tong_lau' or not k['signs']: continue
        a,b_=front_line(tuple(lots[i][:4]),k['front']); mid=((a[0]+b_[0])/2,(a[1]+b_[1])/2)
        on_lane=any(sbox(*s_[2:]).distance(Point(mid))<0.6 for s_ in lanes.values())
        if on_lane and hsh(*mid)%2==0 and all(math.dist(mid,q)>=4.0 for q in blades): k['blade']=True; blades.append(mid)
        else: k['blade']=False
    # the courts as they really stand: COURTS are the blocks' middles from the first grid layout, drawn before the
    # landmarks; what is open is each one less the buildings and lots on it. Every piece of at least court_min is a
    # court: open to a road, or reached by a covered passage through one house's ground floor (a landmark's own
    # ground is its package's to open); a smaller piece is a light well, built up solid to its lowest neighbour
    streets_=unary_union([sbox(*s_[2:]) for s_ in STREETS]+[sbox(*o_[1:]) for o_ in OPENS])
    solids=[(('bldg',b_['n']),sbox(*b_['r']),HEIGHTS.get(b_['n'],8)) for b_ in named]+[(('lot',i),sbox(*l[:4]),l[4]*STOREY.get(l[5],3.25)) for i,l in enumerate(lots)]
    solid_u=unary_union([g for _,g,_ in solids])
    ways=[]
    for ci,c in enumerate(courts):
        left=sbox(*c).difference(solid_u)
        for g in [q for q in (left.geoms if hasattr(left,'geoms') else [left]) if q.geom_type=='Polygon' and q.area>0.5]:
            pts=[(round(x,2),round(z,2)) for x,z in list(g.exterior.coords)[:-1]]
            nb=[(key,pg,ht) for key,pg,ht in solids if pg.distance(g)<0.3]
            if g.area<TOWER_HOUSE['court_min']:
                ways.append(dict(court=ci,pts=pts,area=round(g.area,1),well=True,fill_to=round(min([ht for _,_,ht in nb] or [S_]),2))); continue
            w=dict(court=ci,pts=pts,area=round(g.area,1))
            if g.exterior.intersection(streets_.buffer(0.6)).length>=MH['passage']['w']: w['open']=True; ways.append(w); continue
            best=None
            for key,lg,ht in nb:
                if key[0]!='lot': continue
                i=key[1]; l=lots[i]; k=LOT_KITS[i]
                if l[4]<2 or (k and k['kit']=='lockup'): continue
                f=(k['front'] if k else None) or front_of(tuple(int(v) for v in l[:4]))[0]
                if not f: continue
                a,b_=front_line(tuple(l[:4]),f); fe=LineString([a,b_])
                wall=g.buffer(0.3).intersection(lg.exterior)
                if wall.length<MH['passage']['w']+1.0: continue
                p0=wall.interpolate(0.5,normalized=True) if wall.geom_type=='LineString' else max(wall.geoms,key=lambda q:q.length).interpolate(0.5,normalized=True)
                p1=fe.interpolate(fe.project(p0)); ln=LineString([p0,p1])
                if ln.buffer(MH['passage']['w']/2,cap_style=2).difference(lg.buffer(0.05)).area>0.3: continue
                door=k.get('door') if k else None
                if door and Point(door).distance(p1)<MH['passage']['w']/2+MH['door']['w']/2+0.3: continue
                if best is None or ln.length<best[0]: best=(ln.length,i,p0,p1)
            if best: w['passage']=dict(lot=best[1],court_end=(round(best[2].x,2),round(best[2].y,2)),road_end=(round(best[3].x,2),round(best[3].y,2)),w=MH['passage']['w'],h=MH['passage']['h'])
            else:
                own=[key[1] for key,_,_ in nb if key[0]=='bldg']
                if own: w['within']=own
                else: problems.append(('a court with no way in',c,round(g.area)))
            ways.append(w)
    # Arcade Street's roof: the full width of the street from Market Street to the Rim Walk, square-ended clear of it
    asx=[s_ for s_ in STREETS if s_[0]=='Arcade Street'][0]; ms=[s_ for s_ in STREETS if s_[0]=='Market Street'][0]
    x0,x1=asx[2],asx[4]; z0=ms[5]
    z1=min(math.sqrt(197.0**2-(x-CX)**2) for x in (x0,x1))-MH['arcade']['end_clear']
    n_=max(2,round((z1-z0)/MH['arcade']['arch_every'])); arches=[round(z0+(z1-z0)*t/n_,2) for t in range(n_+1)]
    ARC=dict(x=(x0,x1),z=(round(z0,2),round(z1,2)),h=MH['arcade']['h'],arches=arches)
    roof=sbox(x0,z0,x1,z1)
    for b_ in named:
        if sbox(*b_['r']).intersection(roof).area>0.01: problems.append(('arcade roof over a building',b_['n']))
    for l in lots:
        if sbox(*l[:4]).intersection(roof).area>0.01: problems.append(('arcade roof over a lot',l[:4]))
    for run in DECK['runs']:
        if LineString(run['pts']).buffer(run['w']/2).intersects(roof): problems.append(('arcade roof under the Deck',run['name']))
    # Lamp Lane: lantern strings across it wherever both sides are built, and the night market's stalls, one side at a
    # time, never in front of a door and always leaving walk_min clear
    LL=[s_ for s_ in STREETS if s_[0]=='Lamp Lane'][0]; lz0,lz1=LL[3],LL[5]; zc=(lz0+lz1)/2; LP=MH['lamp']
    lim=math.sqrt(197.0**2-(zc)**2); lx0,lx1=max(LL[2],CX-lim+2),min(LL[4],CX+lim-2)
    side_n=[(sbox(*l[:4]),l[4]) for l in lots if abs(l[3]-lz0)<0.01]+[(sbox(*b_['r']),HEIGHTS.get(b_['n'],8)) for b_ in named if abs(b_['r'][3]-lz0)<0.01]
    side_s=[(sbox(*l[:4]),l[4]) for l in lots if abs(l[1]-lz1)<0.01]+[(sbox(*b_['r']),HEIGHTS.get(b_['n'],8)) for b_ in named if abs(b_['r'][1]-lz1)<0.01]
    built_at=lambda side,x,z: any(g.distance(Point(x,z))<0.2 for g,_ in side)
    lanterns=[]; x=lx0+LP['lantern_every']/2
    while x<lx1:
        if built_at(side_n,x,lz0) and built_at(side_s,x,lz1): lanterns.append(round(x,2))
        x+=LP['lantern_every']
    doors=[LOT_KITS[i]['door'] for i in ML if LOT_KITS[i].get('door')]
    for n_,k_ in BUILDING_KITS.items():
        if k_.get('kit')=='shop':
            b_=[x_ for x_ in named if x_['n']==n_][0]['r']; a_,e_=front_line(b_,k_['front'])
            # a shop's whole front is its window and its entrance: no stall stands before it
            L_=math.dist(a_,e_)
            for t_ in range(int(L_)+1): doors.append((a_[0]+(e_[0]-a_[0])*t_/L_,a_[1]+(e_[1]-a_[1])*t_/L_))
    hm=BUILDING_KITS[38]; hb=[x_ for x_ in named if x_['n']==38][0]['r']
    if hm['shop_floor']['depth']+3.0>hb[3]-hb[1]: problems.append(('the Helmsmith: no room for the workshop behind the shop floor',))
    if hm['shop_floor']['entrance']>hb[2]-hb[0]-2.0: problems.append(('the Helmsmith: the entrance leaves no shopfront',))
    stalls=[]; x=lx0+LP['stall']['w']/2+1.0; sd=0
    while x<lx1-LP['stall']['w']/2:
        for side in ((sd,1-sd)):
            zf=lz0 if side==0 else lz1; ok_=built_at(side_n if side==0 else side_s,x,zf)
            near_door=any(abs(d_[1]-zf)<0.5 and abs(d_[0]-x)<LP['stall']['w']/2+LP['door_clear'] for d_ in doors)
            if ok_ and not near_door:
                zc_=zf+(LP['stall']['d']/2 if side==0 else -LP['stall']['d']/2)
                stalls.append(dict(c=(round(x,2),round(zc_,2)),side='n' if side==0 else 's')); sd=1-sd; break
        x+=LP['stall_every']
    if (lz1-lz0)-LP['stall']['d']<LP['walk_min']: problems.append(('Lamp Lane: a stall leaves too narrow a walk',))
    for a_ in stalls:
        for b2 in stalls:
            if a_ is not b2 and abs(a_['c'][0]-b2['c'][0])<LP['stall']['w'] and a_['side']!=b2['side']: problems.append(('Lamp Lane: stalls face each other across it',a_['c']))
    globals().update(ARCADE_ROOF=ARC,LAMP_LANE=dict(x=(round(lx0,2),round(lx1,2)),z=(lz0,lz1),lanterns=lanterns,lantern_y=LP['lantern_y'],stalls=stalls,stall=LP['stall']),COURT_WAYS=ways)
_p3()
# ---- P5: the North Estate kit (2026-10-19). Existing sites and heights are locked.
ESTATE['kit'] = dict(
    version=2, buildings=[17,18,19,20,21,22,49,50,53],
    civic=[23,51], datum=-60.0, storey=3.25, void_clear=3.01,
    slab=0.24, wall=0.16, gallery=1.8, guard=1.2, bay=3.2,
    column=0.55, column_pitch=6.4, door=(1.5,2.4), landing=2.0,
    lift=dict(shaft=(2.8,3.2),cabin=(2.0,2.4),door=(1.5,2.4)),
    bridge=dict(floor=84.5,width=2.0,guard=1.2,roof=87.5),
    link=dict(top=3.0,width=3.2,slab=0.24,post=0.18,pitch=6.4),
    roof=dict(guard=1.2,headroom=2.4),
    centre=dict(public_floor=0.0,upper_floor=3.25,garden_floor=6.5,roof_top=8.0),
    hawker=dict(floor=0.0,eave=4.5,roof_top=6.0,aisle=2.0),
    palette=dict(wall='#fff0d4',frame='#fff5dd',accent='#298f89',panel='#efb83f',roof='#537c7d',glass='#304f64'),
    facade=dict(recess=0.24,frame_t=0.28,frame_depth=0.18,group_storeys=4,
                panel_fraction=0.38,panel_height_fraction=0.86,mark_fraction=0.62,mark_stroke_fraction=0.24,
                entrance_w=4.4,entrance_h=3.01,entrance_t=0.24,entrance_depth=0.24,
                profile_exponent=5.5,motif_exponent=3.0,sunshade_depth=0.18),
    identities=[
      dict(n=17,primary='#268f88',secondary='#ee795f',motif='circle',frame='grouped',family='jade circle'),
      dict(n=18,primary='#ee795f',secondary='#edbb43',motif='steps',frame='grouped',family='coral steps'),
      dict(n=19,primary='#268f88',secondary='#edbb43',motif='arch',frame='grouped',family='jade arch'),
      dict(n=20,primary='#ee795f',secondary='#268f88',motif='arch',frame='hero',family='coral twin'),
      dict(n=21,primary='#305ba4',secondary='#268f88',motif='arch',frame='hero',family='cobalt twin'),
      dict(n=22,primary='#edbb43',secondary='#268f88',motif='arch',frame='repeated',family='sunflower portals'),
      dict(n=49,primary='#268f88',secondary='#edbb43',motif='arch',frame='repeated',family='jade portals'),
      dict(n=50,primary='#305ba4',secondary='#ee795f',motif='steps',frame='grouped',family='cobalt steps'),
      dict(n=53,primary='#edbb43',secondary='#268f88',motif='circle',frame='grouped',family='sunflower circle')],
    printed_marks=False,
    blocks=[
      dict(n=n,storeys=storeys,court=court,kind=kind,
           court_point=(-628,-146) if court=='west' else (-520,-154))
      for n,storeys,court,kind in [
        (17,28,'west','slab'),(18,32,'east','slab'),(19,36,'east','point'),
        (20,40,'west','point'),(21,40,'west','point'),(22,14,'west','slab'),
        (49,16,'west','slab'),(50,34,'east','slab'),(53,24,'west','slab')]],
    scope='public void decks, court-facing galleries, lifts to every gallery and roof; flats sealed; hawker fit-out P13f',
)
EK=ESTATE['kit']
# W,D are each existing building's local dimensions, H its recorded roof height.
# Repetition endpoints are fitted inside the locked envelope, not added outside it.
EP=[]
def ep(id,what,shape,semi,col,role,**kw):
    row=dict(id=id,what=what,shape=shape,semi=semi,col=col,role=role)
    if shape in ('egg','clipped'): row['eps']=(5.5,5.5)
    if shape=='box': row['reason']='flush structural infill or floor; no rounded seam at a bearing'
    row.update(kw); EP.append(row)
ep('footing','embedded structural foundation on surveyed terrain','box',('W/2',0.25,'D/2'),'solid','floor')
ep('void_column','columns inside the footprint on fitted structural bays','clipped',(0.275,1.505,0.275),'solid','post',join='column_bearing')
ep('void_soffit','first slab top at +3.25, underside +3.01','box',('W/2',0.12,'D/2'),'solid','floor')
ep('floor','upper floor infill excluding lift shaft','box',('W/2',0.12,'D/2'),'landing','floor')
ep('outer_wall','single wall with punched superellipse windows','wall',('face/2','storey_clear/2',0.08),'solid','wall',outline='window_seat')
ep('window','sealed flat window cutter and its fitted dark glazing','egg',(0.65,0.85,0.04),'solid','window')
ep('window_sill','clipped sill seated on its window surround','clipped',(0.75,0.06,0.12),'solid','beam',join='window_seat')
ep('window_trim','superellipse frame around the same aperture','egg',(0.75,0.95,0.06),'decorative','trim')
ep('gallery_floor','court-side gallery within the footprint','box',('face/2',0.12,0.9),'landing','floor')
ep('gallery_guard','continuous solid guard with explicit route openings','clipped',('run/2',0.6,0.08),'solid','rail',join='guard_openings')
ep('gallery_post','square-ended post at guard ends and bays','clipped',(0.08,0.6,0.08),'solid','post',join='guard_openings')
ep('flat_door','sealed door on gallery wall; private flats unbuilt','clipped',(0.75,1.2,0.08),'solid','door',join='door_threshold')
ep('door_trim','piped superellipse door surround','egg',(0.85,1.3,0.08),'decorative','trim')
ep('lift_wall','shaft enclosure with punched floor doors','wall',(1.4,'shaft_height/2',1.6),'solid','wall',outline='door_threshold')
ep('lift_cabin','moving enclosed cabin with real floor and guards','box',(1.0,1.2,1.2),'solid','body')
ep('lift_landing','level landing outside shaft, route through guard','box',(1.0,0.12,1.0),'landing','floor')
ep('roof_floor','roof slab within existing roof height','box',('W/2',0.12,'D/2'),'landing','floor')
ep('roof_guard','roof edge guard, open only at authored routes','clipped',('run/2',0.6,0.08),'solid','rail',join='guard_openings')
ep('bridge_floor','existing bridge polygon, walking top +84.5','box',('span/2',0.12,1.0),'landing','floor')
ep('bridge_guard','two side guards, no rail across either end','clipped',('span/2',0.6,0.08),'solid','rail',join='bridge_landings')
ep('bridge_canopy','square-ended superellipse canopy clipped to landings','clipped',('span/2',0.12,1.0),'solid','roof',join='bridge_landings')
ep('link_post','linkway posts outside 1.5 m clear walking strip','clipped',(0.09,1.38,0.09),'solid','post',join='link_bearing')
ep('link_roof','walkable clipped SuperEgg slab along each polyline segment','clipped',('segment/2',0.12,1.6),'landing','roof',join='link_corners')
ep('bench','softened square-ended seat','egg',(1.1,0.09,0.28),'solid','seat')
ep('bench_leg','seat supports','egg',(0.09,0.2,0.2),'solid','post')
ep('chess_table','table outside through routes','egg',(0.45,0.06,0.45),'solid','table')
ep('chess_base','single table pedestal','egg',(0.14,0.36,0.14),'solid','post')
ep('mailbox','grouped letterboxes beside lift without blocking lobby','egg',(0.6,0.45,0.18),'solid','body')
ep('planter','bounded planting bed on court/garden edges','egg',(1.0,0.3,0.5),'solid','body')
ep('pavilion_post','pavilion column at existing centre point','clipped',(0.16,1.38,0.16),'solid','post',join='link_bearing')
ep('pavilion_roof','squarish clipped canopy over pavilion, radius 3.2','clipped',(3.2,0.16,3.2),'landing','roof',join='link_bearing')
ep('hawker_column','open-sided hall columns','clipped',(0.275,2.25,0.275),'solid','post',join='civic_roof')
ep('hawker_roof','shallow vented roof within 6 m envelope','clipped',('W/2',0.75,'D/2'),'solid','roof',join='civic_roof')
ep('centre_wall','centre walls with real public entry openings','wall',('face/2','storey_clear/2',0.08),'solid','wall',outline='door_threshold')
ep('laundry_pole','paired slender laundry rods on outward faces','egg',(0.025,0.025,0.7),'decorative','trim')
ep('identity_motif','unlettered arch, circle or stepped colour motif, repeated at entry; no numerals','decal',('panel_w/2','panel_h/2',0.001),'decorative','mark')
ep('facade_frame','constant-section cream superellipse frame grouping four storeys; backing recessed inside existing footprint','profile',('bay_span/2','group_h/2',0.09),'solid','frame',n=5.5,join='facade_recess')
ep('entrance_frame','open-bottom U portal with broad rounded crown and flat feet; same colour and motif as block','profile',(2.2,1.505,0.12),'solid','frame',n=5.5,join='portal_bearing')
ep('sunshade','square-ended clipped sunshade inside original envelope','clipped',('bay_span/2',0.10,0.09),'solid','beam',join='facade_recess')
EJ=[
 dict(id='column_bearing',kind='seated',parts=['void_column','void_soffit','footing'],plane='footing top 0, column top 3.01, slab underside 3.01',rule='clip column ends to the shared bearing planes; no rounding gap'),
 dict(id='floor_wall',kind='meet',parts=['floor','outer_wall','gallery_floor'],plane='shared floor perimeter and gallery inner edge',rule='private sealed volume ends at gallery wall; one floor collider owns each surface'),
 dict(id='window_seat',kind='punched',parts=['outer_wall','window','window_sill','window_trim'],plane='same superellipse aperture through wall',rule='derive glazing and trim from one cutter, sill clipped at the wall surface'),
 dict(id='door_threshold',kind='punched',parts=['flat_door','door_trim','lift_wall','lift_landing'],plane='door foot equals landing top',rule='lift doors open a real shaft aperture; private doors remain sealed; no below-floor round lip'),
 dict(id='guard_openings',kind='chain',parts=['gallery_guard','gallery_post','roof_guard'],plane='route opening side planes at each lift/bridge',rule='end and cap guards at clear opening; no railing across a public route'),
 dict(id='bridge_landings',kind='chain',parts=['bridge_floor','bridge_guard','bridge_canopy','lift_landing'],plane='bridge top and both gallery landings at +84.5',rule='derive in-footprint landing tongues to meet existing bridge ends; one continuous walk surface, no overlapping colliders'),
 dict(id='link_bearing',kind='seated',parts=['link_post','link_roof','pavilion_post','pavilion_roof'],plane='roof underside and column top coincide',rule='clip feet to surveyed ground and heads to underside; roof top +3.0 for links'),
 dict(id='link_corners',kind='chain',parts=['link_roof'],plane='angle bisector at every polyline vertex',rule='miter and cap both ends at shared plane and top +3.0; no intersecting double slabs'),
 dict(id='civic_roof',kind='seated',parts=['hawker_column','hawker_roof','centre_wall','roof_floor'],plane='hawker eave +4.5 and roof top +6; centre garden +6.5',rule='support bearing lines continuously, no bowl under roof; roof garden connects existing Deck bridge at its datum'),
 dict(id='furniture_bearing',kind='seated',parts=['bench','bench_leg','chess_table','chess_base','mailbox','planter'],plane='ground or floor top',rule='supports meet seats/table; keep furniture out of route and door-clearance boxes'),
]
EJ += [
 dict(id='facade_recess',kind='seated',parts=['outer_wall','facade_frame','sunshade','identity_motif'],plane='original footprint face; backing recessed 0.24 m, relief depth at most 0.18 m',rule='all relief remains within existing envelope; cut window apertures and relief from coordinated profiles, not overlays blocking windows or galleries'),
 dict(id='portal_bearing',kind='seated',parts=['entrance_frame','footing','void_soffit','identity_motif'],plane='portal feet at ground 0, crown at +3.01, bearing at first-slab underside',rule='flat capped feet and full-profile crown; open-bottom clear path with no crossbar at threshold; mark stays pictorial, never letters/numbers')]
EK['parts']=EP; EK['joins']=EJ
parts_checks('North Estate',EP,EJ)
if set(EK['buildings']) != {x['n'] for x in B if x['kind']=='estate'}:
    problems.append(('P5: estate block coverage differs',))
for row in EK['blocks']:
    if abs(HEIGHTS[row['n']] - row['storeys']*EK['storey']) > 0.6:
        problems.append(('P5: height/storey mismatch',row['n']))
    if HEIGHTS[row['n']]-(row['storeys']-1)*EK['storey']-EK['slab'] < EK['roof']['headroom']:
        problems.append(('P5: top gallery lacks headroom',row['n']))
if {i['n'] for i in EK['identities']} != set(EK['buildings']) or len(EK['identities']) != 9:
    problems.append(('P5: colour identity coverage differs',))
if len({(i['primary'],i['motif'],i['frame']) for i in EK['identities']}) != 9:
    problems.append(('P5: block identities are not distinct',))
for ident in EK['identities']:
    if ident['motif'] not in ('arch','circle','steps'):
        problems.append(('P5: unsupported identity shape',ident['n']))
if EK['printed_marks'] or EK['facade']['frame_depth'] > EK['facade']['recess']:
    problems.append(('P5: printed marks or facade outside locked envelope',))
if EK['facade']['entrance_h'] - EK['facade']['entrance_t'] < 2.4:
    problems.append(('P5: entrance frame lacks clearance',))
if EK['gallery'] < 1.5 or EK['link']['top']-EK['link']['slab'] < 2.4:
    problems.append(('P5: public clearance too small',))
if EK['bridge']['floor'] != 26*EK['storey'] or EK['centre']['garden_floor'] != 2*EK['storey']:
    problems.append(('P5: sky bridge/Deck datum mismatch',))


# ---- P6: Downtown. Geometry schedules only; no locked layout changes.
DOWNTOWN=dict(version=2,datum=-60.0,printed_marks=False,
    towers=[12,14,15],storey=3.6,podium=6.5,slab=0.24,wall=0.24,
    bay=3.6,recess=0.6,guard=1.2,path=2.0,door=(2.4,2.8),
    palette=dict(stone='#eee2c7',glass='#47767e',shadow='#354c55',
        terracotta='#c56849',jade='#278b81',coral='#ed8269',gold='#d8ac45',
        cobalt='#426ca7',leaf='#748c52',ground='#c3b69b',
        aluminium='#aeb7bd',champagne_metal='#b6b0a4',graphite='#626c73',
        glass_smoke='#63717a',glass_bluegrey='#718591',glass_silver='#889397',
        midrise_stone='#c1c2bd',midrise_shadow='#47525b'),
    wind=dict(top=262.0,crown=280.0,turn=90.0,radius=13.8,corner=0.2,
        storey=3.6,gaps=[72.0,144.0,216.0],gap_h=7.2,transfer=3.6,
        core=(4.0,6.0),column=1.2,deck=258.4,stops=[0.0,6.5,258.4],
        cabin=(2.0,2.4),shaft=(2.8,3.2),rotor_z=-7.5,rotor_sweep=4.0,fin=(0.24,0.6),fin_every=3,fin_material='aluminium',crown_material='aluminium',
        crown_frame=dict(base=262.0,mid=268.0,top=274.0,scales=[1.0,0.85,0.7],ring_samples=36,posts=9,
            mast_top=280.0,rotor_y=276.6,rotor_radius=1.5,rotor_height=4.4,rotor_x=0.0,rotor_z=0.0)),
    north=dict(top=175.0,storeys=45,storey=175.0/45,core=(6.0,8.0),
        start=2*175.0/45,garden=(22*175.0/45,24*175.0/45),
        side_mode='alternating_opposite_faces',capsule_w=6.4,capsule_d=[6.0,7.5,9.0],capsule_h=3.5,
        stops=[0.0,22*175.0/45],cabin=(2.0,2.4),shaft=(2.8,3.2)),
    south=dict(top=150.0,storeys=40,storey=3.75,colonnade=7.5,
        core=(6.0,8.0),column=1.4,grid=[-8,-8/3,8/3,8],inner=20.0,outer=26.0,balcony_min=1.5,ripple=1.4,
        terraces=[142.5,146.25,150.0],terrace_inner=[17.0,14.0],pergola_top=3.6,screen_material='champagne_metal',pergola_material='aluminium'),
    site=dict(post=0.24,canopy_top=3.6,bench=(2.2,0.48,0.6),planter=(2.0,0.6,1.2)))
DK=DOWNTOWN
DK['owners']=[]
for i,l in enumerate(lots):
    if l[5]!='midrise': continue
    w_,d_=l[2]-l[0],l[3]-l[1]
    DK['owners'].append(dict(lot=i,rect=l[:4],storeys=l[4],height=l[4]*STOREY['midrise'],
        bays=[max(1,int(w_/DK['bay'])),max(1,int(d_/DK['bay']))],
        variant=('pier','paired','recess')[i%3],accent=('aluminium','champagne_metal','graphite')[i%3],
        passage=next((cw['passage'] for cw in COURT_WAYS if cw.get('passage',{}).get('lot')==i),None)))
# User-authorized P6 site/massing change: LOTS remain stable source IDs for
# cross-package references; sites replace their 23 independent tall owners.
DK['structure']=dict(pier=1.4,core=(6.0,8.0),small_core=(4.0,6.0),
    girder_depth=1.2,girder_width=0.8,wall=0.4,min_shaft=12.0,min_gap=8.0)
DK['sites']=[]
_specs=[
 ('north_garden',[110,114],(-480,-166,-466,-145),86.4),
 ('capsule_neighbours',[111,112,113],(-439,-119,-410,-105),93.6),
 ('wind_garden_edge',[115,116],(-425,-95,-394,-83),93.6),
 ('east_pavilion',[117,118],(-385.5,-55,-373.5,-41),57.6),
 ('block_approach',[119,120],(-443,38,-413,58),122.4),
 ('court_east',[121,122,127],(-405,41,-376,55),86.4),
 ('market_west',[123,124],(-479,81,-441,95),108.0),
 ('market_east',[125,126],(-433,81,-394,95),108.0),
 ('south_garden_edge',[128,129,130],(-439,105,-410,119),108.0),
 ('south_garden',[131,132],(-480,145,-466,166),86.4)]
from shapely.geometry import box as _p6box
from shapely.ops import unary_union as _p6union
for site_id,ids,shaft,height in _specs:
    land=_p6union([_p6box(*lots[i][:4]) for i in ids])
    if land.geom_type!='Polygon': problems.append(('P6: merged site disconnected',site_id))
    w_,d_=shaft[2]-shaft[0],shaft[3]-shaft[1]
    core=DK['structure']['small_core'] if min(w_,d_)<14 else DK['structure']['core']
    DK['sites'].append(dict(id=site_id,sources=ids,podium=list(land.exterior.coords)[:-1],
        shaft=shaft,height=height,storeys=round(height/3.6),core=core,
        bays=[max(1,int(w_/DK['bay'])),max(1,int(d_/DK['bay']))],
        variant=('pier','paired','recess')[ids[0]%3],accent=('aluminium','champagne_metal','graphite')[ids[0]%3],
        glass=('glass_smoke','glass_bluegrey','glass_silver')[ids[0]%3],
        passage=next((o['passage'] for o in DK['owners'] if o['lot'] in ids and o['passage']),None)))
DK['source_role']='provenance only; replace old midrise geometry once per site, not once per source lot'
for st in DK['sites']:
    sh=_p6box(*st['shaft'])
    from shapely.geometry import Point as _p6point
    st['terrace_planters']=[((lots[i][0]+lots[i][2])/2,(lots[i][1]+lots[i][3])/2) for i in st['sources'] if sh.distance(_p6point((lots[i][0]+lots[i][2])/2,(lots[i][1]+lots[i][3])/2))>=3.0]

for st in DK['sites']:
    r=st['shaft'];w_,d_=r[2]-r[0],r[3]-r[1];cw,cd=st['core']
    nx,nz=math.ceil((w_-2)/7.2),math.ceil((d_-2)/7.2)
    xs=[round(-w_/2+1+i*(w_-2)/nx,4) for i in range(nx+1)]
    zs=[round(-d_/2+1+i*(d_-2)/nz,4) for i in range(nz+1)]
    if st['id']=='block_approach': xs=[-14,-10,-6,0,7,14]
    st['grid']=dict(x=xs,z=zs,max_span=7.2)
    st['piers']=[(x,z) for x in xs for z in zs if not(abs(x)<cw/2+0.7 and abs(z)<cd/2+0.7)]

DP=[];DJ=[]
def dp(id,where,shape,semi,col,role='mass',**kw):
    row=dict(id=id,where=where,shape=shape,semi=semi,col=col,role=role)
    if shape in ('egg','clipped'): row['eps']=(5.5,5.5)
    if shape=='profile': row['n']=5.5
    if shape=='box': row['reason']='flush floor or sealed interior infill; rounded seams would leave cracks'
    row.update(kw); DP.append(row)
dp('foundation','surveyed footing below ground; at least 0.5 embed','box',('W/2',0.25,'D/2'),'solid','floor')
dp('podium_column','secondary podium canopy support only, not the skyscraper load path','clipped',(0.7,3.13,0.7),'solid','post',join='podium_bearing')
dp('podium_floor','roof/deck slab top +6.5; through-route voids cut out','box',('W/2',0.12,'D/2'),'landing','floor')
dp('private_mass','sealed above podium, recessed facade bays; passages subtracted','box',('innerW/2','privateH/2','innerD/2'),'solid')
dp('bay_pier','between recessed facade bays, within footprint','clipped',(0.18,'clearH/2',0.3),'solid','post',join='bay_frame')
dp('bay_head','bay head/shade, outer face inside footprint','clipped',('bay/2',0.12,0.3),'solid','beam',join='bay_frame')
dp('window_wall','punched wall; single cutter drives opening and glazing','wall',('bay/2','clearH/2',0.12),'solid','wall',outline='glazing_seat')
dp('glazing','sealed superellipse glazing derived from window cutter','egg',('windowW/2',1.2,0.04),'solid','window')
dp('window_trim','superellipse ring, not a solid plaque','profile',('windowW/2+0.08',1.28,0.06),'decorative')
dp('portal','rounded-head entrance frame with square feet; 2.4 x 2.8 clear','profile',(1.44,1.64,0.18),'solid')
dp('guard','clipped parapets with real route openings','clipped',('run/2',0.6,0.1),'solid','rail',join='guard_chain')
dp('roof_cap','roof/parapet head; no unsupported crown stuck on a box','clipped',('run/2',0.12,0.24),'solid','beam',join='guard_chain')
dp('passage_wall','owner walls split around indexed court passage','wall',('run/2',1.5,0.12),'solid','wall',outline='passage_cut')
dp('tower_floor','slab trimmed to level profile minus public voids and shaft','profile',('profileW/2',0.12,'profileD/2'),'landing')
dp('wind_skin','rounded triangle profile twisted at sampled levels; gaps omitted','profile',(13.8,'bandH/2',13.8),'solid')
dp('wind_core','continuous core; public lift apertures cut at stops','wall',(2.0,131.0,3.0),'solid','wall',outline='lift_opening')
dp('mega_column','three continuous sampled corner lines through gaps','clipped',(0.6,'segmentL/2',0.6),'solid','post',join='wind_structure')
dp('transfer_beam','triangular transfer bands above/below each gap','clipped',('segmentL/2',0.3,0.3),'solid','beam',join='wind_structure')
dp('transfer_diagonal','corner-to-core bracing in transfer band, clear of west-east slot','clipped',(0.24,'segmentL/2',0.24),'solid','beam',join='wind_structure')
dp('wind_fin','brushed aluminium fin following twist; 0.24 x 0.6 section','clipped',(0.12,'segmentL/2',0.3),'solid','beam',join='fin_chain')
dp('turbine_hub','one visible rotor hub per wind gap plus crown rotor','egg',(0.55,0.55,0.55),'solid',eps=(2.0,2.0))
dp('turbine_blade','rounded rotor blade in gap with swept clearance','egg',(0.18,2.2,0.3),'solid',eps=(3.0,3.0))
dp('crown_post','connected crown frame seated at shaft top +262, tied at +268/+274; central mast to +280','clipped',(0.15,'L/2',0.15),'solid','post',join='crown_bearing',mast_semi=(0.225,'L/2',0.225))
dp('crown_ring','closed perimeter ties at crown base/mid/top, same profile as supports','clipped',('segmentL/2',0.2,0.2),'solid','beam',join='crown_bearing')
dp('crown_brace','diagonal lattice braces between adjacent frame nodes','clipped',(0.12,'segmentL/2',0.12),'solid','beam',join='crown_bearing')
dp('rotor_arm','radial supports at upper/lower blade bearings on centred vertical axis','clipped',(0.09,'segmentL/2',0.09),'solid','beam',join='crown_rotor')
dp('north_core','continuous core above open ground; lift and entry apertures','wall',(3.0,87.5,4.0),'solid','wall',outline='lift_opening')
dp('capsule_shell','ceramic superellipse shell, recessed sealed studio glazing','egg',(3.2,1.75,'depth/2'),'solid')
dp('capsule_socket','flat clipped bracket seated between core and capsule','clipped',(0.24,0.3,'L/2'),'solid','beam',join='capsule_seat')
dp('garden_column','garden supports at the core corners, no floating upper capsules','clipped',(0.3,'gardenH/2',0.3),'solid','post',join='garden_bearing')
dp('south_skin','recessed sealed pale facade within 20 m square','wall',(10.0,'housingH/2',10.0),'solid','wall',outline='glazing_seat')
dp('dune_slab','superellipse balcony profile with sampled smooth ripple, bounded by shaft','profile',(13.0,0.12,13.0),'landing')
dp('dune_screen','rounded shade panels behind balcony clear route','clipped',(0.1,1.2,0.6),'solid','post',join='balcony_seat')
dp('colonnade_post','south primary piers continuous through colonnade and upper frame','clipped',(0.7,'southH/2',0.7),'solid','post',join='load_path')
dp('lift_wall','shared lift enclosure with real landing openings','wall',('shaftW/2','rise/2',0.12),'solid','wall',outline='lift_opening')
dp('lift_car','shared cabin, usable by hero and Xiao; clear 2 x 2.4','box',(1.0,1.4,1.2),'landing')
dp('lift_door','shared sliding door leaves, open at served stop','clipped',(0.6,1.4,0.06),'solid','leaf',join='lift_opening')
dp('site_post','pergola/lobby hall posts on recorded site','clipped',(0.12,'(roofTop-0.24)/2',0.12),'solid','post',join='site_bearing')
dp('site_beam','pergola/pavilion roof bearing members','clipped',('L/2',0.12,0.12),'solid','beam',join='site_bearing')
dp('site_roof','pavilion roofs at Deck datum; pergola lattice at +3.6','profile',('W/2',0.12,'D/2'),'landing')
dp('bench_seat','site seating outside circulation clearances','egg',(1.1,0.09,0.3),'solid',eps=(3.0,3.0))
dp('bench_leg','bench supports with flat feet','clipped',(0.12,0.195,0.24),'solid','post',join='furniture_bearing')
dp('planter','physical raised planter with planted soil, not route blocker','egg',(1.0,0.3,0.6),'solid')
dp('plant','shared NatureProps vegetation; substantial trunk physical','egg',('shared_radius','shared_height/2','shared_radius'),'solid',eps=(3.0,3.0))
dp('identity_inlay','unlettered entrance colour/shape inlay, flush decorative finish','decal',(0.4,0.4,0.002),'decorative')
def dj(id,kind,parts,plane,rule): DJ.append(dict(id=id,kind=kind,parts=parts,plane=plane,rule=rule))
dj('podium_bearing','seated',['foundation','podium_column','podium_floor'],'midrise +6.26; south +7.26','feet cap at ground; heads cap at slab underside; sizes derive from owner height')
dj('bay_frame','meet',['bay_pier','bay_head','private_mass'],'bay jamb/head shared planes within original footprint','one fitted bay grid; cap heads and piers; sealed backing recessed 0.6')
dj('glazing_seat','punched',['window_wall','glazing','window_trim','south_skin'],'same superellipse cutter at outer wall','glazing is cutter intersected with shell; no painted fake opening')
dj('passage_cut','punched',['passage_wall','private_mass','foundation','portal'],'COURT_WAYS passage width/height, ground threshold','subtract passage from every overlapping owner solid and foundation; cap reveals')
dj('guard_chain','chain',['guard','roof_cap','tower_floor'],'landing edges and route openings','continuous 1.2 guard; miter corners; cut guards at doors and landings')
dj('wind_structure','chain',['mega_column','transfer_beam','transfer_diagonal','wind_core','wind_skin'],'sampled shared corner/core planes at gap and transfer levels','columns remain continuous; transfer bands 3.6 deep outside the 7.2 clear slot')
dj('fin_chain','chain',['wind_fin','wind_skin'],'twist profile samples, omitted inside open gap','segments share cuts and end caps; no tapered pole ends or isolated rods')
dj('crown_bearing','seated',['crown_post','crown_ring','crown_brace','tower_floor'],'observation +258.4; frame bearing +262, ties +268/+274; mast +280','posts and braces meet closed ties on shared nodes; frame rooted in shaft roof, no disconnected struts')
dj('crown_rotor','seated',['crown_post','rotor_arm','turbine_hub','turbine_blade'],'axis x=z=0; rotor centre +276.6; blade ends +274.4/+278.8','vertical-axis assembly is separate from wind-gap rotors; arms join each blade at both ends; swept volume clear above frame +274')
dj('capsule_seat','seated',['capsule_shell','capsule_socket','north_core'],'capsule inner bearing plane against core','socket caps meet core and shell; capsule roof remains landable; no duplicate collision overlap')
dj('garden_bearing','seated',['garden_column','north_core','tower_floor','capsule_socket'],'north garden floor 22 storeys, soffit 24 storeys minus slab','continuous core and four columns carry upper capsules; clear public garden and lift landing')
dj('balcony_seat','meet',['dune_slab','south_skin','dune_screen','guard'],'south slab top at each 3.75 m level, min clear balcony 1.5','one slab owns surface; guard follows outer profile; screen stays behind circulation')
dj('lift_opening','punched',['lift_wall','lift_car','lift_door','wind_core','north_core','tower_floor'],'served stop top = car floor = landing top','cut shaft from slabs; stop doors and guards clear actual entry; no lift doors on unserved private floors')
dj('site_bearing','seated',['site_post','site_beam','site_roof'],'pergola top +3.6; pavilion/bridge top +6.5','posts cap at roof underside; glass bridge meets existing hotel threshold; all within recorded site')
dj('furniture_bearing','seated',['bench_leg','bench_seat','planter','plant'],'ground 0; bench top +0.48','legs meet seat underside; planting rooted; no object in door clearances')
dp('south_core','continuous 6 x 8 m south core from foundation to roof','wall',(3.0,75.0,4.0),'solid','wall',outline='core_entry')
dp('midrise_core','continuous core from foundation to roof; plain sealed service enclosure','wall',('coreW/2','height/2','coreD/2'),'solid','wall',outline='core_entry')
dp('load_pier','1.4 m primary piers aligned with shaft corners, continuous through podium','clipped',(0.7,'height/2',0.7),'solid','post',join='load_path')
dp('transfer_girder','0.8 x 1.2 deep perimeter and cross girders below podium slab','clipped',('span/2',0.6,0.4),'solid','beam',join='load_path')
dp('podium_wall','0.4 m inhabited podium enclosure with coordinated public openings','wall',('run/2',3.13,0.2),'solid','wall',outline='core_entry')
dj('load_path','seated',['foundation','midrise_core','south_core','colonnade_post','load_pier','transfer_girder','podium_floor','private_mass'],'foundation 0; midrise girder bottom +5.06/top +6.26, slab +6.5; south girder +6.06 to +7.26, slab +7.5','continuous core and aligned piers carry shaft; girder caps meet piers; no entire tower perched on facade mullions')
dj('core_entry','punched',['midrise_core','podium_wall','portal'],'ground threshold 0; entry clear 2.4 x 2.8','single cutter coordinates reveals and glass; keep court-8 passage clear, including core and girders')
DK['parts']=DP; DK['joins']=DJ
parts_checks('Downtown',DP,DJ)
if len(DK['owners'])!=len([l for l in lots if l[5]=='midrise']): problems.append(('P6: owner coverage',))
if DK['printed_marks'] or DK['podium']!=DECK['level']: problems.append(('P6: marks or Deck mismatch',))
for o in DK['owners']:
    if o['height']!=lots[o['lot']][4]*STOREY['midrise'] or min(o['bays'])<1: problems.append(('P6: owner dimensions',o['lot']))
    if min(o['rect'][2]-o['rect'][0],o['rect'][3]-o['rect'][1])<2*DK['recess']+1.5: problems.append(('P6: infill too narrow',o['lot']))
for n,key in [(12,'wind'),(14,'north'),(15,'south')]:
    if DK[key]['top']!=HEIGHTS[n]: problems.append(('P6: tower height',n))
if DK['wind']['crown']!=CROWNS[12] or DK['wind']['radius']*2>28: problems.append(('P6: Windspire envelope',))
if DK['south']['outer']!=26 or (DK['south']['outer']-DK['south']['inner'])/2-DK['south']['ripple']<DK['south']['balcony_min']: problems.append(('P6: dune balcony clearance',))
for y in DK['wind']['gaps']:
    if not DK['wind']['transfer']<y<y+DK['wind']['gap_h']+DK['wind']['transfer']<DK['wind']['deck']: problems.append(('P6: wind gap levels',y))
if not DK['north']['start']<DK['north']['garden'][0]<DK['north']['garden'][1]<175: problems.append(('P6: north levels',))


# Sampled geometry checks prevent envelope and circulation drift in P6.
def _p6_geometry_checks():
    from shapely.geometry import Polygon as P6Polygon
    def sp(v): return math.copysign(abs(v)**(2/5.5),v) if abs(v)>1e-12 else 0.0
    S=DK['south']; clearances=[]
    for j in range(2,41):
        scale=1-0.07*(j-37) if j>37 else 1.0
        inner=S['inner'] if j<=38 else S['terrace_inner'][j-39]
        # At terrace slab +142.5/+146.25, the facade above steps immediately.
        if j==38: inner=S['terrace_inner'][0]
        if j==39: inner=S['terrace_inner'][1]
        outer=[]; inside_=[]
        for i in range(256):
            a=i*math.pi/128; r=(S['outer']/2-S['ripple']*(.5+.5*math.sin(3*a+.43*j)))*scale
            outer.append((r*sp(math.cos(a)),r*sp(math.sin(a))))
            inside_.append((inner/2*sp(math.cos(a)),inner/2*sp(math.sin(a))))
        op,ip=P6Polygon(outer),P6Polygon(inside_)
        if not op.is_valid or not op.covers(ip): problems.append(('P6: south profile intersects private volume',j))
        clear=op.boundary.distance(ip.boundary)-0.08
        clearances.append(clear)
        if clear<1.5-0.01: problems.append(('P6: south guard reduces route below 1.5',j,clear))
        if any(max(abs(x),abs(z))>13.00001 for x,z in outer): problems.append(('P6: south outside shaft',j))
    N=DK['north']
    for j in range(2,45):
        y=j*N['storey']
        if N['garden'][0]-1e-8<=y<N['garden'][1]-1e-8: continue
        for side in range(4):
            if side%2!=j%2: continue
            for bay in range(2):
                if j>40 and (j+side+bay)%3==0: continue
                dep=N['capsule_d'][(j+side+bay)%3]; x=(-3.35,3.35)[bay]
                for xx,zz in [(x-N['capsule_w']/2,4),(x+N['capsule_w']/2,4+dep)]:
                    a=side*math.pi/2; rx=xx*math.cos(a)+zz*math.sin(a); rz=-xx*math.sin(a)+zz*math.cos(a)
                    if abs(rx)>14.00001 or abs(rz)>13.00001: problems.append(('P6: capsule outside shaft',j,side,bay))
                if y+N['capsule_h']>N['top']: problems.append(('P6: capsule above envelope',j))
    W=DK['wind']
    C=W['crown_frame']
    if not (C['base']==W['top']<C['mid']<C['top']<C['rotor_y']-C['rotor_height']/2<C['rotor_y']+C['rotor_height']/2<C['mast_top']==W['crown']):
        problems.append(('P6: crown bearing or rotor/frame clearance',))
    if C['ring_samples']%C['posts']!=0: problems.append(('P6: crown frame samples do not share nodes',))
    if C['rotor_x']!=0 or C['rotor_z']!=0 or C['scales']!=[1.0,0.85,0.7]: problems.append(('P6: crown rotor off centre or frame discontinuity',))
    if abs(W['rotor_z'])-W['rotor_sweep']<W['core'][1]/2+0.3: problems.append(('P6: rotor sweeps into core',))
    if DK['owners'][9]['lot']!=119 or DK['owners'][9]['passage'] is None: problems.append(('P6: court 8 passage missing',))
    if not {0.0,6.5,W['deck']}==set(W['stops']): problems.append(('P6: Windspire public stops drifted',))
    DK['checks']=dict(south_min_clear=round(min(clearances),4),capsules_within_shaft=True,owners=len(DK['owners']))
_p6_geometry_checks()
def _p6_site_checks():
    from shapely.geometry import Polygon
    src=[i for st in DK['sites'] for i in st['sources']]
    if sorted(src)!=sorted(o['lot'] for o in DK['owners']) or len(src)!=len(set(src)):
        problems.append(('P6: merged source coverage/duplicates',))
    gaps=[]
    for st in DK['sites']:
        sh=_p6box(*st['shaft']);land=Polygon(st['podium'])
        for axis in ('x','z'):
            grid=st['grid'][axis]
            if any(b-a>7.2001 for a,b in zip(grid,grid[1:])): problems.append(('P6: unsupported primary span',st['id'],axis))
        if st['passage']:
            px=st['passage']['road_end'][0]-(st['shaft'][0]+st['shaft'][2])/2
            if any(abs(x-px)<st['passage']['w']/2+0.7-1e-6 for x,z in st['piers']):
                problems.append(('P6: primary pier intrudes into passage',st['id']))

        if not land.covers(sh): problems.append(('P6: shaft outside merged site',st['id']))
        if min(st['shaft'][2]-st['shaft'][0],st['shaft'][3]-st['shaft'][1])<12:
            problems.append(('P6: tall sliver persists',st['id']))
        for other in DK['sites']:
            if other['id']<=st['id']: continue
            gap=sh.distance(_p6box(*other['shaft']));gaps.append(gap)
            if gap<8-1e-6: problems.append(('P6: shafts too close',st['id'],other['id'],gap))
        for n in (12,13,14,15):
            gap=sh.distance(_p6box(*TOWER_SITE[n]['shaft']))
            # The P17 climb wall deliberately remains six metres from BLOCK.
            minimum=6 if st['id']=='block_approach' and n==13 else 8
            if gap<minimum-1e-6: problems.append(('P6: landmark separation',st['id'],n,gap))
    approach=next(st for st in DK['sites'] if st['id']=='block_approach')
    if approach['shaft'][0]!=-443 or approach['shaft'][1]>55 or approach['shaft'][3]<55 or approach['height']!=122.4:
        problems.append(('P6: P17 climb interface moved',))
    DK['checks'].update(sites=len(DK['sites']),min_shaft_gap=round(min(gaps),3),source_lots=len(src))
_p6_site_checks()


# P7: complete Crossing kit and exact shared dome topology (planning only).
from moy_crossing_kit import build_crossing_kit
from moy_park_kit import build_park_kit, build_playground_kit
CROSSING['kit']=build_crossing_kit(CROSSING,ESCALATORS,PLATFORMS)
PARK['kit']=build_park_kit(PARK,CROSSING,B)
PARK['playground']['kit']=build_playground_kit(PARK,CROSSING)
parts_checks('Park',PARK['kit']['parts'],PARK['kit']['joins'])
parts_checks('Playground',PARK['playground']['kit']['parts'],PARK['playground']['kit']['joins'])
parts_checks('Crossing',CROSSING['kit']['parts'],CROSSING['kit']['joins'])
if any(l['stops']!=CROSSING['kit']['lift_stops'] for l in CROSSING['kit']['lift_serving']):
    problems.append(('P7: lift stop lists differ from authoritative Clock Room routes',))

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

from gd_plan import lit

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
w("const ESTATE := %s" % lit(ESTATE))
w("const DOWNTOWN := %s" % lit(DOWNTOWN))
w("const OMITTED_STREETS := %s" % lit(OMITTED_STREETS))
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
    return "{" + ", ".join("%s: %s" % (q(a_), ("true" if v is True else "false" if v is False else q(v) if isinstance(v,str) else str(v) if isinstance(v,(int,float)) else lit(v))) for a_,v in k.items()) + "}"
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
w("## The cross lines (city.md 6c): the Spine at +12 m, rising to +20 m flyovers above")
w("## level at +13.2 (the Wall Line's height) with gate interchanges; independent services. Meridian at +36 m.")
w("## Where the Spine follows the Deck it rides on the Deck columns, directly above it.")
w("## Spine follows the Deck it rides on the Deck's columns, directly above it.")
w("const CROSS := %s" % lit(CROSS))
w("## The Crossing: the station and civic shelter at the park's centre (city.md 7a).")
w("const CROSSING := %s" % lit(CROSSING))
w("const TREE_KIT := %s" % lit(TREE_KIT))
w("## The Meridian Arch (city.md 8b): legs (world rects), lower and top bridges (y ranges), the line's east station.")
w("const ARCH := %s" % lit(ARCH))
w("## Civic Plaza (city.md 8a): the square, reflection pool, lawns and forecourt.")
w("const CIVIC_SQUARE := %s" % lit(CIVIC_SQUARE))
w("const WEST_GATE := %s" % lit(WEST_GATE))
w("const GREEN := %s" % lit(GREEN))
w("const TRAIN := %s" % lit(TRAIN))
w("## Platforms, escalators and the timetable (city.md 6f, 6g).")
w("const PLATFORMS := %s" % lit(PLATFORMS))
w("const ESCALATORS := %s" % lit(ESCALATORS))
w("const TIMETABLE := %s" % lit(TIMETABLE))
w("## The launch site outside the city (city.md 12): the way to the Space Kingdom.")
w("const LAUNCH_SITE := %s" % lit(LAUNCH_SITE))
w("## The park (city.md 7a): its gardens, pond, lawn, playground, wind trees and walks.")
w("const PARK := %s" % lit(PARK))
w("## The Grand Hotel (city.md 8): its atrium block, tower, drum, lifts and skybridge.")
w("const HOTEL := %s" % lit(HOTEL))
w("")
w("## The towers' sites: the shaft's footprint and the public ground round it (city.md 7c).")
w("const TOWER_SITE := %s" % lit(TOWER_SITE))
w("## The BLOCK tower's form (city.md 7c): windowless shaft and inward-folded canted blade crown.")
w("const BLOCK_TOWER := %s" % lit(BLOCK_TOWER))
w("")
w("## The Well Quarter (city.md 7, Old Moy): the old town's organic lanes and squares,")
w("## and its tower houses turned to their lanes. lanes: centrelines with widths (lane_polys:")
w("## their outlines); squares: polygons; houses: outline corners (world x, z), storeys, the")
w("## lane or square they front, and their tower house kit. yards: the families' back yards.")
w("const OLD_TOWN := %s" % lit(dict(interiors=OLD_TOWN['interiors'],lanes=OLD_TOWN['lanes'],squares=OLD_TOWN['squares'],lane_polys=OLD_TOWN['_lane_polys'],yards=OLD_TOWN['_yards'],cover=OLD_TOWN['_cover'],courts=OLD_TOWN['_courts'],pockets=OLD_TOWN['_pockets'],roof_links=OLD_TOWN['_roof_links'])))
w("const OLD_HOUSES := %s" % lit(OLD_HOUSES))
w("## The market lanes' kit (moy_market_lanes.md 3; package P3): metres. ARCADE_ROOF: Arcade Street's roof, its arches' z.")
w("## LAMP_LANE: lantern strings' x and the night market's stalls. COURT_WAYS: the open ground of each of COURTS (pts), as a court")
w("## (open to a road, a passage through a lot, or within: landmarks round it, theirs to open) or a light well (well, fill_to).")
w("const MARKET_HOUSE := %s" % lit(MARKET_HOUSE))
w("const ARCADE_ROOF := %s" % lit(ARCADE_ROOF))
w("const LAMP_LANE := %s" % lit(LAMP_LANE))
w("const COURT_WAYS := %s" % lit(COURT_WAYS))
w("## The tower house kit's numbers (moy_tower_house.md 3; package P4): metres, the batter in degrees.")
w("const TOWER_HOUSE := %s" % lit(TOWER_HOUSE))
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
    json.dump(dict(streets=STREETS,omitted_streets=OMITTED_STREETS,opens=OPENS,lots=lots,courts=courts,buildings=[dict(b,angle=ANGLE.get(b['n'],0),corners=corners_of(b) if b['r'] else None,height=HEIGHTS.get(b['n'],0),crown=CROWNS.get(b['n']),form=FORMS.get(b['n'],'block'),part=TOWER_PART.get(b['n']),podium=PODIUM_HEIGHT.get(b['n']),site=TOWER_SITE.get(b['n'])) for b in B],hotel=HOTEL,downtown=DOWNTOWN,storey=STOREY,park=PARK,turbines=TURBINES,precincts=PRECINCTS,estate=ESTATE,deck={k:v for k,v in DECK.items() if not k.startswith('_')},wall=WALL,cross=CROSS,crossing=CROSSING,arch=ARCH,west_gate=WEST_GATE,green=GREEN,train=TRAIN,platforms=PLATFORMS,escalators=ESCALATORS,timetable=TIMETABLE,launch_site=LAUNCH_SITE,civic_square=CIVIC_SQUARE,tree_kit=TREE_KIT,old_town=dict(interiors=OLD_TOWN['interiors'],lanes=OLD_TOWN['lanes'],squares=OLD_TOWN['squares'],lane_polys=OLD_TOWN['_lane_polys'],yards=OLD_TOWN['_yards'],cover=OLD_TOWN['_cover'],courts=OLD_TOWN['_courts'],pockets=OLD_TOWN['_pockets'],roof_links=OLD_TOWN['_roof_links']),old_houses=OLD_HOUSES,tower_house=TOWER_HOUSE,market_house=MARKET_HOUSE,arcade_roof=ARCADE_ROOF,lamp_lane=LAMP_LANE,court_ways=COURT_WAYS,block_tower=BLOCK_TOWER,lot_kits=LOT_KITS,building_kits=BUILDING_KITS),open(path,'w'))
print('wrote scripts/city_plan.gd:',len(STREETS),'streets,',len(B),'buildings,',len(lots),'lots,',len(courts),'courts')
