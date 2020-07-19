used_unique_ids = []

$(document).on 'turbolinks:load', ->
  loadForm()
  $('.add-item').click ->
    setTimeout ( -> @loadForm() ), 300
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@loadForm = ->
  datepicker_amount = $('.datepicker').length
  datepicker_ui_length = Math.ceil(datepicker_amount / 5)
  $('.datepicker').each ->
    if datepicker_amount > 1
      $(this).attr('id', "#{$(this).attr('id')}_datepicker_#{uniqueId(datepicker_ui_length)}")
    $(this).datepicker 'destroy'
    $(this).datepicker dateFormat: 'dd.mm.yy'
    $(this).off('focus.blur').on 'focus.blur', ->
      $(this).blur()
      
  # Render datepicker properly after back button press
  $(document).on 'turbolinks:before-cache', ->
    $.datepicker.dpDiv.remove()
    $('.datepicker').each ->
      $(this).datepicker 'destroy'  
  $(document).on 'turbolinks:before-render', ->
    $.datepicker.dpDiv.appendTo(event.data.newBody)
      
  checkbox_amount = $('.input_container.check_box_container').length
  if checkbox_amount > 1
    checkbox_uid_length = Math.ceil(checkbox_amount / 5)
    $('.input_container.check_box_container').each ->
      checkbox = $(this).find('input[type="checkbox"]')
      label = $(this).find('label')
      uid = uniqueId(checkbox_uid_length)
      $(label).attr('for', "#{$(label).attr('for')}_checkbox_#{uid}")
      $(checkbox).attr('id', "#{$(checkbox).attr('id')}_checkbox_#{uid}")
    
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
