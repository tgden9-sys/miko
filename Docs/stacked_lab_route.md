# Stacked lab route

Open `Play Lab Run.cmd`.

The route crosses three floors with six metres between their walking surfaces.

- Ground floor runs right to the east service shaft.
- Two staggered landings climb to the first floor.
- First floor runs left past the combat dummy to the west shaft.
- Two more landings climb to the second floor.
- Second floor runs right to the external descent shaft.
- Three staggered drop landings lead to the dispatch room on the ground floor.

Corridors have 5.55 metres of clear ceiling height. The existing camera size of 9.25 and its viewing angle are retained, with vertical tracking added for the shafts. Reset points use floor-specific positions. Jump, double jump, dash and combat tuning are unchanged. The art pass adds the wake cradle, coolant equipment, control stations and the standby relay. In the scene tree, move a node under Landings to reposition its collision and trim together. The seven landings also expose a width setting.

The route validation drives Miko's existing input automation through each landing without teleporting. Checkpoint tests then reset independently to each supported floor position.

Files

- `MovementLab/scripts/lab_run.gd`
- `Builds/Validation/MovementLab/verify_stacked_lab.gd`
- `Builds/Validation/MovementLab/capture_stacked_lab.gd`

