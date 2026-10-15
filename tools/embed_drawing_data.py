"""Embed a plan tool's JSON in a drawing page, between /*DATA*/ and /*END*/.

    python3 tools/embed_drawing_data.py docs/drawings/sea_city_3d.html data.json

The page stays openable as it is, and is rebuilt the same way whenever the plan
changes.
"""
import re, sys

page, data = sys.argv[1], open(sys.argv[2]).read().strip()
s = open(page).read()
s2, n = re.subn(r'/\*DATA\*/.*?/\*END\*/', lambda m: '/*DATA*/' + data + '/*END*/', s, flags=re.S)
if n != 1: sys.exit('expected one /*DATA*/ ... /*END*/ block in %s, found %d' % (page, n))
open(page, 'w').write(s2)
print('embedded %d bytes in %s' % (len(data), page))
