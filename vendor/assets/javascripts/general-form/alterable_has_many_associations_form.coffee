if turbolinksSupported()
  $(document).on 'turbolinks:load', -> onLoad()
else
  $ -> onLoad()

onLoad = ->
  alterable_has_many_associations_scripts(true)

@alterable_has_many_associations_scripts = (bind_add_button = false) ->

  form = $('.alterable_has_many_associations_form')
  if bind_add_button
    form.find('.add-item').click (e) ->
      add_item(e, $(this).parent())

  form.find('.delete-button').click (e) ->
    delete_item(e, $(this).parents('tr'))

  add_item = (e, form) ->
    e.preventDefault()
    form.find('table tbody.fields').append form.find('#new-item-template').html()
    alterable_has_many_associations_scripts()
    loadSearchFieldsJs() if typeof(loadSearchFieldsJs) == 'function'
    callback = form.data('add-item-callback')
    window[callback]() if callback
    form.trigger 'itemAdded'

  delete_item = (e, tr) ->
    e.preventDefault()
    tr.find('input._delete').val 1
    tr.addClass 'hidden'
    tr.find('*').prop 'required', false
    if $('tr:not(.hidden)').length <= 1
      add_item e, tr.parents('form')

  $('.alterable_has_many_associations_form:not(.disable_key_binds)').off('keypress').on 'keypress', (e) ->
    if e.keyCode == 13
      add_item(e, $(this))
      return false

  $('.alterable_has_many_associations_form.directly_downward_with_enter').find('input').off('keypress', focus_next_field).on 'keypress', (e) ->
    focus_next_field(e, this)

  focus_next_field = (e, elem) ->
    if e.keyCode == 13
      e.preventDefault()
      $($(elem).parent().parent().parent()).next('tr').find('.'+$(elem).attr('class')).focus();
