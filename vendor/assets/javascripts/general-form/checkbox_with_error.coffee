$(document).on 'turbolinks:load', ->
  fields = $('.check_box_container .field_with_errors')
  if fields.length
    fields.first().append(fields.not(':first').children())
    fields.not(':first').remove()