class_name CombatMath
extends RefCounted

## Shared RPG combat math: damage variance, occasional critical hits, and
## Defense-based mitigation. Used by every attacker (blorb.gd's jump attack
## and elemental combat stream, player.gd's arm-mounted elemental stream)
## and by Blorb's own take_damage(), so every damage source in the project
## rolls and mitigates the same way instead of each script inventing its own
## formula.
##
## Per direct instruction: hit detection stays deterministic (if an attack's
## own range/timing conditions succeed, it connects -- no accuracy/evasion
## rolls), combined with modest damage variance and occasional critical
## hits, so a successful-looking attack in this real-time action game never
## whiffs, but the numbers it deals still feel like a real RPG rather than a
## fixed hit counter. Strength now drives how hard a blorb's own attacks
## land, and Defense now drives how much damage a blorb shrugs off -- per
## direct correction, replacing their earlier (and unrelated) role scaling
## MP/HP growth on level-up (see blorb.gd's own _level_up()).

## +/-15% -- noticeable hit to hit, without being swingy enough to make a
## fixed base damage unrecognizable.
const DAMAGE_VARIANCE := 0.15
## Roughly 1 in 12-13 attacks -- "occasional," not routine.
const CRIT_CHANCE := 0.08
## A classic double-damage critical -- immediately readable as a crit
## without needing a separate crit-damage stat.
const CRIT_MULTIPLIER := 2.0
## Each point of Strength adds this much flat damage to an attack's base --
## tuned so a level-1 blorb's starting Strength roll (5-15, see blorb.gd's
## STAT_MIN/STAT_MAX) adds a modest 2.5-7.5 on top of a small fixed base,
## without needing a separate "attack power" stat of its own.
const STRENGTH_DAMAGE_SCALE := 0.5
## defense / (defense + K) -- a standard diminishing-returns mitigation
## curve (the same shape many RPGs use for armor/defense): an early roll
## (5-15 Defense) trims a modest ~11-27% off incoming damage, while very
## high late-game Defense asymptotically approaches (but per MAX_MITIGATION
## below, never reaches) full immunity.
const DEFENSE_MITIGATION_K := 40.0
## However high Defense climbs, some damage always gets through -- so a
## strong enough attacker can still eventually threaten even the most
## defensive target.
const MAX_MITIGATION := 0.8
## A hit is never fully absorbed to zero -- guarantees combat can always
## resolve one way or the other.
const MIN_DAMAGE := 1.0


## A single discrete attack roll (a punch, a jump-attack bounce -- anything
## that lands once per swing rather than ticking continuously). `base` is
## whatever fixed damage constant the caller already had (e.g. blorb.gd's
## own JUMP_ATTACK_BASE_DAMAGE); `strength` is the attacker's own Strength
## stat, or 0 for an attacker with no such stat (e.g. skeleton_nme.gd's
## punch). `rng` is the caller's own RandomNumberGenerator -- this project's
## established convention (see blorb.gd's own _rng) over the global
## randf()/randi(), so a roll never shares/consumes state with an unrelated
## system's own random draws.
##
## Returns {"amount": float, "is_critical": bool} -- the boolean isn't
## consumed by any caller yet, but is cheap to carry now for a future
## crit-feedback hook (e.g. a HUD message) without changing this signature
## again later.
static func rolled_attack(base: float, strength: int, rng: RandomNumberGenerator) -> Dictionary:
	var amount := base + float(strength) * STRENGTH_DAMAGE_SCALE
	amount *= rng.randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	var is_critical := rng.randf() < CRIT_CHANCE
	if is_critical:
		amount *= CRIT_MULTIPLIER
	return {"amount": amount, "is_critical": is_critical}


## A continuous per-second damage RATE (a water/fire stream/beam). Boosted
## by Strength the same way a discrete attack is, but deliberately skips the
## variance/crit roll: rolling a crit on every single physics frame of a
## continuous beam wouldn't read as an "occasional critical hit" the way a
## discrete swing does, it would just add noise to the average DPS -- so a
## stream stays a steady (if Strength-scaled) rate instead. Multiply the
## result by `delta` at the call site, same as before.
static func rolled_stream_rate(base_per_second: float, strength: int) -> float:
	return base_per_second + float(strength) * STRENGTH_DAMAGE_SCALE


## Applies a defender's own Defense to a raw incoming damage amount --
## diminishing-returns mitigation (see DEFENSE_MITIGATION_K), capped at
## MAX_MITIGATION so a maxed-out Defense stat never grants full immunity,
## and floored at MIN_DAMAGE so a hit can never be fully absorbed to zero.
static func mitigated_damage(raw_amount: float, defense: int) -> float:
	var mitigation := minf(float(defense) / (float(defense) + DEFENSE_MITIGATION_K), MAX_MITIGATION)
	return maxf(raw_amount * (1.0 - mitigation), MIN_DAMAGE)
