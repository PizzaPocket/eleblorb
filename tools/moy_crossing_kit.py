"""P7 planning kit and shared pane/frame topology. Called by city_layout.py.

Coordinates are Crossing-local x/z and heights above city datum. This authors
planning data; it does not replace the runtime builder or certify engineering.
"""
import math
from collections import Counter
from shapely.geometry import Polygon, Point, box
from shapely.ops import triangulate


def build_crossing_kit(crossing, escalators, platforms):
    C=crossing; D=C['dome']; L=D['lattice']; base=D['base']; R=D['drum']['half']; n=D['drum']['n']; dh=D['drum']['h']; ch=D['cupola']['h']
    kit=dict(version=2,datum=-60.0,printed_marks=False,
        palette=dict(marker='#d8143a',steel='#eeeae1',bronze='#927349',glass='#b8d9dc',timber='#c5b691',
                     stone='#c9c7bc',rail='#687b7e',soil='#77715b',leaf='#748a55',flower='#b86c87',ground='#b6b29b'),
        frame=dict(width=L['member'],depth=0.18,n=5.5,fillet=0.006,glass_setback=0.035,
            rule='continuous constant-section profiles, welded flush common-node patches; no six-sided cylinders, capsule ends, ball hubs or overlapping loose struts'),
        references=[dict(name='Queen Elizabeth II Great Court',use='primary: triangulated white steel gridshell and coordinated glass/node geometry'),
            dict(name='Cloud Forest and Flower Dome, Singapore',use='secondary: smooth continuous structural lines and restrained glazing connections, not an extra rib cage')],
        curve_steps=128,well_corner=0.1,lift_shaft=(2.8,2.8),lift_outer=(2.6,2.6),lantern_outer=(3.0,3.0),slab=0.24,guard=1.1,clear_path=2.0,door_clear=(1.5,2.4),eye_sill_depth=0.6,
        lift_stops=[0.0,14.2,37.0,base],lift_cabin=(2.0,2.4),
        notes='P7 finishes the existing Crossing; no street, track, platform, clock-face or tower relocation')
    kit['clock_mount']=dict(radius=8.0, collar_depth=0.3, rule='glass and lattice terminate at outer fixed bezel; opaque clock assembly spans to inner open eye; no glazing behind rotating rings')
    kit['clock_markers']=dict(hour=dict(outline=[[-.62,3.12],[.62,3.12],[.62,4.0],[0,4.88],[-.62,4.0]],shape='broad rectangular base and triangular point'),minute=dict(outline=[[-.35,5.12],[.35,5.12],[0,6.88]],shape='slender triangle'),color='#d8143a')
    P=[]; J=[]
    def part(id,where,shape,semi,col,role='mass',**kw):
        row=dict(id=id,where=where,shape=shape,semi=semi,col=col,role=role)
        if shape in ('egg','clipped'): row['eps']=(5.5,5.5)
        if shape=='profile': row['n']=5.5
        if shape=='box': row['reason']='flush floor, bearing or sealed infill; rounding this surface would open a seam'
        row.update(kw); P.append(row)
    def join(id,kind,parts,plane,rule):J.append(dict(id=id,kind=kind,parts=parts,plane=plane,rule=rule))
    part('foundation','surveyed embedded support foundations','box',('supportW/2',0.4,'supportD/2'),'solid','floor')
    part('trunk','four primary tower trunks, continuous to head beams','clipped',(1.2,20.5,1.2),'solid','post',join='tower_bearing')
    part('rib','eight continuous ribs per tower on recorded drum radius','clipped',(0.22,20.5,0.22),'solid','post',join='tower_bearing')
    part('hoop','tower hoops at recorded heights, coordinated with openings','profile',('drum',0.08,'drum'),'solid')
    part('mesh_sleeve','stainless support mesh between ribs, cut at exits','profile',('drum','panelH/2','drum'),'decorative')
    part('helix_tread','two closed annular bands per tower, from recorded hands.profile','profile',('outerR',0.45,'outerR'),'landing')
    part('helix_soffit','solid closed underside; same tread section and landing cuts','profile',('outerR',0.45,'outerR'),'solid')
    part('helix_handrail','continuous constant-section rail swept along helix','profile',(0.045,0.045,'run/2'),'solid')
    part('helix_guard','guard field with true openings at hand landings','profile',('run/2',0.55,0.06),'solid')
    part('gallery_floor','annulus outside r=4.02 to recorded gallery radius','profile',('galleryR',0.12,'galleryR'),'landing')
    part('guard','gallery/ring/landing guard, clipped around real access','clipped',('run/2',0.55,0.06),'solid','rail',join='guard_chain')
    part('way_out','flat exit tongue from actual gallery to route landing','profile',('run/2',0.12,1.2),'landing')
    part('spine_head_beam','two head beams at +10.4 to +12.0','clipped',('span/2',0.8,0.7),'solid','beam',join='tower_bearing')
    part('high_head_beam','head beams at +30.6 to +32.6','clipped',(0.9,1.0,'span/2'),'solid','beam',join='tower_bearing')
    part('bridge_hanger','cross-bridge hangers seated to the spine beams','clipped',(0.08,'L/2',0.08),'solid','post',join='bridge_bearing')
    part('cross_bridge','two Deck-level bridges between opposite galleries','profile',('run/2',0.12,'width/2'),'landing')
    part('ring_girder','garden ring, inner 24.7 outer 32.7, depth1.6','profile',(32.7,0.8,32.7),'solid')
    part('ring_floor','ring top +6.5, one collision owner','profile',(32.7,0.12,32.7),'landing')
    part('ring_support','eight planned supports, no added forest of posts','clipped',(0.3,'L/2',0.3),'solid','post',join='ring_bearing')
    part('lift_guide','four glazed lift guides, shaft cut through slabs','clipped',(0.12,'rise/2',0.12),'solid','post',join='lift_landing')
    part('lift_car','shared lift car, clear 2 by2.4 m, not character-specific','box',(1.0,1.3,1.2),'landing')
    part('lift_landing','served-level landing, physical route to every call','profile',('landingW/2',0.12,'landingD/2'),'landing')
    part('lift_door','shared openable leaves only at served levels','clipped',(0.375,1.2,0.06),'solid','leaf',join='lift_landing')
    part('call_control','existing shared non-text lift interaction control','egg',(0.16,0.12,0.1),'solid',eps=(3.0,3.0))
    part('lantern_glass','four lift lanterns on Clock Room floor, door toward bell','wall',('lanternW/2',1.7,0.06),'solid','wall',outline='lift_landing')
    part('platform_floor','existing Spine +14.2 and Meridian +37 platform profiles','profile',('length/2',0.12,'width/2'),'landing')
    part('platform_edge','existing boarding edge, correct train clearance','clipped',('length/2',0.1,0.15),'solid','beam',join='platform_join')
    part('platform_canopy','shared louvred/glass shelter at existing height','profile',('length/2',0.15,'width/2'),'solid')
    part('roof_structure','rounded-square louvred table top +41.6, underside+41','profile',(22,0.3,22),'solid')
    part('roof_louvre','constant-section timber louvre on roof framing','clipped',('run/2',0.08,0.05),'solid','beam',join='roof_bearing')
    part('roof_glass','glazing between louvres, coordinated with Clock Room floor','profile',('paneW/2',0.012,'paneD/2'),'solid')
    part('roof_rim','planted roof rim within recorded width1.4','profile',(22,0.25,22),'solid')
    part('gutter','continuous roof drainage routed into trunks','profile',('run/2',0.08,0.12),'solid')
    part('clock_floor','terrazzo +41.6 with actual wells and lift apertures','box',('floorW/2',0.16,'floorD/2'),'landing')
    part('arrival_widening','two platform widenings, exactly recorded rectangles','box',('W/2',0.16,'D/2'),'landing')
    part('arrival_tread','four shared escalator pairs +37 to+41.6','profile',('run/2',0.45,1.6),'landing')
    part('arrival_soffit','closed underside ends flush at common bearing planes','profile',('run/2',0.45,1.6),'solid')
    part('arrival_handrail','shared escalator rail, continuous through runoffs','profile',('run/2',0.04,0.045),'solid')
    part('well_guard','clear glass on bronze shoe, open at actual discharge','profile',('run/2',0.55,0.06),'solid')
    part('well_shoe','bronze shoe follows same guard boundary','clipped',('run/2',0.04,0.06),'solid','beam',join='arrival_well')
    part('frame_member','white steel constant superellipse cross-section from shared nodes','profile',(0.035,0.09,'L/2'),'solid',n=5.5)
    part('frame_node','welded flush valence-dependent node patch, same section depth','profile',('node_extent/2',0.09,'node_extent/2'),'solid',n=5.5,reason='shared trimmed incident profiles union into one smooth patch; not a larger sphere')
    part('glass_pane','each pane polygon from shared grid, eye cut applied once','profile',('paneW/2',0.006,'paneH/2'),'solid')
    part('pane_seal','recessed continuous gasket within frame width','profile',(0.011,0.006,'L/2'),'decorative')
    part('eye_sleeve','bronze trim around the exact circular/flat-sill cutter','profile',('eyeR',0.06,'eyeR'),'solid')
    part('eye_sill','flat sill top +47.7, clear chord3.07 and depth0.6','clipped',('chord/2',0.06,0.3),'landing','beam',join='eye_cut')
    part('crown_tie','small true crown ring, top at upper grid boundary, depth0.45; no drum cage','profile',(3.0,0.225,3.0),'solid')
    part('crown_cap','shallow clipped glazing closes above crown without hanging bowl','profile',(3.0,'capH',3.0),'solid')
    part('bell_hanger','four0.24 by0.45 crown arms and0.24 vertical hanger/yoke','clipped',(0.12,'L/2',0.225),'solid','beam',join='bell_bearing',rod_semi=(0.12,'L/2',0.12))
    part('bell','proper hollow flared bronze bell, mouth4.4 height4.6','profile',(2.2,2.3,2.2),'solid',n=2.0)
    part('bell_clapper','shared scheduled clapper, physical bronze object','egg',(0.12,1.3,0.12),'solid',eps=(3.0,3.0))
    part('clock_hour','four rotating hour rings, radii3 to5','profile',(5,5,0.08),'solid')
    part('clock_minute','four rotating minute rings, radii5 to7','profile',(7,7,0.08),'solid')
    part('clock_bezel','four fixed bezels, radii7 to8, plus outer-radius8 collar depth0.3 joining shell','profile',(8,8,0.08),'solid')
    part('clock_arrow','two distinct magenta profiles from kit.clock_markers, broad shouldered hour and slender triangular minute; no lettering or numeral','profile',('arrowW/2','arrowH/2',0.05),'decorative')
    part('clock_tick','raised abstract ticks, not printed numerals','clipped',(0.06,0.2,0.04),'decorative','trim')
    part('rose','flush bronze compass pictogram under bell','decal',(3.6,0.002,3.6),'decorative')
    part('bench_seat','seating beside wells and along ring, clear of paths','egg',(1.1,0.09,0.3),'solid',eps=(3.0,3.0))
    part('bench_leg','flat-capped supports to bench underside','clipped',(0.1,0.195,0.22),'solid','post',join='furniture_bearing')
    part('planter','physical planters at recorded gallery, ring and room locations','egg',('W/2','H/2','D/2'),'solid')
    part('soil','soil seated inside planter rim','profile',('W/2',0.03,'D/2'),'solid')
    part('tree_trunk','shared NatureProps ghaf, substantial trunk physical','profile',('sharedR','sharedH/2','sharedR'),'solid')
    part('plant_canopy','shared desert planting/vines, tips explicitly decorative','egg',('R','H/2','R'),'decorative',eps=(3.0,3.0))
    part('rain_basin','shelving rain garden below landing, no raised lip','profile',('basinR','depth/2','basinR'),'solid')
    part('desk','simple public information/lost-property counter shell','egg',(1.5,0.55,0.45),'solid')
    part('kiosk_shell','plain kiosk shell, no invented merchant service','wall',('W/2','H/2',0.08),'solid','wall',outline='kiosk_opening')
    part('kiosk_counter','closed kiosk counter clear of ring route','egg',(1.2,0.55,0.45),'solid')
    part('fountain','physical drinking-water fixture with basin','egg',(0.3,0.5,0.3),'solid',eps=(3.0,3.0))
    part('waste_bin','physical small bin beside seating, not in path','egg',(0.25,0.4,0.25),'solid')
    part('light_fixture','warm station/Clock Room fixtures, no text signage','egg',(0.15,0.12,0.15),'solid')
    join('tower_bearing','seated',['foundation','trunk','rib','spine_head_beam','high_head_beam','roof_structure'],'foundation0; spine10.4/12; high30.6/32.6; roof41','members cap at bearing planes; align load paths through the four towers')
    join('helix_chain','chain',['helix_tread','helix_soffit','helix_handrail','helix_guard'],'every hand.profile angle/height transition','one continuous closed section; no height seams, hanging underside or railing at flat exit')
    join('gallery_exit','meet',['helix_tread','gallery_floor','way_out'],'recorded way_out bearing and y','derive flush tongue and opening from common profile; keep inner radius >=4.02')
    join('guard_chain','chain',['guard','helix_guard','gallery_floor','ring_floor','way_out'],'explicit route apertures and landing edges','open guards at actual routes; continuous elsewhere, no railing stumps in path')
    join('bridge_bearing','seated',['cross_bridge','bridge_hanger','spine_head_beam','gallery_floor'],'Deck+6.5; hangers into spine beams','one floor owner; hanger ends seated, no bridge through tower or helix')
    join('ring_bearing','seated',['ring_support','ring_girder','ring_floor','trunk'],'ring top6.5, underside4.9','support at eight recorded points and towers, keep ground routes open')
    join('lift_landing','punched',['lift_guide','lift_car','lift_door','lift_landing','lantern_glass','gallery_floor','clock_floor'],'only stops0/14.2/37/41.6','cut shafts and connect real landings to every call; remove unserved6.5 calls, no ghost stops')
    join('platform_join','meet',['platform_floor','platform_edge','way_out','platform_canopy'],'Spine14.2, Meridian37, existing boarding edges','preserve track envelope; no rail/post in boarding or tower approach')
    join('roof_bearing','seated',['roof_structure','roof_louvre','roof_glass','roof_rim','gutter','rib'],'underside41; roof/Clock Room top41.6','coordinate whole roof/floor volume and holes; one collider, not overlapping roof and terrazzo tiles')
    join('arrival_well','punched',['clock_floor','roof_structure','arrival_tread','arrival_soffit','arrival_handrail','well_guard','well_shoe','arrival_widening'],'existing arrivals.well and y37 to41.6','one cutter through roof and floor; runoff free, guard only three sides and open at discharge')
    join('grid_node','chain',['frame_member','frame_node','pane_seal'],'shared node IDs and incident edge tangent/section frames','trim to common node patch, weld closed topology, smooth/weighted normals; merge batching alone is not a welded joint')
    join('glass_seat','seated',['frame_member','frame_node','glass_pane','pane_seal'],'same pane boundaries, inset under frame seats','one shared grid for skin/frame; no independent radius formula or struts sunk through glass')
    join('eye_cut','punched',['frame_member','frame_node','glass_pane','eye_sleeve','eye_sill','clock_hour'],'outer bezel circle r8 for shell; inner clear eye r2.85 clipped below sill47.7','terminate members/glass at outer bezel; preserve inner eye through clock assembly; subtract identical inner eye volume from clock/collision; flat sill, no bars through eye')
    join('crown_join','chain',['frame_member','frame_node','crown_tie','crown_cap'],'last nonzero ring radius3 and cap top69.6','truncate before apex collapse; continuous crown tie, no zero-length bars or buried half shell')
    join('bell_bearing','seated',['crown_tie','bell_hanger','bell','bell_clapper'],'existing bell bottom/top and crown ring','four arms carry hanger; no floating bell, clocks never intersect the hanging assembly')
    join('clock_turn','placed',['clock_hour','clock_minute','clock_bezel','clock_arrow','clock_tick','eye_sleeve'],'four cardinal clock planes, centre50.1','rotation about common centre, shared game time, no seconds bead or printed numerals')
    join('furniture_bearing','seated',['bench_seat','bench_leg','planter','soil','tree_trunk','desk','fountain','waste_bin'],'actual floor/terrain top','supports meet physical ground; maintain2 m public route and landing clearance')
    join('kiosk_opening','punched',['kiosk_shell','kiosk_counter'],'rounded shop opening over counter','sealed service shell at L4, no unstaffed mechanic or invented sign text')
    kit['parts']=P; kit['joins']=J
    kit['lift_serving']=[]
    for x in D['room']['lifts']:
        dx,dz=C['c'][0]-x['c'][0],C['c'][1]-x['c'][1];dist=math.hypot(dx,dz);u=(dx/dist,dz/dist)
        kit['lift_serving'].append(dict(tower=x['tower'],stops=x['stops'],c=x['c'],toward=u,
            call=(round(x['c'][0]+u[0]*3.0,4),round(x['c'][1]+u[1]*3.0,4)),apron=(1.3,3.8),width=2.4))
    kit['garden_beds']=[dict(c=(sx*14.0,base,sz*6.0),size=(3.2,.6,1.4),plants='desert grasses and low flowering shrubs',canopy_height=1.0) for sx in (-1,1) for sz in (-1,1)]
    # Beds stay away from diagonal arrival wells and central compass rose.
    for bed in kit['garden_beds']:
        x,y,z=bed['c'];assert abs(x)+bed['size'][0]/2<18 and abs(z)+bed['size'][2]/2<8
    kit['furniture']=[]
    for bearing in (45,135,225,315):
        a=math.radians(bearing)
        kit['furniture'].append(dict(kind='bench',c=(round(16.5*math.cos(a),3),base,round(16.5*math.sin(a),3)),bearing=bearing))
        kit['furniture'].append(dict(kind='planter',c=(round(20.5*math.cos(a),3),base,round(20.5*math.sin(a),3)),bearing=bearing))
        kit['furniture'].append(dict(kind='bench',c=(round(30.7*math.cos(a),3),6.5,round(30.7*math.sin(a),3)),bearing=bearing))
    for bearing,kind,r in [(22.5,'kiosk',26.5),(202.5,'kiosk',26.5),(112.5,'desk',30.5),(292.5,'fountain',30.5)]:
        a=math.radians(bearing);kit['furniture'].append(dict(kind=kind,c=(round(r*math.cos(a),3),6.5,round(r*math.sin(a),3)),bearing=bearing))
    # Exact annulus-derived junctions, not rectangles that fill helix voids.
    from shapely.affinity import rotate, translate
    kit['bridges']=[]
    for z in (-13.0,13.0):
        shape=box(-13,z-3,13,z+3)
        for x in (-13,13):shape=shape.difference(Point(x,z).buffer(C['tower']['gallery_r'][1],quad_segs=32))
        assert shape.geom_type=='Polygon'
        kit['bridges'].append(list(shape.exterior.coords)[:-1])
    kit['ring_tongues']=[]
    ring_inside=Point(0,0).buffer(C['ring'][0],quad_segs=32)
    for tw in C['towers']:
        x,z=tw['c'][0]-C['c'][0],tw['c'][1]-C['c'][1];a=math.atan2(z,x)
        strip=rotate(box(0,-1.2,C['ring'][0]+.5,1.2),math.degrees(a),origin=(0,0))
        shape=strip.intersection(ring_inside).difference(Point(x,z).buffer(C['tower']['gallery_r'][1],quad_segs=32))
        # Only the gap outside the tower's outer gallery belongs to the tongue.
        shape=shape.intersection(rotate(box(math.hypot(x,z),-1.2,C['ring'][0]+.5,1.2),math.degrees(a),origin=(0,0)))
        assert shape.geom_type=='Polygon'
        kit['ring_tongues'].append(list(shape.exterior.coords)[:-1])
    # Public ring corridor and north/south Deck approaches remain clear.
    route=Point(0,0).buffer(29.7,quad_segs=64).difference(Point(0,0).buffer(27.7,quad_segs=64))
    route=route.union(box(-3,-34,3,34).intersection(Point(0,0).buffer(33).difference(Point(0,0).buffer(24))))
    for item in kit['furniture']:
        x,y,z=item['c']
        if abs(y-6.5)>.01:continue
        w,d={'bench':(2.2,.6),'kiosk':(2.4,1.5),'desk':(3,.9),'fountain':(.6,.6)}[item['kind']]
        foot=translate(rotate(box(-w/2,-d/2,w/2,d/2),item['bearing']-90,origin=(0,0)),xoff=x,yoff=z)
        assert not foot.intersects(route),('furniture in station route',item)
    kit['grid']=_grid(D)
    for item in list(kit['furniture']):
        if item['kind']!='bench':continue
        x,y,z=item['c'];a=math.radians(item['bearing']);kit['furniture'].append(dict(kind='bin',c=(round(x-1.7*math.sin(a),4),y,round(z+1.7*math.cos(a),4)),bearing=item['bearing']))
    for bearing in (45,135,225,315):
        a=math.radians(bearing);ids=[i for i in kit['grid']['rows'][1] if i>=0];i=min(ids,key=lambda i:abs(math.atan2(math.sin(math.atan2(kit['grid']['nodes'][i][2],kit['grid']['nodes'][i][0])-a),math.cos(math.atan2(kit['grid']['nodes'][i][2],kit['grid']['nodes'][i][0])-a))))
        x,y,z=kit['grid']['nodes'][i];r=math.hypot(x,z);kit['furniture'].append(dict(kind='light',c=(x*(r-.12)/r,y,z*(r-.12)/r),bearing=bearing))
    kit['checks']=dict(parts=len(P),joins=len(J),grid=kit['grid']['counts'],boundary_loops=6,euler=-4,public_ring_clear=True)
    return kit


def _grid(D):
    R=D['drum']['half']; n=D['drum']['n']; dh=D['drum']['h']; ch=D['cupola']['h']; base=D['base']; L=D['lattice']
    vc=math.sqrt(1-(L['crown']/R)**2)
    # Axis-meridian arclength; vertical drum is C1 with the elliptical cupola.
    mer=[(1.0,dh*i/200) for i in range(201)]+[(math.sqrt(1-(vc*i/600)**2),dh+ch*vc*i/600) for i in range(1,601)]
    acc=[0.0]
    for a,b in zip(mer,mer[1:]):acc.append(acc[-1]+math.hypot((b[0]-a[0])*R,b[1]-a[1]))
    def at(d):
        import bisect
        j=min(len(acc)-1,max(1,bisect.bisect_left(acc,d)));t=(d-acc[j-1])/(acc[j]-acc[j-1]);a,b=mer[j-1],mer[j]
        return a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])
    # Uniform perimeter spacing avoids bunching members around rounded corners.
    curve=[]
    for i in range(1441):
        a=2*math.pi*i/1440;den=(abs(math.cos(a))**n+abs(math.sin(a))**n)**(1/n);curve.append((R*math.cos(a)/den,R*math.sin(a)/den))
    lens=[0.0]
    for a,b in zip(curve,curve[1:]):lens.append(lens[-1]+math.dist(a,b))
    def perimeter(u):
        import bisect
        d=(u%1)*lens[-1];j=min(1440,max(1,bisect.bisect_left(lens,d)));t=(d-lens[j-1])/(lens[j]-lens[j-1]);a,b=curve[j-1],curve[j]
        return a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])
    ds=[dh*i/math.ceil(dh/L['row']) for i in range(math.ceil(dh/L['row'])+1)]
    extra=acc[-1]-dh;K=math.ceil(extra/L['row']);ds += [dh+extra*i/K for i in range(1,K+1)]
    nodes=[];lookup={}
    def node(p):
        q=tuple(round(float(v),6) for v in p)
        if q not in lookup:lookup[q]=len(nodes);nodes.append(q)
        return lookup[q]
    rows=[]
    for d in ds:
        scale,h=at(d);N=max(16,8*round(L['around']*scale/8));ids=[]
        for j in range(N):x,z=perimeter(j/N);ids.append(node((x*scale,base+h,z*scale)))
        rows.append(ids)
    raw=[]
    for k,(a,b) in enumerate(zip(rows,rows[1:])):
        i=j=0;na,nb=len(a),len(b)
        while i<na or j<nb:
            u=(i+1)/na if i<na else 2;v=(j+1)/nb if j<nb else 2
            if abs(u-v)<1e-9:
                if k%2:raw.extend([(a[i%na],a[(i+1)%na],b[(j+1)%nb]),(a[i%na],b[(j+1)%nb],b[j%nb])])
                else:raw.extend([(a[i%na],a[(i+1)%na],b[j%nb]),(a[(i+1)%na],b[(j+1)%nb],b[j%nb])])
                i+=1;j+=1
            elif u<v:raw.append((a[i%na],a[(i+1)%na],b[j%nb]));i+=1
            else:raw.append((a[i%na],b[(j+1)%nb],b[j%nb]));j+=1
    ey=D['clocks']['eye'];ey_y=base+D['clocks']['centre'];sill=ey['sill_y']
    mount_r=8.0
    hole=Point(0,ey_y).buffer(mount_r,quad_segs=64)
    panes=[];faces=[]
    def orient(ids):
        a,b,c=[nodes[i] for i in ids];ab=[b[i]-a[i] for i in range(3)];ac=[c[i]-a[i] for i in range(3)]
        cr=(ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]);cen=[sum(p[i] for p in (a,b,c))/3 for i in range(3)]
        normal=(cen[0],max(0,cen[1]-base-dh),cen[2])
        return list(ids) if sum(cr[i]*normal[i] for i in range(3))>=0 else [ids[0],ids[2],ids[1]]
    for tri in raw:
        xyz=[nodes[i] for i in tri];choice=None
        for angle in D['clocks']['bearings']:
            a=math.radians(angle);ux,uz=math.cos(a),math.sin(a)
            if min(p[1] for p in xyz)>ey_y+mount_r or max(p[1] for p in xyz)<ey_y-mount_r:continue
            if max(p[0]*ux+p[2]*uz for p in xyz)<R*.88:continue
            uv=[(-p[0]*uz+p[2]*ux,p[1]) for p in xyz];poly=Polygon(uv)
            if poly.area>1e-9 and poly.intersects(hole):choice=(ux,uz,uv,poly.difference(hole));break
        if choice is None:panes.append(list(tri));faces.append(orient(tri));continue
        ux,uz,uv,geom=choice
        u0,y0=uv[0];u1,y1=uv[1];u2,y2=uv[2];den=(u1-u0)*(y2-y0)-(u2-u0)*(y1-y0)
        def back(q):
            u,y=q;v=((u-u0)*(y2-y0)-(u2-u0)*(y-y0))/den;w=((u1-u0)*(y-y0)-(u-u0)*(y1-y0))/den
            return node(tuple(xyz[0][i]+v*(xyz[1][i]-xyz[0][i])+w*(xyz[2][i]-xyz[0][i]) for i in range(3)))
        for poly in ([geom] if geom.geom_type=='Polygon' else getattr(geom,'geoms',[])):
            if poly.area<1e-9:continue
            assert not poly.interiors,'unexpected hole wholly inside one pane'
            panes.append([back(q) for q in list(poly.exterior.coords)[:-1]])
            for t in triangulate(poly):
                if poly.buffer(1e-8).covers(t):faces.append(orient([back(q) for q in list(t.exterior.coords)[:3]]))
    used=sorted({i for pane in panes for i in pane}|{i for tri in faces for i in tri});remap={old:i for i,old in enumerate(used)}
    nodes=[nodes[i] for i in used];panes=[[remap[i] for i in pane] for pane in panes];faces=[[remap[i] for i in tri] for tri in faces]
    rows=[[remap.get(i,-1) for i in row] for row in rows]
    counts=Counter(tuple(sorted((a,b))) for pane in panes for a,b in zip(pane,pane[1:]+pane[:1]) if a!=b)
    edges=[list(e) for e in sorted(counts)]
    boundary=[list(e) for e,c in counts.items() if c==1]
    assert all(c<=2 for c in counts.values()),'nonmanifold pane boundary'
    assert all(math.dist(nodes[a],nodes[b])>1e-5 for a,b in edges),'zero length member'
    # Every open boundary is intentional: base, nonzero crown or one clock eye.
    cy=base+mer[-1][1]
    def eye_boundary(p):
        for angle in D['clocks']['bearings']:
            a=math.radians(angle);along=p[0]*math.cos(a)+p[2]*math.sin(a);u=-p[0]*math.sin(a)+p[2]*math.cos(a)
            if along<R*.88:continue
            if abs(math.hypot(u,p[1]-ey_y)-mount_r)<.006:return True
        return False
    for a,b in boundary:
        mid=tuple((nodes[a][i]+nodes[b][i])/2 for i in range(3))
        assert abs(mid[1]-base)<.001 or abs(mid[1]-cy)<.001 or eye_boundary(mid),('unintended grid crack',mid)
    adj={}
    for a,b in boundary:adj.setdefault(a,[]).append(b);adj.setdefault(b,[]).append(a)
    assert all(len(v)==2 for v in adj.values()),'open or branched boundary loop'
    loops=[];seen=set()
    for seed in sorted(adj):
        if seed in seen:continue
        loop=[];cur=seed;prev=None
        while cur not in seen:
            seen.add(cur);loop.append(cur);nxt=adj[cur][0] if adj[cur][0]!=prev else adj[cur][1];prev,cur=cur,nxt
        av=[sum(nodes[i][k] for i in loop)/len(loop) for k in range(3)]
        kind='base' if abs(av[1]-base)<.001 else 'crown' if abs(av[1]-cy)<.001 else 'eye'
        loops.append(dict(kind=kind,nodes=loop))
    assert len(loops)==6 and len(nodes)-len(edges)+len(panes)==-4,'grid genus/boundaries inconsistent'
    reached={0};todo=[0];fulladj={}
    for a,b in edges:fulladj.setdefault(a,[]).append(b);fulladj.setdefault(b,[]).append(a)
    while todo:
        for j in fulladj[todo.pop()]:
            if j not in reached:reached.add(j);todo.append(j)
    assert len(reached)==len(nodes),'disconnected frame grid'
    crown_ids=rows[-1];N=len(crown_ids);cap_nodes=[nodes[i] for i in crown_ids];cap_faces=[]
    for k in range(1,8):
        v=vc+(1-vc)*k/8;scale=R*math.sqrt(1-v*v)/L['crown'];y=base+dh+ch*v
        cap_nodes += [(round(nodes[i][0]*scale,6),round(y,6),round(nodes[i][2]*scale,6)) for i in crown_ids]
    for k in range(7):
        for i in range(N):
            a=k*N+i;b=k*N+(i+1)%N;c=a+N;d=b+N;cap_faces += [[a,c,d],[a,d,b]]
    apex=len(cap_nodes);cap_nodes.append((0.0,base+dh+ch,0.0))
    for i in range(N):cap_faces.append([7*N+i,apex,7*N+(i+1)%N])
    cap=dict(nodes=cap_nodes,faces=cap_faces,base_ids=crown_ids,rule='same elliptical meridian and superellipse plan, one apex; no duplicate pole vertices')
    # A real welded six-way patch for the model detail: union the incident strip
    # footprints in the node tangent plane, then fillet concave weld corners.
    from shapely.ops import unary_union
    neighbours={i:[] for i in range(len(nodes))}
    for a,b in edges:neighbours[a].append(b);neighbours[b].append(a)
    detail_id=next(i for i,p in enumerate(nodes) if len(neighbours[i])==6 and base+dh-3<p[1]<base+dh and p[0]>R*.85)
    o=nodes[detail_id];normal=[o[0]**3,0,o[2]**3];ln=math.hypot(normal[0],normal[2]);normal=[v/ln for v in normal]
    tangent=(-normal[2],0,normal[0]);strips=[]
    for j in neighbours[detail_id]:
        v=[nodes[j][k]-o[k] for k in range(3)];x=sum(v[k]*tangent[k] for k in range(3));y=v[1];le=math.hypot(x,y);x,y=x/le*.65,y/le*.65;nx,ny=-y/.65*.035,x/.65*.035
        strips.append(Polygon([(nx,ny),(x+nx,y+ny),(x-nx,y-ny),(-nx,-ny)]))
    patch=unary_union(strips).buffer(.006,quad_segs=8).buffer(-.006,quad_segs=8)
    assert patch.geom_type=='Polygon' and not patch.interiors
    detail=dict(node=detail_id,outline=[list(q) for q in list(patch.exterior.coords)[:-1]],depth=.18,fillet=.006,
        note='one unioned constant-width six-way patch; flat cut ends; no separate spherical hub')
    return dict(cap=cap,boundary_loops=loops,detail=detail,nodes=nodes,edges=edges,panes=panes,glass_faces=faces,rows=rows,boundary=boundary,
        crown_y=round(cy,6),cap_top=base+dh+ch,eye_centre_y=ey_y,sill_y=sill,
        counts=dict(nodes=len(nodes),members=len(edges),panes=len(panes),glass_triangles=len(faces)),
        convention='shared XYZ node IDs; glass triangles CCW outward for browser, reverse for Godot clockwise fronts',
        checks='connected grid; unique nonzero members; pane edge valence<=2; six closed boundaries, Euler=-4; no stray cracks')
