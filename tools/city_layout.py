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
 ('Civic Plaza',-483,-30,-431,30),
 ('Library Square',-686,-30,-637,-6),
 ('Market Square',-590,122,-530,164),
 ('Estate Square',-554,-118,-516,-84),
 ('Meridian Court',-391,-30,-359,30),
]
B=[]
def b(n,name,r,kind,h,who=''): B.append(dict(n=n,name=name,r=r,kind=kind,h=h,who=who))
NB=lambda: 'homes (no one the hero meets)'
b(1,'Grand Hotel',(-483,-98,-431,-38),'civic','atrium block of 12 levels (44 m) round its void; cylinder guest tower of 28 levels (96 m), drum to 108 m (after John Portman)','Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work')
b(2,'City hall',(-431,-30,-397,30),'civic','exterior only: portico, balcony and side wings, with the Timekeeper standing over it, at the head of Civic Plaza (section 8a)','Mayor Teodora Vance, Kenji Mori (clerk)')
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
b(27,"Pinestein's building",(-716,-118,-707,-102),'shop','old tower house, 9 storeys; laboratory on the roof beside its wind tower','Palbert Pinestein (top floor)')
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
HEIGHTS={1:96,2:22,3:22,4:16,5:9,6:4,7:11,8:12,9:4,10:4,12:262,13:150,14:175,15:150,16:22,
 17:91,18:104,19:117,20:130,21:130,22:46,23:6,24:11,25:17,26:20,27:29,28:26,29:20,30:20,31:20,
 32:23,33:9,34:26,35:72,36:42,37:17,38:7,39:6,49:52,50:110,51:8,52:23,53:78,40:8,41:4,42:6,43:35,44:3}
CROWNS={1:108,3:26,12:280}
## Plan forms: twist (a rounded triangle turning as it rises), screen (round-
## cornered square in a screen), capsule (core with plug-in capsules), dune
## (rippling balconies), atrium (the Grand Hotel: an atrium block with a
## cylinder tower, whose rect is TOWER_PART; see HOTEL), clock (city hall).
FORMS={12:'twist',13:'monolith',14:'capsule',15:'dune',1:'atrium',2:'hall'}
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
## (revised 2026-10-16) The park is shared: the Crossing, the city's station, at
## its centre where the two lines cross; the giant playground moved whole to the
## south-east quarter at 0.55 scale; the dry garden, the pond, the green and the
## tea house's parasols round them; the four wind trees stand round the station.
PG_C=(-515,31); PG_K=0.55
def _pg(x,z): return (round(PG_C[0]+(x+560)*PG_K,2),round(PG_C[1]+z*PG_K,2))
PARK={
 'rect':(-625,-50,-495,50),
 'walks':[(-625,-3,-495,3),(-563,-50,-557,50)],
 'dry_garden':(-620,-45,-583,-6),
 'pond':{'c':(-516,-28),'r':(19,13)},
 'lawn':(-551,22,-535,38),
 'parasols':[(-612,12),(-598,14),(-586,22),(-596,32),(-584,40),(-612,44)],
 'playground':{'c':PG_C,'scale':PG_K,'track':(round(24*PG_K,2),round(28*PG_K,2)),
   'towers':[_pg(x,z)+(h,round(r*PG_K+0.6,2),nm) for x,z,h,r,nm in [(-560,0,20,4.5,'Lookout'),(-548,-7,16,3.5,''),(-574,-4,14,3.2,''),(-560,14,12,3,'')]],
   'perches':[_pg(x,z) for x,z in [(-566,18),(-554,18),(-560,21)]],'perch_height':12,
   'hoops':[list(_pg(-560+(9+i*1.6)*math.cos(-math.pi/2+i*0.75),(9+i*1.6)*math.sin(-math.pi/2+i*0.75))) for i in range(8)]},
 'wind_trees':[(-581,-14),(-533,-14),(-581,14),(-533,14)],'wind_tree_height':32,
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
  # to the library's east-wing door, over Garden Walk's mouth
  dict(name='Library walk',kind='walk',w=6,pts=[(-631,-27),(-648,-27)]),
  # straight through the park under the Spine Line, from the Park Deck's north side to its south side: the Crossing's mezzanine
  dict(name='Spine walk',kind='walk',w=6,pts=[(-560,-50),(-560,50)]),
  # the Crossing Ring's concourse, at the Deck's level round the park's centre
  dict(name='Crossing Ring',kind='ring',w=6,pts=[(round(-560+17*math.cos(math.radians(a_)),2),round(17*math.sin(math.radians(a_)),2)) for a_ in range(0,361,15)]),
  # up the east half of North Street to the neighbourhood centre's roof garden
  dict(name='Estate walk',kind='walk',w=6,pts=[(-560,-56),(-560,-121)]),
  dict(name='Neighbourhood centre bridge',kind='bridge',w=6,pts=[(-560,-121),(-554,-121)]),
  # down the east half of South Street, then along Market Square's north edge to the wet market's upper hall
  dict(name='Market walk',kind='walk',w=6,pts=[(-560,56),(-560,125),(-530,125)]),
 ],
 # where the Deck meets a building at +6.5 m: (building, point on its face, what is there)
 'doors':[
  (1,(-457,-38),'the hotel\'s Deck door into the mezzanine gallery'),
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
  # (the park's north and south gate towers are retired, 2026-10-17: the Deck now runs on the street's centre line
  # over the whole park walk, and the Crossing's two spirals take the park's people between the lawn and the Deck)
  dict(name='West gate',c=(-621,8),r=4,head='w',foot='n'),
  dict(name='East gate',c=(-499,-8),r=4,head='e',foot='s'),
  dict(name='Civic north',c=(-457,-20),r=4,head='n',foot='s'),
  dict(name='Civic south',c=(-457,20),r=4,head='s',foot='n'),
 ],
 # the Crossing's spirals are ways down from the Crossing Ring (CROSSING['spirals'])
 'spiral_ways':[(-548.0,-10.6),(-572.0,10.6)],
 'lifts':[dict(name='Park north gate',c=(-555.4,-46),r=1.6),dict(name='Park south gate',c=(-555.4,46),r=1.6),dict(name='Estate Square',c=(-555.4,-112),r=1.6),dict(name='Market Square',c=(-533,129.7),r=1.6)],
 'max_to_way_down':75.0,'min_soffit':5.4,'min_open_beside':4.0,
 # escalating ramps from a square up to the Deck (revised 2026-10-17 after the first prototype: the 12 degree
 # travelators ran 31 m and stood in the squares as long obstructions; these are escalator pairs at 30 degrees,
 # an up and a down side by side, 11.3 m long, set end-on into the Deck's edge). The park's two wing ramps to
 # the Crossing are gone: the Crossing's spirals serve it.
 'escalators':[
  dict(name='Civic Plaza north',foot=(-470,-12.7),head=(-470,-24)),
  dict(name='Civic Plaza south',foot=(-446,12.7),head=(-446,24)),
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
        # the Crossing Ring stands on the Crossing's own column rings (CROSSING)
        if run['kind'] in ('bridge','ring'): continue
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
       piers=[-722,-686,-650,-614,-578,-542,-506,-470,-434,-392],span=36.0,max_span=42.0,
       structure='tree piers: one round-square stem 2.4 m across in the middle of the street, branching at +28 m into a Y that carries twin steel box girders; 36 m spans, one 42 m bridge over city hall; the West Gate\'s tower carries its west end'),
 ],
 'stations':[
  dict(name='North Gate',at=(-560,-184),lines=['Spine Line'],deck=False,mid=7.1,interchange='Wall Line',access='the Spine\'s north terminus just inside the wall: its platforms run on, level, onto the Wall Line\'s inner platform at the North Gate; escalator pairs under both platforms from the street'),
  dict(name='Estate Square',at=(-560,-100),lines=['Spine Line'],deck=True,access='over the Deck\'s Estate walk: escalator pairs under both platforms, from the street by way of the Deck'),
  dict(name='The Crossing',at=(-560,0),lines=['Spine Line','Meridian Line'],deck=True,access='the Crossing Ring at the park\'s centre: its two double-helix spirals join the lawn, the ring, the Spine\'s platforms and the high line\'s'),
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
## spirals of the Plant Kingdom), each with a glass lift beside it or in its eye.
ESCALATORS=dict(pair=dict(angle=30.0,tread=1.2,w=3.2,max_rise=8.0),
  scissor=dict(angle=30.0,w=3.2,max_rise=7.2,landing=1.5),
  helix=dict(angle=25.0,eye=2.0,band=2.6,hands=2,min_headroom=2.6,deck=0.5))
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
## The Crossing Ring (city.md 7a, revised 2026-10-16): open air, after Sou
## Fujimoto's Grand Ring at Expo 2025 Osaka. A ring of slender columns, two rows
## on a 15 degree rhythm, carrying a concourse ring at the Deck's level (+6.5 m)
## and a halo of shade over the Spine's platforms (+17 m), open at the centre to
## the sky and the high line crossing above, and open on every side to the park.
## Revised 2026-10-17 after the first prototype: the ring is centred on the
## street's line (x -560), the halo raised to 18 m over the Spine's platforms at
## 14.2, and the two rectangular cores (which clipped the ring) and the park's
## long wing ramps are replaced by two double-helix spirals: an up and a down
## escalator spiral wound together round a glass lift, rising from the lawn
## through the ring concourse and the halo to the high line. Each stands in the
## ring, beside a Spine platform (a 1.4 m bridge at +14.2) and under the outer
## edge of a high-line platform, onto which its last turn lands at +37.
## spirals: centre, the levels it serves, the side each landing opens to
## (the bearing in degrees: 0 east, 90 south), and what it joins.
CROSSING=dict(c=(-560,0),ring=(14.0,20.0),deck=6.5,halo=(18.0,12.0,22.0),columns=24,
  material='pale timber louvres on slender steel columns',
  program='the ring concourse: shade, water fountains, kiosks, the lost-and-found and the city\'s information desk',
  spirals=[dict(name='north-east',c=(-548.0,-10.6),levels=[0,6.5,14.2,37.0],opens={'6.5':'the ring','14.2':180,'37.0':90},lift=True,
                joins='the lawn, the ring, the Spine\'s east platform and the high line\'s north platform'),
           dict(name='south-west',c=(-572.0,10.6),levels=[0,6.5,14.2,37.0],opens={'6.5':'the ring','14.2':0,'37.0':270},lift=True,
                joins='the lawn, the ring, the Spine\'s west platform and the high line\'s south platform')],
  cores=[])
## The Timekeeper (city.md 8a, revised 2026-10-16): a full circle standing over
## city hall in a bronze cradle, clear of the roof, the high line passing through
## its empty centre. A twelve-hour ring clock: the minute ring and the hour ring
## turn past the fixed index at the top, each carrying one lit marker, and keep
## real time; the fixed bezel carries the twelve hour marks.
TIMEKEEPER=dict(x=-414.0,z=0.0,y=37.5,thick=3.0,roof=22.0,
  rings=[('minute',6.0,9.0,'turns once an hour; one lit marker'),
         ('hour',9.0,12.0,'turns twice a day; one larger lit marker'),
         ('bezel',12.0,13.5,'fixed; twelve hour marks and the index at the top')],
  cradle=dict(z=15.0,w=2.0,material='bronze',note='two pylons from the roof hold the bezel at its sides'),
  # the lit markers: an arc across each moving ring's band, standing proud of both faces so the time reads from the plaza
  # and from Meridian Court; the hour's is wide, the minute's slim; a lit bead runs round the bezel's rim once a minute
  markers=dict(hour=dict(arc=24.0,proud=0.4),minute=dict(arc=7.0,proud=0.4)),
  seconds=dict(r=14.1,bead=0.6,note='runs round the bezel\'s rim once a minute, through the cradle\'s grips'),
  marks=dict(hour=dict(w=0.5),quarter=dict(w=1.2),proud=0.25))
## The Meridian Arch is the East Gate (city.md 8b, revised 2026-10-16): a loop
## after Beijing's CCTV headquarters whose two legs straddle the wall at the gate.
## Meridian Avenue passes under it through a 24 m opening; the Wall Line runs
## through the legs at +12 m with its station between them; the high line ends on
## the lower bridge at +36 m, directly above, crossing the Wall Line at right
## angles; the top bridge, cantilevered toward city hall, is the Wall Watch's
## command room. Revised 2026-10-17: on each leg's court face an open cascade
## of escalating ramps climbs the diagrid under glass canopies, after the
## Centre Pompidou's and Singapore's open-air station escalators, from the
## station hall on Meridian Court to the Wall Line, the high line and the sky
## garden on the lower bridge's roof; the Watch reaches its room by its own lift.
ARCH=dict(legs=[(-363.5,-30,-341.5,-12),(-363.5,12,-341.5,30)],lower=(32.0,42.0),top=(58.0,72.0),cantilever=12.0,
  opening=24.0,wall_line=12.0,
  cores=[dict(name='north leg',c=(-366.7,-21),size=(6.4,16.0),levels=[0,14.2,37,43],lifts=2,enclosure='open cascade',canopy=3.2,lift=(2.6,2.6)),
         dict(name='south leg',c=(-366.7,21),size=(6.4,16.0),levels=[0,14.2,37,43],lifts=2,enclosure='open cascade',canopy=3.2,lift=(2.6,2.6))],
  # the Wall Line's train hall: a void through both legs at +12 m (v: across the wall, outward positive, from the wall's
  # centreline; y: floor and ceiling), holding both tracks and the station's platform on the outer side
  train_hall=dict(v=(-9.0,5.5),y=(12.0,21.0)),
  program='the station hall at the street, the Wall Line\'s station at +12 m, the high line\'s at +36 m, city offices in the legs, the Wall Watch\'s command room at the top',
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
    dict(name='The Deck',on='the Deck',planting=['bougainvillea','date palm'],
         where='planter edges along its parapets and date palms in tubs at the ramp heads: the Deck is Moy\'s park connector, a shaded green walk from every square to the park and the stations',after='Singapore\'s Park Connector Network and its covered walkways to the stations',
         keeper='Orin Pike (park keeper)',collision='planters and tubs solid; fronds decorative'),
    dict(name='The Crossing',on='the Crossing Ring',planting=['bougainvillea','coral vine','desert grasses'],ring_planter=1.0,halo_rim=1.2,
         where='a planter on the ring\'s inner edge spilling bougainvillea into the open middle, coral vine up the inner columns, desert grasses on the halo\'s rim, and a rain garden under the ring catching the halo\'s run-off and the misters\' drip',after='the Supertrees\' climbers and Singapore\'s ABC Waters rain gardens (Bishan–Ang Mo Kio Park)',
         keeper='Orin Pike (park keeper)',collision='the planters are the concourse\'s parapet (solid, a landing); plants decorative'),
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
            # every Spine station but the Crossing (which has its spirals): a scissor stack of escalator pairs under
            # each platform, from the street to the platform, its middle landing the Deck where the Deck runs below
            if sv['line']=='Spine Line' and st['name']!='The Crossing':
                ES=ESCALATORS['scissor']; plat=sv['rail']+PLATFORMS['floor']
                mid=DECK['level'] if st.get('deck') else st.get('mid',plat/2)
                if st.get('deck') and not any(LineString(r_['pts']).buffer(r_['w']/2).contains(p_) for r_ in DECK['runs']): problems.append(('cross: no Deck under a Deck station',st['name']))
                flights=[(0.0,mid),(mid,plat)]; runs=[(b_-a_)/math.tan(math.radians(ES['angle'])) for a_,b_ in flights]
                if max(b_-a_ for a_,b_ in flights)>ES['max_rise']+0.6: problems.append(('cross: a station stack flight too tall',st['name']))
                foot=max(runs)+2*ES['landing']
                if foot>X['platform'][0]: problems.append(('cross: a station stack longer than its platform',st['name'],round(foot,1)))
                ux,uz=(L.coords[-1][0]-L.coords[0][0])/L.length,(L.coords[-1][1]-L.coords[0][1])/L.length
                st['_stacks']=[]
                for sd in (1,-1):
                    off=X['track']+PLATFORMS['edge']+PLATFORMS['width']/2-ES['w']/2+0.0
                    cx_,cz_=st['at'][0]-uz*sd*(X['track']+PLATFORMS['edge']+PLATFORMS['width']/2),st['at'][1]+ux*sd*(X['track']+PLATFORMS['edge']+PLATFORMS['width']/2)
                    st['_stacks'].append(dict(side=sd,c=[round(cx_,2),round(cz_,2)],along=[round(ux,3),round(uz,3)],length=round(foot,1),flights=[[round(a_,2),round(b_,2),round(r_,2)] for (a_,b_),r_ in zip(flights,runs)]))
                    sg=LineString([(cx_-ux*foot/2,cz_-uz*foot/2),(cx_+ux*foot/2,cz_+uz*foot/2)]).buffer(ES['w']/2,cap_style=2)
                    for n_,h,g in tall:
                        if sg.intersection(g).area>0.05: problems.append(('cross: a station stack on a building',st['name'],n_))
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
    # the Meridian passes through the Timekeeper's empty centre with room round its trains
    T=TIMEKEEPER; inner=T['rings'][0][1]; R1=T['rings'][-1][2]
    if LineString(me['pts']).distance(Point(T['x'],T['z']))>0.01: problems.append(('cross: the Meridian Line misses the Timekeeper',))
    for dz in (-X['double']/2,X['double']/2):
        for y in (me['rail']-X['depth'],me['rail']+X['car_h']+0.4):
            if math.hypot(dz,y-T['y'])>inner-0.8: problems.append(('cross: the train fouls the Timekeeper\'s rings',dz,y))
    if T['y']-R1<T['roof']+2.0: problems.append(('cross: the Timekeeper dips into city hall\'s roof',round(T['y']-R1,1)))
    ch=[b_ for b_ in named if b_['n']==2][0]['r']
    if not (ch[0]<T['x']<ch[2] and ch[1]<T['z']-T['cradle']['z']-T['cradle']['w'] and T['z']+T['cradle']['z']+T['cradle']['w']<ch[3]): problems.append(('cross: the Timekeeper\'s cradle does not stand on city hall',))
    if T['cradle']['z']<R1+0.5: problems.append(('cross: the cradle fouls the rings',))
    sb=T['seconds']
    if sb['r']-sb['bead']<R1-0.01 or sb['r']+sb['bead']>T['cradle']['z']: problems.append(('cross: the seconds bead leaves the bezel\'s rim',))
    if max(m['arc'] for m in T['markers'].values())>=30.0: problems.append(('cross: a Timekeeper marker spans an hour mark',))
    if me['rail']-X['depth']-HEIGHTS[2]<2.0: problems.append(('cross: the Meridian Line too low over city hall\'s roof',))
    # the high line's piers: in the street or a square, never on a building, the Spine or a station; spans to rhythm
    ml=LineString(me['pts']); pz=me['pts'][0][1]; xs=sorted(me['piers'])
    for x in xs:
        q=Point(x,pz)
        for n_,h,g in tall:
            if g.distance(q)<1.4: problems.append(('cross: a high-line pier on a building',x,n_))
        if abs(x-sp['pts'][0][0])<4: problems.append(('cross: a high-line pier on the Spine',x))
    ends=[min(lg[0] for lg in WEST_GATE['towers']),max(lg[2] for lg in WEST_GATE['towers']),min(lg[0] for lg in ARCH['legs'])]
    seq=[WEST_GATE['towers'][0][2]]+xs+[ARCH['legs'][0][0]]
    spans=[round(b-a,1) for a,b in zip(seq,seq[1:])]
    me['spans']=spans
    if max(spans)>me['max_span']+0.01: problems.append(('cross: a high-line span too long',max(spans)))
    regular=[sp_ for sp_ in spans if abs(sp_-me['span'])<0.01]
    if len(regular)<len(spans)*0.6: problems.append(('cross: the high line\'s piers keep no rhythm',spans))
    cx_=CROSSING['c'][0]
    if not any(abs(x-(cx_-me['span']/2))<0.01 for x in xs) or not any(abs(x-(cx_+me['span']/2))<0.01 for x in xs): problems.append(('cross: the piers are not set out from the Crossing',))
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
                ct=[o for o in OPENS if o[0]=='Meridian Court'][0]
                if not sbox(*ct[1:]).contains(g): problems.append(('arch: a cascade outside Meridian Court',c['name']))
            if c.get('enclosure') not in ('open frame','open cascade','open loggia'): problems.append(('station: an enclosed core',host,c['name']))
            for hx in ((ARCH if host=='arch' else WEST_GATE if host=='west gate' else {}).get('train_hall',{}).get('x') or []):
                if g.intersects(sbox(hx[0],-300,hx[1],300)) and host!='crossing' and any(sbox(*lg).intersects(g) for lg in (ARCH['legs'] if host=='arch' else WEST_GATE['towers'])): problems.append(('station: a core in the train hall',host,c['name']))
            if host=='west gate' and not any(sbox(*tw).contains(g) for tw in W['towers']): problems.append(('west gate: a core outside its tower',c['name']))
    # the Crossing's double-helix spirals: an up and a down escalator spiral wound round a glass lift's eye. Headroom
    # between the two hands; inside the ring; clear of the Spine's tracks and platforms but a short bridge from one;
    # clear of the high line's deck, and landing on the outer edge of one of its platforms
    C=CROSSING; H=ESCALATORS['helix']; rm=H['eye']+H['band']/2; ro=H['eye']+H['band']
    turn=2*math.pi*rm*math.tan(math.radians(H['angle']))
    if turn/H['hands']-H['deck']<H['min_headroom']: problems.append(('crossing: a spiral without headroom between its hands',round(turn/H['hands']-H['deck'],2)))
    spx=sp['pts'][0][0]; plat_in=X['track']+PLATFORMS['edge']; plat_out=plat_in+PLATFORMS['width']
    for S in C['spirals']:
        cx_,cz_=S['c']; d=math.hypot(cx_-C['c'][0],cz_-C['c'][1])
        if not (C['ring'][0]<=d<=C['ring'][1]): problems.append(('crossing: a spiral not in the ring',S['name']))
        bridge=abs(cx_-spx)-ro-plat_out
        if not (0.5<=bridge<=2.5): problems.append(('crossing: a spiral not beside a Spine platform',S['name'],round(bridge,2)))
        if abs(cz_)-ro<plat_out-0.05 and abs(abs(cz_)-ro-plat_out)>0.3: problems.append(('crossing: a spiral under the high line',S['name']))
        if abs(abs(cz_)-ro-plat_out)>0.3: problems.append(('crossing: a spiral not landing on a high-line platform',S['name'],round(abs(cz_)-ro,2)))
        for x in me['piers']:
            if math.hypot(cx_-x,cz_-me['pts'][0][1])<ro+1.6: problems.append(('crossing: a spiral against a pier',S['name'],x))
        if sorted(S['levels'])!=[0,DECK['level'],sp['rail']+PLATFORMS['floor'],me['rail']+PLATFORMS['floor']]: problems.append(('crossing: a spiral misses a level',S['name'],S['levels']))
        S['turns']=round(max(S['levels'])/turn,2); S['rise_per_turn']=round(turn,2); S['r']=(H['eye'],ro)
    # the Crossing Ring: open, inside the park, clear of its gardens, the pond, the playground and the wind trees
    ring=Point(C['c']).buffer(C['ring'][1],64)
    if not sbox(*PARK['rect']).contains(ring): problems.append(('crossing: the ring leaves the park',))
    from shapely import affinity
    pc=PARK['pond']['c']; pond=affinity.scale(Point(pc).buffer(1,64),*PARK['pond']['r'])
    pg=PARK['playground']; play=Point(pg['c']).buffer(pg['track'][1],64)
    halo=Point(C['c']).buffer(C['halo'][2],64)
    for nm,g in [('dry garden',sbox(*PARK['dry_garden'])),('lawn',sbox(*PARK['lawn'])),('pond',pond),('playground',play)]+[('parasol',Point(t).buffer(2.5)) for t in PARK['parasols']]:
        if halo.intersection(g).area>0: problems.append(('crossing: the ring on the',nm))
    for t in PARK['wind_trees']:
        if halo.distance(Point(t))<2: problems.append(('crossing: a wind tree under the halo',t))
    if not (sp['rail']+X['car_h']+0.5<C['halo'][0]<me['rail']-X['depth']-2): problems.append(('crossing: the halo between the lines\' heights is wrong',))
    if abs(C['deck']-DECK['level'])>0.01: problems.append(('crossing: the ring is not at the Deck\'s level',))
    if not sbox(*PARK['rect']).buffer(-1).contains(play): problems.append(('park: the playground leaves the park',))
    for n_ in (9,10):
        g=sbox(*[b_ for b_ in named if b_['n']==n_][0]['r'])
        for nm,f in [('playground',play),('ring',halo),('pond',pond),('lawn',sbox(*PARK['lawn'])),('dry garden',sbox(*PARK['dry_garden']))]+[('walk',sbox(*w_)) for w_ in PARK['walks']]:
            if g.intersection(f).area>0: problems.append(('park: a park building on the',nm,n_))
    for t in pg['towers']:
        if pond.distance(Point(t[:2]))<t[3]+1 or sbox(*PARK['lawn']).distance(Point(t[:2]))<t[3]: problems.append(('park: a playground tower on the pond or the lawn',t))
    for t in PARK['wind_trees']:
        if pond.contains(Point(t)) or play.distance(Point(t))<3: problems.append(('park: a wind tree on the pond or the playground',t))
_block_checks()
_cross_checks()
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
w("## the Wall Line at both gates; independent services, no junctions. Meridian at +36 m.")
w("## Where the Spine follows the Deck it rides on the Deck columns, directly above it.")
w("## Spine follows the Deck it rides on the Deck's columns, directly above it.")
w("const CROSS := %s" % lit(CROSS))
w("## The Crossing: the station and civic shelter at the park's centre (city.md 7a).")
w("const CROSSING := %s" % lit(CROSSING))
w("## The Timekeeper over city hall (city.md 8a): rings (name, inner and outer radius, what), centre (x, y, z), the")
w("## Meridian Line through its empty centre. Twelve-hour ring; no day ring.")
w("const TIMEKEEPER := %s" % lit(TIMEKEEPER))
w("## The Meridian Arch (city.md 8b): legs (world rects), lower and top bridges (y ranges), the line's east station.")
w("const ARCH := %s" % lit(ARCH))
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
w("const OLD_TOWN := %s" % lit(dict(interiors=OLD_TOWN['interiors'],lanes=OLD_TOWN['lanes'],squares=OLD_TOWN['squares'],lane_polys=OLD_TOWN['_lane_polys'],yards=OLD_TOWN['_yards'],cover=OLD_TOWN['_cover'])))
w("const OLD_HOUSES := %s" % lit(OLD_HOUSES))
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
    json.dump(dict(streets=STREETS,omitted_streets=OMITTED_STREETS,opens=OPENS,lots=lots,courts=courts,buildings=[dict(b,angle=ANGLE.get(b['n'],0),corners=corners_of(b) if b['r'] else None,height=HEIGHTS.get(b['n'],0),crown=CROWNS.get(b['n']),form=FORMS.get(b['n'],'block'),part=TOWER_PART.get(b['n']),podium=PODIUM_HEIGHT.get(b['n']),site=TOWER_SITE.get(b['n'])) for b in B],hotel=HOTEL,storey=STOREY,park=PARK,turbines=TURBINES,precincts=PRECINCTS,estate=ESTATE,deck={k:v for k,v in DECK.items() if not k.startswith('_')},wall=WALL,cross=CROSS,crossing=CROSSING,timekeeper=TIMEKEEPER,arch=ARCH,west_gate=WEST_GATE,green=GREEN,train=TRAIN,platforms=PLATFORMS,escalators=ESCALATORS,timetable=TIMETABLE,launch_site=LAUNCH_SITE,old_town=dict(interiors=OLD_TOWN['interiors'],lanes=OLD_TOWN['lanes'],squares=OLD_TOWN['squares'],lane_polys=OLD_TOWN['_lane_polys'],yards=OLD_TOWN['_yards'],cover=OLD_TOWN['_cover']),old_houses=OLD_HOUSES,block_tower=BLOCK_TOWER,lot_kits=LOT_KITS,building_kits=BUILDING_KITS),open(path,'w'))
print('wrote scripts/city_plan.gd:',len(STREETS),'streets,',len(B),'buildings,',len(lots),'lots,',len(courts),'courts')
