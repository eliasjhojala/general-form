used_unique_ids = []

if turbolinksSupported()
  $(document).on 'turbolinks:load', -> onLoad()
else
  $ -> onLoad()

onLoad = ->
  used_unique_ids = []
  loadForm()
  $('.add-item').click ->
    setTimeout ( -> @loadForm() ), 300
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@isDateSupported = ->
  input = document.createElement('input')
  value = 'a'
  input.setAttribute 'type', 'date'
  input.setAttribute 'value', value
  input.value != value

@setupDateFields = ->
  unless isDateSupported()
    date_fields = $('input[type="date"]')
    datepicker_amount = date_fields.length
    datepicker_ui_length = Math.ceil(datepicker_amount / 5)
    date_fields.each ->
      $(this).val($(this).data('val')) if $(this).data('val')
      if datepicker_amount > 1
        $(this).attr('id', "#{$(this).attr('id')}_datepicker_#{uniqueId(datepicker_ui_length)}")
      $(this).datepicker 'destroy'
      $(this).datepicker dateFormat: 'dd.mm.yy'
      $(this).off('focus.blur').on 'focus.blur', ->
        $(this).blur()

    if turbolinksSupported()
      # Render datepicker properly after back button press
      $(document).on 'turbolinks:before-cache', ->
        $.datepicker.dpDiv.remove()
        date_fields.each ->
          $(this).datepicker 'destroy'
      $(document).on 'turbolinks:before-render', ->
        $.datepicker.dpDiv.appendTo(event.data.newBody)

@setupSelect2Ids = ->
  select2_fields = $('select.select2')
  select2_amount = select2_fields.length
  select2_uid_length = Math.ceil(select2_amount / 5)
  select2_fields.each ->
    if select2_amount > 1
      $(this).attr('id', "#{$(this).attr('id')}_select2_#{uniqueId(select2_uid_length)}")

@loadForm = ->
  setupDateFields()
  setupSelect2Ids()

  checkbox_amount = $('.input_container.check_box_container').length
  if checkbox_amount > 1
    checkbox_uid_length = Math.ceil(checkbox_amount / 5)
    $('.input_container.check_box_container').each ->
      checkbox = $(this).find('input[type="checkbox"]')
      label = $(this).find("label[for=\"#{checkbox.attr('id')}\"]")
      uid = uniqueId(checkbox_uid_length)
      $(label).attr('for', "#{$(label).attr('for')}_checkbox_#{uid}")
      $(checkbox).attr('id', "#{$(checkbox).attr('id')}_checkbox_#{uid}")

  unless select2_no_widths? && select2_no_widths
    $('select.select2:not([multiple="multiple"])').select2(width: '100%')
    $('select.select2[multiple="multiple"]').select2(placeholder: '', width: '100%')
  else
    $('select.select2:not([multiple="multiple"])').select2()
    $('select.select2[multiple="multiple"]').select2(placeholder: '')

  if $('.form-floating .field_with_errors').length > 0
    $('.form-floating .field_with_errors').closest('.form-floating').addClass 'errors'
    $('.form-floating .field_with_errors').children().unwrap()



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
