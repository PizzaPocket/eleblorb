# Chinese garden pine

Reusable prop: `NatureProps.build_chinese_pine(height, seed_value)` in
`scripts/nature_props.gd`. Returns a `StaticBody3D`; callers position and rotate
that root like the other NatureProps trees. Height is in world metres.

The model's sculpted pine supplies the silhouette: an exposed, bent trunk,
unequal lateral branches and separated, cloud-pruned foliage pads. The game
version uses overlapping flattened SuperEgg lobes, an irregular leader and
alternating branch bearings. A seed changes the lean, branch heights, reaches,
pad proportions and foliage tones; a repeated seed reproduces the specimen.
The top remains compact and the broad lower pads are off the trunk's axis.
The leader is one tapering sweep through the bent trunk, with branches embedded
into it. Unequal branch intervals and thin overlapping SuperEgg foliage lobes
preserve negative space between the pruned canopy pads.

Trunks, branches and the cores of broad pruned pads have collision. Fine lobe
edges remain visual. Static specimens can use `StaticMerge.merge(tree)` after
construction; China includes them in its generated geometry cache.

Placement is part of the prop's use. Garden pines occupy the model's dedicated
corners, separate from the pavilion and pool crossing. Rim specimens are
seeded by island and sample index, with conservative exclusions around plots,
paths and bridgehead aprons. Reloading the region does not reseed its trees.

For an isolated comparison, run `tools/chinese_pine_gallery.tscn`. It renders
four specimens, seeds 41–44, to `wip/tree_audit/chinese_pine_variants.png` without
staging the world. The China runtime validator checks equal-seed reproduction,
different-seed variation and structural/landing collision.
