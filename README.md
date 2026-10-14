# Blaster-Saber-Godot-Demo

A Godot third-person cinematic gunblade combat prototype. **Stages 1 and 2 and Stage 4 Steps 1–7 have passed initial manual acceptance. Stage 4 Step 8: rapid directional enemy test bursts is authorized and implemented, awaiting manual acceptance.** Stage 3 visual presentation is postponed, not cancelled. Walking 2.0 m/s and running 3.5 m/s remain the accepted, adjustable baseline. Stage 0 has no explicit final acceptance; further work needs approval. Enemy bursts are temporary greybox timing tests, not formal AI. Pose matching, real clashes and damage prevention remain separate; no Bind/resources/IK is implemented.

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

Initial inspection: 2026-10-13. Stages 1 and 2 and Stage 4 Steps 1–7 are initially accepted. Step 8 replaces the slow enemy rhythm with stationary deterministic Thrust/Left Cut/Right Cut bursts and changes enemy-to-player test damage to 5 HP. Player attacks, locks, movement/camera, defense, HP maximum and bounded matching remain. No formal AI, pursuit, reactions, Stamina/Posture, Bind, instinctive defense or skeleton IK is implemented.

| Item | Observed state |
| --- | --- |
| Project | `project.godot` exists; `config_version=5` is a configuration format, not the engine major version |
| Local engine | `--version` returned `4.7.2.stable.steam.ed1daf0bf` |
| Project feature markers | `4.7`, `Forward Plus` |
| Application name | `Wuwaproject`; renaming remains open |
| Rendering/physics | Forward Plus, Windows `d3d12`, `Jolt Physics`; controls, HP, defense/motion, clashes and matching accepted; directional bursts awaiting review |
| Scenes/scripts | Existing nodes/scripts expanded with bounded burst scheduling and two enemy cut paths; no new gameplay files/assets or AI framework. Dimensions and initial positions retained |
| Assets | Native primitive meshes, simple embedded materials, marker nodes, and labels; default icon retained. No imported actor models, textures, or custom shaders |
| Input/systems | Existing inputs/F4 retained; Q / L1 / LB adds active defense. F7 resets both lives, motions and defense. No formal AI/reactions, shooting, instinctive defense/resources, dodge, Bind, Force, durability, execution, trail, or soft lock |
| Tests/export | `tests/smoke_test.gd`: 438 checks passed, retaining previous 362 with historical single-thrust/25 HP fixtures and adding 76 burst/current-damage checks. Import/loading/headless startup passed; no CI/export presets |
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

The user completed Stage 2 and Stage 4 Steps 1–7 initial manual acceptance. Step 8 directional bursts await review. Stage 3 presentation remains postponed rather than cancelled.

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

`Player/DebugDefense` uses `scripts/debug_player_defense.gd`. The only added Input Map action is `active_defense`: **L1 / Xbox LB** and temporary keyboard **Q** (physical key). Neither binding overlaps existing movement, camera, attack or debug actions. Press starts **Perfect Parry**, default **0.15 s**; remaining time decreases on physics ticks. Keeping the same press never renews it: after expiry the state becomes **Held Guard**. Release immediately removes defense when input is processed. Dead players cannot defend. Inspector exposes **Perfect Window Seconds** and **Defense Half Angle Degrees**, default **60° per side** (120° full cone); the editor range remains below 90° per side so rear sources cannot be guarded. These are temporary tests, not replacement values for the formal defensive timing/resource design.

The player HP receiver resolves defense only after a real **Valid Attack Contact** from the existing enemy blade sweep. Windup/return physical overlap and proximity alone never produce a block/parry. Facing uses the horizontal direction from the player origin to the actual attacking enemy origin, compared with the player's actual -Z forward. No automatic turn, face-target or soft lock is added. This is a minimal source-facing filter over blade/body contact, not weapon-versus-weapon interception, defense animations or full sword alignment.

Within the frontal cone, a held press with positive parry time yields **Perfect Parry**; a held press after expiry yields **Block**. Either prevents the whole test damage and sets the latest injury to **0 HP**. No press, rear/out-of-cone source, or otherwise unavailable defense yields **Failed** and ordinary HP deduction. The HP receiver consumes the enemy request ID before resolving defense, so a blocked request cannot damage later through duplicate delivery or after release. Both successful outcomes have no Stamina/Posture cost in this test. No instinctive defense, guard break, enemy stagger, disarm, retaliation reward or execution is included.

Defense has physics priority before player attack input, and the common attack entry also refreshes defense input. Both ordinary and forced debug requests are discarded while defending; no buffer is created. A fresh defense press immediately cancels an existing player Tween and closes its active window, retaining the current hand pose as the beginning of Step 6's defensive transition. Its final trajectory diagnostic cannot deduct enemy HP once defense is active. The original **remaining 0.26/0.24/0.30 s request lock is preserved**, so releasing defense cannot bypass it; after lock expiry and release, a fresh attack request is required. No generic cancellation framework or new combo rule is added.

F4 adds current **None / Perfect Parry / Held Guard**, precise-window remaining seconds, latest **Perfect Parry / Block / Failed**, prevented damage and latest injury (zero on success). Both HP readouts remain. F4 off hides this text without affecting resolution. F7 clears held/parry state and results alongside both HP/motion resets; if defense is still physically held through reset, release and press again to rearm. This prevents a held key from silently starting another perfect window after F7.

Verification on 2026-10-14: **319 checks passed**, preserving all previous 287 and adding 32 active-defense checks. Added coverage includes Q/L1 binding and no conflicts, Inspector defaults, press/hold/release transitions without parry extension, ordinary/debug attack rejection and no buffering, real-cylinder valid-contact parry/block versus rear/unguarded damage, prevented HP, lethal failed defense and Dead gating, timed parry and long-held block against the full existing enemy thrust, F4 state/result/zero injury and hiding, current-motion cancellation with unchanged hand pose and preserved input lock, fresh post-lock attacks, adjustable cone without auto-facing, zero-duration parry, F7 state/record cleanup and release-to-rearm. Editor import, scene loading and headless Main Scene startup passed without script/resource errors.

The user completed initial Step 5 manual acceptance of Q/L1 defense and damage prevention. Step 6 adds primitive visual transitions and independently observes blade contact below; it does not replace these accepted damage conditions.

### Stage 4 Step 6: Defense Motion and Blade Contact Diagnostics

`DebugDefense` owns a small physics Tween while raising/holding/returning the right hand. A press transitions from the current hand pose toward the short parry pose in 0.06 s, then settles into Held Guard in 0.09 s. A zero parry duration goes straight to guard. Release returns to existing Idle Guard in 0.20 s. New transitions kill only the previous defense Tween and retain its current transform; an accepted player attack stops any unfinished visual return before continuing the existing attack executor. The weapon remains a child of the hand with its original local transform. No bone, IK, AnimationTree or imported animation asset is added.

| Temporary pose in player local coordinates | Hand position (m) | Hand rotation (degrees) |
| --- | --- | --- |
| Short parry | (0.22, 1.14, -0.62) | (-55, 0, 70) |
| Held Guard | (0.30, 1.08, -0.42) | (-65, 0, 65) |

These pose vectors and Return Seconds are editable on `Player/DebugDefense` under **Temporary Defense Poses**. They are experimental coverage poses, not approved sword techniques. The 0.15 s precise window, ±60° cone, Q/L1, original request locks, HP/damage and enemy thrust are unchanged. A canceled player attack begins defense from its current pose, without snapping to Idle first.

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

Manual review must judge swing direction, rapid transitions, short rests, recovery, player movement/guard timing and F4 marker readability. In particular inspect Right Cut and late/limited matching. Headless continuity checks do not establish natural animation or input feel. Blocked damage and real blade clashes remain different results. Further stages/steps require approval.

## Planned Prototype Stages

Stage 0 has no explicit final acceptance. Stages 1 and 2 and Stage 4 Steps 1–7 passed initial manual acceptance. Stage 3 is temporarily postponed, not cancelled. Step 8 directional bursts is implemented for review; further work remains unapproved. Formal AI, Bind, resources and final contact/combat rules are not established by this test.

| Stage | Minimum scope | Validation gate |
| --- | --- | --- |
| Stage 0 — Project Inspection & Design Discussion | Inspection, README, mechanics/scope discussion | Ongoing, without acceptance; documentation is not stage approval |
| Stage 1 — Greybox Foundation | Static greybox, movement, walk/run and right-shoulder camera; enemy static | Initially manually accepted; walk 2.0/run 3.5 m/s debugging baseline retained |
| Stage 2 — Weapon Motion | Accepted three motions, selection/transitions, world-space sampling and optional debug lines. Defensive/shooting/extension motions remain future scope | Manual acceptance completed; preserved in contact-check regression |
| Stage 3 — Visual Effects | Temporarily postponed, not cancelled: Glow experiments, trail, presentation/contact feedback | No formal effects implemented; debug contact crosses are diagnostic only |
| Stage 4 — Basic Combat Exchange | Steps 1–8: contacts/windows/HP, directional stationary bursts, active defense, blade diagnostics and bounded matching | Steps 1–7 accepted; Step 8 awaiting review. Bind, resources, formal AI and later work remain unapproved |
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

Stages 1 and 2 and Stage 4 Steps 1–7 are initially accepted. Stage 3 is postponed; Step 8 test bursts are authorized and awaiting review. Further steps need approval. Test timing/pose coverage does not resolve formal AI, full sword alignment, Bind, resources or death design. Future Animation + IK may replace the greybox correction.

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

Current scope includes accepted player controls/attacks and Stage 4 Steps 1–8 contacts/windows, HP, stationary directional bursts, defense/motion, real-clash diagnostics and bounded hand matching. Enemy incoming damage is 5 HP per valid request. F4 is debug feedback. No Bind, formal AI, pursuit, resources, instinctive defense, skeleton IK, automatic attack tracking, jump, soft lock, Curve resource or commit is included. Stage 3 is postponed; further work is not authorized.

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

Player attacks, speed/locks, camera, HP maximum and defense remain. Stage 4 Steps 1–7 are accepted; Step 8 replaces enemy pacing with directional bursts and 5 HP incoming damage for review. Stage 3 remains postponed, not cancelled. Stop here: further work requires separate authorization. No commit is created.
