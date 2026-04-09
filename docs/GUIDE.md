# general-form

Rails engine that standardises **declarative form definitions**, **rendering** (edit and read-only), **strong parameters**, and **editable has-many tables** (nested rows with add/delete). Host applications describe each model’s inputs as arrays of `GeneralForm::Field` (often via a `*Fields::DEFAULT` constant) instead of hand-writing every label and input in ERB.

This guide describes the gem’s behaviour and the conventions used in consuming apps (for example **gvodata** and **menddie**).

## Main point first

Use `general-form` so each form is defined in one place (for example `app/form_fields/user_fields.rb`) and reused in:

- view rendering (`general_form_with_fields_for`, `allFormFields`, `formFields`)
- controller strong parameters (`permit_fields`)
- read-only rendering (`show_form_fields`)

This removes duplicate form definitions in both ERB inputs and controller `permit(...)` lists.

## When to use

- Prefer `general-form` for most CRUD-style forms and nested association tables.
- If something is missing, prefer extending `general-form` in a backward-compatible way rather than bypassing it.
- Use fully custom form code only when the UX/logic is genuinely outside what this abstraction can model (for example multi-step wizards with client-side-only state machines, canvas-like editors, drag-drop layout builders, or heavy real-time collaborative flows). JS-enhanced forms that still map to stable model fields should usually stay in `general-form` and be extended as needed.

## Installation and setup

1. Add the gem to the host `Gemfile` and bundle.
2. **JavaScript** — require the manifest so datepicker, Select2, and form behaviours load:

   ```js
   //= require general-form
   ```

3. **Styles** — import the gem’s styles and override SCSS variables *before* importing `general-form` partials, for example:

   ```scss
   $general-form-accent-color: #2296f3;
   @import 'general-form/theme';
   @import 'general-form/without_theme';
   ```

   Floating labels use `general-form/form_floating` (pulled in via the theme stack depending on how you import).

4. **Configuration** — in `config/initializers/general_form.rb`, call `GeneralForm.setup` and point `default_fields` at how the host resolves field lists for a model class.

### Default field resolution

```ruby
GeneralForm.setup do |config|
  config.default_fields = ->(klass) { "#{klass}Fields".constantize::DEFAULT rescue nil }
  config.use_form_floating = true   # optional
  config.auto_select2 = true        # long selects get Select2 when appropriate
  config.locales = [:fi, :en]      # used for :localised / :localised_text_area
end
```

**Engine default** (if you do not set `default_fields`): `klass::DEFAULT_FORM_FIELDS` (with `rescue nil`).

Host apps commonly use **`ModelFields::DEFAULT`** (e.g. `SettingFields::DEFAULT`) by constantizing `"#{klass}Fields"` — see gvodata and menddie initializers.

### Host app helpers

Include the engine’s helpers (or rely on `helper GeneralFormHelper` in controllers that already mix them). Typical modules involved:

| Module | Role |
| -------- | ------ |
| `GeneralFormHelper` | `general_form_with_fields_for`, `allFormFields`, `formFields`, `formField`, labels, floating, errors |
| `ShowFormFieldsHelper` | `show_form_fields`, read-only display |
| `AlterableHasManyAssociationsHelper` | editable nested tables |
| `ShowAlterableHasManyAssociationsHelper` | read-only nested tables |
| `Fields` (via `FieldsHelper` in gem) | `permit_fields`, `flat_fields`, and field introspection for controllers |
| `FileHelper` | uploads and attachment listing (expects host routes/helpers such as `post_file_path`, `delete_attachment_path`) |

Also define **`ApplicationFields`** in the host app with a short factory for fields, for example:

```ruby
class ApplicationFields
  def self.X(name, **args)
    GeneralForm::Field.new(field_name: name, **args)
  end
end
```

(`field_name:` is required; the constructor maps `type:` to the internal `field_type`.)

## Public API reference

This section documents helpers/concerns that are intended for direct host-app usage. Internal helper plumbing (for example label internals and low-level normalization helpers) is intentionally omitted.

`Usage` indicates where the method is actively used today:

- `both` = found in both gvodata and menddie
- `gvodata` = found in gvodata
- `menddie` = found in menddie
- `public` = exposed by the gem and intended for host apps, even if current usage is limited

### Form rendering helpers (`GeneralFormHelper`)

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `general_form_with_fields_for(record, fields = nil, **options)` | both | Default wrapper: errors + generated fields + submit. |
| `allFormFields(f, record, fields = nil, **options)` | both | Render a full field list for a form builder and record. |
| `formFields(f, record, form_fields, **options)` | both | Render one field (or grouped row of fields). |
| `allFormFieldsWithTabs(f, record, tabs)` | gvodata | Render tabbed sections from a hash of field lists. |
| `allFormFieldsForAssoc(f, record, assoc, fields, **options)` | gvodata | Render fields inside `fields_for` for a named association. |
| `formField(f, record, form_field, **options)` | public | Advanced low-level single-field renderer (usually called through `formFields`). |

### Form layout and utility helpers (`GeneralFormHelper`)

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `list_errors(records, **options)` | both | Shared validation error block. |
| `input_container { ... }` | both | Consistent wrapper with `input_container` class. |
| `form_floating_container(name, placeholder, ...) { ... }` | both | Floating-label container for custom controls. |
| `form_tag_if(condition, ...) { ... }` | gvodata | Conditionally wrap content in `form_tag`. |
| `text_span(text)` | gvodata | Standard label span helper for custom rows. |

### Read-only helpers

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `show_all_form_fields(record, fields, fields_name = nil, **opts)` | gvodata | Render read-only versions of a field list. |
| `show_form_fields(record, form_fields, fields_name = nil, **opts)` | gvodata | Render read-only output for one field/group. |
| `show_alterable_has_many_associations_form_contents(**options)` | gvodata | Read-only table view for has-many field definitions. |

### Editable has-many table helpers

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `alterable_has_many_associations_form_contents(**options)` | both | Main inline has-many editor used inside parent forms. |
| `alterable_has_many_associations_form(**options)` | public | Standalone has-many editor when not embedded in another form. |

### Controller concern API (`Fields`, `AlterableHasManyAssociationHandler`)

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `permit_fields(fields, skip_disabled: false)` | both | Generate strong-parameter structures from field definitions. |
| `flat_fields(fields, **opts)` | both | Flatten fields for inspection/table subjects. |
| `field_names(fields)` | gvodata | Convenience list of field names. |
| `handle_alterable_has_many_association(**options)` | both | Persist add/update/delete rows from alterable has-many tables. |
| `fields_for_association_experimental(fields, association_path)` | menddie | Advanced helper for association-path subset extraction. |

### File/attachment helpers (`FileHelper`)

| Method | Usage | Purpose |
| -------- | -------- | -------- |
| `show_link_for_attachment(attachment, **opts)` | gvodata | Link to in-app attachment preview/show route. |
| `download_link_for_attachment(attachment)` | gvodata | Download icon link for an attachment. |
| `links_for_attachments(model, files_name = :attachments)` | gvodata | Inline list of attachment links. |
| `list_attached_files(model, **options)` | public | Rich attachment table with preview/delete controls. |
| `default_file_field(f, model, **options)` | public | Multi-file input + existing attachments list. |
| `single_file_field(f, model, **options)` | public | Single-file input + optional preview/delete behaviour. |

## Core concepts

### `GeneralForm::Field`

Fields are plain Ruby objects. Important attributes (see `lib/general_form/field.rb` for the full list):

- **`field_name`** — attribute on the model (Symbol).
- **`type`** (stored as `field_type`) — which widget and behaviour to use (`:default`, `:select`, `:check_box`, `:associated_fields`, …).
- **`hide_name`**, **`name_after`**, **`text`**, **`text_after`**, **`localised_text`** — label layout and copy.
- **`privileges`** / **`privileges_strict`** — if set, the field is omitted unless `current_user` passes the corresponding check (helpers must have `current_user`).
- **`association_path`** — array of nested `fields_for` keys to reach the object that owns the attribute (e.g. `[:profile]` or `[:account, :profile]`).
- **`associated_model`**, **`associated_fields`** — for `type: :associated_fields`, nested forms for a belongs-to-style object and its fields.
- **Select-related**: `select_options` (proc, relation, array, Range, …), `options_name`, `options_value`, `multiple`, `select2`, `no_select2`, `polymorphic`, `prompt`, `allowed_keys`, `data_for_select_options`, `data_for_allowed_keys`, `data_attributes_for_options`, `no_policy_scope`.
- **Validation/HTML**: `required`, `readonly`, `autofocus`, `disabled`, `min`, `max`, `step`, `scale`, `html`, `autocomplete`, `direct_upload`, `preview` (files).

### Field lists per model

Convention: one module per model, e.g. `SettingFields`, with `DEFAULT` (and sometimes other presets like `ADMIN`, `INFO`):

```ruby
class SettingFields < ApplicationFields
  DEFAULT = [
    X(:type, type: :select, required: true),
    X(:value, type: :text_area)
  ]
end
```

`GeneralForm.default_fields[SomeModel]` returns that array when the initializer’s lambda resolves `SomeModelFields::DEFAULT`.

### Edit views: `general_form_with_fields_for`

Renders `form_for` with class `general` (and `floating` when floating is on), prints **`list_errors`** for the record, then **`allFormFields`** for the field list, yields the form builder, then **submit** unless `submit: false`.

```erb
<%= general_form_with_fields_for @setting, use_form_floating: true %>
```

```erb
<%= general_form_with_fields_for @user, UserFields::DEFAULT do |f| %>
  <%# extra markup, nested alterable tables, etc. %>
<% end %>
```

Options passed through to field rendering include:

- **`use_form_floating`** — per-form override of `GeneralForm.use_form_floating`.
- **`field_descriptions`** — nested hash for tooltips: `field_descriptions[object.class.to_s][field_name]`.
- **`custom_fields`** — for `type: :custom`, a map `field_name => HTML` (or callable result) injected instead of a standard widget.

### Lower-level: `allFormFields` and `formFields`

- **`allFormFields(f, record, fields = nil, **options)`** — iterates `fields` (default: `GeneralForm.default_fields[record.class]`) and concatenates `formFields` for each.
- **`formFields(f, record, form_fields, **options)`** — accepts a single `Field`, a `Symbol`, or an array of `Field`s (one logical “row” wrapped in `input_container` when applicable).

Special handling in `formFields`:

- **`associated_fields`** — `fields_for` + nested `allFormFields` using `associated_fields` or `GeneralForm.default_fields[associated_model]`.
- **`localised` / `localised_text_area`** — one column per locale (`GeneralForm.locales` or `I18n.available_locales`), attribute names suffixed with `_#{locale}`.
- **`flags_check_boxes`** — no shared outer container (each checkbox is its own container).
- **`custom`** — pulls content from `options[:custom_fields][field_name]`.

### Read-only: `show_form_fields`

Mirrors many of the same structures for display (`ShowFormFieldsHelper`). Use for show pages or tables where you want the same field definitions without inputs. Not every `field_type` has rich display support; unsupported types fall through to a generic message in `show_form_field`.

Optional **`fields_name`** (third argument) matches the form-helper call shape used in some hosts; when omitted, nested calls default it to `"fields"`.

## Field types (edit)

These are the `type:` values handled in `formField` (plus the special cases above handled in `formFields`):

| Type | Purpose |
| ------ | --------- |
| `:default` | Text field |
| `:password` | Password field |
| `:title`, `:subtitle` | Text with extra CSS classes |
| `:check_box` | Boolean; Material-style label |
| `:text_area` | Multiline |
| `:trix_editor` | Trix (if available) |
| `:datepicker`, `:date` | Date (native or jQuery UI fallback in JS) |
| `:time` | Time |
| `:datetime` | `datetime_local_field` |
| `:date_and_time` | Two fields: `#{name}_date` and `#{name}_time` (use `DateAndTimeFields` concern on the model — see below) |
| `:phone_number` | Uses `Phone.readable` if present |
| `:disabled`, `:disabled_date`, `:disabled_time`, `:disabled_datetime` | Read-only-looking inputs |
| `:function` | Display-only via `text_field_tag` |
| `:hidden`, `:reset` | Hidden inputs |
| `:only_text` | No input |
| `:only_value`, `:only_value_as_date`, `:title_only_value` | Display spans in forms |
| `:label` | Label-only control |
| `:number` | Numeric text; `scale` controls decimals |
| `:range` | Range input |
| `:file`, `:files` | ActiveStorage-friendly file inputs (`FileHelper`) |
| `:color` | Color input |
| `:select` | Enum (no `select_options`), collection, or `Range`; optional Select2 |
| `:collection_select` | `collection_select`, multiple |
| `:flags_select` | Multi select for bitflag enums via `translated_flag_pairs` |
| `:habtm_select` | HABTM ids on the join attribute |
| `:partial` | `render partial: ...` with `f`, `field`, `record` |
| `:flags_check_boxes` | Per-flag checkboxes with `[]` name |

**Floating:** `floatable?` limits which types get Bootstrap-style floating labels; selects can float; alterable-table rows pass `is_part_of_alterable_has_many_association: true` to avoid floating inside table cells.

### Model concern: `DateAndTimeFields`

For `type: :date_and_time`, include `DateAndTimeFields` and declare `date_and_time_fields :some_attr` so the model exposes `some_attr_date` / `some_attr_time` setters that merge into the single datetime column.

## Strong parameters: `permit_fields` / `Fields`

Controllers include the `Fields` concern (via `FieldsHelper` in the gem). **`permit_fields(fields)`** walks a field list and returns an array suitable for `params.require(...).permit(...)`:

- Simple attributes → symbols.
- **`association_path`** → nested `..._attributes` hashes (see `deeper_merge`).
- **`associated_fields`** → `#{name}_attributes` with nested `permit_fields` for the child definition.
- **Localised fields** → `field_locale` keys for each configured locale.
- **`date_and_time`** → `#{name}_date`, `#{name}_time`.
- **Arrays** — file multi-uploads, `flags_select`, `flags_check_boxes`, `collection_select`, etc. merge in `[]` keys as needed.

Use **`flat_fields`** for name→`Field` maps and **`field_names`** for simple lists.

## Alterable has-many associations

For inline editable tables (rows backed by `has_many` children or standalone records), pair the view helper with the controller handler.

### Typical flow

1. Render rows with `alterable_has_many_associations_form_contents`.
2. User adds/removes rows in the browser (JS clones from `new-item-template`, marks deletions via `_delete`).
3. Controller calls `handle_alterable_has_many_association` with the same field definition.
4. Handler inserts/updates/deletes rows in one transaction.

### Minimal example

```erb
<%= form_for @user do |f| %>
  <%= alterable_has_many_associations_form_contents(
    f: f,
    associated_object: @user.contact_methods,
    item_fields: ContactMethodFields::DEFAULT,
    delete_button: true
  ) %>
  <%= f.submit %>
<% end %>
```

```ruby
def update
  @user = User.find(params[:id])
  @user.assign_attributes(user_params)
  handle_alterable_has_many_association(
    items: params[:user],
    associated_object: @user.contact_methods,
    item_fields: ContactMethodFields::DEFAULT,
    run_callbacks: true
  )
  @user.save!
end
```

### Key options to know

| Option | Where | Meaning |
| -------- | -------- | -------- |
| `associated_object:` | view + controller | Target relation/collection for rows. |
| `item_fields:` | view + controller | Field list for one row. Keep this same on both sides. |
| `item_array_name:` | view + controller | Param key for row array; default is inferred from class name. |
| `delete_button:` | view | Shows delete UI; handler respects `_delete`. |
| `add_item_callback:` | view | Name of a global JS function called after a row is added. |
| `disable_key_binds:` | view | Disables Enter-to-add-row keyboard binding in alterable table. |
| `directly_downward_with_enter:` | view | Moves focus to same-column input on next row when pressing Enter. |
| `existence_field_name:` | controller | Defines when a new row is considered non-empty and should be saved. |
| `run_callbacks:` | controller | Use callback-aware save/delete path; otherwise bulk import/delete path may be used. |
| `unsaved_items_data:` | view | Rehydrate typed rows back into the table after validation failures. |

### Parameter shape

Rows are posted under the parent param key and the row-array key, for example:

```ruby
params[:user][:contact_methods] # => [{ id: 1, value: "...", _delete: "0" }, ...]
```

Existing rows with `_delete` truthy are removed, existing rows with changed values are updated, and new non-empty rows are inserted.

Standalone variant `alterable_has_many_associations_form` wraps its own `form_for` when the table is not part of a larger model form.

## Internationalisation

- Labels use `localised_field_name`: `human_attribute_name`, or I18n when `text` looks like a key.
- Enum selects use `activerecord.enums.*` (see `enum_options_for_select`).
- Select prompts: `prompt_translated` or `activerecord.prompts.model_name.field_name`.

## Assets and behaviour

- **form.coffee** — `loadForm(optionalRoot)` calls `setupDateFields(root)`, `setupSelect2Ids(root)` (returns selects to init), checkbox id wiring, then Select2 widget init on those selects; default `root` is the whole document. `loadFormWithin(container)` does the same wiring but only when `container` is present and matches at least one element; missing, `false`, or empty roots no-op (they do not fall back to the whole document). Public helpers `setupDateFields` / `setupSelect2Ids` accept the same optional root. Turbolinks datepicker teardown is registered once.
- **alterable_has_many_associations_form.coffee** — add row from template, delete row, Enter key behaviour, optional `add_item_callback`.
- **direct_uploads.js** — direct upload support for file fields when used.

### JS integration points (practical)

- Call `loadForm()` with no arguments to wire **the whole document** (same as `loadForm(document.documentElement)`).
- When you inject a **fragment** (modal, table row panel, etc.) and the page already has other Select2 widgets, call `loadForm(fragmentRoot)` or `loadFormWithin(fragmentRoot)` — same subtree behaviour when the root exists. Prefer `loadFormWithin` if the node might be absent (empty jQuery, selector miss) so the rest of the page is not wired by mistake. Only nodes inside `fragmentRoot` get Select2 init (skips elements that already have Select2); ids are still uniquified using counts across the **whole document**. Targets: `select.select2`, `input[type="date"]`, and checkboxes in `.input_container.check_box_container` / `.flags_check_boxes_container` under the root. Matching `label[for]` inside the fragment root are updated when ids change.
- Alterable tables trigger a jQuery `itemAdded` event on `.alterable_has_many_associations_form` after adding a row.
- `add_item_callback:` can be passed to `alterable_has_many_associations_form_contents`; its value must be a global function name.
- If your flow is JS-heavy but still model-field based, keep using `general-form` and hook behavior through these integration points.

### JS side effects and selector safety

- `loadForm()` may mutate generated element ids to keep them unique when multiple similar controls exist (for example date inputs, Select2-backed selects, and checkbox controls).
- Do not rely on static DOM ids for these controls in custom JS/CSS.
- Prefer stable selectors such as field classes, wrapper classes (for example `.<field_name>_container`), `name` attributes, and `data-*` attributes you control.
- If you must target a specific element instance, add your own stable wrapper or `data-*` marker in the field `html:` options and target that marker.

Dependencies (see gemspec): `activerecord-import`, `active_flag`, `select2-rails`, `jquery-ui-rails`, `deep_merge`.

## Patterns in real apps

- **gvodata** — broad usage of `general_form_with_fields_for`, `alterable_has_many_associations_form_contents`, custom `GeneralForm::Field` compositions in partials, and `ModelFields::DEFAULT` resolution.
- **menddie** — broad usage with global floating labels, nested `associated_fields`, `handle_alterable_has_many_association`, and `custom_fields` compositions.

## Contribution direction

When you need new behavior:

1. Prefer adding or improving capability in `general-form`.
2. Keep changes backward compatible for existing field definitions and helpers.
3. Document new options in this guide so host apps can adopt consistently.
4. Fall back to fully custom forms only when the workflow is truly outside the abstraction.

## Troubleshooting

| Symptom | Things to check |
| -------- | ------------------ |
| No inputs for a model | `GeneralForm.default_fields[Model]` is `nil` — define `ModelFields::DEFAULT` or pass an explicit field array. |
| Privilege-related `NoMethodError` in views/helpers | Field rendering checks `current_user.privileges?` / `privileges_strict?` when field definitions use privilege options; ensure `current_user` exists in that rendering context or avoid privilege-gated fields there. |
| Strong params missing nested keys | Field list must match the structure; use `associated_fields` / `association_path` as in the form; use `permit_fields` with the same definition as the form. |
| Select2 not styled | `//= require general-form` and Select2 CSS from the asset pipeline; `auto_select2` / `select2: true` on the field. |
| Only one Select2 works / duplicate DOM ids | Multiple `select.select2` with the same `id` confuse Select2. Use `loadForm()` or `loadForm(container)` after render; generated suffixes are tracked in `used_unique_ids` so they stay unique within the page session. `label[for]` inside the fragment root is updated when an id changes. |
| Alterable table does not add rows | JS not loaded; template id `new-item-template`; class `alterable_has_many_associations_form` on the wrapper. |
| JS selector hooks break after form init | `loadForm()` may rewrite element ids; target by stable class/name/`data-*` selectors instead of fixed ids. |
| Localised columns wrong | Locales in initializer vs columns `attr_name_locale` on the model. |

---

*Version and behaviour follow the gem source; when in doubt, refer to `GeneralFormHelper#formField`, `Fields#permit_fields`, and `AlterableHasManyAssociationHandler#handle_alterable_has_many_association`.*
