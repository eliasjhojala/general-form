if turbolinksSupported()
  $(document).on 'turbolinks:load', -> onLoad()
else
  $ -> onLoad()

onLoad = ->
  fields = $('.check_box_container .field_with_errors')
  if fields.length
    fields.first().append(fields.not(':first').children())
    fields.not(':first').remove()
