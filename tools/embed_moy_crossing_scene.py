"""Embed the one P7 scene in both standalone HTML models; --check verifies parity.

The embedded copies keep each downloaded HTML usable as a single model file.
Edit docs/drawings/moy_crossing_scene.js, never the generated scene blocks.
"""
from pathlib import Path
import re
import sys

root=Path(__file__).resolve().parents[1]
source=(root/'docs/drawings/moy_crossing_scene.js').read_text().strip()
pattern=re.compile(r'/\*P7_SCENE\*/.*?/\*END\*/',re.S)
block='/*P7_SCENE*/\n'+source+'\n/*END*/'
check='--check' in sys.argv
for name in ('moy_crossing_3d.html','moy_park_playground_3d.html'):
    page=root/'docs/drawings'/name
    text=page.read_text()
    matches=list(pattern.finditer(text))
    if len(matches)!=1:raise SystemExit(f'{name}: expected exactly one generated P7_SCENE block')
    if check:
        if matches[0].group()!=block:raise SystemExit(f'{name}: embedded P7 scene is stale')
    else:page.write_text(pattern.sub(lambda _:block,text))
print('Both model pages use the identical canonical P7 scene'+(' (verified)' if check else ' (embedded)'))
