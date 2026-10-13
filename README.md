# Blaster-Saber-Godot-Demo

A Godot third-person cinematic gunblade combat prototype. **Stage 0 has not received final acceptance. Stage 1 static rendering has been manually accepted, and basic movement plus the right-shoulder third-person camera are now authorized and implemented.** Controls and camera feel await manual acceptance. Stage 2 and combat remain unapproved and unimplemented. This document distinguishes confirmed rules, provisional parameters, future implementation ideas, unresolved questions, and actual implementation. Combat design decisions are not implemented features.

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

Dodge/L1 relative priority over attacks is set; other arbitration/cancellation remains incomplete. Grounded roll/swing/rise priorities are now set, while automatic safe-direction rising and agency remain open. This does not approve a complete state machine.

### Soft Target Lock and Camera

Use automatic soft selection rather than rigid manual lock-on. Keep selected targets stable rather than continually changing for a nearer enemy. The following rules replace the old nearest-first, first-in-list tie-break, and direct directional-switch scheme; those are not parallel confirmed alternatives.

While locked, right-stick camera operation within **±40° of the target-centered direction** does not switch or unlock. Input beyond the range must persist before unlocking. **0.8–1 second** remains only a candidate controller duration. After unlocking, restore **Orient to Movement**, turning by movement direction.

Automatic reacquisition requires both:

1. Enemy within **±40° of camera facing**.
2. Enemy within **±20° of player movement direction**.

Randomly select among multiple qualifying enemies. A brief post-unlock relock-protection period is a candidate only. Initial acquisition, stationary-player behavior, and target-death handling under these revised rules require clarification; do not silently restore nearest-enemy fallback.

Mouse/controller thresholds remain adjustable. The earlier same-direction mouse motion above a velocity threshold for about 0.4 seconds remains only a candidate to test against the new angular design. Exact mouse thresholds and post-unlock camera response remain open. Increasing camera resistance and fast-initial/slow-settling return remain a feel direction subject to tuning.

Future damping or input response must expose an editable Godot **Curve** resource with a **linear default** for manual editor adjustment. This task creates no Curve file. Bind's fixed encounter camera/direction QTE takes priority over normal soft-lock input. Soft lock stays outside Stage 1's basic camera scope.

## Current Implementation

Initial inspection: 2026-10-13. Stage 1 now includes the accepted static greybox, basic camera-relative player movement, walk/run toggle, and a controllable right-shoulder perspective camera. The enemy remains static. The table describes current implementation; historical inspection and static checks are retained separately. No combat or weapon animation is implemented.

| Item | Observed state |
| --- | --- |
| Project | `project.godot` exists; `config_version=5` is a configuration format, not the engine major version |
| Local engine | `--version` returned `4.7.2.stable.steam.ed1daf0bf` |
| Project feature markers | `4.7`, `Forward Plus` |
| Application name | `Wuwaproject`; renaming remains open |
| Rendering/physics | Forward Plus, Windows `d3d12`, `Jolt Physics`; static rendering manually confirmed after the Step 1 camera correction, new camera presentation still pending acceptance |
| Scenes/scripts | Arena, reusable actor/gunblade, and `scenes/camera/third_person_rig.tscn`; `scripts/player_controller.gd` on the player instance only and `scripts/third_person_camera.gd` on the rig. No skeleton or animation system |
| Assets | Native primitive meshes, simple embedded materials, marker nodes, and labels; default icon retained. No imported actor models, textures, or custom shaders |
| Input/systems | Minimal movement/look/walk-run/mouse-capture Input Map. Camera-relative CharacterBody3D movement and orbiting shoulder camera exist. No Autoload, plugins, combat, AI, weapon detection, shooting, trail, jump, dodge, or soft lock |
| Tests/export | `tests/smoke_test.gd` performs 56 input/physics/camera checks; import and startup checked. No CI or export presets |
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

Implemented controls: WASD / left stick move, Shift / L3 toggle walk/run, mouse / right stick look. Left-click the game viewport to capture the mouse; Esc releases it, and focus loss releases it as well. Mouse starts visible; a click captures it. Left-click performs no attack. Only these 11 necessary actions are mapped; combat and jump inputs are absent. Physical gamepad and native-window mouse behavior remain manual checks.

Automated verification on 2026-10-13: editor import and main-scene short startup passed without parse/resource/runtime errors. The headless smoke test passed **56 checks** covering resource loading, active perspective camera, default offsets and left-of-center neck projection, initial enemy projection, keyboard/controller mappings, absence of combat/jump actions, walking/running distances, toggling, camera-relative movement after yaw changes, realized-motion facing, floor/enemy collision, static enemy, follow convergence, stick rotation/pitch clamps, mouse look math, self-collider exclusion (including a centered sweep), shoulder preservation after body rotation, and arm retraction/restoration against a temporary test-only wall. The wall is not part of the arena file. Native mouse capture cannot be validated by the headless dummy display; only its mappings and look calculations are covered. Log: `.godot/stage1-controls.log` (ignored).

Manual acceptance remains required: F5/F6 rendered startup; actual WASD/left-stick input and Shift/L3 switching; physical right-stick and mouse capture/release/focus behavior; smooth turns and follow; right-shoulder composition across yaw/pitch and aspect ratios; obstacle avoidance near the floor and enemy, including lack of jitter/undesired self-retraction; and overall sensitivity/smoothing feel. The finite floor has no arena walls: stepping off its edge can cause a fall, with no respawn system added. Do not interpret the automated projection/obstruction tests as visual or feel acceptance. Await acceptance before further work; Stage 2 is not authorized.

## Planned Prototype Stages

Stage 0 is not finally accepted. The user accepted static rendering and authorized Stage 1 basic movement and the right-shoulder third-person camera. Those systems are implemented and automatically checked, with manual acceptance pending. Stages 2–6 remain unapproved and unimplemented. This authorization does not include weapon animation or combat.

| Stage | Minimum scope | Validation gate |
| --- | --- | --- |
| Stage 0 — Project Inspection & Design Discussion | Inspection, README, mechanics/scope discussion | Ongoing, without acceptance; documentation is not stage approval |
| Stage 1 — Greybox Foundation | Static greybox plus camera-relative movement, walk/run toggle, and controllable right-shoulder perspective camera; enemy remains static | Static rendering accepted; movement/camera import, startup, and 56 checks passed. Native input, visual composition, obstruction feel and control feel await manual acceptance |
| Stage 2 — Weapon Motion | One-handed poses, a few thrusts/cuts, defensive/shooting transitions; extension presentation after approval | Controllable continuous motion and credible muzzle orientation; visuals are not combat resolution |
| Stage 3 — Visual Effects | Blade material, Glow experiments, trail, contact feedback | Trail follows actual motion independently of detection; clear fast motion; test contact events drive feedback |
| Stage 4 — Basic Combat Exchange | Limited enemy behavior, spatial/trajectory contact, attack windows, three defenses and resource/guard-break loop | Credible contact, control, depletion-hit absorption then immediate break; Bind core is documented but parameters/contact/animation need design, without automatic scope expansion; no general AI/physical simulation; may overlap Stage 3 |
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

The authorized movement/camera input subset is now implemented for keyboard/mouse and controller. The broader combat keyboard/mouse scheme still needs separate review. Interaction/jump/climb/dialogue are not implemented. Walk 2 m/s and run 3.5 m/s remain tuning references, with Inspector-adjustable camera parameters; click capture and Esc release are now implemented, pending native-window acceptance.

Future sequence: static arena/actor/weapon and coordinate check → movement/collision → follow camera → main scene/minimum input → import/resource/short startup checks → manual proportions/feel review. Logic depends on actor body and explicit visual nodes, not a required future skeleton.

Future automated acceptance: no import/parse/resource errors, smoke-test instantiation, and short startup without errors. This does not verify feel or grip.

Future manual acceptance: F5/F6 enters arena; agreed movement matches camera; actors do not pass through ground/target; camera stays outside actor/ground; mouse capture works if used; proportions and one-handed grip are clear, other hand visible; approach/circling distance readable; no unauthorized attack/pursuit. Record scale/speed/framing adjustments, not Headless success as visual proof.

## Open Design Questions / Deferred Discussions

Static foundation and basic movement/right-shoulder camera are authorized; further development awaits manual acceptance and new approval. Preserve resolved combat rules while discussing unfinished details; do not implement default answers.

### Six Major Design Areas

| Area | Current status and remaining work |
| --- | --- |
| 1. Blade contact and sustained binding | Bind entry, pressure QTE, camera/input override, ordinary victory/mutually exclusive defeat, and separate trajectory-based retraction outcomes are confirmed. Staged encounters preserve duels; multi-participant combat disables Bind. Ordinary Sword Art contact, complex presses, specific moves, spatial/trajectory tests, Bind tuning/animations, execution input/timing, encounter classification scope, and durability formulas remain open |
| 2. Dodge and lethal-attack QTE | Positive resource with normal defense excludes special QTE; post-depletion collapse is prerequisite, not guarantee. QTE cannot interrupt Stagger / Knockback or insert a rescue dodge during it; grounded roll becomes available after the fall reaction ends. Exact triggers, motions, warnings, window, failure, and agency remain open |
| 3. Knockdown and serious injury | Stagger / Knockback is an uninterruptible hit-reaction process, followed by controllable Knocked Down if grounded or normal control after recovery if not. Only after the fall reaction ends: grounded roll > swing > rise; roll/swing reset rising; five accepted presses with progressive feedback. Blur below 30% remains confirmed. Reaction/recovery duration, get-up timing, safe direction, blur curve, injury motions, healing/recovery values remain open |
| 4. Enemy AI | Intent/Reaction/Mistake; waiting/offense/distance adjustment; reaction mistakes first; actual attack pressure (including defended attacks, excluding whiffs) increases the streak without requiring HP loss; valid defense followed by genuine breathing resets it. Pools, aggression/frequency, reaction time, special-attack eligibility, breathing detection, caps, and later judgment errors remain open |
| 5. Force abilities and gunfire | Force costs and attack-based recovery, per-ability requirements without extra universal threshold, Choke exception, and fluid transitions confirmed; hold-to-aim deferred. Values, Bind assistance, eligibility/interruption, precise aim and derived attacks remain open |
| 6. Soft-lock feel | ±40° safe range, sustained overrun unlock, Orient to Movement, combined camera ±40° / movement ±20° random eligible reacquisition confirmed. Thresholds/timing, Curve tuning, candidate relock protection, initial/stationary/death behavior, and mouse details remain open |

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
| Instinctive detection/cost? | Positive pre-trigger resource suffices without full payment; zero or an ongoing uninterruptible Stagger / Knockback hit reaction prevents it. That reaction restriction is not a persistent all-action lock while Knocked Down. Detection/cost values open |
| Initial blade state/extension timing? | One-meter reference, R2 toggle, and Bind retraction set; timings/contact activation provisional |
| Dodge form? | Respect direction; no assumption every dodge is a large roll |
| Ordinary contact/torque/Bind presentation? | Mutual clash itself costs no resource; detailed ordinary contact/pressing and Bind contact/animation solutions unapproved |
| Execution/injury eligibility and thresholds? | Body hits, ordinary-enemy guard break, and Choke may permit execution, not every hit guarantees death. Blur starts below 30%; other thresholds/recovery/body-part and Bind-defeat injury details open |
| Quick-shot intent/muzzle geometry? | Intelligible pose/hit feedback; no assumed random spread or guaranteed hit; no unique animation per prototype combination required |
| Enemy pressure streak/mistake calculation? | 10% base plus five percentage points per effective player attack pressure event, including ordinary/instinctively defended attacks, excluding whiffs; neither button presses nor HP damage define the count. Reset after valid defense followed by genuine breathing. Caps, breathing detection, special-attack eligibility, and mistake types remain open |
| Grip/camera/application name? | Reference dimensions exist; tune grip/camera manually, decide name separately |

## Development & Testing Instructions

Current scope is Stage 1 static foundation plus basic movement and the right-shoulder camera, with only their required Input Map and smoke tests. No combat, jump, soft lock, weapon animation, Curve resource, or commit is included. Stage 0 final acceptance and Stage 2 approval are not implied.

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

Current movement/camera verification commands (the smoke test now exists):

```powershell
& $godotExe --headless --path . --editor --import --quit
& $godotExe --headless --path . --script res://tests/smoke_test.gd
& $godotExe --headless --path . --quit-after 120
```

Short headless runs detect resource/script/runtime errors. Inspect output/logs, not only exit codes. `--quit-after` limits frames, not visual quality or performance. Record verified behavior, uncovered areas, and manual acceptance separately.

In future development, version scenes/scripts/assets and required import descriptions/UID files; exclude `.godot/` caches/logs. Keep implementation/stage status accurate instead of presenting plans as completed work.

The authorized foundation, basic movement and shoulder camera are implemented and automatically checked; new controls/visuals await manual acceptance. Stage 0 is not finally accepted. Stop here: Stage 2, weapon animation, and combat require separate authorization.
