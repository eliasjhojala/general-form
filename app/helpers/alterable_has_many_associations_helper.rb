module AlterableHasManyAssociationsHelper

  def one_item(**options)
    f = options[:f]
    item_class = options[:item_class]
    item_array_name = options[:item_array_name]
    item = options[:item]

    item ||= options[:new_item] || item_class.new(options[:field_values]) || {}
    item_for_fields = item.dup
    item_for_fields.id = nil
    f.fields_for item_array_name, item_for_fields do |sif|
      tag.tr do
        concat sif.hidden_field :id, value: item.id
        concat sif.hidden_field :_delete, value: 0, class: '_delete' if options[:delete_button]
        item_fields = options[:item_fields] || GeneralForm.default_fields[item_class]
        item_fields.each do |field|
          concat tag.td(formFields(sif, item, field, is_part_of_alterable_has_many_association: true), class: [field].flatten.map(&:field_name))
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
    item_array_name = options[:item_array_name] || "#{associated_object.klass.name.demodulize.pluralize.underscore}[]"
    item_class = options[:item_class]
    item_class ||= associated_object.klass
    item_fields = options[:item_fields]
    item_fields ||= GeneralForm.default_fields[item_class]
    subjects = options[:subjects]
    subjects ||= flat_fields(item_fields) rescue nil
    subjects_raw = options[:subjects_raw] || subjects.map { |s, f| [item_class.human_attribute_name(s), s] }
    custom_subject_row = options[:custom_subject_row]
    form_name = options[:form_name]
    form_url = options[:form_url]
    disable_key_binds = "disable_key_binds" if options[:disable_key_binds]
    directly_downward_with_enter = "directly_downward_with_enter" if options[:directly_downward_with_enter]
    add_item_callback = options[:add_item_callback]
    render_initial_item = options.key?(:render_initial_item) ? options[:render_initial_item] : true

    tag.div(class: "alterable_has_many_associations_form #{disable_key_binds} #{directly_downward_with_enter}", **(add_item_callback ? { data: { add_item_callback: add_item_callback } } : {})) do
      general_table(class: options[:table_class]) do
        concat options[:custom_colgroups]
        concat (tag.tbody(class: "fields") do
          if custom_subject_row
            custom_subject_row
          else
            tag.tr(class: "subjectRow") do
              subjects_raw.each do |s, c|
                concat tag.th(s, class: c)
              end
              if options[:delete_button]
                concat tag.th('')
              end
            end
          end + capture do
            associated_object.each do |item|
              concat one_item(f: f, item: item, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button))
            end
          end + capture do
            existence_field_name = options[:existence_field_name] || options[:existence_field] || :any_field
            unsaved_items_data = options[:unsaved_items_data]&.select do |item|
              should_be_kept = (existence_field_name == :any_field && item.except(:id).values.any?(&:present?)) || item[existence_field_name].present?
            end
            if unsaved_items_data&.any?
              unsaved_items_data.each do |item|
                concat one_item(f: f, field_values: item, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button))
              end
            elsif render_initial_item
              concat one_item(f: f, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button, :field_values, :new_item)) unless associated_object.any?
            end
          end
        end + capture do
          concat tag.tr(tag.td(f.submit('Tallenna'), colspan: subjects.length)) if options[:show_submit]
        end)

      end + capture do
        concat add_button unless options[:hide_add_button]
        concat tag.template(one_item(f: f, item_array_name: item_array_name, item_class: item_class, item_fields: item_fields, **options.slice(:delete_button, :field_values, :new_item)), id: "new-item-template") unless options[:hide_add_button]
      end

    end

  end

end
