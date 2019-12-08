$(document).on 'turbolinks:load', ->
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@loadForm = ->
  $('.datepicker').datepicker 'destroy'
  $('.datepicker').datepicker dateFormat: 'dd.mm.yy'
  $('.datepicker').on 'focus', ->
    $(this).blur()
