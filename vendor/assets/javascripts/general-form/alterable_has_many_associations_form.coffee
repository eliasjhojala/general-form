$(document).on 'turbolinks:load', ->
  alterable_has_many_associations_scripts(true)
  
@alterable_has_many_associations_scripts = (bind_add_button = false) ->
  
  if bind_add_button
    form = $('.alterable_has_many_associations_form')
    form.find('.add-item').click (e) ->
      add_item(e, $(this).parent())
  
  add_item = (e, form) ->
    e.preventDefault()
    form.find('table tbody.fields').append form.find('#new-item-template').html()
    alterable_has_many_associations_scripts()
    loadSearchFieldsJs()
    
  $('.alterable_has_many_associations_form:not(.disable_key_binds)').unbind().bind 'keypress', (e) ->
    if e.keyCode == 13
      add_item(e, $(this))
      return false
    
  $('.alterable_has_many_associations_form.directly_downward_with_enter').find('input').unbind('keypress', focus_next_field).bind 'keypress', (e) ->
    focus_next_field(e, this)
    
  focus_next_field = (e, elem) ->
    if e.keyCode == 13
      e.preventDefault()
      $($(elem).parent().parent().parent()).next('tr').find('.'+$(elem).attr('class')).focus();
