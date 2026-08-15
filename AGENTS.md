- Never update the plan without approval from the user.
- Always stick to the plan, and never deviate from it.
- If user asks to implement something that is not in the plan, always ask for approval, clarification and then update the plan first but only after approval and require permission to implement.
- If I say "m", just do a mental check, which means you are going through run "in your head" through all the code and check if there are parts of it which will fail or not work as expected, in which case you will fix them without asking. So that whenever I am testing, I dont waste time with small stupid problems.
- Before presenting the output to the user, think and check if the user would write "m", if so, then just do the mental check again anyway and fix any issues.
- YAGNI, remove old stuff if you arent using it, dont keep backwards compability
- Dont hide errors, let it fail fast
- Use lua to check syntax errors and run basic unit tests that you cant run ingame, and others ingame leave to user to run
- dont hide errors let it blow up with a stack trace, as quickly as possible, also run the tests as quickly as possible, like during game load
- NO OLD STUFF EVER, ALWAYS FORWARDS AND ONWARDS!
- NO MORE BACKWARDS COMPABILITY, IF ITS NOT USED REMOVE IT!
- NO CHECKING IF SOME CONDITION MIGHT BE NULL, EITHER YOU KNOW IT CAN BE NULL (SEARCH ONLINE IF YOU HAVE TO) OR DONT CHECK, MEANINGLESS GUARDS POLUTE THE CODE

## Factorio Modding

- If the task involves creating, modifying, or debugging a Factorio mod — or anything related to Factorio modding (prototypes, `data.lua`, `control.lua`, settings, locale, GUI, circuit network, ammo effects, etc.) — **load the base skill `factorio-modding` first**.
- This base skill is a router that points to the appropriate sub-skills (prototypes, runtime, GUI, circuit network, ammo effects, performance, migrations, debugging, vanilla reference).
- The skill files live at `.windsurf/skills/factorio-modding*.md`.
- Consult the official API docs at https://lua-api.factorio.com/latest/ whenever exact prototype fields or class methods are needed.

## Ralph usage

- For any non-trivial coding task (feature, refactor, bugfix), start a `ralph_loop` via the `ralph-wiggum` MCP server.
- Prefer a template when available:
  - `ralph_list_templates`
  - `ralph_get_template` with a suitable `template_id`
- Default behavior:
  - Use `template_id: "tdd"` for backend work.
  - Set `max_iterations: 10` unless the user asks for more or less.
- Do not implement large tasks in a single shot; always route them through Ralph’s loop.
