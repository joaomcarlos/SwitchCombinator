# Switch Combinator

> A programmable, multi-branch circuit combinator for Factorio 2.0.

Switch Combinator lets one combinator evaluate several named condition groups and
produce the outputs for the branch—or branches—that match. It is useful when a
large circuit would otherwise need a stack of decider combinators.

## Features

- **First match** mode: checks groups from top to bottom and uses the first match.
- **Multi match** mode: evaluates every group and combines their outputs.
- Add, remove, and name condition groups; each group has its own outputs.
- Use `AND` and `OR` between conditions inside a group.
- Compare a signal with a constant or another signal.
- Select red wire, green wire, or both for each side of a condition and output.
- Set a fixed output count or pass through the matching input signal count.
- Works with item, fluid, virtual, and quality-aware signals.
- Shows live input/output signal shelves and match status in a Factorio-style GUI.

## Installation

1. Download or clone this repository into your Factorio `mods` directory.
2. Keep the folder name as `switch-combinator`.
3. Start Factorio and enable **Switch Combinator** for your save.

The mod requires Factorio `2.0` and the base game. Its recipe is unlocked with
the circuit network technology.

## Usage

Place a Switch Combinator and open it to configure its condition groups. Select
an input signal, choose an operator, and compare it with a constant or another
signal. Add outputs to the matching group, then connect the combinator to your
circuit network as you would a vanilla decider combinator.

Groups are evaluated in their displayed order. In **First match** mode evaluation
stops after the first matching group. In **Multi match** mode, values from every
matching group are added together for the same output signal.

## Development

The runtime logic lives in `control.lua` and `scripts/`. Pure Lua tests are in
`tests/`; see [`tests/README.md`](tests/README.md) for the debug test commands.

Contributions and bug reports are welcome.
