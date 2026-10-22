"""P8/P9: one park-ground plan and a coordinated playground construction kit.

World metres and heights above Moy datum. Planning data, not runtime geometry.
"""
import math
from shapely.geometry import Point, Polygon, LineString, box
from shapely.affinity import scale
from shapely.ops import unary_union


def _schedule():
    parts=[];joins=[]
    def p(id,where,shape,semi,col='solid',role='mass',**kw):
        d=dict(id=id,where=where,shape=shape,semi=semi,col=col,role=role)
        if shape in ('egg','clipped'):d['eps']=(5.5,5.5) if role in ('post','beam','rail','floor') else (3.,3.)
        if shape in ('profile','punched'):d['n']=5.5
        if shape in ('box','facet'):d['reason']='continuous cut-to-cut ground/floor or flush bearing; rounded ends would leave open seams'
        d.update(kw);parts.append(d)
    def j(id,kind,ids,plane,rule):joins.append(dict(id=id,kind=kind,parts=ids,plane=plane,rule=rule))
    return parts,joins,p,j


def _polys(shape):
    return [dict(outer=list(p.exterior.coords)[:-1],holes=[list(h.coords)[:-1] for h in p.interiors]) for p in ([shape] if shape.geom_type=='Polygon' else getattr(shape,'geoms',[])) if p.geom_type=='Polygon' and p.area>.01]


def track_safe(pg,q,clear):
    return q.distance(Point(pg['c']))>pg['track'][1]+clear


def build_park_kit(park,crossing,buildings):
    P=park;pg=P['playground'];cx,cz=pg['c'];pr=box(*P['rect']);pond=P['pond'];water=scale(Point(pond['c']).buffer(1,quad_segs=48),*pond['r']);bank=scale(Point(pond['c']).buffer(1,quad_segs=48),pond['r'][0]*pond['bank_top'],pond['r'][1]*pond['bank_top'])
    byid={b['n']:b for b in buildings};houses={str(n):dict(rect=byid[n]['r'],height=4.,door=(byid[n]['r'][2],(byid[n]['r'][1]+byid[n]['r'][3])/2),private='rear keeper/service room; existing upper-flat program remains reserved, no new storey in this pass') for n in (9,10)}
    # Public walking comes from the civic axes, not a separate playground island.
    route_lines=[dict(id='tea_loop',pts=[(-592,0),(-592,42),(-604,42),(-604,30),(-600,30)],w=2.4),dict(id='tea_door',pts=[(-604,30),(-592,30)],w=2.4),dict(id='dry_approach',pts=[(-608,0),(-608,-8)],w=2.4),dict(id='pond_west',pts=[(-541,0),(-541,-7),(-534,-20)],w=2.4),dict(id='pond_east',pts=[(-498,-20),(-496.5,-18),(-496.5,0)],w=2.4),dict(id='lawn_lodge',pts=[(-533,0),(-533,20),(-553,20),(-553,40),(-540,40),(-540,45),(-542,45)],w=2.4),dict(id='play_entry',pts=[(-533,20),(-533,31),(-525.8,31)],w=2.4)]
    boardwalk=dict(id='pond_arch',pts=[(-534,-20),(-498,-20)],width=2.4,structural_width=2.8,y=.08,rise=1.6,depth=.26,rail=1.1,bays=3,arch_drop=1.1,arch_rise=.3,pier_width=.7,reference='scripts/chinese_village_plan_builder.gd: bridge_height and _build_stone_arch_bridge',rule='three visible stone arch barrels and two bed-founded piers carry a gently humped deck; sin-squared rise gives level ends; stone balustrade follows deck, no stairs or roof')
    assert pr.buffer(-2).covers(bank),'pond outer bank breaches2m park buffer'
    bank_clearance=pr.boundary.distance(bank)
    assert pr.covers(LineString(boardwalk['pts']).buffer(1.7,cap_style=3)),'bridge/abutments leave park'
    paths=unary_union([box(*r) for r in P['walks']]+[LineString(r['pts']).buffer(r['w']/2,cap_style=2,join_style=1) for r in route_lines])
    footprints=[box(*byid[n]['r']) for n in (9,10)];towerholes=unary_union([Point(t['c']).buffer(crossing['tower']['drum']) for t in crossing['towers']])
    paths=paths.intersection(pr).difference(bank).difference(towerholes).difference(unary_union(footprints))
    assert paths.geom_type=='Polygon','park path network disconnected'
    # New walking strips may omit low source planting locally; substantial trees stay.
    for t in P['trees']:
        assert paths.distance(Point(t['c']))>.38,('park path at tree trunk',t['c'])
    benches=[dict(c=c,bearing=a) for c,a in [((-535,-7),0),((-500,-7),0),((-619,-4.8),180),((-590,45),90),((-537,42),0),((-500,16),90)]]
    chess=[(-609,42),(-599,34.5),(-586,43)]
    for bench in benches:
        q=Point(bench['c']);assert paths.distance(q)>1.25 and track_safe(pg,q,1.25),('bench in path/track',bench)
    for c in chess:
        q=Point(c);assert paths.distance(q)>1.6,('chess seating in path',c)
    for t in chess:assert not box(*houses['9']['rect']).contains(Point(t))
    land=pr.difference(bank).difference(towerholes).difference(unary_union(footprints))
    track=Point(pg['c']).buffer(pg['track'][1],quad_segs=64)
    soil=land.difference(paths).difference(box(*P['lawn'])).difference(track)
    green=land.difference(paths).difference(box(*P['dry_garden'])).difference(track)
    rain=unary_union([Point(g['c']).buffer(g['r']) for g in crossing.get('rain_gardens',[])])
    green=green.difference(rain)
    dry_ground=soil.difference(green)
    A,J,p,j=_schedule()
    for args in [
        ('ground','earth and terrain excluding pond basin and built sockets','facet',('patchW/2',.1,'patchD/2'),'landing','floor'),
        ('path','connected pale paving, flat top +0.08','profile',('patchW/2',.04,'patchD/2'),'landing','floor'),
        ('gravel','dry garden and unwatered soil grounds','profile',('patchW/2',.02,'patchD/2'),'decorative','mass'),
        ('lawn','broad connected park lawn patches from kit.lawns, flush paths; retains original picnic lawn','profile',('patchW/2',.02,'patchD/2'),'decorative','mass'),
        ('bed_edge','low rounded garden edging, no kerb across paths','profile',(.08,.12,'run/2'),'solid','rail'),
        ('soil','planted soil surface inside bed edge','profile',('W/2',.03,'D/2'),'decorative','mass'),
        ('rock','existing boulder and bank-stone extents from PARK.rocks','egg',('rx','ry','rz'),'solid','mass'),
        ('tree_trunk','NatureProps trunk and principal branch dimensions by existing kind/height','egg',('R','H/2','R'),'solid','mass'),
        ('tree_canopy','NatureProps ghaf/flame/palm/banyan crowns, existing positions','egg',('crownR','crownH/2','crownR'),'decorative','mass'),
        ('shrub','low clumped edge planting, omit at path openings','egg',(.7,.4,.7),'solid','mass'),
        ('reed','shared reed clumps rooted at actual shelf heights','profile',(.035,'H/2',.035),'decorative','mass'),
        ('agave','shared thick natural blades, no pinched tips','egg',(.12,.75,.2),'decorative','mass'),
        ('pond_bed','continuous shared source radial shelves; no invisible paving cap','facet',('rx',1.05,'rz'),'landing','floor'),
        ('water','shared translucent VillageWorks water at -0.3','profile',(16.5,.001,13),'open','mass'),
        ('board_deck','2.4m clear arched stone deck, ends+0.08 and crest+1.68','profile',(1.4,.13,'stripL/2'),'landing','floor'),
        ('board_pier','two stone arch piers embedded into actual pond bed','clipped',(.35,'H/2',1.4),'solid','post'),
        ('bridge_arch','three continuous stone arch barrels, shared extrados/intrados cuts','profile',('bay/2','archH/2',1.4),'solid','beam'),
        ('bridge_abutment','two bank-founded stone abutments, level entry through centres','clipped',(1.2,.4,1.7),'solid','post'),
        ('guard_post','1.1m guards at pond bridge edges','clipped',(.045,.55,.045),'solid','post'),
        ('guard_rail','continuous stone coping over open balustrade','profile',(.045,.045,'run/2'),'solid','rail'),
        ('parasol_stem','six fixed timber parasol columns to canopy bearing','clipped',(.18,2.1,.18),'solid','post'),
        ('parasol_arm','radial timber branches under roof','clipped',(.1,.12,'L/2'),'solid','beam'),
        ('parasol_roof','broad shallow rounded canopy, radii4.2 and height0.65','egg',(4.2,.325,4.2),'solid','mass'),
        ('bench_seat','benches at shade/overlook points','egg',(1.1,.09,.3),'solid','mass'),
        ('bench_leg','two ground-bearing bench supports','clipped',(.12,.2,.22),'solid','post'),
        ('chess_top','square-round stone chess table with abstract carved grid','egg',(.48,.07,.48),'solid','mass'),
        ('chess_base','single pedestal and foot below each tabletop','egg',(.16,.36,.16),'solid','mass'),
        ('chess_stool','four stools around each table, kept off walks','egg',(.22,.22,.22),'solid','mass'),
        ('chess_piece','simple carved game pieces; decorative board, no new chess UI','egg',(.035,.08,.035),'decorative','mass'),
        ('bin','closed refuse/recycling containers beside seating','egg',(.25,.4,.25),'solid','mass'),
        ('light','low path lighting and shaded tea lanterns','egg',(.15,.22,.15),'decorative','mass'),
        ('tea_plinth','building9 socket, one flat floor and level east threshold','box',(7,.18,6),'landing','floor'),
        ('tea_wall','single walls punched at public door and service windows','punched',('wallW/2',1.8,.12),'solid','mass'),
        ('tea_roof','existing 14 by12 envelope, flat louvred roof at4m','clipped',(7,.14,6),'solid','floor'),
        ('door_trim','square-foot rounded-head public opening 2 by2.5m clear','profile',(1.15,1.4,.09),'solid','mass'),
        ('tea_counter','simple serving counter with physical rear service zone','egg',(1.8,.5,.4),'solid','mass'),
        ('tea_table','shared small tables and stools in public room','egg',(.65,.07,.4),'solid','mass'),
        ('tea_cup','shared village tea props, no printed labels','egg',(.07,.07,.07),'decorative','mass'),
        ('lodge_shell','park-lodge existing 10 by8,4m envelope, plain service shell','punched',(5,2,4),'solid','mass'),
        ('lodge_door','east-facing rounded-head service door, actual opening','profile',(.75,1.25,.09),'solid','mass'),
        ('drain','shallow runnels and covered drains below path top','profile',(.12,.06,'run/2'),'decorative','mass')]:p(*args)
    for piece in A:
        if piece['id'] in ('water','reed'):piece['n']=2.0
    j('ground_cut','punched',['ground','pond_bed','path','tea_plinth'],'pond bed, tower drums and building sockets','one physical standing surface per location; clockwise up-facing fronts')
    j('path_seam','meet',['path','gravel','lawn','bed_edge'],'same ground datum and exact patch boundaries','flush edges, no grass/paving overlaps or path kerbs')
    j('pond_bank','chain',['pond_bed','water','reed','rock'],'source bed and waterline','bed/ground meet at bank_top1.15; water -0.3; water hazard uses actual depth queries')
    j('bridge_bearing','seated',['board_deck','bridge_arch','board_pier','bridge_abutment'],'curved deck underside, arch extrados and actual bed/bank','three stone barrels meet deck; two piers embedded below bed; abutments anchored inside park; no floating arch decoration')
    j('bridge_guard','chain',['board_deck','guard_post','guard_rail'],'bridge sides only','guards continuous1.1 above deck, openings at both landings')
    j('parasol_bearing','seated',['parasol_stem','parasol_arm','parasol_roof'],'canopy underside+4.2','arms seated at common stem; shared roof curve, no loose caps')
    j('furniture','seated',['bench_seat','bench_leg','chess_top','chess_base','chess_stool','bin'],'actual floor/ground','legs meet seats and ground; maintain route clearances')
    j('plant_root','seated',['tree_trunk','tree_canopy','shrub','reed','agave','soil'],'surveyed ground and pond shelf','root planting at actual levels; use shared NatureProps, not spikes')
    j('tea_socket','meet',['tea_plinth','tea_wall','tea_roof'],'locked building9 footprint and roof4','walls, floor and roof same envelope; one owner per surface')
    j('tea_opening','punched',['tea_wall','door_trim','tea_counter'],'east public threshold, rear service partition','one real2 by2.5 opening, clearance2m both sides, no hidden wall collider')
    j('lodge_opening','punched',['lodge_shell','lodge_door'],'locked building10 east service threshold','guard private service, no speculative interior or sign text')
    j('drainage','meet',['drain','pond_bed','path'],'pond shelf and path margins','no open trench across route; splash recirculation separate from pond swimming water')
    return dict(version=1,datum=-60,parts=A,joins=J,palette=dict(bridge_stone='#aaa99c',stone='#d2c7ac',sand='#cbb790',gravel='#aa9c81',lawn='#94a575',leaf='#788c63',bloom='#b7868d',timber='#b39c75',steel='#78878a',water='#8ab6b2',ochre='#d6b275',terracotta='#b97f68',net='#688f92',slide='#bc8b9c',rubber='#b5b39a',soil='#8e836b'),routes=route_lines,paths=_polys(paths),dry_ground=_polys(dry_ground),lawns=_polys(green),green_area=round(green.area,2),boardwalk=boardwalk,benches=benches,chess=chess,houses=houses,parasol=dict(radius=4.2,underside=4.2,height=.65),excluded_shrubs=[q for q in P['shrubs'] if paths.distance(Point(q))<1.2],checks=dict(paths_connected=True,tree_trunks_clear=True,pond_bank_clearance=round(bank_clearance,3),bridge_max_grade=round(math.degrees(math.atan(math.pi*boardwalk['rise']/36)),2),parts=len(A),joins=len(J)),ownership='P8 park grounds, boardwalk, parasols, furniture and simple public tea house; P9 playground inside pump-track rim; P7 structures unchanged')


def build_playground_kit(park,crossing):
    pg=park['playground'];cx,cz=pg['c'];outer=pg['track'][1];A,J,p,j=_schedule()
    for args in [
        ('play_ground','playground continuous soft ground inside pump track','profile',(13.2,.08,13.2),'landing','floor'),
        ('track','closed packed-earth annulus with rollers and banked turns','profile',(15.4,.18,15.4),'landing','floor'),
        ('track_edge','flush rounded berms, no fence across tabletop entry','egg',('L/2',.2,.35),'solid','mass'),
        ('dune','three soft SuperEgg sand mounds west of Lookout','egg',('rx','ry','rz'),'solid','mass'),
        ('bounce_floor','recessed soft court south of towers','profile',(3.6,.05,2.4),'landing','floor'),
        ('splash_floor','flat drained splash pad east, physical dry floor','profile',(2.1,.05,3.1),'landing','floor'),
        ('splash_jet','short intermittent jets, separate decorative water','profile',(.035,'H/2',.035),'decorative','mass'),
        ('splash_drain','flush grating and closed recirculating sump','profile',(.14,.025,1.2),'decorative','mass'),
        ('tower_foot','embedded six-foot tower bearings','clipped',(.24,.24,.24),'solid','post'),
        ('tower_post','six rounded-square ochre structural ribs per tower','clipped',(.16,'H/2',.16),'solid','post'),
        ('tower_band','bearing hoops tying tower ribs at each landing','profile',('r',.14,'r'),'solid','beam'),
        ('tower_skin','sculpted canyon panels, cut at bridge and slide exits','punched',('panelW/2','H/2',.12),'solid','mass'),
        ('tower_deck','top lookout and bridge decks, radius by source tower','profile',('r',.12,'r'),'landing','floor'),
        ('tower_guard','guard field with deliberate route/slide openings','profile',('L/2',.55,.07),'solid','rail'),
        ('lookout_ramp','continuous annular ramp to9m shared bridge level','profile',('outerR',.1,'outerR'),'landing','floor'),
        ('ramp_rail','continuous rounded handrail along actual ramp edges','profile',(.045,.045,'L/2'),'solid','rail'),
        ('jump_leaf','Lookout optional spiral landing platforms at1.2m rises','clipped',(.9,.12,.65),'landing','floor'),
        ('bridge_deck','three rope-bridge surfaces at9m,1.6m wide','profile',(.8,.12,'L/2'),'landing','floor'),
        ('bridge_rope','sagging support and guard ropes anchored at ribs','profile',(.035,.035,'L/2'),'solid','rail'),
        ('net_edge','catenary net support ropes, no loose floating corners','profile',(.045,.045,'L/2'),'solid','rail'),
        ('net_strand','visible knitted-net lattice, close shared cell pattern','profile',(.025,.025,'L/2'),'decorative','mass'),
        ('net_surface','matching standable open-net surface, simplified triangulated collider','profile',('W/2',.025,'D/2'),'landing','floor'),
        ('slide_shell','open spiral and wave troughs, tube shell with true hollow centre','profile',('profileW/2',.06,'L/2'),'solid','mass'),
        ('slide_support','real slide brackets/posts to tower ribs or ground','clipped',(.1,'H/2',.1),'solid','post'),
        ('slide_exit','flush run-out onto soft ground, no closed cap at mouth','profile',(.75,.07,1.2),'landing','floor'),
        ('perch_post','three narrow12m perch stems rooted in bounce court','clipped',(.18,6,.18),'solid','post'),
        ('perch_deck','three high bounce perches','egg',(.65,.14,.65),'landing','mass'),
        ('hoop_rim','eight open3m-diameter hoops, wall thickness0.10','profile',(1.5,1.5,.05),'solid','mass'),
        ('hoop_cable','suspension cables tied to playground towers only','profile',(.02,.02,'L/2'),'decorative','mass'),
        ('anchor','visible existing-power swing attachment at real structure','egg',(.12,.12,.12),'solid','mass')]:p(*args)
    for piece in A:
        if piece['id'] in ('track','bridge_rope','net_edge','net_strand','slide_shell','hoop_rim','hoop_cable'):piece['n']=2.0
    j('track_ground','meet',['track','track_edge','play_ground'],'outer15.4 inner13.2; no vertical kerb','closed smooth surface and simplified contact mesh; planned level tabletop entry west')
    j('court','meet',['dune','bounce_floor','splash_floor','play_ground','splash_drain'],'ground top0.08','flush impact surfaces, no loose boards or hazard cap')
    j('tower_bearing','seated',['tower_foot','tower_post','tower_band','tower_deck','tower_skin'],'foot top0, deck9 and source top12/14/16/20','continuous load path and cut openings; no solid proxy tower collider')
    j('ramp_chain','chain',['lookout_ramp','ramp_rail','tower_deck'],'inner1.0 outer2.75; pitch3.3; ground to9','same swept profile and end cuts; real2m headroom and connected landings')
    j('jump_chain','seated',['jump_leaf','tower_post','tower_deck'],'source jump spiral,1.2m rises','optional skill route, no stairs or claim of universal reachability')
    j('bridge_seat','meet',['bridge_deck','bridge_rope','tower_deck','tower_guard'],'three tower-to-Lookout routes at9m','cut correct guard openings; bridge joins deck edge, not tower centre through solid skin')
    j('net_anchor','chain',['net_edge','net_strand','net_surface','tower_post'],'three satellite anchor points at8m; centre sag to6m','all strands and contact mesh share one catenary surface; visible support corners')
    j('slide_cut','punched',['slide_shell','slide_exit','tower_skin','tower_guard','tower_deck'],'top entry and open exit atground','true hollow tube and open trough; trim intersecting bridge/guard geometry')
    j('slide_bearing','seated',['slide_shell','slide_support','tower_post'],'source path brackets at2.5m intervals','no floating slide; supported at real ribs or embedded ground posts')
    j('perch_bearing','seated',['perch_post','perch_deck'],'perch tops12m','same shared bearing plane, no overlapping rounded caps')
    j('hoop_hang','seated',['hoop_rim','hoop_cable','tower_post'],'eight3D centres, source cable anchors','solid rims, open centres; cables end at visible structure, not sky')
    j('swing_anchor','seated',['anchor','tower_post'],'real Lookout and unchanged P7/high-line structures','reuse shared swing tags; no movement retuning or new power framework')
    towers=[]
    for i,t in enumerate(pg['towers']):towers.append(dict(id=i,c=t[:2],h=t[2],r=t[3],bridge_y=9.,ribs=6,top_guard=1.1,skin_fraction=.45))
    bridges=[]
    for t in towers[1:]:
        dx,dz=t['c'][0]-cx,t['c'][1]-cz;d=math.hypot(dx,dz);u=(dx/d,dz/d)
        bridges.append(dict(a=(cx+u[0]*towers[0]['r'],9,cz+u[1]*towers[0]['r']),b=(t['c'][0]-u[0]*t['r'],9,t['c'][1]-u[1]*t['r']),width=1.6))
    net_plan=Polygon([t['c'] for t in towers[1:]]).difference(unary_union([Point(t['c']).buffer(t['r']+.15,quad_segs=24) for t in towers]))
    assert not net_plan.is_empty
    # Fixed-height towers retain the approved0.55 horizontal scale. Hoops stay3m.
    hoops=[dict(c=(q[0],round(6+9*math.sin(i/7*math.pi),3),q[1]),radius=1.5,bearing=round(math.degrees(math.atan2(q[1]-cz,q[0]-cx))+90,3)) for i,q in enumerate(pg['hoops'])]
    def helix(c,r,y1,turns,phase=0,N=144):return [(round(c[0]+r*math.cos(phase+math.tau*turns*i/N),4),round(y1*(1-i/N)+.16,4),round(c[1]+r*math.sin(phase+math.tau*turns*i/N),4)) for i in range(N+1)]
    slide_paths=[dict(kind='spiral',pts=helix((cx,cz),4.2,20,3.25),width=1.5),dict(kind='tube',pts=helix(towers[1]['c'],3.35,16,2.5,math.pi/2),width=1.5),dict(kind='wave',pts=[(cx-2,9,cz+1),(cx-4,7,cz+1),(cx-6,4.8,cz+2),(cx-8,3.7,cz+2),(cx-10,1.2,cz+1),(cx-11,.16,cz)],width=1.5)]
    # All substantial play footprints stay inside the existing pump-track rim.
    for slide in slide_paths:
        assert all(math.hypot(q[0]-cx,q[2]-cz)+slide['width']/2<pg['track'][0] for q in slide['pts'])
    assert math.degrees(math.atan(3.3/(math.tau*1.0)))<32
    return dict(version=1,datum=-60,parts=A,joins=J,towers=towers,bridges=bridges,hoops=hoops,slides=slide_paths,ramp=dict(tower=0,inner=1.,outer=2.75,pitch=3.3,top=9.,width=1.75),net=dict(anchors=[(t['c'][0],8.,t['c'][1]) for t in towers[1:]],centre=(cx,6.,cz+1),grid=.65,patches=_polys(net_plan),rule='trim both visible strands and contact mesh around all four tower envelopes; catenary perimeter ropes anchor at actual ribs, not centres'),dunes=[dict(c=(cx-8,0,cz-3),semi=(3,1.0,2)),dict(c=(cx-9,0,cz+2),semi=(2.5,.8,2)),dict(c=(cx-6,0,cz+5),semi=(2.3,.65,1.7))],bounce=dict(c=(cx,0,cz+10.5),semi=(3.6,.05,2.4)),splash=dict(c=(cx+10,0,cz+1),semi=(2.1,.05,3.1),water='short intermittent recirculated jets; no untreated run-off to swimming pond'),track=dict(inner=pg['track'][0],outer=outer,width=round(outer-pg['track'][0],2),rollers=.35,bank=.45,entry_bearing=180,tabletop='west pedestrian crossing, flat atground; bank/rollers taper away here'),jump_spiral=dict(tower=0,rise=1.2,from_y=9.2,to_y=20.,radius=3.,platform=(1.8,.24,1.3)),anchors=[dict(owner='Lookout',c=(cx,20,cz)),dict(owner='P7 southeast tower',c=(crossing['c'][0]+13,41,crossing['c'][1]+13)),dict(owner='high-line east pier',c=(-506,36,0))],checks=dict(parts=len(A),joins=len(J),slides_inside_track=True,lookout_ramp_grade=round(math.degrees(math.atan(3.3/math.tau)),2)),notes='public ground and9m bridges connected; high perches, hoops and tower tops are optional platforming challenges; no snowboard sandboarding or Penguin slide mechanic')
