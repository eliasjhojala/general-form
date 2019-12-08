$(document).on 'turbolinks:load', ->
  loadForm()
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@loadForm = ->
  $('.datepicker').datepicker 'destroy' # Remove possibly existing datepicker
  $('.datepicker').datepicker dateFormat: 'dd.mm.yy' # Add datepicker
  $('.datepicker').on 'focus', ->
    $(this).blur()
