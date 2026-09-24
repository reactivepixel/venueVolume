# Agent coordination

## Branches and worktrees

- `dev` is the integration branch. The repository owner alone promotes changes to `master`; agents must not merge, reset, or push `master`.
- Give each agent one task, one branch named `agent/<task>`, and one worktree at `.worktree/<task>`. Create it from the current `dev` branch with `git worktree add -b agent/<task> .worktree/<task> dev`.
- An agent edits, installs dependencies, tests, and commits only in its assigned worktree. Do not switch branches in the primary checkout or edit another agent's worktree. `.worktree/` is ignored by Git in the primary checkout.
- Assign file ownership before parallel work. Coordinate changes to shared docs, package lockfiles, and generated design assets; worktrees isolate files but do not prevent merge conflicts.
- Keep the branch and worktree until its changes are integrated and reviewed. Then remove the clean worktree with `git worktree remove .worktree/<task>` and delete the merged agent branch.

## Local servers and tests

- Before starting any server, check that its intended port has no listener (for example, `lsof -nP -iTCP:5174 -sTCP:LISTEN`). Choose a different port if it is occupied. After launch, confirm the server actually bound to the chosen port. Never stop another agent's process to free a port.
- Give concurrently running servers distinct ports. For the design studio, run `npm run dev -- --port 5174 --strictPort` from `apps/design-studio`, substituting an available port. Set `VV_BASE_URL=http://127.0.0.1:5174` for its browser tests and screen export when using that port. The test scripts otherwise target port 5173.
- For the marketing app, pass an available port with `npm run dev -- --port 4322` from `apps/marketing`. Use a different port if 4322 is taken.
- Run `npm ci` separately in each app within each worktree. Build output and dependencies stay local to that worktree. The design studio browser tests and export write tracked files under `assets/design/venue-volume`; review those changes before committing.

## Integration and patch tags

- A single integration owner reviews and merges completed agent branches into `dev` sequentially. Resolve conflicts there and run the checks relevant to the changed apps.
- For an integration batch, increment the patch version in both app `package.json` and `package-lock.json` files. Include that bump in the final merge commit, then create an annotated `vX.Y.Z` tag on that commit. Do not reuse or move a published tag.
- Leave `master` untouched. The repository owner decides when to promote `dev` to `master`.
