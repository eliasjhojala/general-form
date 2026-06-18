# CLAUDE.md

Operating rules for Claude in this repository. The **source of truth for project
conventions is `.cursor/rules/`**. This file mirrors them for Claude; the linked
`.mdc` files are authoritative.

## Project at a glance

- Form helper gem (`general_form_for`, field types, alterable has-many forms) consumed by snacktime-gvodata, menddie, visualevents-intra, home_automation, visualsites.fi, and extended by the **fiscal** engine
- Ruby in `app/` (helpers, form_fields, concerns); browser assets vendored: CoffeeScript in `vendor/assets/javascripts/general-form/`, SCSS (themed + unthemed) in `vendor/assets/stylesheets/general-form/`
- Integration reference: `README.md` + `docs/GUIDE.md` — keep in sync with changes
- Lightweight regression test suite under `test/` (`rake test`); does **not** boot
  a full Rails app, only the gem's plain-Ruby units. Behaviour that needs a real
  view context is still best verified in a consuming app — say how.
- Branch: `master`

## Always-applied rules (summary + link)

- **[base](.cursor/rules/base.mdc)** — Helper signatures, field-type names, CSS classes, and JS entry points are public API across many consumers: search consumers before changing; new behavior is opt-in; keep docs in sync.
- **[commit-messages](.cursor/rules/commit-messages.mdc)** — Imperative subject; trailer `Made-with: Claude`; no `Co-authored-by:`.
- **[dry](.cursor/rules/dry.mdc)** — New field types inherit from the closest existing class; shared logic in one place.
- **[english-code-and-docs](.cursor/rules/english-code-and-docs.mdc)** — English everywhere; translatable copy resolves in the consuming app.

## Scoped rules

| Rule | Scope |
| --- | --- |
| [assets-conventions](.cursor/rules/assets-conventions.mdc) | `vendor/assets/**` — `loadForm`/`loadFormWithin` API stability, no double-binding, themed vs `without_theme` SCSS, LibSass unit gotcha |

## Commit checklist

- Searched consumers for the changed surface? Docs updated for user-visible changes?
- State how the change was verified (which consuming app).
- Trailer: `Made-with: Claude`.

## Persisting conventions

When the user corrects style/process/tooling, or you discover a non-obvious
convention worth keeping, add or extend a `.cursor/rules/*.mdc` file in the same
task. This file stays a thin index.
