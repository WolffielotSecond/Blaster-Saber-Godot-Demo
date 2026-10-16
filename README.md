# Blaster-Saber-Godot-Demo

A Godot third-person cinematic gunblade combat prototype. **Stages 1 and 2 and Stage 4 Steps 1–17, including Enemy Contact Matching and defensive reactions, have passed initial manual acceptance. Player keyboard/mouse defense uses RMB. Stage 4 Step 18 Enemy Mistake and Pressure is authorized and implemented, awaiting manual acceptance.** Stage 3 is postponed, not cancelled. Walking 2.0 m/s and running 3.5 m/s remain the accepted, adjustable baseline. Stage 0 has no explicit final acceptance; Step 19 and further work need approval. Resource costs/timers are temporary greybox values; formal Stamina/Posture terminology and design are retained. No enemy resource, Bind or skeleton IK is implemented.

## Project Vision

Explore continuous weapon exchanges inspired by the fast lightsaber duels of the Star Wars prequels: attacks, probes, parries, and changing pressure.

The main motion reference is one-handed Sabre, combined with Rapier / Épée thrusts, probing, distance control, and energy-blade contact and extension. Fast thrusts, small cuts, tip probes, wrist changes, feints, occasional broad cuts, deflections, presses, and clashes are relevant. This is not strict historical fencing or competition simulation. Probing and feints remain movement references but are deferred from the first enemy AI scope.

The blade has almost no mass and need not depend on broad swings to build momentum, while even light contact can cause serious injury. **Precision, distance, angle, timing, and continuity** matter more than swing power. Neither thrust-only attacks nor a ban on broad cuts is intended.

**The player decides what to do; the character decides how to execute it.** Inputs express intent; execution considers distance, weapon position, and current motion. The immediate goal is a credible, readable, controllable exchange between two opponents. Narrative confrontation and escalation remain longer-term directions.

## Core Design Principles

- **Intent-Driven Combat:** Inputs request attacks, defense, dodges, or shots rather than always playing the same animation. Out-of-range behavior still needs validation.
- **Continuous Combat:** Transition from current poses where possible. Contact should affect subsequent weapon positions rather than force a return to idle.
- **Player Agency:** The player chooses attacks, defense, dodges, shots, blade toggles, and Force abilities. Execution must not autonomously choose attacks, counters, pursuit, dodges, or abilities. Limited instinctive interception is a costly defensive exception, not authorization for new tactics.
- **Meaningful Weapon Contact:** Parries and clashes affect subsequent exchanges. Authored motion, spatial detection, and procedural alignment are a starting direction; full rigid-body fencing is not required.
- **Real Outcomes:** Not every attack must be blocked, and no fixed clash count is required before a hit. Openings can lead directly to hits; mistakes have consequences.
- **Pacing:** Do not assume Souls-like pacing, rhythm-game parrying, or noninteractive automatic clash sequences.
- **Motion Priorities:** Readability > continuity > expressiveness > anatomical realism. Cinematic presentation must preserve awareness of threats, positions, and player state.
- **Engineering Scope:** Prefer GDScript and native Godot nodes. Separate responsibilities without prebuilding general combat, state-machine, ability, AI, RPG, event-bus, or large move-database frameworks. Neither fixed animations for every action nor complex physical sword simulation is mandatory.

## Confirmed Decisions

Subsections explicitly label provisional values and unfinished details alongside confirmed rules.

- Greybox actors use one vertical body cylinder and two spherical hands, without limbs, skinning, or a required Skeleton3D.
- Separate actor logic from visual nodes for later presentation replacement, without building a skeletal compatibility framework now.
- The gunblade uses a vertical body cylinder, transverse barrel cylinder, and energy blade, primarily held in one hand. Dimensions below are adjustable visual references.
- Sword use and gunfire are not mutually exclusive modes. Quick shots can occur with the blade vertical or angled. Precise aiming would explicitly align the barrel, but hold-to-aim is currently deferred. Quick shots must relate intelligibly to pose, actual muzzle direction, and stability.
- Hitscan is an acceptable initial approach. Distinguish intended target, actual muzzle direction, and hit position; do not guarantee hits while the muzzle points elsewhere.
- Sword Trail is a separate visual effect based on blade-root/tip history. It does not perform hit detection or rely solely on Motion Blur.
- Use simple blade geometry/materials. Explore Glow, anti-aliasing, and camera effects incrementally; engine renderer modification is not a prerequisite.

### Actor and Gunblade Dimensions

With metric scale, one world unit is approximately one meter. These design references replace the original rough proportions and are now represented by the Step 1 static greybox scenes. Visual proportions still require manual acceptance.

| Part | Reference | World units |
| --- | --- | --- |
| Actor height | Approximately 170 cm | 1.7 |
| Hilt / gunblade body length | Approximately 20 cm | 0.20 |
| Transverse barrel length | Approximately 15 cm | 0.15 |
| Barrel mounting position | Approximately 16 cm above hilt bottom | 0.16 |
| Energy blade length | Approximately 1 m, primarily one-handed | 1.0 |

A slender aiming aid on the barrel's right side is omitted from the first greybox. Preserve the barrel's position/orientation relative to the hilt and identify the muzzle clearly.

### Blade Contact and Torque

A nearly massless blade can still contact weapons and transmit forces to the hilt. Contact farther from the grip can create a larger moment, rotating the wrist, redirecting the blade, disrupting defense, reducing control, or potentially causing disarm.

Results depend on direction, force, grip, and both actors' motions; a tip hit does not guarantee disarm. Abstract resolution and procedural feedback may express this initially. Detailed contact physics, complex pressing animations, and specific Sword Art movements remain unresolved; the sword system as a whole is not finalized.

### Blade Extension Toggle

**R2 / RT toggles on each press**, not hold-to-retract with automatic extension on release.

Outside Bind, retraction removes expected contact/resistance. A committed opponent may overextend or expose an opening; light probing or timely adjustment may produce no advantage. Retraction does not guarantee stagger. The player decides whether to reignite and attack.

During Bind, the player may press R2 / RT to retract deliberately, removing the resistance supporting the enemy blade and immediately changing the weapons' motion relationship. Current motion, relative position, enemy blade trajectory, and retraction timing determine the result, without a random success/failure roll: if the continuing attack hits, the player suffers serious injury; if loss of blade support makes it miss, the enemy loses balance and falls, giving the player a direct execution opportunity. This is a high-risk, high-reward tactic, not a penalty-free QTE cancel, and is separate from ordinary Bind QTE victory/defeat. Trajectory detection, action windows, fall animation, execution input and timing remain open, as do initial blade state, permission during other actions, and collision activation/deactivation timing.

Ignition should resemble flame-like emission followed by magnetic straightening. Candidate timings: 0.1–0.3 seconds for emission, another 0.2–0.3 seconds for straightening, and about 0.2 seconds for retraction. These are not final specifications. L2 assistance during Bind is confirmed below, with cost and pressure benefit unresolved.

### Force Block

**Hold L2 / LT** to constrain the targeted enemy weapon's forward attack motion, without freezing time or the enemy's body. The enemy can move, change pose, retract, lift, or redirect to escape, like withdrawing a blade stuck in wood.

Releasing L2 ends the constraint. After escape, continued holding does not automatically reapply it; release and press again are required. Recognizing escape after approximately one second is a candidate behavior. Range, eligible attacks, and exact escape detection remain open.

Force Block adds unexpected resistance; retraction removes expected contact. Neither guarantees stagger or a free counterattack. Against multiple enemies or dual-wielded weapons, L1 can defend against other actual threats while the left hand uses Force Block. The right hand can also recall the gunblade while L2 is active. Bind itself is disabled in multi-participant combat.

### Ordinary Melee and Gunfire

**□ / X requests one ordinary attack per accepted press.** Each animation has a short lockout/attack window, provisionally 0.2–0.3 seconds. Presses during it are completely ignored, without buffering. Afterward, a new press can interrupt the remaining animation and transition to another attack. Timing is per-animation, not a global cooldown; autoclicking cannot exceed the permitted rate.

Use a small number of ordinary motion pools; avoiding excessive group repetition is a future improvement. Initial greybox work does not need detailed selection. Parry motion should match the attack/response. Blend transitions without teleporting the weapon. Godot animation blending is a candidate starting point; add trajectory work only if testing reveals problems.

The current out-of-range fallback idea is an ordinary empty-space attack without autonomous pursuit. Taunt behavior/input remain unresolved. Dodge outranks ordinary attacks for interruption; L1 may interrupt attacks but has lower priority than dodge. Full arbitration remains unspecified.

**△ / Y fires one shot.** Motion adapts to blade/arm pose, using vertical- or horizontal-blade shooting poses as appropriate. A swing may lead into a derived shot based on arm/elbow pose; this does not require anatomical arms in the greybox.

Gunfire and melee are generally sequential; inputs during the other action may execute after its short action completes. Queue/ignore boundaries remain unresolved and must not override ordinary-melee lockout's no-buffer rule. Fluid gun/sword transitions are allowed in principle; the prototype needs no separate transition animation for every combination. Special derived attacks remain unspecified. **Holding the shoot button to enter precise aim is deferred.** All shots respect actual muzzle orientation.

### Three Defensive Behaviors and the Posture/Stamina Resource

The final name is undecided; use **posture/stamina resource** for now. The following are design rules, not implementation.

| Defense | Trigger and motion | Outcome |
| --- | --- | --- |
| Precisely timed parry | Press L1 before an incoming attack; matching motion. Candidate window 0.25–0.3 seconds, potentially scaled per attack | No player resource cost on success; increased enemy resource loss and possible enemy stagger |
| Held defense | Hold L1 in a defensive pose; respond to real attacks without meaningless repeated blocks | Absorbs without HP damage but costs resource; no equivalent precise-parry enemy penalty; depletion immediately breaks guard |
| Instinctive defense | Without L1, pre-trigger resource must be greater than zero; full payment of the coming cost is not required. May interrupt the current attack | Absorbs without HP damage, costs substantial resource, and normally causes baseline stumble. Depletion still absorbs this hit, then immediately causes guard-break stagger. Unavailable at zero or during an uninterruptible Stagger / Knockback hit reaction; held defense is also unavailable during that reaction, leaving subsequent hits dangerous |

Resource does not passively drain to zero. Relevant incoming attacks/defensive pressure reduce it; breathing during periods without parrying or automatic interception restores it. When defense reaches zero or below, absorb that hit, immediately enter guard-break stagger, and clamp stored/displayed resource at zero. `10 - 10` and `0.1 - 1000` yield the same guard-break state; overkill does not change the result. Subsequent attacks create the danger.

The existing resource probabilities remain unchanged. Applicable events and sampling before/after deduction are unresolved. Knockback and disarm can occur together; knockback distance does not scale with resource. Weapon Durability separately influences enemy disarm probability; no combination formula is selected.

| Event | Resource ≥50% | Resource falling from 50% to zero |
| --- | --- | --- |
| Additional knockback | 20% chance | Linear increase to 80% |
| Base resource-driven disarm | 0% chance | Linear increase to 60% |

These are current balancing parameters. Keep the following triggers distinct even if some animations are shared:

| Outcome | Trigger |
| --- | --- |
| Baseline instinctive-defense stumble | Normal instinctive-defense consequence; does not require zero resource or a knockback roll |
| Zero-resource guard-break stagger | Immediate defense depletion to zero/below, independent of defense type or knockback probability |
| Additional probabilistic knockback | Resource-based probability; applicable events/sampling remain open; does not replace either stumble or guard-break stagger |

Stagger / Knockback restrictions apply to the uninterruptible hit-reaction motion, including any retreat or fall, not to a persistent control lock throughout the later Knocked Down state. Once that motion ends, a grounded player can use the established grounded actions below; a player who has not fallen regains normal control after the hit-recovery motion ends. The three outcome triggers above remain distinct.

### Stagger, Injury, Knockdown, and Disarm

- **Stagger / Knockback:** The uninterruptible hit-reaction process of losing balance, retreating, or falling after an attack, rather than a persistent control-lock state while already on the ground. During this process the player cannot move, attack, block, dodge, shoot, or perform other actions; a QTE cannot bypass or interrupt it. After the hit-reaction/recovery motion ends, enter the controllable Knocked Down state if the character has fallen; otherwise restore normal control. Exact reaction/recovery duration needs discussion and later tuning; a short cinematic camera response remains possible.
- **Injury:** HP damage is uncommon but serious. An enemy body hit may cause dismemberment/execution. Player hand hits may disarm according to resource state, leg hits may cause stumbling, and torso hits may cause major stagger/knockdown. Serious injury causes major HP loss, longer reactions, and difficulty with precise defense. **Blur starts below 30% HP and strengthens as HP falls.** Blur curve, injury motions, and recovery values remain tunable. Penalties recover after HP crosses appropriate thresholds. Recovery after a period without being attacked remains the direction, with about five seconds as a candidate delay. Consumable healing/input remain unresolved.
- **Knockdown / Knocked Down:** The controllable grounded state entered only after the uninterruptible falling hit reaction has ended. At that point, □ / X swings defensively, ○ / B rolls, and ✕ / A attempts to rise. **Grounded roll has highest priority and interrupts rising or grounded swings; grounded swings interrupt rising.** Rolling or swinging during rising immediately resets get-up progress. Rising requires **five accepted jump/get-up presses**, with progressive bracing/partial-rise feedback, not a sudden stand on press five. These grounded permissions and priorities do not allow interruption of the preceding hit reaction. Accepted-press timing and other interruption details remain open. Automatic selection of a safer rising direction is still a candidate needing threat/agency discussion.
- **Disarm:** □ / X becomes unarmed melee without meaningful damage. L1 can be attempted but risks further knockback. Left-hand L2 remains available; if the gunblade is visible, right-hand R2 may recall it, automatically igniting the recalled blade. Repeated □ during recall may enable catch-and-slash; conditions remain open. L2 and R2 recall can occur simultaneously.

#### Dodge and Lethal-Attack QTE

With positive resource and normal defense available, no special lethal-attack dodge QTE triggers. Attacks follow precise-parry, held-defense, or instinctive-defense rules.

Only danger following resource depletion and defensive collapse permits consideration of special lethal attacks and a dodge QTE. Zero resource does not guarantee a QTE on every attack. Lethal motions, warning timing, dodge window, failure resolution, and whether/how the QTE is used remain open. The earlier head-directed slow-motion dodge idea belongs to this restricted, unresolved area.

During an uninterruptible Stagger / Knockback hit reaction, the player cannot dodge, and a QTE grants no additional interruption permission. If a lethal attack connects during that motion, the system must not force in a rescue dodge. After the falling motion ends, the player can roll using the established Knocked Down controls. This boundary does not define new QTE trigger, warning-window, or failure-resolution rules; those remain unresolved.

### Offensive Blade Contact and Ordinary Enemies

If both attacks miss, both miss. When both could hit, actual spatial contact and trajectories must establish a valid blade exchange. Valid contact resolves as a clash; invalid contact cannot be turned into a clash for presentation, nor may the system arbitrarily choose whether to clash. Potential body hits or animation progress alone are insufficient. Neither participant loses resource merely because of that valid mutual clash.

Exact spatial/trajectory tests, collision response, torque, and complex pressing motions require dedicated design. Ordinary collisions, parries, and bounces do **not** automatically become sustained Bind.

Organize the first enemy AI conceptually into three layers, without prebuilding a framework:

| Layer | Responsibility |
| --- | --- |
| Intent | Defensive waiting, active offense, or distance adjustment |
| Reaction | Whether defense can occur in time given current action state and reaction capability |
| Mistake | Reaction and judgment errors creating understandable openings; accumulated actual attack pressure increases mistake probability |

Initial scope is defensive waiting, offense, and distance adjustment. Probes/feints are deferred. Start with reaction mistakes; judgment mistakes are later extensions. Enemy differences primarily use parameters such as aggression and reaction speed. Move pools, attack frequency, and reaction-time values are unspecified. Advanced dodging is not required initially.

An internal timing/decision table may schedule attacks, e.g. after several inactive seconds. Being attacked during anticipation/recovery may provoke costly defense with substantial resource loss or stagger. Outside attacks, held-defense-like behavior loses resource when blocking. Enemies may turn to defense according to timing/state. Ordinary-enemy guard break may permit direct execution.

Mistakes are decision/reaction errors, not random post-contact victory declarations. Retain **10% base mistake probability plus five percentage points each time the enemy actually receives effective player attack pressure**. Attacks stopped by ordinary defense, instinctive defense, or another defensive response count as pressure; HP loss is not required. Whiffs and attacks that exert no actual pressure do not count. Accumulation represents the difficulty of continually handling player offense, not the number of attack-button presses. Reset the accumulated pressure streak **after successful valid defense followed by a genuine breathing opportunity**; defense alone is not sufficient. Probability caps, breathing-opportunity detection, which special attacks count, and eligible mistake types remain open; attack frequency/timing still require tuning.

#### Blade Bind

**Trigger:** Enemy attacks are selected from move pools; some special moves have `CanInitiateBind`. Selecting one and making valid blade contact with the player enters Bind without another probability roll. The move starting alone does not guarantee Bind. Earlier player dodge, interruption of the enemy attack, or no valid blade contact prevents entry.

**One-on-one encounters allow Bind; multi-participant combat disables it outright.** Even a selected Bind-capable move resolves only as ordinary attack/contact in multi-participant combat. Encounters use prearranged waves or encounter areas, without regular sword enemies suddenly joining an ongoing duel. This shared encounter/combat constraint removes the need for a special mid-Bind second-swordsman mechanism in the regular flow. Environmental exceptions such as stray dogs must not arbitrarily interrupt a duel or Bind. Classification scope remains configurable; no fixed distance, wave count, spawning method, or area size is chosen. See Exploration, Confrontation, and Combat Permissions for the encounter structure.

**Interaction:** Bind is an arm-wrestling-like two-sided pressure QTE over one shared progress track. Repeated attacks (□ / X or left mouse button) add player pressure; enemy continuous pressure moves progress toward its side. Direction prompts require right-stick movement (RS) or mouse movement to redirect the blade press. Correct input adds player progress; wrong input adds enemy progress rather than instantly failing. Prompts may appear in-game and must match the pressing motion.

L2 / LT Force Block may assist in maintaining Bind; Force cost and pressure bonus remain open. During Bind, the camera locks onto both participants. RS/mouse movement drives the direction QTE rather than the ordinary camera, taking priority over soft-lock control. Normal combat camera/input return afterward. **RS movement is not R3/RS Click; R3 remains interaction.**

Accepted repeated-press rate cap, direction thresholds, prompt frequency, pressure rates, and duration are tuning questions without confirmed values. Do not silently reuse ordinary-attack lockout values for Bind inputs.

**Ordinary Bind QTE victory:** Suppress/deflect the enemy blade and reduce enemy Weapon Durability, increasing disarm chance on subsequent ordinary player attacks. A brief blade-opening/stagger animation is allowed; extra damage or prolonged stun is not a default reward. Victory does not immediately destroy the weapon.

**Ordinary Bind QTE defeat:** Exactly one outcome occurs: player weapon leaves the hand **or** player suffers serious injury. They are mutually exclusive in the same Bind defeat. The move and matching animation determine the outcome. Damage, injury location, and serious-injury duration are unspecified.

**Deliberate blade retraction during Bind:** R2 / RT removes blade support; current motion, relative position, enemy trajectory, and timing determine whether the continuing attack hits the player (serious injury) or misses because support disappeared (enemy loses balance and falls, enabling direct execution). This is a separate tactical resolution, not an ordinary QTE win/loss or random roll, and not a penalty-free cancel. Detailed trajectory detection, action windows, fall animation, execution input, and execution timing remain to be designed.

Bind is a special interaction with explicit conditions, not a replacement for ordinary attacks, precise parries, held defense, instinctive defense, or momentary clashes, and not the default outcome of blocking. The player chooses actions; the system chooses motion presentation. Bind animations and physical-contact details require separate design.

#### Weapon Durability

Weapon Durability is independent of posture/stamina. Ordinary Bind QTE victory is the primary confirmed way to reduce enemy durability; lower durability increases enemy disarm chance from subsequent player attacks.

It coexists with unchanged base resource-driven disarm: 0% at ≥50% resource, rising linearly to 60% at zero. Combination formula, curves, combined cap, durability recovery, and zero-durability outcome are unresolved. Do not assume addition, automatic breakage, or automatic disarm at zero.

### Force Ability Layer

**Hold R1 / RB:** □ / X = Force Pull; △ / Y = Force Push; ✕ / A = Force Slam (force the enemy down); ○ / B = Force Choke. Effects, interruption, and concurrency are incomplete; this does not authorize an ability framework.

Force abilities consume a Force resource separate from posture/stamina. Player attacks against enemies restore Force. Meeting an ability's own Force requirement permits use without another universal activation threshold. Costs, limits, and restoration amounts remain open.

**Choke retains its special rule:** at least 75% Force to start; completion consumes all Force and may execute an ordinary enemy. Approximately two seconds to complete remains a candidate duration. Interruption and target eligibility remain unresolved.

### Controller Layout & Input Permissions

DualSense labels with Xbox equivalents describe the current design; no Input Map exists. Stick movement differs from clicks. Unresolved timing/concurrency cannot be inferred from assignments.

| PlayStation | Xbox | Function |
| --- | --- | --- |
| Left stick | Left Stick | Movement |
| L3 | LS Click | Toggle walk/run |
| Right stick movement | RS movement | Normal camera/soft lock; direction QTE during Bind |
| R3 | RS Click | Interaction |
| ✕ | A | Jump/contextual climb; grounded get-up |
| L1 | LB | Precisely timed parry / held defense |
| L2 | LT | Hold left-hand Force Block; assist Bind |
| R1 | RB | Hold four-button ability layer |
| R2 | RT | Blade toggle; disarmed recall |
| □ | X | One ordinary melee per accepted press; contextual grounded/unarmed actions; repeated Bind pressure input |
| △ | Y | Single shot; hold-to-aim deferred |
| ○ | B | Contextual dodge / roll |
| D-pad | D-Pad | Four dialogue choices |

R1's effects on L1/L2/R2 and general concurrency remain incomplete. Bind overrides camera motion with direction QTE; R3 remains interaction.

Prototype Step 13 temporarily uses **Tab / R3 (RS Click)** to toggle single-target Soft Lock. Interaction is not implemented; this test mapping does not redefine the formal input table. RS movement still controls the camera.

### Keyboard/Mouse Layout (Provisional; Separate Review Required)

| Action | Keyboard / Mouse |
| --- | --- |
| Move | WASD |
| Camera / Bind direction QTE | Mouse movement, by context |
| Walk/run toggle | Shift |
| Melee / Bind pressure presses | Left mouse button |
| Shoot | F |
| Parry/guard | Right mouse button |
| Dodge | Alt |
| Interact | E |
| Jump/get up | Space |
| Force Block | R |
| Blade toggle / recall | Q |
| Force Pull | Ctrl + 1 |
| Force Push | Ctrl + 2 |
| Force Slam | Ctrl + 3 |
| Force Choke | Ctrl + 4 |
| Dialogue choices | 1 / 2 / 3 / 4 |

The broader keyboard/mouse scheme remains provisional, not an Input Map. Hold/modifier-release/context semantics need review; Bind's left-click and mouse-direction roles are recorded above.

### Exploration, Confrontation, and Combat Permissions (Future Direction)

**Confirmed encounter structure:** Use Devil May Cry-like staged encounters, primarily organized into prearranged enemy waves or encounter areas. Regular sword enemies do not suddenly join an ongoing one-on-one fight. One-on-one encounters permit Bind under its contact rules; multi-participant encounters disable it, with Bind-capable moves treated as ordinary attacks/contact. Level and combat design share this constraint rather than requiring complex handling of a second regular swordsman joining mid-Bind. Stray dogs and other environmental enemies may be special exceptions, but must not arbitrarily interrupt an ongoing duel or Bind. Wave counts, spawning methods, area sizes, and detailed level flow are not specified.

Noncombat does not imply holstering or that drawing a blade is the only combat entry. Ignition may be available outside combat, subject to city/narrative restrictions. Cities may disable attacks, shooting, blocking, dodging, and Force combat actions and use a closer camera. Exploration does not universally disable R2. Movement, camera, walk/run, interaction, environment actions, and dialogue depend on context.

Future confrontation may use L1 near a potentially hostile humanoid with an unlit blade. Camera changes, holster preparation, dialogue, and explicit □ draw/ignite or △ shoot choices may follow. Dialogue may defuse/escalate; combat after about five seconds without response is only a candidate. A lit blade in a hostile outpost may prompt confrontation or combat; hostile animals may skip confrontation.

Context/permission/transition details are unfinished; do not reduce everything to a permanently fixed `is_in_combat` boolean. Dialogue/confrontation are outside Stage 1, and candidates are not approved implementation.

## Candidate Approaches & Design Risks

### Fast Motion and Player Decision Frequency

A separate block press per contact may force slow attacks and a wait-for-cue loop. Automatic defense against every attack may turn one attack press into an autonomous duel. Both risks need testing.

**Motion frequency can exceed decision frequency:** held L1 maintains defense and responds to real threats within that intent. Density/rhythm/continuity need testing; one offensive input does not authorize an entire automatic exchange.

| Current-intent execution details | Unauthorized tactics |
| --- | --- |
| Wrist adjustment, tip redirection, small pose changes | Counters or new attacks |
| Deflections needed for current defense | Pursuit or dodge |
| Contact-driven weapon adjustment | Autonomous abilities |

Validate readability, traceability to intent, response to input changes, and excessive protection. Presentation cannot guarantee safety or clashes. Bind's contextual QTE does not globally redefine ordinary inputs.

### Instinctive Defense and Offensive/Defensive Priority

Costs, baseline stumble, guard-break stagger, and defense restrictions during the uninterruptible hit reaction are defined above; that reaction lock does not extend throughout the controllable Knocked Down state. Instinctive defense is consequential, without automatic counters or guaranteed safety. Positive pre-trigger resource is sufficient without full payment; detection/cost values remain open.

The authorized Stage 4 Step 11 greybox uses a full-payment exception for testing, documented in its implementation section below; its 50 Resource cost and hand-only reaction are not final formal balance.

Dodge/L1 relative priority over attacks is set; other arbitration/cancellation remains incomplete. Grounded roll/swing/rise priorities are now set, while automatic safe-direction rising and agency remain open. This does not approve a complete state machine.

### Soft Target Lock and Camera

Use automatic soft selection rather than rigid manual lock-on. Keep selected targets stable rather than continually changing for a nearer enemy. The following rules replace the old nearest-first, first-in-list tie-break, and direct directional-switch scheme; those are not parallel confirmed alternatives.

While locked, right-stick camera operation within **±40° of the target-centered direction** does not switch or unlock. Input beyond the range must persist before unlocking. The earlier **0.8–1 second** controller suggestion is historical; the current adjustable Step 14 test default is **0.5 seconds**. After unlocking, restore **Orient to Movement**, turning by movement direction.

Automatic reacquisition requires both:

1. Enemy within **±40° of camera facing**.
2. Enemy within **±20° of player movement direction**.

Randomly select among multiple qualifying enemies. A brief post-unlock relock-protection period is a candidate only. The current single-target prototype uses the same dual cones for first moving-player acquisition, excludes stationary acquisition, and clears dead targets; multiple-target initial selection remains deferred. Do not silently restore nearest-enemy fallback.

Mouse/controller thresholds remain adjustable. The earlier same-direction mouse motion above a velocity threshold for about 0.4 seconds remains only a candidate to test against the new angular design. Exact mouse thresholds and post-unlock camera response remain open. Increasing camera resistance and fast-initial/slow-settling return remain a feel direction subject to tuning.

Future damping or input response must expose an editable Godot **Curve** resource with a **linear default** for manual editor adjustment. This task creates no Curve file. Bind's fixed encounter camera/direction QTE takes priority over normal soft-lock input. Soft lock stays outside Stage 1's basic camera scope.

Stage 4 Step 14 now implements single-target manual locking, the default ±40° horizontal offset, 0.5 s sustained-input release, Orient to Movement and combined-angle automatic reacquisition. Optional local Curve response is supported with a linear fallback. Random selection among multiple eligible targets remains a future multi-target requirement; no multi-target system is implemented.

## Current Implementation

Initial inspection: 2026-10-13. Stages 1 and 2 and Stage 4 Steps 1–17 are initially accepted. Step 15 first acquisition is accepted; Step 16 adds default-off manual enemy guard through the existing valid-contact settlement and shared two-blade sweep. Bursts, 5 HP incoming damage, player attacks/locks, movement/camera, HP and bounded matching remain. Current temporary outgoing damage is 10 HP and held-block cost is 10 Resource. Step 17 defensive reactions are accepted; Step 18 adds bounded-probability mistakes and effective-contact pressure; full Intent/Reaction/Mistake AI, pursuit, enemy resource, Bind and skeleton IK remain unimplemented.

| Item | Observed state |
| --- | --- |
| Project | `project.godot` exists; `config_version=5` is a configuration format, not the engine major version |
| Local engine | `--version` returned `4.7.2.stable.steam.ed1daf0bf` |
| Project feature markers | `4.7`, `Forward Plus` |
| Application name | `Wuwaproject`; renaming remains open |
| Rendering/physics | Forward Plus, Windows `d3d12`, `Jolt Physics`; controls, HP, player defense/resource/break, clashes, matching, bursts and Soft Lock accepted; manual enemy guard and matching accepted; defensive reactions accepted; pressure/mistakes awaiting review |
| Scenes/scripts | Player `DebugDefense` owns resource/break/recovery and active/automatic feedback. Enemy `debug_enemy_defense.gd` owns shared manual/automatic guard transitions and bounded matching, using the shared player pose solver; existing HP and two-blade sweep handle settlement/diagnostics. No new animation assets or attribute framework. Dimensions/initial positions retained |
| Assets | Native primitive meshes, simple embedded materials, marker nodes, and labels; default icon retained. No imported actor models, textures, or custom shaders |
| Input/systems | Existing inputs retained; Guard Break disables attack/defense but permits movement/look. F4 shows permissions/trigger; F7 resets HP, resource, break, recovery, hand pose and locks. Reactive defense with temporary pressure/mistake probability is implemented; no full decision AI, enemy resources, dodge, Bind, Force, durability or execution |
| Tests/export | `tests/smoke_test.gd`: 935 checks passed with normal timing and fixed 60 fps, retaining all prior 864 and adding 71 pressure/mistake/recovery checks. Coverage includes RMB/L1 mapping exclusivity, rejection of Q, and actual RMB press/hold/release; physical keypad mapping and old-key rejection remain covered. Import/loading/headless startup passed; no CI/export presets |
| Repository support | Git, `.editorconfig`, `.gitattributes`, `.gitignore`; working tree clean before initial inspection |
| Local cache | Git-ignored `.godot/` editor/import caches are not game implementation |

### Initial Inspection Verification (Historical)

- Engine version query succeeded.
- `--headless --editor --import --quit` succeeded without errors.
- `--headless --quit` reported `Can't run project: no main scene defined in the project.` The game could not start despite exit code 0; exit status alone is insufficient.
- Initial sandbox checks had editor-data write errors. After approved rerun outside the sandbox, import succeeded and startup reported only the missing main scene.
- Local ignored logs: `.godot/inspection-import.log`, `.godot/inspection-run.log`.
- No scripts/scenes existed for logic/resource-loading tests. Headless import does not validate camera, motion, rendering, or feel. Graphical startup has not been accepted.

### Stage 1 Step 1: Static Layout and Verification (Historical)

World coordinates are Y up, ground surface Y=0, actor local forward -Z, and local right +X, with one unit per meter. Both actors instance the same scene: a script-free `CharacterBody3D` and matching 1.7 m cylindrical collision, with a separate `VisualRoot`, cylindrical body, and two spherical hands. The body radius is 0.25 m; hands have 0.065 m radius. These greybox width/hand-size choices are adjustable presentation parameters, not combat rules.

Player origin is `(0, 0, 1.5)`, facing -Z; the static enemy is `(0, 0, -1.5)`, rotated 180° about Y to face the player. Origins are 3 m apart. The 10 × 10 m floor has a top surface at Y=0 and a `StaticBody3D` collision. A 1 m reference grid, colored X/Z axes, labels, and a small front-facing marker make scale and orientation readable.

The right hand is at actor-local `(0.38, 1.1, -0.18)`; the gunblade grip origin coincides with its center. Weapon local +Y follows the hilt and blade; -Z is barrel/muzzle forward. Hilt bottom is Y=-0.07 and top Y=0.13; its length is 0.20 m. The 0.15 m barrel runs from Z=0 toward -Z at Y=0.09, 0.16 m above the hilt bottom. `Muzzle` is `(0, 0.09, -0.15)` facing -Z; `BladeBase` is `(0, 0.13, 0)` and `BladeTip` is `(0, 1.13, 0)`, with a 1 m blade between them. `Grip` and `HiltBottom` markers make the coordinate origin explicit. No weapon collision or shooting behavior is added.

The blade has a simple unshaded emissive material for identification; there is no Glow/trail system. `StaticObservationCamera` is a fixed orthographic view at `(4.5, 3.4, 5.5)`, aimed at `(0, 1.1, 0)`, with size 5.6. It is a temporary static-inspection camera, not the Stage 1 third-person camera rig or soft-lock camera.

Automated checks completed on 2026-10-13 using Godot `4.7.2.stable.steam.ed1daf0bf`:

- Headless editor import succeeded without resource/parse errors.
- Main scene started for eight frames and exited without resource/script errors. Initial sandbox startup could not create the engine user-data directory; the approved run outside the sandbox succeeded.
- A temporary, ignored `.godot/` geometry-check script loaded/instantiated the arena and passed **49 checks**: actor structure and height, collision dimensions, sphere hands, shared actor/independent weapon instances, grip alignment, hilt/barrel/blade dimensions, mounting height, muzzle/base/tip positions and axes, world blade span, origin spacing/facing, active static camera, and floor surface. A physics ray hit the floor at Y=0. The helper was removed after verification; no gameplay script or future smoke-test infrastructure was created.
- Logs remain local and Git-ignored: `.godot/inspection-import.log`, `.godot/step1-startup.log`, `.godot/step1-geometry.log`.

At the initial delivery, manual acceptance covered proportions, grip, blade/muzzle visibility, labels, lighting, and the fixed-camera framing via F5/F6. Headless checks alone did not establish visual quality. The failure and repair below are historical; the user has since confirmed that the static scene renders and authorized basic movement and third-person camera work.

The first manual run failed: the editor showed the geometry, but the game view was nearly black with no actors. Runtime diagnosis found that the serialized Camera3D basis had been transposed. Its forward direction was `(0.633238, 0.238323, -0.736350)` rather than the intended `(-0.602468, -0.307928, -0.736350)`; the player body center was behind the camera and both body centers were outside its frustum. The original checks verified an active camera but did not verify its aim or framing. The basis was corrected without changing position, orthographic size, near/far, actors, or weapon geometry. A second configuration issue was corrected: ambient source was Sky with no Sky resource; it now uses Color so the existing ambient color/energy apply.

After repair, runtime checks confirmed the assigned main scene and active camera, exact aim toward `(0, 1.1, 0)` (alignment dot product 1.0), and **26 actor/weapon sample points inside the frustum** at a representative 1152 × 648 viewport. Visibility/layers permit both bodies, the directional light is visible at energy 1.2, and no SubViewport exists. The existing `canvas_items` / `expand` stretch configuration was retained. Editor import and eight-frame headless startup passed again. The temporary diagnostic helper was removed; its ignored log is `.godot/step1-camera-diagnostic.log`. Static rendering was subsequently confirmed by the user; the fixed camera has now been replaced as described below.

### Stage 1: Basic Movement and Right-Shoulder Camera

Only the player instance has `player_controller.gd`; the reusable greybox scene remains script-free for the static enemy. Input uses a circular 0.2 stick deadzone through `Input.get_vector`. Camera forward/right vectors are flattened onto the ground plane to calculate movement, retaining analog magnitude and limiting diagonal speed. CharacterBody3D uses project gravity and `move_and_slide()` for ground/enemy collision. The default is walking at 2 m/s; Shift or L3 toggles running at 3.5 m/s. Turning smoothly follows realized horizontal velocity, including collision sliding; no movement animation is added.

The independent `ThirdPersonRig` follows player position at neck height, without inheriting player rotation. Its yaw and `PitchPivot` control orbit around this observation point rather than world origin. Shoulder offset is defined in the camera-orbit frame, so player turns do not flip its side. The SpringArm sphere sweep runs diagonally from the observation point toward the offset camera and excludes the player's RID. A counter-rotation makes Camera3D face orbit-forward while leaving the actor left of screen center. Obstacles shorten the arm; its unobstructed length is approximately 2.693 m, corresponding to 1 m right and 2.5 m rear components.

Select `TestArena/ThirdPersonRig` in the Inspector to adjust:

| Property | Initial value | Meaning |
| --- | --- | --- |
| Rear Distance | 2.5 m | Rear component of unobstructed camera offset |
| Right Offset | 1.0 m | Right component in the orbit frame; no shoulder switching |
| Observation Height | 1.55 m | Follow/orbit point above player feet |
| Mouse Sensitivity | 0.12 degrees/pixel | Captured mouse look |
| Stick Sensitivity | 120 degrees/second | Full right-stick look |
| Min / Max Pitch Degrees | -60 / +45 | Downward / upward look limits |
| Follow / Rotation Smoothing | 16 / 12 | Exponential response rates; zero makes that response immediate |

Camera3D uses Perspective, FOV 70°, near 0.08 m, far 50 m. SpringArm uses a 0.15 m sphere and 0.1 m collision margin. These camera and smoothing values are initial tuning, not finalized composition. Player speeds and turning response can be edited on `TestArena/Player`. No camera manager, soft lock, target selection, shoulder switching, cinematic camera, or Bind camera is added.

Implemented Stage 1 movement and camera controls remain unchanged: WASD / left stick move, Shift / L3 toggle walk/run, mouse / right stick look, first left-click capture, Esc/focus-loss release. After capture, left-click now requests one ordinary visual motion as authorized for Step 2. The four temporary selectors/debug request and one ordinary request are the only motion inputs added; no full combat mappings exist. Physical input and new transition feel remain manual checks.

Automated verification on 2026-10-13: editor import and main-scene short startup passed without parse/resource/runtime errors. The headless smoke test passed **56 checks** covering resource loading, active perspective camera, default offsets and left-of-center neck projection, initial enemy projection, keyboard/controller mappings, absence of combat/jump actions, walking/running distances, toggling, camera-relative movement after yaw changes, realized-motion facing, floor/enemy collision, static enemy, follow convergence, stick rotation/pitch clamps, mouse look math, self-collider exclusion (including a centered sweep), shoulder preservation after body rotation, and arm retraction/restoration against a temporary test-only wall. The wall is not part of the arena file. Native mouse capture cannot be validated by the headless dummy display; only its mappings and look calculations are covered. Log: `.godot/stage1-controls.log` (ignored).

The user has completed initial Stage 1 manual acceptance and accepted **walk 2.0 m/s / run 3.5 m/s** as the current debugging baseline. Do not revert to the earlier 1.0 / 2.5 values without authorization; these remain future tuning parameters, not immutable final speeds. Movement, camera settings and their scripts are unchanged by Stage 2 Step 1. The finite floor still has no arena walls or respawn; walking off its edge can cause a fall. Broader device/aspect-ratio and obstruction refinement remains subject to manual review, not implied by headless tests.

### Stage 2 Step 1: Greybox Weapon Motion Demo

`Player/WeaponMotionDemo` drives only `VisualRoot/RightHand.transform` using physics-mode Godot Tween interpolation with sine easing. The gunblade remains a child of that hand with an unchanged identity grip transform; both hand and weapon move together. Body, left hand, actor root, collision, weapon dimensions, movement and shoulder camera are unchanged. This is a small set of single-handed visual poses, not a formal attack system.

Idle Guard tilts the blade forward 25 degrees with a small wrist angle. Thrust uses a short preparation followed by forward grip extension and a forward-pointing blade. Short Cut uses a compact cross-body sweep; Broad Cut uses a wider lateral preparation, forward arc and cross-body finish. Each ends with a smooth Return to guard. Accepted new requests stop the previous Tween at its current pose and transition from there, without resetting to Idle first. Scene entry also blends from the existing greybox pose. Step 2 adds the lightweight selection and shared request windows below; the original motion poses and durations remain unchanged. There is no input buffer, target acquisition or root motion.

Temporary debug controls (selection alone does not perform a motion):

| Action | Keyboard | Controller |
| --- | --- | --- |
| Select Thrust (default) | 1 | D-pad left |
| Select Short Cut | 2 | D-pad down |
| Select Broad Cut | 3 | D-pad right |
| Force selected motion once | V | Square / Xbox X is now reserved for ordinary selection |

Holding a request does not repeat motions. The original `1 / 2 / 3 + V` debug scheme remains; D-pad selectors still work but do not fire an action. Square/X now exclusively requests ordinary selection, avoiding simultaneous normal/debug execution. These temporary meanings do not implement dialogue or a full combat input system. Motions can be requested while standing, walking or running. Weapon overlap has no gameplay effect.

All poses/timings are initial presentation choices, not confirmed attack windows or combat tuning. Preparation/strike durations are Thrust 0.12/0.14 s, Short Cut 0.10/0.14 s, Broad Cut 0.18/0.16/0.18 s across three poses; Return defaults to 0.30 s and can be edited on `Player/WeaponMotionDemo`. No bones, IK, authored move database or general state machine is introduced.

Automated verification: import and short main-scene startup without resource/script errors; **87 smoke-test checks passed**, including all earlier movement/camera checks at the accepted speeds. New checks cover three motion excursions, larger Broad Cut excursion, forward thrust reach, bounded frame-to-frame position/rotation changes, exact return to guard, hand/weapon attachment, unchanged actor root/collision/left hand, interruption from current pose, temporary selector/request input, single-request behavior while moving, and static enemy. These sampled bounds are mechanical checks, not proof of visually natural motion.

The user completed initial Step 1 visual acceptance and subsequently accepted Step 2 selection, transitions and input handling. Broader visual refinement remains manual work, rather than proof that every possible interrupted transition is final.

### Stage 2 Step 2: Basic Selection and Transitions

An ordinary input submits one request, without requiring manual move selection. `WeaponMotionDemo` reads a single Inspector-configurable static reference (`Reference Target Path`, default `../../Enemy`), calculates horizontal actor-origin distance and the angle from actor -Z forward, and chooses only among the existing three motions. This is a geometric test reference, not soft lock or a target manager. It does not rotate, move or pursue the actor, track the enemy, or add enemy behavior.

Temporary selection rules, editable on `Player/WeaponMotionDemo`:

| Condition | Initial thresholds | Choice |
| --- | --- | --- |
| Near and directly ahead | Distance ≤1.6 m, angle ≤20° | Thrust; if a previous Thrust is still playing, choose Short Cut instead |
| Medium range, broadly ahead | Distance >1.6 m and ≤2.8 m, angle ≤55° | Broad Cut; if a previous Broad Cut is still playing, choose Short Cut instead |
| Otherwise | Off-axis, far away, missing reference, or coincident origins | Short Cut into the current forward space |

The simple active-motion check uses the existing Tween and last accepted motion, with no combo history, scoring, randomness, or general state machine. Distances/angles are demo tuning, not confirmed combat range rules. At the initial 3 m spacing, the ordinary fallback is Short Cut; approach the static enemy to test other bands.

Normal and forced-debug requests share `request_motion()` and exactly the same pose executor. Each accepted motion starts its own no-buffer lock: **Thrust 0.26 s, Short Cut 0.24 s, Broad Cut 0.30 s**. These Inspector values remain adjustable within 0.2–0.3 s. Requests during the window are completely discarded, including debug V requests, with no queued replay. A fresh request after the window may replace the remaining motion/return, smoothly starting at the current hand transform. No dedicated cancel command or combo system is introduced. If simultaneous normal/debug requests occur, the first accepted request starts the shared lock and the other is rejected; they cannot stack Tweens.

Input mapping: **left-click while captured or Square / Xbox X** = ordinary request; **1/2/3 + V** = force a named motion. The camera now consumes left-click only when it captures a visible pointer; that first click does not also request motion. Once captured, the event reaches the motion driver. Esc still releases the mouse; controller ordinary input does not require mouse capture. There is one ordinary action (`ordinary_motion_request`) and no new defense/shoot/dodge/ability mappings. The camera edit is limited to this capture-event guard; camera geometry, controls and parameters are unchanged.

Verification on 2026-10-14: **105 smoke-test checks passed**, retaining all movement/camera and existing-motion checks. New coverage includes exclusive Square/left-click mapping, uncaptured click suppression, close/medium/off-axis/far/missing-reference choices, active-motion selection, one event/one request without hold-repeat, shared debug/ordinary locking, rapid request rejection, no buffered replay, acceptance after lock expiry, current-pose transition, and no automatic actor motion or enemy behavior. Editor import and short main-scene startup also passed. These checks do not validate a real captured mouse window or the visual quality of interrupted arcs.

Step 2 has passed initial manual acceptance. Its ordinary/debug inputs, temporary selection thresholds and 0.26/0.24/0.30 s no-buffer locks are retained without change in Step 3. The trajectory display below supports further review of arcs and interrupted transitions; it does not expand combat scope.

### Stage 2 Step 3: World-Space Weapon Trajectory Verification

`WeaponTrajectoryDebug` reads the existing gunblade `Grip`, `BladeBase` and `BladeTip` Marker3D global positions. Blade direction is the normalized world-space vector from base to tip, so it follows the actual hand/weapon Transform rather than being inferred from actor facing. Grip is the real hand-centered weapon origin; the base/tip span remains 1 m. No new weapon model, component framework, collision shape or hit query is added.

Each accepted ordinary or forced-debug request emits a start ID and motion type from the shared executor. The observer immediately records the actual start pose, then samples after each physics tick via a deferred read, after player movement and the physics-mode motion Tween. Samples contain physics frame, grip/base/tip world coordinates, blade direction and a start/frame/end tag. Return-to-guard is included. A completed Tween closes the record with `completed`; replacement by a post-lock request closes it with `interrupted`, samples the current pose and begins the new record at that same pose. Rejected lock-period inputs create no record. Initial scene-entry guard blending is not an attack request and is not recorded as one.

Records remain in memory only. Defaults retain the latest 8 requests and at most 256 samples per request. On sample overflow, the explicit start and newest/end samples are retained and the record is marked `truncated`; this is a bounded diagnostic history, not a disk archive. Adjacent tip displacement produces `max_step` and `jump_samples` warnings above an Inspector-adjustable 0.5 m per-sample diagnostic threshold. This threshold is not a hit test or a final continuity rule: movement speed, rotation and physics sampling rate affect displacement and must be considered when reviewing warnings.

**F4 toggles the display**, which defaults off. It can also be set with `Debug Display Enabled` on arena-root `WeaponTrajectoryDebug` in the Inspector (use Remote Inspector during play). `Retained Requests`, `Max Samples Per Request`, `Blade Snapshot Stride` (default 4) and `Jump Warning Distance` are adjustable. Recording continues while the display is off; the debug mesh and legend are hidden and no line redraw is performed.

Native ImmediateMesh lines render world-space data without following the moving actor. Cyan/orange/violet tip polylines identify Thrust/Short Cut/Broad Cut; darker base-to-tip segments show sampled blade placement. Green crosses mark request starts, red crosses mark completed/interrupted ends. Current grip is yellow, base/tip are white, and a yellow extension indicates actual blade direction. These remain development lines, not Stage 3 Sword Trail. Stage 4 adds separate contact query results to the legend and short pink markers below; the polylines themselves never determine contact.

Verification on 2026-10-14: **136 checks passed**, retaining all prior 105. The 31 new checks cover actual marker positions/direction and 1 m span, independent request IDs/types, completed start/end records, sampled displacement bounds for all three motions, interruption reason and matching end/start coordinates, absence of records for rejected requests, F4 mapping, display/legend toggles and line generation, world-space mesh coordinates, moving-action endpoint and actor displacement, recording with display off, bounded recent history and preserved speeds. Import and main-scene short startup passed without resource/script errors. In the moving-endpoint test, comparison is made when the action actually ends; later walking is correctly outside that action's record.

The user completed Stage 2 and Stage 4 Steps 1–16 initial manual acceptance. Step 16 manual enemy defense and matching are accepted. Stage 3 remains postponed rather than cancelled.

### Stage 4 Step 1: Basic Swept Weapon Contact Diagnostics

The arena adds `Enemy/DebugContactRegion`, an Area3D with a 0.25 m radius, 1.7 m high cylinder centered 0.85 m above the enemy origin. It follows the enemy's actual Transform, matching the existing cylindrical body. Collision layer 2 is dedicated to this diagnostic region; its mask is zero and overlap monitoring is disabled. Existing CharacterBody collision on layer 1 is unchanged. This is one simple debug region, without body-part distinctions or a formal hurtbox system. Step 3 stores HP separately on `Enemy/DebugHealth`.

`WeaponContactDebug` subscribes to actual trajectory samples. Each includes sword base/tip world positions and the actual weapon rotation. It constructs a capsule along the blade, radius 0.012 m and height equal to the measured blade span (1 m at current scale). Between adjacent samples, interpolate base translation and weapon quaternion rotation, choosing subdivisions from the maximum endpoint travel and a conservative rotation/length travel bound. The default step is 0.01 m, capped at 512 subdivisions per sampled segment. Each subsegment uses a native capsule translation sweep plus overlap checks at interpolated poses. Starting overlap is explicitly checked because native motion casts ignore it. Rotating poses are checked rather than relying only on tip rays or frame endpoints.

All three motions use this same algorithm. Actor-center distance and move type never declare contact. Queries include only areas on layer 2 and require the returned collider to be the configured enemy region, excluding player/ground bodies. The detector runs even with F4 hidden. Physical Contact checks the full recorded request, including preparation and return; Step 2 separately checks Valid Attack Contact within the active interval below. Motion selection, input lock windows and visual trajectories are untouched.

On first physical contact, a `contact_detected` signal emits a Dictionary with `request_id`, numeric `motion`, `motion_name`, enemy `target`, `target_path`, world-space `position`, `physics_frame`, surface `normal`, and `contact_kind: physical`. The contact point comes from the native shape query. Later samples still advance the trajectory and valid-window queries, but do not emit another physical event for that request/target. A new accepted request resets both contact flags and the previous sample, preventing sweeps across unrelated requests. The last 32 physical events are retained in memory and logged as `WEAPON_CONTACT`. Physical events themselves cause no damage or enemy response.

F4 retains all trajectory lines and a **pink physical-contact cross**, default lifetime 1.2 seconds. Physical status is attached to its request record. Pink markers are separate from red trajectory-end crosses and appear only after a real physics query, not merely because the sword looks close. Turning F4 off hides the entire line mesh and legend; recording continues, and markers expire while hidden. Lifetime is editable on `WeaponTrajectoryDebug`; blade radius, sweep step and subdivision cap are editable on `WeaponContactDebug`. Step 2 adds lime valid-contact markers and separate statuses below. These are diagnostic parameters, not final combat rules or effects.

Verification on 2026-10-14: **162 checks passed**, preserving all previous 136. Added checks exercise real Thrust/Short Cut/Broad Cut contacts, event contents/request association, per-request first-contact deduplication and next-request contact, real misses, near misses, cylinder height, self-body exclusion, region translation/rotation, moving contact, marker/status display, hide/expiry behavior, and no subdivision-cap overflow for tested normal motions. Synthetic fast translation and rotation cases have nonintersecting endpoint blades but detected intermediate contact, specifically testing the skipped-frame-space problem. Enemy repositioning for these test cases is test-only; the arena enemy's appearance and start position are unchanged. Editor import and short main-scene startup passed without resource/script errors.

Limits: this is a thin-capsule approximation with 0.0005 m numerical query margin, discrete frame sampling and adaptive interpolation, not an exact continuous rigid-body solver. Subsegment translation casts hold orientation fixed while endpoint overlap checks approximate rotation; very shallow grazes may differ at the step/tolerance scale. Between-frame translation/rotation is inferred from actual endpoint transforms; an unobserved path that departs from that interpolation is not reconstructed. Motion exceeding the subdivision cap produces a warning and reduced precision, not a guarantee of detection. Current support is a single static cylindrical target and the existing unit-scale blade; no moving-target relative sweep, blockers, weapon-versus-weapon contact, or body-part system is implemented.

The user completed initial manual acceptance of Step 1 spatial contacts and F4 feedback. This does not establish final contact precision or visual presentation; the geometric limitations above remain.

### Stage 4 Step 2: Active Attack Windows

Physical Contact means actual blade/body overlap during any recorded phase. Valid Attack Contact requires a real swept contact during the current request's active playback interval; preparation and return never produce valid events. Windows read `Tween.get_total_elapsed_time()` from the same physics Tween driving the hand, without a separate attack timer or changes to authored poses/timing.

| Motion | Active window in playback seconds, start inclusive / end exclusive | Total playback with default return |
| --- | --- | --- |
| Thrust | [0.12, 0.26) | 0.56 s |
| Short Cut | [0.10, 0.24) | 0.54 s |
| Broad Cut | [0.18, 0.52) | 0.82 s |

These are temporary greybox values, editable as X = start and Y = end on `Player/WeaponMotionDemo`, under **Temporary Active Windows (Playback Seconds)**. Runtime bounds are clamped to the motion's existing strike phase: Thrust 0.12–0.26, Short Cut 0.10–0.24, Broad Cut 0.18–0.52 seconds. Reversed or zero-width ranges produce no valid interval. This prevents Inspector values from enabling preparation/return contacts. Input locks remain independently unchanged at 0.26/0.24/0.30 seconds, with no input buffering.

Trajectory samples include playback time, effective window bounds, live-request and active-window flags. If a sampled frame span crosses a boundary, only its time-overlapping portion is checked for valid contact. Blade base, quaternion rotation and length are interpolated using the same geometric sweep model as physical queries; physical contact time alone is never used to declare validity. The end bound is exclusive (a 1-microsecond exclusion is used for the sampled sweep endpoint). The existing interpolation/tolerance limitations still apply at very narrow windows and shallow grazes.

`valid_attack_contact_detected` emits the same identity/spatial/frame fields as physical contact, plus `contact_kind: valid_attack` and an interpolated `playback_time` within the window. Its separate last-32-event history logs `VALID_ATTACK_CONTACT`. Physical and valid contacts have independent once-per-request/target flags. An outside-window physical contact does not spend the later valid opportunity, including continued overlap. A replacement closes the old live window before emitting its end sample, then starts a fresh request at playback zero; completion also closes it. A final end sample may resolve the legitimate preceding swept interval, but grants no new instantaneous or subsequent contact after closure. No previous request's samples or deduplication flags carry into a new request.

F4 shows all three configured intervals, current playback time, effective bounds and **ACTIVE / CLOSED**. The live blade is lime while active and white otherwise. Pink crosses indicate Physical Contact; larger lime crosses indicate Valid Attack Contact, with separate latest-request statuses. Both categories expire and the complete mesh/overlay is hidden when F4 is off. Existing ordinary input and 1/2/3 + V remain unchanged.

Verification on 2026-10-14: **217 checks passed**, preserving all previous 162 and adding 55 active-window checks. These cover the three independent intervals and actual contacts, Tween-derived time, valid event identity/time, inactive preparation/return, completion/interruption and fresh replacement timelines, separate physical/valid deduplication, an outside-window contact followed by a valid contact, repeat requests, exclusive end, closed-request rejection, boundary-clipped fast sweeps and spatial misses, Inspector narrowing/clamping/reversed bounds, and F4 state/category/hide/expiry checks. Editor import and headless Main Scene startup passed without resource/script errors.

The user completed Step 2 manual acceptance of active-window feedback and contact behavior. Step 2 introduced no damage or HP; Step 3 now subscribes to its valid contact signal below. The geometric approximation limits remain, and headless checks cannot establish final visual timing or control feel.

### Stage 4 Step 3: Minimal Enemy HP and Damage Validation

The 25 HP defaults/results in this section record its original acceptance. Step 14 changes current outgoing test damage to 10 HP; settlement and death rules remain unchanged.

This is a temporary greybox loop: **Valid Attack Contact → enemy HP deduction → Dead at zero**. It does not approve final injury, damage balance, death animations or enemy death rules, and does not alter confirmed combat design above.

`Enemy/DebugHealth` is a small Node using `scripts/static_enemy_health.gd`. Inspector parameters are **Max HP = 100** and **Test Damage = 25**, shared by all three existing motions. Initial HP equals the configured maximum. The maximum has a positive minimum of 1; negative damage is clamped to zero. HP is read-only externally and remains within [0, Max HP]. Lowering the maximum clamps current HP; increasing it neither heals nor revives the enemy. Explicit debug reset fills the configured maximum.

The node subscribes only to `WeaponContactDebug.valid_attack_contact_detected`, checks `contact_kind: valid_attack` and the actual target identity, then subtracts the configured damage. No independent distance, animation-time or visual-overlap damage test exists. Physical Contact never deducts HP. In addition to the detector's existing deduplication, the HP receiver remembers damaged request IDs for the current debug life, preventing duplicate delivery from deducting twice. New requests may damage again. F4 only controls drawing; damage continues while it is off. Actual removed HP is retained as `last_damage` and logged as `DEBUG_ENEMY_DAMAGE` with request ID, HP/maximum and Dead status; overkill reports the remaining HP removed rather than the full configured value.

At zero HP, `Dead` becomes true and all subsequent damage is rejected. The node, model, contact region and movement collider remain in place; only the enemy body receives a local dark-gray material override. Shared meshes/materials and the player are unaffected. There is no death animation, reaction, knockback, ragdoll, execution, automatic respawn or victory flow. Geometric contact diagnostics may still register against the retained dead model, but they cannot remove additional HP.

F4's development overlay shows **Enemy HP / Max HP**, **Last damage**, **Dead**, and a **Debug Only F7 reset** reminder. All this text hides with F4. Step 4 extends F7 to both actors and cancels active temporary motions before reset, without changing either actor's position. Reset excludes previously accepted requests, so new requests are required before further damage. F7 uses a simple unhandled key event; existing attack mappings and the Input Map are unchanged.

Verification on 2026-10-14: **254 checks passed**, preserving all previous 217 and adding 37 HP/damage checks. New coverage includes initial values and absence of player HP, physical-only overlap, valid contact damage with F4 hidden, duplicate signal/overlap rejection, new requests, target/kind filtering, actual four-hit attacks across all three motions, legal HP bounds, Dead/node retention and isolated material tint, unchanged transforms/collision, subsequent dead-target rejection, F4 text visibility, no automatic revival, F7 reset, old/current request exclusion, configurable maximum and damage, overkill, zero/negative damage, maximum clamping, and fresh post-reset attacks. Editor import, scene loading and headless Main Scene startup passed without script/resource errors.

The user completed Step 3 manual acceptance of the temporary enemy HP/death/reset loop. Its 100 HP and 25 damage remain test values. Step 4 extends the environment to reciprocal damage below; headless checks do not establish rendered color/text readability or input feel.

### Stage 4 Step 4: Stationary Enemy Thrust and Player HP (Historical Rhythm)

The following 2 s cooldown and 25 HP incoming-damage values record the original Step 4 acceptance. Step 8 replaces them with short burst rhythm and **5 HP** incoming damage; player Max HP remains 100. The old single-thrust description is historical, not a second active enemy behavior mode.

This is reciprocal greybox validation, not formal enemy AI or final damage/death balance. `Enemy/DebugAttack` uses one lightweight physics Tween thrust: 0.25 s preparation, 0.25 s extension, 0.30 s return to single-hand guard. It never moves the enemy root. In range, the enemy rotates toward the player's current position at a bounded angular speed while idle; rotation stops during the swing. There is no snapping, mid-swing homing, pursuit, navigation, move selection, attack combination or behavior tree. Being in range only permits a request; it never declares damage. Leaving range allows an already-started attack to finish but prevents new requests. Either actor being Dead prevents enemy attacks; enemy death immediately cancels its current attack.

| Inspector location | Temporary default | Meaning |
| --- | --- | --- |
| `Enemy/DebugAttack` — Enabled | true | Can disable the test attacker |
| Attack Interval | 2.0 s | Cooldown after completion/cancellation; initial wait also uses this value |
| Attack Distance | 1.6 m | World-space origin distance permitting a new request |
| Turn Speed Degrees | 90°/s | Maximum idle facing change |
| Active Window | X=0.25, Y=0.50 s | Tween playback interval, start inclusive/end exclusive; clamped to extension phase |
| `Player/DebugPlayerHealth` — Max HP | 100 | Initial/reset maximum, minimum 1 |
| Incoming Test Damage | 25 | HP removed per valid enemy request, minimum 0 |

The existing `weapon_contact_debug.gd` is instantiated as `Enemy/DebugAttack/EnemyBladeContact` with automatic player-trajectory subscription disabled. Only its target path and query mask are configured differently. It samples the enemy weapon's actual BladeBase/BladeTip transforms and quaternion after physics/Tween updates, uses the same adaptive capsule sweep and active-interval clipping, and emits the same physical/valid event structure with separate enemy request IDs. A 0.25 m radius, 1.7 m tall `Player/DebugContactRegion` follows the player's actual Transform on layer 4. Player attack queries retain layer 2, and enemy queries use only layer 4, excluding enemy/self/ground bodies. Per-request physical and valid deduplication remain separate. Existing sweep approximation limits apply, including discretized rotation and inferred between-frame paths; this is not exact relative CCD for moving targets.

`Player/DebugPlayerHealth` receives only valid enemy contact events for the player and independently deduplicates request IDs. HP stays in [0, Max HP]; overkill reports actual removed HP. At zero, temporary Dead freezes movement/velocity, rejects ordinary and debug attack requests, and cancels the current player motion and enemy attack. No death animation, injury reaction, revive flow or Game Over UI is added; the camera remains operable. Dead players cannot deal damage through a cancelled motion's final diagnostic sample. Enemy HP, death tint and the three player motions remain as before.

F4 adds **Player HP / Max HP**, **Last injury** and **Dead** alongside the existing enemy readout. Hidden debug does not stop either attack/damage path. F7 restores both lives and last-damage values, restores the enemy material, clears player velocity/run toggle/input lock, cancels both active motions and restarts enemy cooldown. It preserves positions/facing; the enemy returns to guard, and future player motions continue from the retained hand pose. Old/current requests cannot be replayed after reset. This is Debug Only, not a respawn design or new formal attack mapping.

Verification on 2026-10-14: **287 checks passed**, retaining the previous 254 and adding 33 stationary enemy attack/player HP checks. Historical checks disable the periodic attacker only inside the test fixture to isolate previously accepted behavior; the normal scene enables it. The earlier enemy-only HP-node check now explicitly describes the unchanged enemy node rather than claiming that player HP is absent. New coverage includes default player HP/damage, outside-range inactivity, periodic in-range requests, fixed enemy origin, actual weapon contacts, exit-range misses and no new requests, four distinct thrusts/once-per-request damage, legal HP bounds, player Dead movement/attack rejection, enemy stopping against Dead players, both F4 readouts/hiding, both-life F7 reset/lock cleanup, restored movement, preparation/return-only overlaps, duplicate valid-event rejection, self-region exclusion, bounded turn rate, frozen swing heading, and enemy death cancellation/future inactivity. Editor import, scene loading and headless Main Scene startup passed without resource/script errors.

The user completed initial Step 4 manual acceptance of stationary thrust, reciprocal damage, death and reset. Step 5 adds the temporary player active defense below; enemy actions and contact/HP parameters remain unchanged. Headless checks do not establish final rendered swing/contact readability or input feel.

### Stage 4 Step 5: Basic Active Guard and Perfect Parry

Step 5's resource-free behavior below records its historical baseline. Step 9 adds a single player resource, held-block costs and break availability; input and contact/angle rules remain.

`Player/DebugDefense` uses `scripts/debug_player_defense.gd`. The only added Input Map action is `active_defense`: **L1 / Xbox LB** and **right mouse button (RMB)**. Q is no longer bound to defense. RMB has no other project Input Map binding: look remains mouse movement, capture remains LMB, and Soft Lock remains Tab/R3. Press/hold/release use the same existing action polling and state transitions; no defense script or combat values change. Neither binding overlaps existing movement, camera, attack or debug actions. Press starts **Perfect Parry**, default **0.15 s**; remaining time decreases on physics ticks. Keeping the same press never renews it: after expiry the state becomes **Held Guard**. Release immediately removes defense when input is processed. Dead players cannot defend. Inspector exposes **Perfect Window Seconds** and **Defense Half Angle Degrees**, default **60° per side** (120° full cone); the editor range remains below 90° per side so rear sources cannot be guarded. These are temporary tests, not replacement values for the formal defensive timing/resource design.

The player HP receiver resolves defense only after a real **Valid Attack Contact** from the existing enemy blade sweep. Windup/return physical overlap and proximity alone never produce a block/parry. Facing uses the horizontal direction from the player origin to the actual attacking enemy origin, compared with the player's actual -Z forward. No automatic turn, face-target or soft lock is added. This is a minimal source-facing filter over blade/body contact, not weapon-versus-weapon interception, defense animations or full sword alignment.

Within the frontal cone, a held press with positive parry time yields **Perfect Parry**; a held press after expiry yields **Block**. Either prevents the whole test damage and sets the latest injury to **0 HP**. No press, rear/out-of-cone source, or otherwise unavailable defense yields **Failed** and ordinary HP deduction. The HP receiver consumes the enemy request ID before resolving defense, so a blocked request cannot damage later through duplicate delivery or after release. Both successful outcomes have no Stamina/Posture cost in this test. No instinctive defense, guard break, enemy stagger, disarm, retaliation reward or execution is included.

Defense has physics priority before player attack input, and the common attack entry also refreshes defense input. Both ordinary and forced debug requests are discarded while defending; no buffer is created. A fresh defense press immediately cancels an existing player Tween and closes its active window, retaining the current hand pose as the beginning of Step 6's defensive transition. Its final trajectory diagnostic cannot deduct enemy HP once defense is active. The original **remaining 0.26/0.24/0.30 s request lock is preserved**, so releasing defense cannot bypass it; after lock expiry and release, a fresh attack request is required. No generic cancellation framework or new combo rule is added.

F4 adds current **None / Perfect Parry / Held Guard**, precise-window remaining seconds, latest **Perfect Parry / Block / Failed**, prevented damage and latest injury (zero on success). Both HP readouts remain. F4 off hides this text without affecting resolution. F7 clears held/parry state and results alongside both HP/motion resets; if defense is still physically held through reset, release and press again to rearm. This prevents a held key from silently starting another perfect window after F7.

Verification on 2026-10-14: **319 checks passed**, preserving all previous 287 and adding 32 active-defense checks. Historical coverage included Q/L1 binding and no conflicts; the current RMB replacement is covered by the latest regression suite below, alongside, Inspector defaults, press/hold/release transitions without parry extension, ordinary/debug attack rejection and no buffering, real-cylinder valid-contact parry/block versus rear/unguarded damage, prevented HP, lethal failed defense and Dead gating, timed parry and long-held block against the full existing enemy thrust, F4 state/result/zero injury and hiding, current-motion cancellation with unchanged hand pose and preserved input lock, fresh post-lock attacks, adjustable cone without auto-facing, zero-duration parry, F7 state/record cleanup and release-to-rearm. Editor import, scene loading and headless Main Scene startup passed without script/resource errors.

The user completed initial Step 5 manual acceptance of the original Q/L1 defense and damage prevention. The later input-only adjustment replaces Q with RMB without changing those rules. Step 6 adds primitive visual transitions and independently observes blade contact below; it does not replace these accepted damage conditions.

### Stage 4 Step 6: Defense Motion and Blade Contact Diagnostics

`DebugDefense` owns a small physics Tween while raising/holding/returning the right hand. A press transitions from the current hand pose toward the short parry pose in 0.06 s, then settles into Held Guard in 0.09 s. A zero parry duration goes straight to guard. Release returns to existing Idle Guard in 0.20 s. New transitions kill only the previous defense Tween and retain its current transform; an accepted player attack stops any unfinished visual return before continuing the existing attack executor. The weapon remains a child of the hand with its original local transform. No bone, IK, AnimationTree or imported animation asset is added.

| Temporary pose in player local coordinates | Hand position (m) | Hand rotation (degrees) |
| --- | --- | --- |
| Short parry | (0.22, 1.14, -0.62) | (-55, 0, 70) |
| Held Guard | (0.30, 1.08, -0.42) | (-65, 0, 65) |

These pose vectors and Return Seconds are editable on `Player/DebugDefense` under **Temporary Defense Poses**. They are experimental coverage poses, not approved sword techniques. The 0.15 s precise window, ±60° cone, RMB/L1, original request locks, HP/damage and enemy thrust are unchanged. A canceled player attack begins defense from its current pose, without snapping to Idle first.

`BladeClashDebug` reads both weapons' actual BladeBase/BladeTip world transforms and rotation quaternions. Between paired samples it interpolates each base, quaternion and blade length at the same time fractions. A conservative travel bound combines both blades' base translation and rotation/length travel; the default 0.005 m subdivision step is capped at 1024. At each subdivision, closest points between the two blade segments are checked against their combined thickness (default radius 0.012 m each). A detected event reports the midpoint of these closest points as the approximate thickness contact location. Fast translation, rotation and simultaneous blade movement are considered, rather than only frame-end poses, character distance or defense state.

Detection runs during each complete enemy request, including preparation/return, and emits at most one independent `blade_clash` event per enemy request. Fields include `request_id`, world `position`, `physics_frame`, sample `fraction` and current `defense`. The last 32 events remain in memory. It runs before the existing enemy/body query at each actual physics sample, so a lethal body contact does not suppress that frame's earlier blade observation. No hit reward, weapon redirection, sustained lock or Bind is produced.

This is a thin-segment/capsule approximation and adaptive sampled sweep, not an exact rigid-body contact solver. Quaternion/base interpolation infers the unobserved path; tiny grazing contacts may differ at the subdivision/thickness scale. Reaching the cap warns and reduces precision. The returned position represents approximate overlap of the modeled blade thickness, not a mesh triangle contact. Parameters are Inspector diagnostics on `BladeClashDebug`, not final collision/balance rules.

For each enemy request, diagnostics separately retain blade clash, physical body contact, valid body contact, defense state at valid body contact, and final damage prevention (YES / NO / pending). **Step 5 body-contact plus frontal-angle defense remains authoritative**, even when no blade clash is observed. Blade contact never adds or removes HP and is not required for parry/block in this step. Coverage mismatches must be reviewed as pose/trajectory observations; they do not silently redefine defense or confirm formal sword contact rules.

F4 uses **blue crosses** for blade clashes, **orange-red crosses** for enemy-blade/player-body contact and an **aquamarine segment** for the actual enemy blade. Existing player trajectory/body markers remain. The overlay separates clash/body/valid-body flags and final prevention from the current Perfect Parry/Held Guard status. All markers use the existing temporary lifetime and disappear with the shared mesh/overlay when F4 is off; sampling continues. F7 resets both lives/motions/defense as before, clears clash records and temporary contact markers, and smoothly returns the hand toward Idle. Holding through reset still requires release/repress.

Verification on 2026-10-14: **345 checks passed**, preserving previous 319 and adding 26 motion/clash checks. The previous frozen-hand assertion now checks bounded first-frame movement because visible defense is explicitly authorized; other prior checks remain. Added coverage includes immediate pose continuity, visible raise, configured held pose, distinct parry/guard, hand attachment, smooth return and attack ownership after return interruption, static crossing/contact position, near miss, fast translation with missing endpoints, both-blade motion, rotational sweep, actual Marker transforms, event identity/once-per-request delivery, no HP side effect, F4 statuses/markers/hiding, F7 record cleanup, body/defense/final-result association and no tested subdivision overflow. Editor import, scene loading and headless Main Scene startup passed without resource/script errors.

**Observed coverage mismatch:** with the enemy origin 0.24 m to the player's right and 0.9 m forward, a completed thrust against Held Guard recorded `blade_contact=false`, `body_contact=true`, `valid_body_contact=true`, `damage_prevented=YES`, and player HP remained 100. Thus this test pose does not physically intercept that blade trajectory even though the accepted angle/body-contact baseline blocks damage. The result is explicitly retained for visual/pose review; neither the damage rule nor the attack trajectory was changed to force agreement. It does not prove that every other pose/distance misses, nor that formal defense may ignore blades.

The user completed initial Step 6 acceptance of defense motion and blade diagnostics, including the coverage discrepancy above. Step 7 addresses it below; the Step 6 discrepancy is retained as a historical baseline.

### Stage 4 Step 7: Procedural Blade Contact Matching

The confirmed direction is to retain reasonable defensive angle tolerance while adapting the weapon pose to the actual incoming blade. Future authored **Animation + IK** may replace this greybox layer. `Player/ContactMatchingDebug` uses `scripts/debug_contact_matching.gd` to correct only the existing right-hand Transform, never the character root, weapon attachment or attacker's motion. There is no skeleton, general IK solver or animation framework.

Matching runs before independent blade/body queries on actual enemy physics samples, only when the player is alive and defending, the source is inside the existing ±60° cone, and enemy playback is in its existing active window. Actual enemy base/tip positions and observed tip displacement determine targets and incoming direction. Candidate contact points use the interior 10–90% of the enemy blade and 20–80% of the player's blade. Hand-local Marker offsets solve the required hand position. Candidate rotations retain the baseline basis or turn toward the target within the angular limit; selection favors small corrections and crossing the observed incoming motion.

Targets must admit a bounded pose with hand height 0.8–1.75 m and the grip/entire blade forward of local Z=-0.28 m. Applied intermediate poses are checked too. This conservative front plane protects the cylindrical greybox; it is not a full anatomical self-collision solver. Translation and quaternion rotation approach the target at bounded speeds, without teleporting or changing blade thickness. Unreachable/unsafe poses record a failure reason and retain the existing defense result.

| `Player/ContactMatchingDebug` Inspector parameter | Temporary default |
| --- | --- |
| Enabled | true |
| Max Position Correction | 0.30 m from current matching baseline |
| Max Rotation Degrees | 35° from that baseline |
| Hand Speed | 3.0 m/s |
| Rotation Speed Degrees | 360°/s |
| Contact Hold Seconds | 0.08 s |
| Recovery Seconds | 0.12 s |

The defense Tween yields hand control on entry, retaining the current pose. Perfect Parry begins from its short raised pose and does not renew the 0.15 s window. Held Guard adapts as the actual attack approaches. Only an independently detected real clash starts the brief local-pose hold. After that single contact for the enemy request, matching stops tracking and smoothly restores guard. Release returns toward Idle as before; attack end, death, out-of-cone source and reset stop correction. This brief visual hold does not constrain the enemy weapon or create Bind, sustained tracking, pressure, rewards or new cancellation rules.

**Matched** means the applied chosen player-blade point is within 0.01 m of the target. **Limited** means a feasible target is still approached under speed limits. **Failed** records no feasible safe pose or an out-of-cone source, with a reason. These pose outcomes are separate from real clash detection and damage prevention. Matching never emits Blade Clash; `BladeClashDebug` alone detects it at the unchanged 0.012 m radius. The accepted body-contact/angle baseline still determines blocked damage when matching fails.

F4 adds activity, target world position (yellow cross while active), position/rotation correction, Matched/Limited/Failed and reason, alongside the separate real-clash and prevention flags. Hidden debug does not change behavior. F7 clears request/hold/target/correction data with the existing resets.

Verification on 2026-10-14: **362 checks passed**, retaining all previous 345 and adding 17 matching checks. Historical tests disable only the new correction in their fixture; the normal scene enables it. Added coverage checks active response, real clash in the formerly uncovered stance, pose convergence, limits and per-frame continuity, front-body safety, root/attachment preservation, unchanged radius, unchanged guard result, recovery/no ongoing tracking, separate F4 states/hiding, F7 cleanup, zero-limit failure with baseline block preserved, rear rejection/damage, and unchanged timed-parry behavior. Editor import, scene loading and headless startup passed without errors.

**Typical stance:** enemy origin 0.24 m right / 0.9 m forward, Held Guard: `blade_contact=true`, valid body contact true, damage prevented YES, HP 100. Measured maximum correction was approximately **0.0081 m / 11.93°**, maximum frame position step **0.0118 m**. This improves the Step 6 no-clash baseline without changing radius or damage. With position/rotation limits both zero, matching fails explicitly, real clash remains false, and the original Block still prevents damage. A later timed Perfect Parry test also prevented damage but recorded no real clash; safe bounded matching is not guaranteed for every timing. The 0.15 s window was not extended to force coverage.

The user completed initial Step 7 acceptance and approved directional rhythm tests. Late-input coverage remains a limitation, not a reason to silently change damage rules. Step 8 keeps correction limits and uses each new enemy move's own active window.

### Stage 4 Step 8: Rapid Directional Enemy Test Bursts

This is temporary greybox attack pacing for defensive motion/matching review, **not formal enemy AI** or a player combo system. The enemy remains stationary and uses a predictable repeating **Thrust → Left Cut → Right Cut** order; groups of four/five continue the cycle without adjacent duplicates. Each sword gets a monotonically increasing request ID, separate body/clash record and valid-contact deduplication. There is no random selection, navigation, pursuit or new decision framework.

| `Enemy/DebugAttack` Inspector parameter | Current test default |
| --- | --- |
| Sequence Length | 4 swords, editor range 3–5 |
| Attack Gap Seconds | 0.15 s, editor range 0.10–0.20 |
| Sequence Recovery Seconds | 0.80 s, editor range 0.6–1.0 |
| Attack Distance / Turn Speed Degrees | Unchanged: 1.6 m / 90°/s |
| Active Window (Thrust) | [0.25, 0.50) s |
| Left Cut Active Window | [0.12, 0.32) s |
| Right Cut Active Window | [0.12, 0.32) s |

Thrust retains its original preparation/extension trajectory and uses a short 0.10 s follow-through bridge inside a group (0.60 s authored total). Left Cut sweeps from one side to the other; Right Cut reverses direction using different hand positions and rotations. Each cut uses 0.12 s preparation, 0.20 s strike and 0.10 s follow-through (0.42 s total). Their windows read the same motion Tween and clamp to each move's strike phase. Gaps start after actual playback completion, not an independent nominal-duration timer; physics-frame quantization may add roughly a tick to requested timing.

Each new Tween begins from the actual current hand pose. Group attacks finish in follow-through instead of snapping to Idle. Only group completion/range-abort blends toward Idle over 0.25 s during the recovery interval. Idle/gap facing remains speed-limited and freezes during a sword; the enemy root never translates. Leaving range finishes the currently started sword and discards remaining group swords (or aborts immediately during a gap). No new group starts out of range. Enemy/player death, disabling the test attacker or F7 immediately cancels the current Tween and clears group/index state; reset starts a fresh recovery delay, without a queued sword surviving.

`Player/DebugPlayerHealth` now defaults to **Incoming Test Damage = 5 HP**. Player Max HP remains **100**, and enemy HP/player outgoing damage remain **100 / 25 HP**. Only actual valid enemy body contact deducts HP, once per request; new requests can deduct independently. Preparation/return contact never damages. Perfect Parry and Held Guard retain their existing ±60°/0.15 s input rules and no resource cost; a held key never gains a refreshed parry from a new sword.

The existing detector retains player motion labels but accepts explicit enemy labels, so enemy events identify Thrust/Left Cut/Right Cut correctly. `BladeClashDebug` keeps bounded per-request records (last 32), including move, start/end frames, body/clash flags and prevention. No sword collision is fabricated to guarantee a group presentation.

Matching only changes how it reads active bounds: it asks the current enemy move for its window rather than assuming the old thrust interval. Position/rotation/speed/safety limits and the independent real-clash detector are unchanged. F4 adds current burst activity, sword index/count, move name and recovery/gap countdown alongside existing records. F7 also clears group and diagnostic histories. These changes do not establish a generic ability, animation or combat framework.

Verification on 2026-10-14: **438 checks passed**, retaining previous 362 and adding 76 burst/current-damage checks. Historical fixtures explicitly use one sword and 25 HP incoming damage to preserve prior death/defense coverage; the normal scene uses the new defaults. New checks cover default 5 HP, actual 3/4/5-sword groups, independent IDs/records and cycle order, continuous hand position/rotation, fixed root, distinct ordered Left/Right trajectories, actual 5 HP body damage, per-request deduplication and named active windows, gap measured from actual completion frames, group recovery, held guard/expired parry, per-direction matching attempts, independent real clashes, F4 burst info/hiding, range exit, F7 cancellation/no stale sword and death cancellation. Godot editor import, scene loading and headless Main Scene startup passed without script/resource errors.

**Observed four-sword guard coverage** at 0.24 m right / 0.9 m forward: all four valid body contacts were blocked, player HP stayed 100 and three independently detected clashes were recorded (Thrust, Left Cut, final Thrust). Right Cut had no real clash and its matching result was **Limited / Speed-limited approach**. Last observed per-direction matching also included a Thrust Failed/no-safe-pose sample and a Left Cut Matched sample; a pose status at one later sample is not the same as an earlier real clash. Maximum player-hand frame step was approximately **0.050 m / 6°**, within the existing speed limits. The higher-frequency matching limitation is retained; no radius inflation, forced contact event, expanded correction limit or solver refactor was used.

The user completed initial Step 8 acceptance of bursts/damage/reset and matching. Its resource-free observations above are the historical baseline; Step 9 adds costs and break availability below. Right Cut/late-matching limitations remain; real clash and defense outcomes are still distinct.

### Stage 4 Step 9: Single Defensive Resource and Guard Break

This section records Step 9's accepted historical 25 Resource held-block baseline. Step 14 supersedes only that test cost with 10; the resource/recovery/exhausting-hit rules below remain.

`Player/DebugDefense` owns **one** temporary Resource pool, without splitting Stamina and Posture or redefining their formal role above. Initial/reset resource equals Max Resource; values stay in [0, maximum]. Lowering the Inspector maximum clamps the stored value; F7 fills the configured maximum. No attribute framework or enemy-resource system is added.

| Inspector — Temporary Single Defense Resource | Test default |
| --- | --- |
| Max Resource | 100 (minimum 1) |
| Held Guard Cost | 25 per successfully blocked request |
| Guard Break Seconds | 1.0 s |
| Recovery Delay Seconds | 1.0 s |
| Recovery Per Second | 20 points/s |

**Perfect Parry** retains the 0.15 s press window, ±60° source-facing filter and actual valid body-contact requirement, fully preventing HP damage at zero resource cost. Holding does not refresh it. **Held Guard** charges only a successful valid block; there is no holding-time drain, physical-only contact cost or failed/rear-defense cost. The HP receiver already deduplicates request IDs, and the defense resolver also caches each request's blocked/failed result. Repeated delivery cannot charge again or reconsider the exhausting hit. Debug last cost shows actual clamped resource reduction, possibly less than 25 on an underfunded final block.

Positive pre-block resource permits held defense without requiring full payment. Reaching zero, including an oversized cost, **still completely blocks that attack**, then immediately starts Guard Break. Effective held/parry state and matching are cleared; that event keeps Block and zero injury. Its body record preserves the successful pre-break state. Subsequent valid hits fail defense and deduct the existing 5 HP. No retroactive damage, automatic defense or enemy reward is introduced.

Guard Break has its own 1.0 s timer and cannot be canceled by releasing/repressing RMB/L1. Returning/raised hand visuals cannot block during it. This step validates defensive availability; the full formal uninterruptible Stagger animation/action process remains deferred. No knockback/fall or new movement/attack locking framework is added, and existing request locks/no-buffer behavior are unchanged.

Recovery is explicit: none during break, while Dead or while defense input is pressed. Break expiry starts a fresh delay, without refill on the expiry tick. At zero resource defense remains unavailable until some resource returns. Release, wait 1.0 s, then recover 20 points/s; holding/repressing pauses recovery and resets the delay. Holding through expiry neither recovers resource nor creates a new parry. Once resource is positive, a new press can defend. Recovery clamps at maximum. These are greybox rules rather than complete breathing/intent arbitration.

F4 adds Resource/Max Resource, last block cost, Guard Break flag/time and recovery state/delay alongside the last defense result, HP and independent clash data. Visibility never affects settlement. F7 restores full resource and clears break, recovery time, request cache and last cost with the existing resets. Holding through F7 still requires release/repress. Death clears effective defense without replenishing resource.

Verification on 2026-10-14: **465 checks passed**, preserving previous 438 and adding 27 resource/break checks. Historical fixtures set block cost to zero to retain accepted resource-free behavior; the normal scene uses 25. Added coverage checks defaults, physical-only/precise/held/rear contacts, event deduplication, no passive drain, exhausting-hit prevention and subsequent HP damage, release/repress resistance, immediate matching/defense cleanup, F4 data/hiding, break recovery suppression/expiry, zero-resource gating, delay/rate/holding pause/cap, underfunded positive-resource absorption, F7 cleanup and native five-sword resource settlement. Godot import, scene loading and headless startup passed without script/resource errors.

**Native five-sword result:** four valid held blocks each consumed 25 (resource 100→75→50→25→0) and prevented damage, including the exhausting fourth hit. The fifth valid hit during break caused 5 HP damage: final player HP 95, resource 0; records contain four prevention YES results and a final NO. No damage rule depends on a real blade clash.

Manual review must test four-block exhaustion, subsequent damage, timely parries conserving resource, release/delay recovery, break versus lingering hand pose, F4 readability and F7. Step 9 passed initial manual acceptance. Its resource and damage rules remain; Step 10 adds temporary break motion and constraints below. No formal resource UI or instinctive defense is included.

### Stage 4 Step 10: Guard Break Motion and Action Constraints

Step 9 has passed initial manual acceptance. This step adds temporary greybox feedback to the existing resource settlement, without changing formal Stamina/Posture terminology or implementing the full Stagger process.

On an exhausting held block, `DebugDefense` clears effective defense and Contact Matching, records the enemy request ID, and stops any player motion without clearing its remaining ordinary input lock. A physics Tween starts from the actual current right-hand pose, deflects the hand and attached gunblade, briefly holds, then smoothly returns to Idle Guard. The player root and collision shape are untouched. Blade Clash still requires actual contact; no event, radius or attack window is altered.

| Inspector — Player/DebugDefense, Temporary Guard Break Motion | Temporary default |
| --- | --- |
| Break Deflect Seconds | 0.12 s |
| Break Hold Seconds | 0.08 s |
| Break Return Seconds | 0.30 s |
| Break Position Offset | (0.22, -0.10, 0.08) m, relative to current hand position in VisualRoot coordinates |
| Break Rotation Offset Degrees | (20, 0, -45), composed in current hand-local axes |

The default visual lasts 0.50 s; the independent combat restriction remains 1.0 s (`Temporary Single Defense Resource / Guard Break Seconds`). Both are adjustable greybox values. A new permitted attack after expiry can blend from an unfinished visual if these durations are changed.

During Guard Break, the shared ordinary/debug attack executor rejects all requests without buffering, and effective defense is unavailable. Normal movement and camera control remain available. Attack permission returns on expiry, subject to existing death/ordinary-lock checks. Holding RMB/L1 through expiry does not restart defense: release and a new press are required, with positive resource. Repressing during break does not count as that post-break press. No full-body stun, knockback or new input architecture is introduced.

The exhausting block still prevents its entire damage, and subsequent independent valid contacts still cause 5 HP damage. Perfect Parry remains free, held blocks cost 25, player damage remains 25, and resource recovery stays release-delayed at 1.0 s / 20 points per second. Request IDs, deduplication, enemy sequences and active windows remain unchanged.

F4 now includes explicit combat state, Attack/Defense availability and the most recent break-trigger request alongside resource change, defense result and remaining time. F4 visibility never affects settlement or permissions. F7 cancels motion/defense Tweens, restores the exact Idle Guard debug pose, clears ordinary locks, matching, break/trigger records and recovery, and refills both HP pools and resource. The reset pose is intentionally immediate; gameplay transitions remain smooth.

Verification on 2026-10-14: **487 checks passed, zero failures**, preserving all previous 465 and adding 22 checks for explicit state, trigger ID, continuous visible hand displacement/return, root/attachment stability, ordinary/debug attack rejection, movement/camera availability, matching cleanup, F4 permissions, expiry/release latch and mid-break F7 cancellation with no later Tween overwrite. The native five-sword fixture still records four blocked hits, including resource exhaustion, then one 5 HP damaging hit. Godot editor import, scene loading and headless Main Scene startup passed without script/resource errors; diff whitespace checks passed.

Manual review must confirm readable deflection, natural rotation and return, no body penetration, preserved movement/camera during break, held-Q rearming behavior, repeated burst damage and mid-motion F7 reset. Step 10 has passed manual acceptance. No formal animation assets, IK, effects or Soft Lock are added; Step 11 automatic defense is the next authorized greybox increment below.

### Stage 4 Step 11: Temporary Instinctive Defense

Step 10 has passed manual acceptance. This greybox step resolves automatic defense at the existing swept **Valid Attack Contact** callback, before HP is deducted. Proximity, physical-only contact and animation time alone cannot trigger it. Successful active Perfect Parry/Held Guard take priority. Otherwise, an alive player outside Guard Break may automatically stop a frontal valid contact without RMB/L1 or actor rotation.

**Explicit temporary exception:** this step requires full payment of the automatic cost. The earlier formal design's positive-pre-trigger-resource rule remains recorded above; this authorized greybox test does not silently redefine that rule. Default cost is 50 Resource: insufficient positive resource causes ordinary damage; exact payment stops the exhausting hit then enters Guard Break. Costs never become negative, and each request's resolved result is cached. Perfect Parry remains free, Held Guard costs 25, incoming damage remains 5 HP and outgoing damage remains 25 HP.

| Inspector — Player/DebugDefense, Temporary Instinctive Defense | Greybox default |
| --- | --- |
| Instinctive Enabled | true; historical test fixtures disable only this new response |
| Instinctive Cost | 50 Resource (minimum effective cost 1) |
| Instinctive Raise Seconds | 0.06 s |
| Instinctive Intercept Seconds | 0.18 s |
| Instinctive Stagger Seconds | 0.12 s |
| Instinctive Return Seconds | 0.22 s |
| Instinctive Stagger Offset | (0.10, -0.06, 0.04) m in VisualRoot coordinates |
| Instinctive Stagger Rotation Degrees | (10, 0, -20) in hand-local axes |

The existing ±60° source-facing cone, guard pose and Contact Matching correction/speed limits remain adjustable at their existing Inspector locations. Angles, costs and hand feedback are temporary test values.

On success, the current player attack is canceled immediately, its active window closes, and its remaining no-buffer lock is preserved. A stale outgoing final sample cannot damage during the reaction. The canceled attack is never restored, queued or replayed. A continuous short raise enters the existing safe guard envelope, then bounded Contact Matching follows the actual enemy blade for that request only. Ordinary hand stagger and return follow; movement and look remain available. This short automatic hand reaction temporarily rejects new player attack/defense requests. Another independent qualifying enemy contact can trigger again while resource permits, replacing the old hand Tween continuously from the current pose; it cannot refresh or charge the same request. RMB pressed during the reaction requires release/repress to begin active defense afterward.

Matching starts after actual body-contact confirmation. The same request's visual matching can continue through the remaining enemy recovery motion, without extending its effective attack window or adding damage opportunities. A real Blade Clash still comes only from unchanged two-blade space detection. No clash is guaranteed, fabricated or produced by enlarging blade radii; a late contact, ended request or bounded pose can limit matching. On exact resource exhaustion Guard Break takes priority over ordinary automatic interception/stagger, using the existing break visual and restrictions.

Resource recovery retains its previous release/delay/rate rules; successful automatic defense restarts the recovery delay. F4 adds latest automatic trigger status, trigger request, actual cost, action phase, rejection reason and independent real-clash status alongside matching/break data. F7 clears the action, request/payment records, all hand Tweens and matching targets, then restores the existing HP/resource/Idle/lock state. No formal full-body hit reaction, IK, new move, Soft Lock or AI framework is included.

Automated verification on 2026-10-14 with **both normal timing and fixed 60 fps steps: 523 checks passed, zero failures**, retaining all 487 historical checks in explicit pre-automatic-defense fixtures and adding 36 for real contact/active-window gating, full/exact/insufficient payment, duplicate requests, active-defense priority, rear sources, attack cancellation/stale-damage suppression/no lock reset, smooth raise/return, reset cleanup, native directional swords, independent real clash and five-sword resource-limited bursts. The normal scene enables automatic defense. Godot editor import, scene loading and headless Main Scene startup passed without script/resource errors; diff whitespace checks passed.

At enemy offset (+0.24 m right, 0.9 m forward), native unheld Thrust, Left Cut and Right Cut each prevented damage at 50 cost. Right Cut reached Matched and independent real Blade Clash. Thrust/Left Cut failed the front-body-safe bounded-pose solve and did not report clashes; this late-intercept coverage remains a limitation. Native five-sword sequences automatically block their first two contacts (100→50→0), including the break-trigger contact, then receive three 5 HP hits (final HP 85). No failed match is converted into a fake clash.

Automated results and manual acceptance remain separate. Manual review must check emergency raise speed, blade coverage, natural stagger/return without snaps or body penetration, rapid bursts, exact-payment break priority, attack interruption and repeated F7 resets. Step 11 has passed manual acceptance. Its full-payment greybox rules remain in force; Step 12 integrates existing mechanisms below. Stage 3 remains postponed rather than cancelled.

### Stage 4 Step 12: Local Combat-State Arbitration and Ownership

Step 11 has passed manual acceptance. This integration adds no ability, move, input mapping or balance change. Existing `DebugPlayerHealth` remains the single incoming valid-body settlement entry; `DebugDefense` retains local defense resolution and hand transitions. No Combat Manager or generic state/input framework is added.

**Audit and call order:** normal/debug requests share the motion executor and refresh current defense input before permission checks. `DebugDefense` advances resource/break/parry/automatic timers at physics priority -10; player motion runs at priority 5. The enemy deferred sample reads actual weapon Transforms, updates bounded matching, performs independent blade-clash detection, then emits physical/active-window body contacts. Player HP reserves the incoming request ID before resolving defense, commits its final result once, and only applies damage when unblocked. Blade/body diagnostics read that request's committed result. Separate requests settle in callback delivery order against the current physics/input state, including same-frame resource depletion; no later defense retroactively revises an earlier result.

| Event priority | Settlement |
| --- | --- |
| Dead | No new attack or defense; incoming HP entry ignores further contacts |
| Guard Break | No attack, active guard or automatic defense; a new valid contact causes normal damage |
| Successful frontal Perfect Parry | Complete prevention, zero cost |
| Successful frontal Held Guard | Complete prevention, 25 Resource cost |
| Otherwise eligible Instinctive Defense | Complete prevention, full 50 Resource payment required |
| Unblocked valid contact | Existing 5 HP damage |

Player attack is not defense and remains interruptible by automatic interception. Exhausting held/automatic contacts keep their successful result before break begins; subsequent independent IDs can damage. Parry and break expiry clamp negligible floating-point residue to zero so the confirmed boundaries are not accidentally prolonged. Numeric windows/costs/recovery remain unchanged.

**Actual issues and local repairs:**

- The enemy sampler called automatic matching twice per physics frame, doubling correction/hold progression. Remove the duplicate call and guard matching advancement to at most one eligible update per physics frame. No enemy pose, rhythm, window, blade radius or solver bound changes.
- Match recovery could overwrite a freshly started parry after a release/repress in the same frame. Existing `DebugDefense` now claims hand ownership (Attack, Guard, Matching, automatic raise/return, break, death return); hand transitions stop the old visual/attack writer and invalidate old matching as appropriate. Completed attack/return releases ownership to Idle. This is local Transform ownership, not a mutually exclusive combat state machine.
- Blade/body diagnostics used the latest global defense string, which could belong to another request. The existing HP request cache now stores the immutable final result, actual damage, resource before/after and physics frame after its pending reservation. Diagnostic consumers use this per-request record and never trigger settlement.
- F7 left detector-local samples/history alive, and a reset inside a contact/transition callback could allow the old callback to continue. Reset clears detector state and increments reset generations; receivers reject stale-generation events, and an in-progress sweep stops after a reset. Defense/HP verify their reset generation before committing continuation. Motion end notification rejects reentrant duplicate closure; clash sampling likewise cannot restore old history after a reset inside its signal.

F4 adds just one compact line: final result/request and current hand owner. Death immediately clears effective defense, automatic phase and matching; only the existing non-defensive return remains. F7 cancels both actors' requests and all hand writers, restores HP/resource/Idle/locks, clears settlement/defense/contact records and matching, and preserves monotonic request IDs. Historical trajectory trails remain diagnostic history; cleared contacts cannot settle again.

**Resource-rule difference remains open:** the accepted prototype still requires full 50 payment for Instinctive Defense. The earlier positive-pre-trigger-resource proposal remains recorded; choosing the final formal rule requires a separate decision. Perfect Parry 0, Held Guard 25, incoming/outgoing damage 5/25, resource maximum/recovery, Guard Break 1.0 s, movement 2.0/3.5 m/s and all input mappings remain unchanged.

Verification on 2026-10-14 with both normal timing and fixed 60 fps: **557 checks passed, zero failures**, retaining all previous 523 and adding 34 checks. Added coverage includes active/automatic competition, attack/contact order, exact parry expiry and exhausting payment, cached duplicate settlement, same-frame matching advancement and handoff, death during guard raise, F7 during automatic/break/active-swing states and inside physical-contact, attack-end and actual-clash callbacks, stale-generation rejection, diagnostic result provenance and release of hand control. Godot editor import, scene loading and headless Main Scene startup passed without script/resource errors; diff whitespace checks passed. Visual feel and manual acceptance remain pending.

Known late Thrust/Left Cut matching failures remain geometric limitations. Matching failure does not invalidate a successful defense, and this step neither enlarges radii nor modifies trajectories to improve it. Manual review should alternate attack/Q, hold/repress during break, allow automatic interruption in a burst, die mid-defense, and use F7 during an active swing, automatic raise or break; check for competing hand motion, stuck poses or repeated settlement. Step 12 has passed acceptance; Step 13 basic Soft Lock follows below. Stage 3 remains postponed.

### Stage 4 Step 13: Basic Single-Target Soft Lock

This section records the accepted basic-lock baseline. Step 14 below supersedes its horizontal 20° clamp and deferred unlock/reacquisition scope; 20° remains the vertical adjustment limit only.

Step 12 has passed acceptance. Development order now places Soft Lock before enemy basic defense/AI. Only the basic lock is authorized here; Step 14 will address formal release timing, reacquisition and angle response. No new enemy behavior, combat capability or general target/camera manager is added.

**Inspection:** the existing rig is `ThirdPersonRig → PitchPivot → SpringArm3D → Camera3D`. It orbits the player's 1.55 m observation height with a 2.5 m rear distance and 1.0 m right offset, using perspective and native collision exclusion. Movement already uses the actual camera's horizontal right/back axes and faces realized motion when unlocked. Attacks already select from the three existing motions using actual actor facing and the same Enemy reference. Mouse and RS rotate the orbit independently of character heading.

`third_person_camera.gd` stores the single actual `Enemy` reference. **Tab / R3** (`JOY_BUTTON_RIGHT_STICK`, index 8 in this Godot build) toggle acquisition/release; keyboard repeat is ignored. The lock point is `Enemy.to_global(Vector3.UP * Lock Target Height Offset)`, default body center at 0.85 m, not the floor origin or a cloned target. No range gating, alternate target choice or automatic acquisition is implemented.

Locked yaw/pitch aim toward that actual world point plus bounded manual mouse/RS offsets, then use exponential smoothing. Existing positional follow, spring collision shape/margin, player exclusion, near/far/FOV and projection stay unchanged. Shoulder bias scales the existing right offset and blends without an entry/exit snap; default 1 preserves the current composition. Release keeps the actual current orbit angles, then restores ordinary free-look input.

In `player_controller.gd`, movement/collision/gravity/speeds remain camera-relative. Only heading changes: when locked, horizontal target direction replaces movement-facing yaw with smooth turning. This supports side stepping/backing away without pursuit, attack initiation, distance compensation or root-position manipulation. When unlocked, the original realized-motion heading resumes. This local branch is not Step 14's formal orientation-mode system. Dead exits the movement/turn path before lock steering.

| Inspector — TestArena/ThirdPersonRig, Temporary Single Target Soft Lock | Default |
| --- | --- |
| Lock Camera Follow Speed | 8.0, exponential angular/shoulder response |
| Lock Character Turn Speed | 8.0, exponential yaw response |
| Lock Target Height Offset | 0.85 m in Enemy-local coordinates |
| Lock Camera Shoulder Bias | 1.0 × existing Right Offset |
| Lock Manual Look Degrees | 20° temporary yaw/pitch offset clamp |

The 20° clamp only keeps Step 13's free adjustment small. It neither implements the formal ±40° safe range nor releases lock when input persists against the clamp. No 0.8–1 s timer, candidate randomization, movement/camera reacquisition cones, Curve resource or shoulder switch exists. Composition and control feel remain adjustable greybox values.

Attack selection, animation, real blade sweeps, active windows, locks, HP/resource costs and enemy trajectories/rhythm remain unchanged. Defense checks the actual player's ±60° facing cone; a lock reference cannot bypass it. Guard Break permits the locked camera, while player Dead clears lock and prevents forced yaw. Enemy death signals immediately clear the target. A freed/out-of-tree target also clears safely; F7 restores an explicitly unlocked state without snapping the current view. The one Enemy may be manually locked after HP reset; replacement/multi-target management is outside scope.

F4 adds one line with lock flag, actual target name, body-center distance, horizontal yaw error and camera-follow flag. F4 visibility has no control effect. No formal HUD or target-art asset is created.

Verification with both normal timing and fixed 60 fps: **597 checks passed, zero failures**, retaining all 557 and adding 40 for Tab/R3 mapping/conflicts/repeat, actual body-center point, smooth entry/release/yaw, no pursuit/automatic attack, target frustum/player-left composition, mouse/RS adjustment, side/back/forward motion, world-target following, F4 hiding, unlocked movement, ordinary attacks and all defense costs/cone rules, break camera, death, F7 and freed-reference cleanup. Godot import, scene loading and headless Main Scene startup passed without script/resource errors; diff whitespace checks passed. Rendered composition, physical-controller behavior and visual feel remain for manual acceptance.

Manual review covered basic shoulder framing, input, movement and reset. Step 13 has passed acceptance; Step 14 extends it below. Close-range composition and known Thrust/Left Cut matching limitations remain; no automatic distance/occlusion selection or enemy defense/AI is added. Stage 3 remains postponed.

### Stage 4 Step 14: Full Single-Target Soft Lock and Temporary 10/10 Tuning

This records Step 14's accepted release/reacquisition baseline with the subsequently accepted 0.5 s default. Step 15 below supersedes its Free Camera automatic-acquisition inhibition only; unlocked movement, rearm protection and all numerical tuning remain.

Step 13 has passed manual acceptance. This step extends its existing rig, movement and input paths; it does not implement enemy defense/AI or add a new camera/target manager.

**Current test values:** `Player/DebugDefense → Held Guard Cost` defaults to **10 Resource per successful valid held block**. `Enemy/DebugHealth → Test Damage` defaults to **10 HP per accepted player valid contact**, shared by all three motions. A 100 HP enemy therefore needs ten effective hits. These supersede the historical 25/25 prototype defaults above. Perfect Parry stays free; Instinctive Defense still requires full 50 payment; incoming damage stays 5 HP, both HP maxima and Resource maximum stay 100, recovery stays 1 s / 20 points per second and Guard Break stays 1 s. Request deduplication, windows, trajectories, attack locks/rhythm, movement 2.0/3.5 m/s and controls remain unchanged.

| Inspector — TestArena/ThirdPersonRig | Current default |
| --- | --- |
| Lock Yaw Limit Degrees | 40° each side |
| Lock Overrun Seconds | 0.5 s; editable 0.5–1.0 s |
| Reacquire Camera Degrees | 40° each side |
| Reacquire Movement Degrees | 20° each side |
| Lock Angle Response Curve | Optional; None means linear |
| Lock Manual Look Degrees | Existing 20° vertical adjustment only |

Subsequent parameter-only tuning changes Lock Overrun Seconds from 0.9 to **0.5 s**. Neither the camera-rig scene nor its arena instance overrides this property, so the actual Main Scene inherits 0.5 s from the script. The Inspector range now includes 0.5 s. Angle bounds, input-intent/reset rules, reacquisition, camera and combat behavior are unchanged. All **689 fixed-60-fps checks passed** after this tuning, including retention just before 0.5 s and release at 0.5 s; Godot import and headless Main Scene startup also passed. Manual timing/feel acceptance remains pending; no new stage is started.

Follow/turn speeds, target-center height, shoulder bias, spring collision and perspective settings remain in the existing Inspector group. No new input mapping is added.

**View boundary versus input intent:** the accumulated horizontal request offset is bounded at ±40° around the current target-follow direction. Desired yaw is converted through the optional response Curve and then follows existing smooth rotation. Horizontal differences use a signed `atan2(cross, dot)` on flattened vectors, correctly handling ±180° wrap. F4's view offset is the actual smoothed orbit direction relative to target-follow direction, not the clipped input request. A sudden target-direction change or lock entry may have a transient tracking error while smoothing catches up; the requested endpoint remains bounded, without a snap or radius/collision change.

Mouse and RS feed the same outward-intent test: a nonzero horizontal input must attempt to push beyond the bounded request angle. Only continued outward intent at that boundary advances the 0.5 s timer. A stationary angle at the boundary does not count. No input, inward input, leaving the boundary or switching overrun side clears/restarts the accumulated intent, so a brief mouse spike cannot release lock. Crossing the timer releases to Orient to Movement and records the reason. Manual Tab/R3 release uses the same smooth unlock path. The current orbit is retained; unlocked mouse/RS behavior remains the existing free camera.

**Modes and rearm protection:** startup/F7, invalid/dead targets and player death use Free Camera with automatic capture disabled. Manual or sustained-input release uses Orient to Movement. Both unlocked modes keep the existing camera-relative movement and smooth realized-motion heading; no movement input means no forced character turn. Guard Break does not disable camera/movement. Dead exits before any forced heading.

In Orient to Movement, the single Enemy must be alive and valid, within the actual camera's horizontal ±40° view direction and within ±20° of the player's realized horizontal movement. Explicit movement input and nonzero actual movement are required, excluding idle/gravity-only motion. Both tests must pass. Reacquisition only stores the existing target and starts smooth following; it does not change player position/input direction, compensate attack distance or initiate attack/defense.

After **every unlock**, eligibility is initially unarmed. At least one camera/movement condition must become false; a later return to both true can capture immediately. This prevents same-instant relock without a fixed cooldown or new cooldown Inspector parameter. Stopping movement is a clear condition exit. No oscillation occurs without a new sustained outward input and a new exit/re-entry into eligibility. With one candidate, random selection would have no effect; the formal random eligible-candidate rule is preserved for later multi-target work.

**Curve:** assign an optional Godot `Curve` locally in the existing camera Inspector. It shapes normalized requested yaw magnitude, symmetrically by sign, without changing the ±40° endpoint. None uses linear response. Curves with sampled reversal, non-finite/out-of-range values or endpoints other than 0/1 fall back to linear; output is bounded and actual rotation remains smoothed. No standalone Curve file is created and no non-linear default is imposed.

F4 adds mode, actual view deviation, overrun time, last release reason, active reacquisition camera/movement angles and pass flags, rearm flag, and current held-block/outgoing-damage values. F7 clears target, modes, timer/intent side, rearm and transient records to Free Camera; Inspector tuning/Curve assignments are retained. Defense still checks actual actor-facing ±60°, not lock membership. Known Thrust/Left Cut blade matching failures remain geometric; no fake clash, expanded radius or changed enemy trajectory is used.

Verification with both normal timing and fixed 60 fps: **689 checks passed, zero failures**, retaining all 597 prior checks with explicit historical numerical fixtures and adding 92 current-value/lock tests. Coverage includes ten real spatial valid hits at 10 HP, duplicate rejection, ten 10-resource held blocks and exhausting-hit protection, following injury, ±180° angle math, mouse/RS overrun timing/stop/inward/side changes, stationary orientation, eligibility rearm/no immediate loop, both reacquisition cones independently and jointly, Free Camera inhibition, optional Curve/fallback/boundary, mode-transition combat and F4/F7. One unlimited-speed fixed-step run reported a non-failing Jolt job-capacity warning; the normal-timing run did not report it. Import, scene loading and headless startup passed without script/resource errors; diff whitespace checks passed. Manual visual/feel acceptance remains pending.

Manual review must check mouse and physical RS sustained-overrun feel, stopping/reversing near the boundary, right-shoulder framing, repeated orbit/unlock/re-entry while moving, Curve editing and smooth response, ten-hit damage and ten-block exhaustion, defense actual-facing behavior during yaw changes, Guard Break movement/view and F7. Enemy defense/AI, multiple targets, Bind and further stages remain unapproved. Stage 3 remains postponed; stop here until Step 15 authorization.

### Stage 4 Step 15: First Automatic Soft Lock Acquisition

Step 14, including the **0.5 s** outward-input release default, has passed manual acceptance. This increment enables first automatic acquisition in Free Camera without Tab/R3, using the existing single Enemy. No new target-detection system, camera/input architecture or enemy AI is added.

The existing `_update_reacquisition()` now serves both unlocked modes. Target availability is shared with manual acquisition through `_target_available()`: player alive, actual Enemy valid/in-tree and enemy alive. Both automatic paths also require explicit effective movement input, nonzero realized horizontal movement, the target within the actual camera's horizontal **±40°** cone and within **±20°** of actual movement. Character facing from a previous action, idle/gravity-only motion and either angle alone are insufficient. All entries share `_acquire_lock(source)` and retain the current smooth view/heading transition.

| Transition | Requirement / debug source |
| --- | --- |
| Free Camera → Soft Lock | Both automatic conditions satisfied: **Auto Acquisition** |
| Orient to Movement → Soft Lock | Conditions have first failed, then both become true: **Auto Reacquisition** |
| Either unlocked mode → Soft Lock by Tab/R3 | Valid living target; automatic angle/movement requirements do not apply: **Manual Acquisition** |
| Soft Lock → Orient to Movement by Tab/R3 | **Manual Unlock**; rearm cleared |
| Soft Lock → Orient to Movement after outward intent | Existing **0.5 s** rule: **Boundary Unlock**; rearm cleared |

The first-acquisition branch cannot bypass manual/boundary unlock protection because those transitions stay in Orient to Movement. While both conditions remain true after release, no automatic entry is allowed. At least one must become false, then both must return true. Stopping movement is one valid exit. No fixed cooldown, extra cooldown parameter or multi-target selection is introduced; random eligible-candidate selection remains a later multi-target requirement.

F4 shows the latest acquisition/unlock source beside existing mode/release information; shared candidate angle/pass diagnostics are available in either unlocked mode. F7 immediately clears the target, sources, overrun/intent and rearm records to Free Camera. Without moving input it stays unlocked. If input continues and a later frame satisfies both conditions, that frame may perform a fresh **Auto Acquisition** to the valid reset Enemy; it is not reuse of a stale target or bypass of an unlock cooldown. Enemy death/invalid target and player death still prohibit acquisition and clear references; Dead cannot force actor yaw.

Acquisition never supplies movement or attack input, pursues, compensates distance or settles defense/damage. Right-shoulder composition, ±40° view requests, **0.5 s** sustained-input release, orientation smoothing, movement 2.0/3.5 m/s, Curve behavior, weapon trajectories/windows/selection, 10 HP outgoing / 5 HP incoming damage, 10 Resource held guard and full 50 Resource instinctive defense remain unchanged. Contact Matching and independent real Blade Clash remain on their existing paths; geometric matching limits remain.

Verification with both normal timing and fixed 60 fps: **723 checks passed, zero failures**, retaining all previous 689 and adding 34 first-acquisition/source/compatibility checks. Historical fixtures disable only the new initial-acquisition branch through an internal regression-isolation flag; normal scene default is enabled and dedicated Step 15 cases exercise it. Coverage includes no-input and individual cone rejection, first entry without Tab/R3, no snap/pursuit/attack/resource change, all five F4 source labels, manual override and persistent-condition unlock suppression, exit/re-entry, stable 0.5 s boundary release, attack/parry/guard/instinctive compatibility, F7 immediate clearing/fresh moving-frame entry, death and freed-reference safety. Godot import, scene loading and headless startup passed without script/resource errors; diff whitespace checks passed. One accelerated fixed-step run emitted a non-failing Jolt job-capacity warning; the normal-timing run did not. Visual/physical-controller acceptance remains pending.

Manual acceptance should begin at F5/F6 without Tab: move toward the enemy and inspect smooth first lock, approach from an off-camera or sideways direction and verify rejection, manually unlock while still approaching and verify no immediate relock, stop/re-enter the cones and observe re-acquisition, then test boundary release, attacks/RMB, enemy death and F7 while idle/moving. Inspect physical-controller behavior and close-range composition separately from headless geometry checks. Stage 3 remains postponed. Step 15 is now manually accepted; Step 16 is documented below. Enemy AI remains unapproved.

### Stage 4 Step 16: Enemy Defense Foundation

Stage 15 has passed manual acceptance. This step adds manual enemy Held Guard, default off, without enemy decision AI, resources, parry or instinctive defense. All existing movement, camera, player attacks, player defense and burst tuning remain unchanged. Outgoing damage remains 10 HP; enemy Max HP remains 100.

**Debug control:** physical numeric keypad 0 (`KP 0`, Godot `KEY_KP_0`) toggles Enemy Debug Guard through Input Map action `debug_toggle_enemy_guard`. F8 was removed because the editor uses it for Stop; F9 is also reserved for Toggle Breakpoint, so it is not used. The binding uses `physical_keycode`, distinct from main-keyboard `KEY_0`. Num Lock-on numeric input is supported; main-keyboard 0, F8 and the former semicolon binding do not toggle guard. KP 0 conflicts with no other project Input Map action. Physical keyboard/Num Lock behavior must still be checked manually in the focused game window. Keep the running game viewport focused. No editor shortcut settings are changed. A toggle-on during an active enemy swing is rejected (not queued); F4 reports the reason. Retry after that sword finishes. During a burst gap/recovery, entry stops the pending sequence. Held Guard and its entry/exit transitions own the enemy hand exclusively, pausing attack starts and automatic yaw adjustment. On exit, defense judgment stops immediately; attacks resume only after the smooth return, using the existing recovery timer and bounded turn behavior. There is no hit-time rotation to obtain a block.

**Settlement:** the existing player blade/body swept detector still produces Physical Contact and Valid Attack Contact independently. Only a valid body-contact event enters enemy HP settlement, using its existing per-request ledger. An alive guarding enemy blocks if the attacking player's actual world position is within the enemy's actual horizontal forward arc (default ±60°). Soft Lock itself grants no defense eligibility. A guarded request removes no HP; an unguarded or out-of-arc request removes 10 HP. Physical-only contact does not settle or consume the later valid opportunity. A request cannot settle again after a change in guard state or orientation.

**Blade geometry:** `blade_clash_debug.gd` keeps a separate player-request stream while the enemy guards. It uses both weapons' actual BladeBase/BladeTip transforms and the existing adaptive two-moving-blade sweep, unchanged 0.012 m radius and 0.005 m subdivision step. One player request emits at most one real clash; player and enemy request IDs have separate records. Successful Guard does not require Actual Blade Clash, and neither a body hit nor a guard state generates a fake clash.

**Procedural enemy Contact Matching:** Step 16 and this Contact Matching correction have passed manual acceptance. Enemy Held Guard now reuses the player's extracted `solve_contact_pose` and `safe_contact_pose` calculations rather than a separate collision or IK framework. After physics Tweens, once per physics frame, the enemy reads actual player blade markers and tip motion. For a live frontal player request, preparation and strike can drive a bounded correction; return/closed requests cannot continue tracking. The solver searches interior blade points, translation and limited rotation, retaining the original front-body clearance checks. It never moves the enemy root or snaps to the player's weapon. No feasible safe pose produces a reported Failed result without changing guard judgment.

The canonical guard pose anchors absolute correction limits, preventing cumulative drift. Position moves at a bounded m/s rate and rotation uses speed-limited quaternion interpolation; intermediate blade/grip clearance is checked too. Entry/exit Tweens own the hand until completed and matching cannot overwrite them. The enemy attack stays paused throughout guard ownership. After a genuine player-side Blade Clash, matching holds briefly, stops tracking that request and returns smoothly; a new request may match again. Player-side clash IDs cannot accidentally complete the player's incoming-attack matching. No collision event is emitted by the matching solver.

Inspector location: **TestArena / Enemy / DebugDefense**.

| Parameter | Temporary default |
| --- | --- |
| Enemy Debug Guard Enabled | false; F7 always restores false |
| Enemy Guard Arc | 60° on either side of forward |
| Guard Enter / Exit Duration | 0.16 / 0.20 s |
| Guard Hand Position | enemy visual-local `(0.50, 1.22, -0.35)` m |
| Guard Hand Rotation Degrees | `(0, 0, 90)`; horizontal blade across the front |
| Contact Matching Enabled | true; diagnostic isolation only, no effect on guard judgment |
| Matching Hand / Rotation Speed | 4.0 m/s / 360°/s |
| Matching Max Position / Rotation | 0.35 m / 40°, relative to canonical guard |
| Matching Contact Hold Seconds | 0.08 s after actual clash |

The gunblade stays attached to the hand; guard never translates the enemy root. Enter/exit Tweens start at the current pose, including a corrected matching pose. The enemy attack's disabled path no longer overwrites a guard-owned hand with Idle every tick. Death stops guard and its Tween. F7 clears the toggle, pose ownership, transitions, enemy matching target/request/hold/corrections, HP settlement and both clash streams, alongside the existing player matching, lock and attack resets; no old burst resumes.

F4 adds Enemy Guard State, the toggle outcome, last player valid request/result, frontal eligibility, actual damage, enemy Matching active/result/reason and translation/rotation correction, and the independent current player-swing Actual Blade Clash flag. Matched denotes pose convergence, not a collision claim. Gold crosses indicate player-blade/enemy-guard-blade contacts; blue remains enemy-blade/player-blade contact, pink physical body contact and lime valid body contact. F4 off hides all debug geometry/text without affecting settlement or matching.

Verification: **810 checks passed, zero failures**, with normal timing and fixed 60 fps, retaining all prior 787 checks and adding 23 dynamic-matching checks. Coverage includes native unguarded/guarded/rear thrusts, all three unchanged frontal player motions, independent guard/clash outcomes, geometry overlap/miss and deduplication, physical-only rejection, side/rear direction, input conflicts, transition ownership, attack-time toggle rejection, death, F7 and existing lock/selection compatibility. New checks monitor every matching/recovery sample for speed, absolute correction limits and body clearance, confirm return/ownership release, active matching reset, out-of-cone nontracking and unreachable failure without clash. At the test position (enemy 0.38 m right and 0.9 m ahead, facing the player), all three motions now produce genuine blade clash and valid body contacts are guarded. Broad Cut involves actual hand displacement; its former fixed-pose miss is resolved at this stance. This does not guarantee contact at every distance/angle: unreachable or speed-limited poses remain honest failures, with Successful Guard still independent. Godot import, scene loading and headless startup are checked separately; visual smoothness and controller feel still require manual acceptance.

Manual review: F5/F6, F4 for feedback, approach the enemy and enable Num Lock and press `KP 0` during a gap. Use left click/X or 1/2/3 + V from the front: verify dynamic blade interception for Thrust/Short Cut/Broad Cut, zero damage, distinct gold clash feedback and smooth matching/recovery. Try several distances and lateral offsets; Failed/Limited matching must not invent a clash or alter frontal guard judgment. While guard freezes enemy turning, circle to its side/rear and strike within actual blade reach: verify 10 HP damage and failed frontal eligibility. Toggle off to check smooth return and resumed bursts; toggle on mid-swing to inspect rejection; use F7 during entry/exit, check default attacks resume and no guard pose remains. Review Soft Lock orbiting and ordinary selection as well. Stage 3 remains postponed; Step 16 is now accepted; reactive Enemy Defensive AI is documented in Step 17 below. Broader enemy AI remains unapproved.

### Stage 4 Step 17: Enemy Defensive AI

Steps 1–16 are manually accepted. This step adds deterministic defensive reactions to the existing `Enemy/DebugDefense`, not a second defense/collision system or a full Intent/Reaction/Mistake AI. Step 17 has passed manual acceptance; Step 18 below adds pressure and mistakes. All player inputs (RMB/L1 guard), damage/resource values, movement, camera, lock timing, attacks and matching limits stay unchanged.

**Recognition:** only the player's executed `motion_started` signal is observed, with a live matching request ID. A rejected/buffered input never emits a recognized attack. The enemy checks actual player/enemy world positions, its current ±60° forward arc, and a configurable 2.0 m threat distance. No future trajectory, contact result, HP callback or Soft Lock eligibility informs the decision. Each real request is considered once; an out-of-range, rear, attacking-state or recovery-state rejection is not queued for later. Recognition needs preparation/strike still live; return, interruption and closed windows count as Attack Ended.

**Transitions:** Idle → Reacting starts at actual recognition, then accumulates physics time (default 0.20 s). Throughout the wait, request validity, direction, distance and weapon ownership are rechecked. If the enemy begins attacking, the player cancels/finishes the strike, or eligibility is lost, the reaction is discarded. At delay expiry, the existing Held Guard entry runs only if still available. Guarding lasts 0.35 s from entry decision, including the unchanged 0.16 s pose transition; then judgment ends and Recovering uses the unchanged 0.20 s exit. When the hand is released, Idle resumes. New threats during Guarding do not extend the hold or create queued reactions; each new eligible request may react after recovery. Physics priority places defensive availability updates before the stationary attacker; no attack is interrupted to obtain defense, and no damage is retroactively removed.

**KP 0 Manual Guard Override:** the same physical-key Input Map remains. On switches to continuous manual guard, clearing any pending automatic reaction. During an active enemy sword it is still rejected; retry in a gap. Manual takeover of an already guarding enemy does not restart its pose or compete with matching. Off clears the override and smoothly exits, then returns to Auto decisions for fresh executed attacks; an attack seen while overridden cannot immediately retrigger on release. Inspector **Manual Guard Override** uses the same rule. F7 clears override/AI timers/request/hold, hand transitions, matching and contact history while preserving the configured Auto Defense Enabled setting. Enemy death immediately clears reaction and guard; no delayed callback survives it.

Inspector on **Enemy / DebugDefense**:

| Parameter | Temporary default |
| --- | --- |
| Auto Defense Enabled | true |
| Reaction Delay | 0.20 s |
| Guard Hold Duration | 0.35 s, including entry |
| Threat Distance | 2.0 m, world-space source distance |
| Manual Guard Override | false; KP 0 toggles |

F4 adds **Enemy Defense Mode: Auto / Manual Override**, **AI State: Idle / Reacting / Guarding / Recovering**, recognized request/motion, reaction elapsed/configured time, hold remaining, and the last reason (Out of Range, Outside Guard Arc, Already Attacking, Recovering, Attack Ended, etc.). Existing matching and independent Actual Blade Clash diagnostics remain. Mode Auto with Auto Defense Enabled off reports Auto Disabled. No formal HUD is added.

**Known timing limits:** the default 0.20 s delay deliberately permits fast Thrust/Short Cut contacts before guard becomes available; late guard never refunds damage. At the reference position (enemy 0.38 m right, 0.9 m ahead), default-delay Broad Cut is blocked by body-contact judgment, but the unchanged entry/solver limits report a Failed match and no real clash. A dedicated 0.05 s reaction Inspector fixture produces a genuine Broad Cut clash through the same unmodified matching path; this is a feasibility test, not a replacement default. Step 16 continuous-manual-guard coverage still achieves real clashes for all three motions. Successful Guard remains independent of Actual Blade Clash. No faster matching, expanded radius/arc, forced attacker cooperation or fake event was introduced to hide a late interception.

Verification: **864 checks passed, zero failures**, with normal timing and fixed 60 fps. The previous 815 checks are retained, with the new Auto branch disabled only for historical regression isolation; normal scene default is enabled. Added 49 checks cover default configuration, executed-versus-rejected request recognition, real delay/hold/exit, quick pre-reaction damage without retroactive block, interruption/strike-end expiration, range/arc rejection and revalidation, attacking/recovering ownership, once-per-request behavior, manual takeover/release, F4, actual matching/clash feasibility, death, F7, lock/selection and unchanged combat/control values. Godot import, scene loading and headless startup are checked; visual interception and real-controller operation remain manual.

Manual review: F5/F6 and F4, keep KP 0 override off and approach from the front. Use 1/2/3 + V or ordinary attack to observe Reacting before Guarding, short hold and smooth exit; some fast attacks should hit first. Attack during enemy swings and after its recovery, compare reason/state without instant cancellation. Whiff from beyond 2 m and attack from its side/rear without allowing idle turning to confuse the angle test. Toggle KP 0 in a gap to compare continuous manual matching, then off to restore Auto. Check RMB/L1 defense, Soft Lock movement, gold real-clash markers, HP and F7 during reaction/guard. Optionally tune Reaction Delay in the remote Inspector to compare coverage, restoring 0.20 s afterward. At Step 17 no random mistakes/pressure were added; Step 18 below supplies them. Enemy movement, new attacks, enemy resource/parry/instinctive defense, Bind and Force remain unimplemented. Stage 3 remains postponed; Step 17 is now accepted; pressure/mistakes are documented below in Step 18. Further AI capabilities remain unapproved.

### Stage 4 Step 18: Enemy Mistake and Pressure

Step 17 is manually accepted. Step 18 adds pressure and once-per-request mistakes inside the existing Enemy Defense; it awaits manual acceptance. It does not change attacks, collision shapes/windows, reaction/guard/matching speeds, camera/input or combat values.

**Pressure event:** `static_enemy_health.gd::_on_valid_contact` keeps its existing final-settlement checks and request ledger, then calls `Enemy/DebugDefense.record_valid_pressure` immediately after Successful Guard versus Damage is decided and before HP deduction. Only the actual `WeaponContactDebug` valid-body-contact stream with its current generation and a live executed player request can add a stack. Guarded and damaging valid hits both add one. Independent pressure deduplication rejects replay; physical-only contacts, whiffs, canceled/closed requests and dead targets add none. A later cancellation does not undo an already settled real hit. Actual Blade Clash is not required. Fatal damage invokes death cleanup immediately, leaving no pressure on a dead target. Legacy debug HP calls do not manufacture pressure.

**Probability:** `min(Base Mistake Chance + Pressure Stacks × Mistake Increase Per Pressure, Max Mistake Chance)`. Defaults are 0.10 + 0.05 per stack, capped at temporary 0.60: stacks 0/1/2/3/5/10 give 10/15/20/25/35/60 percent. Stacks may continue accumulating beyond the probability cap. These are greybox values, not a final cap or balance decision.

**Decision order:** after an executed motion passes Step 17's automatic eligibility checks (alive, live preparation/strike, range/forward arc and available weapon), one `RandomNumberGenerator.randf()` sample is compared with a snapshot of the current chance. A mistake skips this request's automatic reaction; no mistake follows the unchanged 0.20 s Reaction Delay → 0.35 s Guarding → Recovering path. The later contact increases pressure only for future decisions. The request/stack/chance/roll/result snapshot never changes when that request subsequently contacts. Input rejection, repeated motion signals, contact callbacks or multiple sweep samples cannot reroll. A superseding executed request drops an old pending reaction. Mistakes neither deal damage nor stop an existing enemy swing; real valid contact remains necessary for HP loss.

**Breathing:** a Successful Guard valid-contact event qualifies recovery and starts the quiet interval at that physics frame, with elapsed time initially zero. Successful Guard alone does not clear stacks. After 1.0 s without another qualifying pressure event, stacks reset to zero and the qualification is consumed. Every new pressure event cancels the old attempt and resets elapsed time; if that new event is also guarded, it immediately starts a new qualified interval. If it damages the enemy, recovery stays unqualified until another Successful Guard. Thus standing/backing away or waiting after damage alone cannot clear pressure. Only new effective pressure interrupts the interval; the same request's ongoing overlap cannot renew it. Physics-time accumulation begins on the frame after the qualifying event.

Inspector additions on **Enemy / DebugDefense → Greybox Mistake and Pressure**:

| Parameter | Default |
| --- | --- |
| Base Mistake Chance | 0.10 |
| Mistake Increase Per Pressure | 0.05, five percentage points |
| Max Mistake Chance | 0.60, temporary cap |
| Breathing Duration | 1.0 s, temporary quiet interval |
| Use Test Seed | false; normal play randomizes this RNG |
| Test Seed | 12345; applied when Use Test Seed is enabled |

With Use Test Seed enabled, changing the seed configures the next eligible roll and F7 restarts that seed's sequence for repeatable live-attack tests. Without it, F7 reseeds randomly. KP 0 Manual Guard Override never rolls mistakes but actual guarded contacts still add pressure and may qualify breathing; turning it off restores automatic decisions for fresh requests. F7 clears stacks, pressure IDs, qualification/timer and decision snapshots/counts, together with all previous AI/pose/matching state. Death performs the same cleanup with reason Enemy Dead. Configuration values are retained.

F4 adds stack count, current probability, last request/roll/result and the pressure/chance snapshot used for that roll, recovery qualification, breathing elapsed/required time, and last pressure/reset reason. Matching convergence, true clash and Successful Guard remain separate diagnostics; debug visibility has no decision or resource effect.

Verification: **935 checks passed, zero failures**, with normal timing and fixed 60 fps. All prior 864 are retained; prior deterministic AI fixtures set base/increase to zero, while dedicated Step 18 tests restore/exercise the real defaults. Added 71 checks cover the default parameters, actual damaging and guarded pressure chains, the +5pp curve/cap beyond ten stacks, duplicate real-event rejection, before-contact snapshots, seeded repeatability, certain-mistake misses versus real damage, zero-mistake delayed guard, manual override, physical-only/canceled/remote attacks, guard/clash independence, full/partial/interrupted breathing, no unqualified idle reset, F4/F7 and native lethal-hit cleanup. New pressure scenarios execute actual weapon motions and native collision events; no hit/damage is forged for them. Import, scene loading and headless startup are checked separately. Visual feel and probability tuning remain manual.

Manual review: F5/F6, F4, KP 0 off. Attack repeatedly from the front and compare the stored roll chance with the next increased pressure count; misses should leave HP/pressure untouched. A mistake may miss defense but cannot damage by itself. Fast hits and attacking/recovering rejections remain possible for their existing reasons. Toggle KP 0 on in a gap for deterministic continuous guard, apply several real hits less than 1 s apart, then pause: pressure must survive each block and reset only after a full quiet interval. Check that damage interrupts a qualified attempt, and that damage followed by inactivity alone does not reset. Enable Use Test Seed in the remote Inspector and use F7 to compare repeatable runs. Verify F7/death cleanup, RMB/L1, Soft Lock, matching and actual gold clash markers. The existing delayed-interception limitation from Step 17 remains; no radius/speed/angle was widened. No enemy movement, new strategy, wrong-direction animation, additional reaction delay, enemy resources/parry, Bind or Force is added. Stage 3 remains postponed; Step 19 is unapproved. Stop for manual acceptance; no commit.

## Planned Prototype Stages

Stage 0 has no explicit final acceptance. Stages 1 and 2 and Stage 4 Steps 1–17 passed initial manual acceptance. Stage 3 is postponed, not cancelled. Steps 9–17 have passed initial manual acceptance; Step 16 manual enemy defense and matching are manually accepted. Step 17 is manually accepted; Step 18 pressure/mistakes await acceptance. Step 19 and further work remain unapproved. Formal AI, Bind, full defense and final balance are not established by this test.

| Stage | Minimum scope | Validation gate |
| --- | --- | --- |
| Stage 0 — Project Inspection & Design Discussion | Inspection, README, mechanics/scope discussion | Ongoing, without acceptance; documentation is not stage approval |
| Stage 1 — Greybox Foundation | Static greybox, movement, walk/run and right-shoulder camera; enemy static | Initially manually accepted; walk 2.0/run 3.5 m/s debugging baseline retained |
| Stage 2 — Weapon Motion | Accepted three motions, selection/transitions, world-space sampling and optional debug lines. Defensive/shooting/extension motions remain future scope | Manual acceptance completed; preserved in contact-check regression |
| Stage 3 — Visual Effects | Temporarily postponed, not cancelled: Glow experiments, trail, presentation/contact feedback | No formal effects implemented; debug contact crosses are diagnostic only |
| Stage 4 — Basic Combat Exchange | Steps 1–18: contacts/windows/HP, bursts/defense/resource, arbitration/reset, Soft Lock, enemy defense and pressure/mistakes with 10/10 tuning | Steps 1–17 manually accepted; Step 18 awaiting review. Enemy resources, Bind, formal AI and later work remain unapproved |
| Stage 5 — Contextual Combat | Distance/pose selection, defensive transitions, quick shots; approved exploration of retraction, Force Block, soft targets, disarm/injury | Intent and muzzle fidelity; no guaranteed advantage from retraction/Force Block; Bind/durability and remaining contextual details need planning, not full-system rollout |
| Stage 6 — Cinematic Presentation | Dynamic composition, shake, slow motion, key moments | Improved presentation while preserving control/readability |

### Stage 1 Implementation Plan (Foundation and Basic Controls Authorized)

A flat arena with a movable greybox player and static opponent, both cylinder-and-hands actors with one-handed gunblades. Use reference proportions and an approximately one-meter blade; static display does not decide default gameplay blade state.

No combat, shooting, dodge, jump, automatic pursuit, tactical extension, Force Block, ability layer, Bind, soft lock, or full exploration/dialogue belongs here. Static foundation and basic controls below now exist; additions beyond this authorized scope require separate approval.

| Planned file | Responsibility |
| --- | --- |
| Modified `project.godot` | Main arena and only the movement/look/walk-run/mouse-capture Input Map; rendering/physics settings retained |
| Modified `scenes/test_arena.tscn` | Preserved greybox; player-only controller and independent shoulder-rig instance replace the fixed camera; labels identify initial spacing/start location |
| Created `scenes/actors/greybox_actor.tscn` (Step 1; unchanged this round) | Script-free reusable `CharacterBody3D`, collision, separate `VisualRoot`, body cylinder and hands; gunblade on right hand. Only the arena player instance receives the controller; the enemy stays static |
| Created `scenes/weapons/gunblade.tscn` (Step 1) | Two cylinders/blade mesh; grip origin, `Muzzle`, `BladeBase`, `BladeTip`, `HiltBottom`; no combat logic |
| Created `scripts/player_controller.gd` and generated `.uid` | Player input, camera-relative movement, gravity, collision, realized-motion facing |
| Created `scenes/camera/third_person_rig.tscn` | Yaw/pitch pivots, diagonal SpringArm sphere sweep, perspective Camera3D |
| Created `scripts/third_person_camera.gd` and generated `.uid` | Exported shoulder/look/smoothing parameters, follow/orbit, self-exclusion, capture/release; no lock-on/cinematic cuts |
| Created `tests/smoke_test.gd` | Headless input, movement/collision, perspective/offset/follow and obstruction checks; not visual acceptance |
| Updated `README.md` | Implementation, controls, tuning and automated/manual coverage; combat decisions unchanged |

Step 1 uses the coordinate conventions and dimensions recorded above. Hand spacing, visual proportions, and observation-camera distance remain subject to manual acceptance; these are static layout choices, not finalized combat poses.

The Stage 1 movement/camera subset has passed initial manual acceptance with walk 2.0/run 3.5 m/s as the adjustable debugging baseline. Stage 2 demo inputs are documented separately above. The broader combat keyboard/mouse scheme still needs review; interaction/jump/climb/dialogue remain unimplemented.

Future sequence: static arena/actor/weapon and coordinate check → movement/collision → follow camera → main scene/minimum input → import/resource/short startup checks → manual proportions/feel review. Logic depends on actor body and explicit visual nodes, not a required future skeleton.

Future automated acceptance: no import/parse/resource errors, smoke-test instantiation, and short startup without errors. This does not verify feel or grip.

Future manual acceptance: F5/F6 enters arena; agreed movement matches camera; actors do not pass through ground/target; camera stays outside actor/ground; mouse capture works if used; proportions and one-handed grip are clear, other hand visible; approach/circling distance readable; no unauthorized attack/pursuit. Record scale/speed/framing adjustments, not Headless success as visual proof.

## Open Design Questions / Deferred Discussions

Stages 1 and 2 and Stage 4 Steps 1–17 are initially accepted. Stage 3 is postponed; Steps 9/10 resource/break validation are initially accepted; Step 15 first automatic acquisition is accepted; Step 16 manual enemy defense and matching are accepted. Further steps need approval. Test costs/timers do not resolve formal resource naming/positioning, enemy resources, full sword alignment, Bind or death design. Future Animation + IK may replace the greybox correction.

### Six Major Design Areas

| Area | Current status and remaining work |
| --- | --- |
| 1. Blade contact and sustained binding | Bind entry, pressure QTE, camera/input override, ordinary victory/mutually exclusive defeat, and separate trajectory-based retraction outcomes are confirmed. Staged encounters preserve duels; multi-participant combat disables Bind. Ordinary Sword Art contact, complex presses, specific moves, spatial/trajectory tests, Bind tuning/animations, execution input/timing, encounter classification scope, and durability formulas remain open |
| 2. Dodge and lethal-attack QTE | Positive resource with normal defense excludes special QTE; post-depletion collapse is prerequisite, not guarantee. QTE cannot interrupt Stagger / Knockback or insert a rescue dodge during it; grounded roll becomes available after the fall reaction ends. Exact triggers, motions, warnings, window, failure, and agency remain open |
| 3. Knockdown and serious injury | Stagger / Knockback is an uninterruptible hit-reaction process, followed by controllable Knocked Down if grounded or normal control after recovery if not. Only after the fall reaction ends: grounded roll > swing > rise; roll/swing reset rising; five accepted presses with progressive feedback. Blur below 30% remains confirmed. Reaction/recovery duration, get-up timing, safe direction, blur curve, injury motions, healing/recovery values remain open |
| 4. Enemy AI | Intent/Reaction/Mistake; waiting/offense/distance adjustment; reaction mistakes first; actual attack pressure (including defended attacks, excluding whiffs) increases the streak without requiring HP loss; valid defense followed by genuine breathing resets it. Pools, aggression/frequency, reaction time, special-attack eligibility, breathing detection, caps, and later judgment errors remain open |
| 5. Force abilities and gunfire | Force costs and attack-based recovery, per-ability requirements without extra universal threshold, Choke exception, and fluid transitions confirmed; hold-to-aim deferred. Values, Bind assistance, eligibility/interruption, precise aim and derived attacks remain open |
| 6. Soft-lock feel | Step 15 adds first Free Camera automatic acquisition to the shared ±40° camera / ±20° actual-movement checks. Manual/boundary release keeps condition-exit/re-entry protection; ±40° view requests, 0.5 s outward-input release and optional linear-default Curve remain. Timing/input feel, Curve tuning and composition remain adjustable. Multiple-target random eligible selection remains open; no fixed relock cooldown is imposed |

These areas are partly resolved, not finished systems. Keyboard/mouse still requires independent review.

### Additional Input and Permission Questions

| Question | Established boundary / remaining work |
| --- | --- |
| Precise-parry/held-defense transition? | Press/hold roles set; timing/release/motion transitions need testing |
| Force Block constraints/costs? | Hold/release, escape without automatic reapply, L1 against other weapons, R2 recall, and Bind assistance set; range/eligible attacks/cost/bonus open |
| R1 and other inputs? | Hold/face-button roles set; L1/L2/R2 interactions and concurrency incomplete |
| Melee/gun input waiting/ignoring/interruption? | Ordinary lockout has no buffering; sequential gun/sword behavior cannot silently override it |
| Future precise aiming? | Single shots set; hold-to-aim and tap/hold distinction deferred |
| Dodge direction? | Preserve player direction; contextual motion open |
| Combat jump/climb, dialogue, interaction coexistence? | Permission/concurrency open; do not assume interaction disabled in combat |
| Context permissions? | Noncombat need not mean holstered; city/narrative restrictions and confrontation incomplete |
| Stage 1 test inputs? | Movement, look, Shift/L3 walk-run and click/Esc capture-release are authorized and implemented. Physical-device feel remains manual; broader interaction/combat mappings are not approved |
| Bind arbitration/exits? | RS/mouse direction QTE and L2 assistance are set; deliberate retraction resolves separately by current motion/trajectory into player serious injury or enemy fall/direct execution opportunity. Detection, action windows, fall animation, execution input/timing, and other action arbitration remain open; regular mid-duel sword-enemy arrivals are excluded by encounter design |

### Combat Mechanics, Execution, and Outcomes

| Question | Established boundary / remaining work |
| --- | --- |
| Resource name/costs/recovery? | Posture/stamina and HP exist in design; costs, breathing rates/intervals open |
| Knockback/disarm rolls? | Existing curves preserved; applicable events and pre/post-deduction sampling open. Baseline stumble, guard-break stagger, and extra knockback remain distinct |
| Durability and enemy disarm? | Ordinary Bind QTE victory lowers durability; combination curve/cap, recovery, and zero outcome unset; no assumed addition/breakage/automatic disarm |
| Multi-participant Bind exclusion and encounter scope? | Bind disabled outside one-on-one encounters; prearranged waves/areas exclude regular sword enemies joining a duel. Classification scope, environmental exceptions, wave counts, spawning, area sizes, and detailed level flow remain unspecified; no fixed radius |
| Bind tuning/feedback? | Press-rate cap, direction thresholds/prompts, pressure, duration, Force assistance, animations/contact need design. Ordinary QTE victory has no default damage/long stun; ordinary defeat is disarm OR injury by move. Deliberate retraction has separate trajectory-based outcomes, with detection/windows/fall animation/execution input and timing unresolved |
| Out-of-range attacks/taunts? | Empty-space attack candidate, no autonomous pursuit; taunt input/behavior open |
| Cancellation/intent arbitration? | Dodge > ordinary attacks; L1 interrupts below dodge. No player action or QTE interrupts an ongoing Stagger / Knockback hit reaction. Grounded priorities apply after the fall reaction ends; other windows/concurrency incomplete |
| Instinctive detection/cost? | Current accepted greybox requires full 50 Resource payment. The earlier positive-pre-trigger-resource proposal remains a pending formal-rule difference, not a second enabled mechanism. Final detection/cost and formal hit-reaction integration remain open; uninterruptible Stagger restrictions do not extend throughout controllable Knocked Down |
| Initial blade state/extension timing? | One-meter reference, R2 toggle, and Bind retraction set; timings/contact activation provisional |
| Dodge form? | Respect direction; no assumption every dodge is a large roll |
| Ordinary contact/torque/Bind presentation? | Mutual clash itself costs no resource; detailed ordinary contact/pressing and Bind contact/animation solutions unapproved |
| Execution/injury eligibility and thresholds? | Body hits, ordinary-enemy guard break, and Choke may permit execution, not every hit guarantees death. Blur starts below 30%; other thresholds/recovery/body-part and Bind-defeat injury details open |
| Quick-shot intent/muzzle geometry? | Intelligible pose/hit feedback; no assumed random spread or guaranteed hit; no unique animation per prototype combination required |
| Enemy pressure streak/mistake calculation? | 10% base plus five percentage points per effective player attack pressure event, including ordinary/instinctively defended attacks, excluding whiffs; neither button presses nor HP damage define the count. Reset after valid defense followed by genuine breathing. Step 18 tests a 60% cap and a 1 s successful-guard-qualified quiet interval; final cap/breathing criteria, special-attack eligibility and broader mistake types remain open |
| Grip/camera/application name? | Reference dimensions exist; tune grip/camera manually, decide name separately |

## Development & Testing Instructions

Current scope includes accepted controls/attacks and Stage 4 Steps 1–18 contacts/windows/HP, bursts, defense/matching, resource/break and shared first/re-acquisition single-target Soft Lock with optional Curve response. Current outgoing damage/held-block cost are 10/10; incoming damage remains 5 HP; boundary release stays 0.5 s. F4 is debug feedback. Enemy Auto Defense is on by default with temporary pressure/mistake rules; `KP 0` toggles Manual Guard Override (default off). No enemy resources, Bind, full decision AI, pursuit, skeleton IK, jump, multi-target selection, standalone Curve file or commit is included. Stage 3 is postponed; further work is not authorized.

Previously verified engine: `E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`. Use the appropriate local path elsewhere. Only the recorded 4.7.2 build was checked; other versions/export platforms were not validated. `godot` was not on PATH.

From the project root in PowerShell:

```powershell
$godotExe = 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
& $godotExe --version
& $godotExe --headless --path . --editor --import --quit --log-file .godot/inspection-import.log
```

Import root `project.godot`, open `scenes/test_arena.tscn`, then F5 runs the main scene and F6 the current arena. Click the game viewport to capture the mouse; use WASD/left stick to move, Shift/L3 to toggle walk/run, mouse/right stick to look, and Esc to release. Select `ThirdPersonRig` to tune the exported camera properties. Inspect actor/weapon subscenes separately for dimensions.

Step 1 startup check:

```powershell
& $godotExe --headless --path . --quit-after 8 --log-file .godot/step1-startup.log
```

Current movement/camera and visual weapon-motion verification commands:

```powershell
& $godotExe --headless --path . --editor --import --quit
& $godotExe --headless --path . --script res://tests/smoke_test.gd
& $godotExe --headless --path . --quit-after 120
```

Short headless runs detect resource/script/runtime errors. Inspect output/logs, not only exit codes. `--quit-after` limits frames, not visual quality or performance. Record verified behavior, uncovered areas, and manual acceptance separately.

In future development, version scenes/scripts/assets and required import descriptions/UID files; exclude `.godot/` caches/logs. Keep implementation/stage status accurate instead of presenting plans as completed work.

Player attacks, speed/locks, camera, HP, bursts and matching remain. Stage 4 Steps 1–17 are accepted; Step 17 defensive reactions are accepted; Step 18 pressure/mistakes await acceptance. Stage 3 remains postponed, not cancelled. Stop here: Step 19/further work requires separate authorization. No commit is created.
