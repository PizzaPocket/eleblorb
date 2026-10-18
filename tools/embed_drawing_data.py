"""Embed a plan tool's JSON in a drawing page, between /*DATA*/ and /*END*/.

    python3 tools/embed_drawing_data.py docs/drawings/sea_city_3d.html data.json

A page that carries a second block names it, between /*NAME*/ and /*END*/:

    python3 tools/embed_drawing_data.py docs/drawings/moy_block_tower_3d.html figure.json FIGURE

The page stays openable as it is, and is rebuilt the same way whenever the plan
changes.
"""
import re, sys

page, data = sys.argv[1], open(sys.argv[2]).read().strip()
name = sys.argv[3] if len(sys.argv) > 3 else 'DATA'
s = open(page).read()
s2, n = re.subn(r'/\*%s\*/.*?/\*END\*/' % name, lambda m: '/*%s*/' % name + data + '/*END*/', s, flags=re.S)
if n != 1: sys.exit('expected one /*%s*/ ... /*END*/ block in %s, found %d' % (name, page, n))
open(page, 'w').write(s2)
print('embedded %d bytes in %s' % (len(data), page))
