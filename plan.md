# Switch Combinator Mod Implementation Plan

This plan details the creation of a Factorio mod that adds a "Switch Combinator" - an advanced circuit network entity that functions like a switch statement with multiple condition groups, replacing the need for multiple decider combinators, with additional features for internal state tracking and output timing/latch functionality.


## Core Requirements

**Entity:** New "Switch Combinator" entity type that extends decider combinator functionality
**Unlock:** Same technology as decider combinators (Circuit network)
**Crafting:** Same recipe and cost as decider combinator
**Integration:** Full red/green circuit network compatibility like standard combinators

## Key Features

#### 1. Dual Matching Modes
- **First Match:** Evaluates groups sequentially, outputs from first matching group only
- **Multi Match:** Evaluates all groups, combines outputs from all matching groups

#### 2. Dynamic Condition Groups
- Start with one condition group
- "Add Group" button to create additional groups (placed at bottom, following Factorio UI patterns)
- No maximum limit - UI scrolls when needed
- Groups are reorderable via drag-and-drop (affects First Match priority)
- Default names: "Match 1", "Match 2", "Match 3", etc.
- Groups can be renamed via [Edit] button

#### 3. Synchronized Input/Output Groups
- Input groups on left, corresponding output groups on right
- Output groups automatically match input group order and names
- Only input groups can be reordered - output groups follow automatically
- Single "[+ Add Group]" button creates both input and output groups simultaneously

#### 4. Output Types and Timing
- **Output Type:** Each output signal can be "External" (circuit network) or "Internal" (state tracking)
- **Output Duration:** 
  - Default: 1 tick (small button with "1")
  - Custom: Click "1" button to reveal textbox for tick duration
  - Latch behavior: Output continues for specified duration even if condition stops matching
  - Timer resets: If condition unmatches and re-matches after timer expires, duration starts from zero
  - Timer persistence: If condition stays matched, duration continues counting

#### 5. Internal State Tracking
- Internal signals allow tracking state across multiple evaluations
- Internal outputs don't affect circuit network but can be used in conditions
- Enables complex state machines and memory functionality

#### 6. Group Structure
Each group contains:
- **Left side:** Multiple input conditions (AND logic within group)
- **Right side:** Output signals with type, merge mode, and duration settings
- **Conditions:** Same signal limits as standard decider combinator
- **Outputs:** Same signal limits as standard decider combinator

#### 7. Output Merge Modes (Multi Match only)
- **Merge:** Signal values are summed across matching groups
- **Single:** Signal uses value from first matching group only
- Per-signal radio buttons to configure merge behavior

#### 8. Signal Compatibility
- All signal types: items, fluids, virtual signals
- Same comparison operators as decider combinators (≤, ≥, =, ≠)
- Same arithmetic operators for outputs

### Technical Implementation

#### GUI Implementation Approach
Based on research of Improved Combinator and other Factorio mods:

**Key Findings:**
- Built-in decider combinator UI cannot be directly reused (hardcoded in game engine)
- Custom entity types require completely custom GUI implementation
- Must use `on_gui_opened` events and create custom GUI frames
- Factorio's GUI building blocks provide consistent look and feel

**Implementation Strategy:**
- Use Improved Combinator's node-based GUI architecture as reference
- Implement custom GUI using Factorio's standard GUI elements
- Handle all GUI events manually (click, text change, selection change, etc.)
- Create reusable GUI components for signal selectors, dropdowns, etc.

#### File Structure
```
switch-combinator/
├── info.json                    # Mod metadata
├── control.lua                  # Main control logic and event handlers
├── data.lua                     # Entity/recipe/technology definitions
├── locale/
│   └── en/
│       └── base.cfg            # English localization
├── graphics/
│   ├── icons/
│   │   └── switch-combinator.png
│   └── entities/
│       └── switch-combinator/
│           └── *.png           # Entity sprites
└── scripts/
    ├── gui/
    │   ├── main.lua             # Main GUI framework
    │   ├── components.lua       # Reusable GUI components
    │   ├── signal_selector.lua  # Signal selection component
    │   └── duration_control.lua # Duration control component
    ├── logic/
    │   ├── evaluator.lua        # Group evaluation engine
    │   ├── timer.lua            # Output duration/latch system
    │   └── state_manager.lua    # Internal state tracking
    └── utils/
        ├── signal_utils.lua     # Signal manipulation utilities
        └── gui_utils.lua        # GUI helper functions
```

#### Core Components

#### 1. Entity Definition (data.lua)
- New entity type based on decider-combinator prototype
- Custom sprite set (distinctive appearance)
- Same collision box, selection box, energy usage
- Circuit network connection points identical to decider

#### 2. GUI System (scripts/gui/)
- Main GUI framework with tabbed interface
- Custom signal selector components
- Drag-and-drop reordering system
- Duration control components
- Event handling for all GUI interactions

#### 3. Logic Engine (scripts/logic/)
- Group evaluation engine
- First Match: sequential evaluation with early exit
- Multi Match: parallel evaluation with output merging
- Signal aggregation logic for merge modes
- Timer system for output duration/latch behavior
- Internal state management and tracking

#### 4. Data Storage
- Entity behavior storage for group configurations
- GUI state management
- Group ordering data
- Merge mode settings per signal
- Output duration timers per signal
- Internal state storage

#### 5. Timer System Implementation
**Per-signal timer tracking:**
```lua
-- Example timer structure
signal_timers = {
  [unit_number] = {
    [signal_name] = {
      remaining_ticks = 600,
      is_active = true,
      last_match_tick = 12345
    }
  }
}
```

**Timer behavior:**
- Start/restart timer when condition matches
- Continue output while timer > 0, even if condition unmatches
- Reset timer to 0 when condition matches again after expiry
- Handle both External and Internal signal types

### GUI Layout Design

#### Main Interface (Decider Combinator + Groups Style)
```
┌─────────────────────────────────────────────────────────┐
│ Switch Combinator                      [Mode: ▼First Match] │
├─────────────────────────────────────────────────────────┤
│ Input: Not connected                  Output: Not connected │
│ ● Working                                               │
│ ┌─────────────────────────────────────────────────────┐   │
│ │                                                     │   │
│ │               [Combinator Graphic]                  │   │
│ │                                                     │   │
│ └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│ Input Groups                          Output Groups       │
│ ┌─────────────────────┐   ┌─────────────────────────────┐   │
│ │                     │   │                             │   │
│ │ ┌─────────────────┐ │   │ ┌─────────────────────────┐ │   │
│ │ │☰ Match 1 [×][Edit]│ │   │ │ Match 1                 │ │   │
│ │ ├─────────────────┤ │   │ ├─────────────────────────┤ │   │
│ │ │ Conditions      │ │   │ │ Outputs                 │ │   │
│ │ │ ┌─────────────┐ │ │   │ │ ┌─────────────────────┐ │ │   │
│ │ │ │[Signal] R G │ │ │   │ │ │● 1 [Pencil] Input count R G│ │ │ │
│ │ │ │[<][0] R G   │ │ │   │ │ │[×]                   │ │ │ │
│ │ │ │[×]          │ │ │   │ │ └─────────────────────┘ │ │   │
│ │ │ └─────────────┘ │ │   │ │ [+ Add output]          │ │   │
│ │ │ [+ Add condition]│ │   │ └─────────────────────────┘ │   │
│ │ └─────────────────┘ │   │                             │   │
│ │                     │   │ ┌─────────────────────────┐ │   │
│ │ ┌─────────────────┐ │   │ │ Match 2                 │ │   │
│ │ │☰ Match 2 [×][Edit]│ │   │ ├─────────────────────────┤ │   │
│ │ ├─────────────────┤ │   │ │ Outputs                 │ │   │
│ │ │ Conditions      │ │   │ │ ┌─────────────────────┐ │ │   │
│ │ │ ...             │ │   │ │ │ ...                   │ │   │
│ │ └─────────────────┘ │   │ │ └─────────────────────┘ │   │
│ │                     │   │                             │   │
│ │ [+ Add Group]       │   │                             │   │
│ └─────────────────────┘   └─────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ Input signals: [Signal bar]                              │
│ Output signals: [Signal bar]                             │
└─────────────────────────────────────────────────────────┘
```

#### Group Controls (Train Schedule Style)
- **☰:** Drag handle for reordering input groups (output groups follow automatically)
- **[×]:** Remove group button (removes both input and corresponding output group)
- **[Edit]:** Rename group button (updates name on both input and output sides)
- **Default names:** "Match 1", "Match 2", "Match 3", etc.
- **Synchronization:** Output groups cannot be reordered independently - they always match input group order
- **Mode ▼:** Dropdown for First Match/Multi Match

#### Condition/Output Controls (Decider Combinator Style)
**Condition Row Layout:**
```
┌─────────────────────────────────┐
│ [Copper Plate] [>] [1000] [×]   │
└─────────────────────────────────┘
```
- **[Copper Plate]:** Signal selector dropdown
- **[>]:** Comparison operator dropdown (>, <, =, ≤, ≥, ≠)
- **[1000]:** Numeric input for comparison value
- **[×]:** Remove condition button

**Output Row Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ [Iron Plate] [External▼] [Merge▼] [Count:1] [1▼] [×]   │
└─────────────────────────────────────────────────────────┘
```
- **[Iron Plate]:** Signal selector dropdown
- **[External▼]:** Output type dropdown (External/Internal)
- **[Merge▼]:** Merge mode dropdown (Merge/Single, only in Multi Match mode)
- **[Count:1]:** Numeric input for output count
- **[1▼]:** Duration button (click "1" to reveal tick duration textbox)
- **[×]:** Remove output button

**Duration Control Examples:**
```
Default (1 tick):    [1▼]
Custom duration:     [Duration: 600 ticks] [×]
```

**Add Buttons:**
- **[+ Add Condition]:** Button to add a new condition row within a group
- **[+ Add Output]:** Button to add a new output row within a group

#### Signal Display Sections
- **Input signals:** Shows current input signals (like decider combinator)
- **Output signals:** Shows resulting output signals (like decider combinator)

### Implementation Phases

#### Phase 1: Foundation
1. Create basic mod structure and info.json
2. Define entity prototype in data.lua
3. Add basic crafting recipe and technology integration
4. Create placeholder graphics

#### Phase 2: Core GUI
1. Implement base GUI framework
2. Add mode selection dropdown
3. Create single group interface (decider equivalent)
4. Add "Add Group" functionality

#### Phase 3: Group Management
1. Implement scrollable group container
2. Add group removal functionality
3. Implement drag-and-drop reordering
4. Add group collapse/expand states

#### Phase 4: Logic Engine
1. Implement First Match evaluation logic
2. Implement Multi Match evaluation logic
3. Add signal merging algorithms
4. Integrate with circuit network system

#### Phase 5: Polish
1. Create custom graphics and icons
2. Add localization support
3. Implement GUI state persistence
4. Add error handling and validation
5. Performance optimization

### Technical Challenges & Solutions

#### 1. GUI Complexity
- **Challenge:** Managing multiple collapsible groups with reordering
- **Solution:** Use Lua GUI framework with proper event handling and state management

#### 2. Performance
- **Challenge:** Evaluating many groups could impact performance
- **Solution:** Implement efficient evaluation with early exit for First Match mode

#### 3. Data Persistence
- **Challenge:** Storing complex group configurations across game loads
- **Solution:** Use entity behavior storage with proper serialization

#### 4. Circuit Integration
- **Challenge:** Ensuring proper circuit network behavior
- **Solution:** Leverage existing combinator framework and circuit network APIs

### Testing Strategy

#### Unit Tests
- Group evaluation logic
- Signal merging algorithms
- GUI state management

#### Integration Tests
- Circuit network connectivity
- Multi-entity interactions
- Save/load functionality

#### Performance Tests
- Large numbers of groups
- Complex signal configurations
- Multi-entity scenarios

### Compatibility Considerations

- Factorio version: 2.0+ (matching existing mods)
- Dependencies: Base game only
- Multiplayer compatibility: Full support
- Mod compatibility: No conflicts with circuit network mods

## Success Criteria

1. **Functional:** All specified features work as described
2. **Usable:** Intuitive GUI that feels natural to Factorio players
3. **Performant:** No noticeable impact on game performance
4. **Compatible:** Works seamlessly with existing circuit networks
5. **Extensible:** Code structure allows for future enhancements

This implementation will create a powerful new combinator that significantly simplifies complex circuit logic while maintaining the familiar Factorio interface patterns.

## Raw User Prompts

This implementation plan was created from the following verbatim user prompts:

1. "i want you to create a mod that adds a factorio combinator that will work like a "switch" statement. Basically take the "Decider Combinator" but instead of having each condition on the left always turn on ALL the conditions on the right I want to add "condition groups" on the left, which turn on outputs on the right, like a switch statement. For example group 1 "if copper_signal >= 1k and iron_signal <= 1k then output 1 iron_signal", group 2 "if iron_signal >= 1k and copper_signal <= 1k then output 1 copper_signal", etc use megaplan"
2. "1. Lets have an option "dropdown" for the type of behavior "First match" (behaves like a return statement), "Multi match" (sums matches like multiple in parallel) 2. allow adding groups, start with one and have a button to add another group 3. new entity type. UI same as decider combinator but on the left side it adds the conditions inside a "groups" in the and you can add more groups. A decider combinator is basically the same as this new type except its only one group. Effectively, if you do this with just 1 group it works like a decider combinator. Then on the right side, the outputs work exacly like a decider combinator but grouped. Effectively this is like having multiple decider combinators in one. 4. separate output groups. If mode is "multi match" have a radio buttons on each signal for "Merge Mode" "Merge" "Single" which allows you to configure if that specific signal gets "summed" (example if I output train_signal count 1 in 2 groups and both match, then output train_signal with count 2) or if single then it will just output train_signal count 1 (the first match wins) 5. should work with any signals all your questions satisfied? do you have any more questions?"
3. "1. yes 2. no need for maximum number, just have the ui scroll if needed. They should be re-ordable since their order mattters. 3. same as decider combinator. 4. same as decider combinator the name of this combinator is "Switch Combinator""
4. "no, the GUI Layout Design, dont implement yet, we are still ont he plan. This is the design of the decider combinator, update your layout to match it, but then add the groups"
5. "I want the outputs on the right side, like the decider combinator"
6. "I want the groups to look sort of like the train schedule design, no need for buttons for up/down, just allow the drag and drop"
7. "no, i want it to look like this, with inputs on left outputs on right"
8. "put the "Add group" button under the matches, so that as you add more match groups, the button stays under it (to better match factorio design)"
9. "remove the "add output grop" button since that list matches the input"
10. "perfect, please align it. Now, the output groups cannot be re-ordered, they match the order of the input groups. If you re-order them or update their names on the left side, the right side follows Groups can be renamed and they start with the name "Match 1" then "Match 2" etc"
11. "can you align the design?"
12. "can you search online if the decider combinator code exists somewhere and we can just re-use it? Specially for the UI"
13. "yes. study the improved combinators code. I want to add a functionality to allow to track internal state too. In output allow the signal output to be type "External" or "Internal". Add another feature to allow the output signal to be outputted for X amount of ticks. Default to 1 (add a small button with a "1" on it - meaning 1 tick, if you press it, adds a textbox stating how long that output should be active for in ticks). If the match is no longer matching, that signal will continue to output for that amount of time. If the match stays matched, then that output will continue to output for that amount of time. If the match un-matches and then re-matches, it still remembers that output time. But if the time runs out, and then a re-match happens, then it should start from zero. The idea is simple: If i connect a condition of battery level < 70% turns off a switch for 10 seconds, I want that "turn off" signal to stay active for 10 seconds, regardless if the battery level went above 70% in that time. This is a basic "latch" switch."
14. "add a section to the plan of "Raw User Prompts", and add there my prompts to you verbatim so we can refer back to them later and update them if needed. Dont change a thing, literally put them in quotes. Explain that the plan was made from these prompts"
15. "add those to the bottom of the file, dont make each one a title, just make a list of quotes"

## Design Assertions from Screenshot Analysis

Based on detailed comparison with vanilla Factorio decider combinator screenshots, the following design assertions were identified and implemented:

### Core Layout Requirements

#### 1. Two-Operand Condition Model
- **Left Operand**: Signal selector with R/G wire filter checkboxes
- **Operator**: Dropdown (>, <, =, ≥, ≤, ≠)
- **Right Operand**: Toggle between constant value OR signal selector with R/G checkboxes
- **R/G Checkboxes**: Appear on BOTH left and right sides of each condition
- **Wire Filter Layout**: 2x2 grid pattern (R checkbox + R label / G checkbox + G label)

#### 2. OR/AND Logic Between Conditions
- **Logic Buttons**: "OR" or "AND" buttons appear between condition rows
- **Default Logic**: First condition has no logic, subsequent conditions default to "OR"
- **Toggle Function**: Click logic buttons to toggle between OR/AND
- **Grouping**: Conditions are grouped by OR, connected by AND within groups
- **Evaluation**: (c1 AND c2) OR (c3 AND c4) OR c5

#### 3. Signal Value Display
- **Signal Buttons**: Use `choose-elem-button` with `number` property for value overlay
- **Value Position**: Number appears as overlay on signal icon (bottom-left)
- **Live Updates**: Values update in real-time from wire connections
- **Zero Suppression**: Signals with value 0 show no number overlay

#### 4. Output Row Design
- **Signal Selector**: With value overlay showing current input signal count
- **Count Field**: Textfield for fixed count value (hidden when using input count)
- **Radio Buttons**: Mutually exclusive "count value" vs "Input count" options
- **R/G Checkboxes**: For output wire filtering
- **Delete Button**: Standard utility/close sprite button
- **Active Indicator**: Orange dot (●) when conditions met, grey dot (○) when not

#### 5. Signal Preview Sections
- **Style**: `slot_button` style with `number` overlay
- **Layout**: Horizontal flow of signal buttons
- **Input Preview**: Shows actual signals from connected wires
- **Output Preview**: Shows signals from hidden constant combinator
- **Value Display**: Number overlay on each signal icon

#### 6. Description Management
- **Button**: "Add description" button (changes to "Edit description" when text exists)
- **Dialog**: Modal dialog with text area and "Accept" button
- **Behavior**: Matches vanilla decider combinator description editing

#### 7. Visual Consistency
- **Window Size**: 880px width to accommodate two-column layout
- **Styles**: Use Factorio mandatory styles (`deep_frame_in_shallow_frame`, `inside_shallow_frame_with_padding`, `frame_action_button`)
- **Colors**: R labels in red (1, 0.2, 0.2), G labels in green (0.2, 1, 0.2)
- **Spacing**: Consistent with vanilla combinator UI patterns

### Data Model Requirements

#### Condition Structure
```lua
{
  left_signal, left_red, left_green,
  operator,
  compare_type,  -- "constant" or "signal"
  constant,       -- number value
  right_signal, right_red, right_green,
  logic           -- "or", "and", or nil for first condition
}
```

#### Output Structure
```lua
{
  signal,
  count,
  use_input_count,  -- boolean, mutually exclusive with count
  red_wire,
  green_wire
}
```

### Evaluation Logic
- **Single Condition**: Compare left signal value against right operand
- **Right Operand**: Either constant number OR another signal's value
- **Wire Filtering**: Each operand can filter red/green wires independently
- **Group Logic**: OR between condition groups, AND within conditions
- **Short Circuit**: Stop evaluation in first_match mode after first successful group

### Implementation Details

#### GUI Element Naming Convention
- Prefix: `sc_` for all GUI elements
- Conditions: `sc_cond_lsig_{gi}_{ci}`, `sc_cond_rsig_{gi}_{ci}`, `sc_cond_const_{gi}_{ci}`
- Logic: `sc_cond_logic_{gi}_{ci}`
- Outputs: `sc_out_sig_{gi}_{oi}`, `sc_out_radio_input_{gi}_{oi}`, `sc_out_radio_count_{gi}_{oi}`
- Wire checkboxes: `sc_cond_lw_{gi}_{ci}_red`, `sc_cond_rw_{gi}_{ci}_green`, etc.

#### Event Handling
- **Checkbox Changes**: `on_gui_checked_state_changed` for all checkboxes and radiobuttons
- **Signal Selection**: `on_gui_elem_changed` for signal selectors
- **Text Changes**: `on_gui_text_changed` for constant values and count fields
- **Dropdown Changes**: `on_gui_selection_changed` for operators and mode
- **Button Clicks**: `on_gui_click` for add/remove/toggle actions

#### Performance Considerations
- **Evaluation Frequency**: Every 6 ticks (~10 times per second)
- **Signal Reading**: Cache input signals per evaluation cycle
- **GUI Updates**: Only rebuild when configuration changes
- **Memory Usage**: Compact data structures, no Lua functions in storage

### Migration Requirements
- **Old Saves**: `on_configuration_changed` handler to rebuild entity registry
- **Cleanup**: Remove old `storage.hidden_combinators` from previous architecture
- **Compatibility**: Maintain save/load compatibility across mod updates

These design assertions ensure the Switch Combinator exactly matches the visual and functional behavior of the vanilla Factorio decider combinator while adding the requested multi-group functionality.