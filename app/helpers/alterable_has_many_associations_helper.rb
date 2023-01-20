module AlterableHasManyAssociationsHelper
  
  def one_item(**options)
    f = options[:f]
    item_class = options[:item_class]
    item_array_name = options[:item_array_name]
    item = options[:item]
    
    item ||= item_class.new **options[:field_values] || {}
    item_for_fields = item.dup
    item_for_fields.id = nil
    f.fields_for item_array_name, item_for_fields do |sif|
      tag.tr do
        concat sif.hidden_field :id, value: item.id
        item_fields = options[:item_fields] || GeneralForm.default_fields[item_class]
        item_fields.each do |field|
          concat tag.td(formFields(sif, item, field, is_part_of_alterable_has_many_association: true))
        end
        if options[:delete_button]
          concat tag.td(link_to('delete', '', class: 'material-icons delete-button'))
        end
      end
    end
  end
  
  def add_button
    link_to(tag.span("add", class: "material-icons"), nil, class: 'add-item')
  end
  
  def alterable_has_many_associations_form(**options)
    
    item_array_name = options[:item_array_name]
    item_class = options[:item_class]
    associated_object = options[:associated_object]
    subjects = options[:subjects]
    form_name = options[:form_name]
    form_url = options[:form_url]
    
    form_for form_name, url: form_url, method: :post, html: { class: "general" } do |f|
      options[:f] = f
      options[:show_submit] = true
      alterable_has_many_associations_form_contents(**options)
    end
    
  end
  
  def alterable_has_many_associations_form_contents **options
    
    f = options[:f]
    associated_object = options[:associated_object]
    associated_object ||= options[:association]
    associated_object ||= options[:assoc]
    item_array_name = options[:item_array_name]
    item_array_name ||= "#{associated_object.klass.name.pluralize.underscore}[]"
    item_class = options[:item_class]
    item_class ||= associated_object.klass
    item_fields = options[:item_fields]
    item_fields ||= GeneralForm.default_fields[item_class]
    subjects = options[:subjects]
    subjects ||= flat_fields(item_fields) rescue nil
    subjects_raw = options[:subjects_raw] || subjects.map { |s, f| [item_class.human_attribute_name(s), s] }
    form_name = options[:form_name]
    form_url = options[:form_url]
    disable_key_binds = "disable_key_binds" if options[:disable_key_binds]
    directly_downward_with_enter = "directly_downward_with_enter" if options[:directly_downward_with_enter]
    add_item_callback = options[:add_item_callback]
    
    tag.div(class: "alterable_has_many_associations_form #{disable_key_binds} #{directly_downward_with_enter}", **(add_item_callback ? { data: { add_item_callback: add_item_callback } } : {})) do
      general_table do
        tag.tbody(class: "fields") do
          tag.tr(class: "subjectRow") do
            subjects_raw.each do |s, c|
              concat tag.th(s, class: c)
            end
            if options[:delete_button]
              concat tag.th('')
            end
          end + capture do
            associated_object.each do |item|
              concat one_item(f: f, item: item, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button))
            end
          end + capture do
            concat one_item(f: f, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button, :field_values)) unless associated_object.any?
          end
        end + capture do
          concat tag.tr(tag.td(f.submit('Tallenna'), colspan: subjects.length)) if options[:show_submit]
        end
        
      end + capture do
        concat add_button unless options[:hide_add_button]
        concat tag.template(one_item(f: f, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button, :field_values)), id: "new-item-template") unless options[:hide_add_button]
      end
      
    end
    
  end
  
end
