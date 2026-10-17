# Ohio proximity music repair

`distance_music.gd` enabled forward looping on the imported WAV but left its loop endpoints at their non-looping defaults, 0..0. An isolated audio probe reproduced a playback cursor stuck at one sample (0.0000227 s), even though the player reported `playing=true`. The listener path resolved correctly.

The duplicated stream now explicitly loops from sample 0 through all 1,495,040 samples (33.901 s at 44.1 kHz). The source asset and its import settings are unchanged.

Verified with Godot's actual decoder and AudioEffectCapture: playback advances, captured peak amplitude rises from 0.000413 to 0.205, and seeking near the end wraps back to the beginning while continuing playback. Distance checks pass for town volume, the approach fade and silence outside the configured radius. These checks used the real Ohio WAV and music script in an isolated project; no broader music or world-loading behavior was changed.
