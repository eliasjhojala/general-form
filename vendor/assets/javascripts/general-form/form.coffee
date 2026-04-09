used_unique_ids = []
datepickerTurbolinksHooksInstalled = false

if turbolinksSupported()
  $(document).on 'turbolinks:load', -> onLoad()
else
  $ -> onLoad()

onLoad = ->
  used_unique_ids = []
  installDatepickerTurbolinksHooksOnce()
  loadForm()
  $('.add-item').click ->
    setTimeout ( -> @loadForm() ), 300
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@isDateSupported = ->
  nativeDateInputReliable()

# True when the browser applies native `type="date"` behaviour (same check as @isDateSupported).
nativeDateInputReliable = ->
  input = document.createElement('input')
  v = 'a'
  input.setAttribute 'type', 'date'
  input.setAttribute 'value', v
  input.value != v

installDatepickerTurbolinksHooksOnce = ->
  return if datepickerTurbolinksHooksInstalled
  return if nativeDateInputReliable()
  return unless turbolinksSupported()
  datepickerTurbolinksHooksInstalled = true
  $(document).on 'turbolinks:before-cache', ->
    $.datepicker.dpDiv.remove()
    $('input[type="date"]').each -> $(this).datepicker 'destroy'
  $(document).on 'turbolinks:before-render', ->
    $.datepicker.dpDiv.appendTo(event.data.newBody)

# Root for full-page wiring (default when `loadForm()` is called with no args).
loadFormScopeRoot = (root) ->
  if root? && root != false
    $(root)
  else
    $(document.documentElement)

elementWithinRoot = (rootEl, el) ->
  !!(el && rootEl.nodeType == 1 && rootEl.contains(el))

# Always assigns a new id (short uid suffix). `uniqueId` records values in `used_unique_ids`, so
# candidates do not collide with other ids we generate in this page session. Updates `label[for]`
# inside `root` when the previous id is replaced.
@ensureUniqueHtmlIdInDocument = ($el, kind, root, uidLength) ->
  oldId = $el.attr('id')
  base = if oldId?.length then oldId else "#{kind}_#{@uniqueId(uidLength)}"
  candidate = "#{base}_#{kind}_#{@uniqueId(uidLength)}"
  $el.attr 'id', candidate
  if oldId?.length && root? && root.length && oldId != candidate
    root.find('label').filter( -> $(this).attr('for') == oldId).attr 'for', candidate

# Optional `root`: defaults to the whole document. Not exported; used by `loadForm` only.
setupCheckboxIds = (root) =>
  root = loadFormScopeRoot(root)
  return unless root.length
  rootEl = root[0]
  checkbox_containers_in_doc = $('.input_container').filter('.check_box_container, .flags_check_boxes_container')
  checkbox_uid_length = Math.max(1, Math.ceil(checkbox_containers_in_doc.length / 5))
  (checkbox_containers_in_doc.filter (i, el) ->
    elementWithinRoot(rootEl, el)
  ).each (i, el) =>
    checkbox = $(el).find('input[type="checkbox"]').first()
    return unless checkbox.length
    @ensureUniqueHtmlIdInDocument checkbox, 'checkbox', root, checkbox_uid_length

# Datepicker fallback for `input[type="date"]` under `root` (default: document). Turbolinks hooks
# are installed once from `loadForm`, not here.
@setupDateFields = (root) ->
  root = loadFormScopeRoot(root)
  return unless root.length
  rootEl = root[0]
  unless nativeDateInputReliable()
    dates_in_document = $('input[type="date"]')
    datepicker_uid_length = Math.max(1, Math.ceil(dates_in_document.length / 5))
    date_fields = dates_in_document.filter -> elementWithinRoot(rootEl, this)
    if date_fields.length > 0
      date_fields.each (i, el) =>
        $d = $(el)
        $d.val($d.data('val')) if $d.data('val')
        @ensureUniqueHtmlIdInDocument $d, 'datepicker', root, datepicker_uid_length
        $d.datepicker 'destroy'
        $d.datepicker dateFormat: 'dd.mm.yy'
        $d.off('focus.blur').on 'focus.blur', ->
          $d.blur()

# Assigns unique ids to `select.select2` under `root` that are not yet Select2-initialized.
# Returns those fields so callers can run `.select2(...)` only on them. Uid length uses counts
# across the whole document. Optional `root`: defaults to the whole document.
@setupSelect2Ids = (root) ->
  root = loadFormScopeRoot(root)
  return $() unless root.length
  rootEl = root[0]
  select2_in_document = $('select.select2')
  select2_uid_length = Math.max(1, Math.ceil(select2_in_document.length / 5))
  select2_fields = select2_in_document.filter ->
    elementWithinRoot(rootEl, this) && !$(this).data('select2')
  select2_fields.each (i, el) =>
    @ensureUniqueHtmlIdInDocument $(el), 'select2', root, select2_uid_length
  select2_fields

initSelect2Widgets = (select2_fields) ->
  return if select2_fields.length == 0
  unless select2_no_widths? && select2_no_widths
    select2_fields.filter(':not([multiple="multiple"])').select2(width: '100%')
    select2_fields.filter('[multiple="multiple"]').select2(placeholder: '', width: '100%')
  else
    select2_fields.filter(':not([multiple="multiple"])').select2()
    select2_fields.filter('[multiple="multiple"]').select2(placeholder: '')

# Optional `root`: jQuery selector, element, or jQuery collection. When omitted, the whole
# document is processed (same as passing `document.documentElement`).
@loadForm = (root) ->
  installDatepickerTurbolinksHooksOnce()
  @setupDateFields(root)
  select2Targets = @setupSelect2Ids(root)
  setupCheckboxIds(root)
  initSelect2Widgets(select2Targets)
  scoped = loadFormScopeRoot(root)
  if scoped.find('.form-floating .field_with_errors').length > 0
    scoped.find('.form-floating .field_with_errors').closest('.form-floating').addClass 'errors'
    scoped.find('.form-floating .field_with_errors').children().unwrap()

# Like `loadForm(root)` but never defaults to the whole document: missing, false, or empty roots no-op.
@loadFormWithin = (root) ->
  return unless root? && root != false
  $root = $(root)
  return unless $root.length
  @loadForm($root)

@uniqueId = (length) ->
  uid = randomId(length)
  if uid in used_unique_ids
    uid = @uniqueId(length, used_unique_ids)
  else
    used_unique_ids.push(uid)
  uid

@randomId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length
