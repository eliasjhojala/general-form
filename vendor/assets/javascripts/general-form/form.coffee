$(document).on 'turbolinks:load', ->
  loadForm()
  $('input.disabled').on 'focus', ->
    $(this).blur()

@formUrl = (form) ->
  $(form).attr 'action'

@loadForm = ->
  $('.datepicker').each ->
    $(this).attr('id', "#{$(this).attr('id')}_datepicker_#{uniqueId(50)}")
    $(this).datepicker 'destroy'
    $(this).datepicker dateFormat: 'dd.mm.yy'
    $(this).on 'focus', ->
      $(this).blur()

@uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length
