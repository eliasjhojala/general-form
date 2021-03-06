module GeneralFormHelper
  
  def standardize_form_fields fields
    if fields.is_a? GeneralForm::Field
      [fields]
    elsif fields.is_a? Symbol
      [GeneralForm::Field.new(field_name: fields)]
    else
      fields
    end
  end
  
  def standardize_form_field field
    if field.is_a? Symbol
      GeneralForm::Field.new(field_name: field)
    else
      field
    end
  end
  
  def allFormFieldsWithTabs(f, record, tabs)
    tabs.each do |tab_name, fields|
      concat (tag.div class: "tab #{tab_name}" do
        concat allFormFields(f, record, fields)
      end)
    end
    nil # Prevent printing tabs.each (array)
  end

  def allFormFieldsForAssoc(f, record, assoc, fields, **options)
    f.fields_for assoc do |f_assoc|
      allFormFields f_assoc, record.send(assoc), fields, **options
    end
  end
  
  def allFormFields(f, record, fields = nil, **options)
    fields ||= GeneralForm.default_fields[record.class]
    fields.each do |field|
      concat formFields(f, record, field, **options)
    end
    return
  end

  def formFields(f, record, form_fields, **options)
    form_fields = standardize_form_fields form_fields
    if form_fields.count() == 1 && form_fields[0].field_type == :associated_fields
      f.fields_for form_fields[0].field_name do |ff|
        associated_fields = form_fields[0].associated_fields
        associated_fields ||= GeneralForm.default_fields[form_fields[0].associated_model]
        allFormFields(ff, record.send(form_fields[0].field_name), associated_fields, **options)
      end
    else
      if form_fields.count != 1 || !form_fields.first.field_type.in?([:custom, :flags_check_boxes])
        tag.div class: ['input_container', form_fields.map(&:field_name).map{|field| "#{field}_container"}, form_fields.map(&:field_type).map{|field| "#{field}_container"}].flatten.uniq.join(' ') do
          form_fields.each do |field|
            unless field.privileges.present? && !current_user.privileges?(field.privileges)
              text = field.text.present? ? field.text : field.field_name
              span_content = record.class.human_attribute_name(text) unless field.hide_name
              span_content = tag.a(span_content, href: '') if field.text_type == :link
              text_span = tag.span(span_content, class: "#{field.field_name} text_span")
              
              concat text_span unless field.hide_name || field.name_after
              concat formField(f, record, field, **options)
              concat text_span if field.name_after
              concat tag.span(field.text_after.html_safe, class: "#{field.field_name} text_after text_span") if field.text_after
            end
          end
        end
      elsif form_fields.first.field_type == :flags_check_boxes
        form_fields.each do |field|
          concat formField(f, record, field, **options)
        end
        nil
      elsif form_fields.first.field_type == :custom
        options.dig(:custom_fields, form_fields.first.field_name)
      end
    end
  end

  def formField(f, record, form_field, **options)
    form_field = standardize_form_field form_field
    field_name = form_field.field_name
    field_type = form_field.field_type || :default
    field_name_translated = record.class.human_attribute_name(field_name) unless [:check_box, :only_value, :only_value_as_date, :title_only_value, :hidden].include?(field_type) || record.nil?
    autocomplete = form_field.autocomplete || field_name
    if field_name.present?

      case field_type
      when :default; f.text_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': autocomplete
      when :password; f.password_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': form_field.autocomplete
      when :title; f.text_field field_name, class: "#{field_name} title", placeholder: field_name_translated, 'autocomplete': autocomplete
      when :subtitle; f.text_field field_name, class: "#{field_name} subtitle", placeholder: field_name_translated, 'autocomplete': autocomplete
      when :check_box; f.check_box(field_name, class: field_name, include_hidden: options[:is_part_of_alterable_has_many_association].blank?) + f.label(field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: "material-icons #{field_name}")
      when :text_area; f.text_area field_name, class: field_name, placeholder: field_name_translated
      when :trix_editor; tag.div(f.trix_editor(field_name, class: field_name, placeholder: field_name_translated), class: 'trix-container')
      when :datepicker, :date; f.date_field field_name, class: "#{field_name} datepicker", value: (f.object.send(field_name).strftime('%Y-%m-%d') rescue nil), data: { val: (f.object.send(field_name).strftime('%-d.%-m.%Y') rescue nil) }, placeholder: field_name_translated
      when :time; f.time_field field_name, class: "#{field_name} time", value: (f.object.send(field_name).strftime('%H:%M') rescue nil), data: { val: (f.object.send(field_name).strftime('%H:%M') rescue nil) }, placeholder: field_name_translated
      when :date_and_time; [:date, :time].sum { formField(f, record, GeneralForm::Field.new(field_name: "#{field_name}_#{_1}", type: _1)) }
      when :phone_number; f.text_field field_name, class: "#{field_name} phone_number", placeholder: field_name_translated, 'autocomplete': autocomplete, value: Phone.readable(f.object.send(field_name))
      when :disabled; f.text_field field_name, class: "#{field_name} disabled"
      when :disabled_date; f.text_field field_name, class: "#{field_name} disabled", value: (f.object.send(field_name).strftime('%-d.%-m.%Y') rescue f.object.send(field_name))
      when :disabled_time; f.text_field field_name, class: "#{field_name} disabled", value: (f.object.send(field_name).strftime('%-d.%-m.%Y %H:%M') rescue f.object.send(field_name))
      when :function; text_field_tag field_name, record.send(field_name), class: "#{field_name} disabled"
      when :hidden; f.hidden_field field_name, class: field_name
      when :reset; f.hidden_field field_name
      when :only_text; ""
      when :only_value; tag.span f.object.send(field_name).to_s, class: 'only_value_span'
      when :only_value_as_date; tag.span((l f.object.send(field_name) rescue nil), class: 'only_value_span')
      when :title_only_value; tag.span f.object.send(field_name).to_s, class: 'only_value_span title'
      when :label; f.label field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: 'material-icons'
      when :number; f.text_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': autocomplete, type: 'number', step: 1.0 / (10**(form_field.scale || 0))
      when :range; f.range_field field_name, class: field_name, min: form_field.min, max: form_field.max, step: form_field.step
      when :file; single_file_field(f, record, attachment_name: field_name, replace_instead_of_delete: true, preview: form_field.preview, direct_upload: form_field.direct_upload)
      when :files; default_file_field(f, record, files_name: field_name, direct_upload: form_field.direct_upload)
      when :select
        prompt = form_field.prompt.present? ? t("activerecord.prompts.#{record.class.name.underscore}.#{field_name}") : '-'
        use_policy_scope = form_field.no_policy_scope.blank?
        unless form_field.select_options.present?
          options = enum_options_for_select(record, field_name)
          if options.present?
            f.select field_name, options, {include_blank: prompt}, {class: field_name, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled }
          end
        else
          form_field.options_name ||= "name"
          if form_field.data_for_select_options.present?
            options = form_field.select_options[record[form_field.data_for_select_options]]
            options = policy_scope(options) if use_policy_scope
          else
            if form_field.select_options.respond_to? :call
              options = form_field.select_options[]
            elsif form_field.select_options.is_a? Range
              options = options_for_select(form_field.select_options.map {|i| [i,i] }, record.send(field_name.to_s))
            else
              options = form_field.select_options
            end
            if form_field.polymorphic
              options = options.map { |x| policy_scope(x) } if use_policy_scope
              options = options.sum
            elsif use_policy_scope && !options.is_a?(ActiveSupport::SafeBuffer)
              options = policy_scope(options)
            end
          end
          unless options.is_a? ActiveSupport::SafeBuffer
            options_value = form_field.options_value || (!form_field.polymorphic ? 'id' : 'global_id')
            options = options_from_collection_for_select(options, options_value, form_field.options_name, record.send(field_name.to_s))
          end
          f.select field_name, options, {include_blank: prompt}, {class: field_name, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled }
        end
      when :collection_select
        form_field.options_name ||= "name"
        options = form_field.select_options[]
        f.collection_select field_name, options, 'id', form_field.options_name, {}, { multiple: true, class: 'select2' }
      when :flags_select
        f.collection_select field_name, translated_flag_pairs(record.class, field_name), 'last', 'first', {}, { class: "select2", multiple: true }
      when :habtm_select
        value = record.send(form_field.habtm).pluck(:id)
        if form_field.select_options.respond_to? :call
          options = form_field.select_options[]
        else
          options = form_field.select_options
        end
        options = policy_scope(options) if form_field.no_policy_scope.blank?
        form_field.options_name ||= "name"
        f.select field_name, options_from_collection_for_select(options, "id", form_field.options_name, value), {:include_blank => "-"}, {class: field_name, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled }
      when :flags_check_boxes
        f.collection_check_boxes(field_name, translated_flag_pairs(record.class, field_name), :last, :first) do |b|
          concat (tag.div class: ['input_container', "#{field_name}_container", "#{field_type}_container"].flatten.uniq.join(' ') do
            concat b.check_box + b.label(class: 'material-icons') { '<span>check_box_outline_blank</span><span>check_box</span>'.html_safe } + tag.span(b.text, class: 'text_span')
          end)
        end
      end

    end

  end

  def input_container
    tag.div(class: 'input_container') do
      yield
    end
  end

  def text_span(text)
    tag.span(text, class: 'text_span')
  end

  def translated_flag_pairs klass, flags_name
    klass.send(flags_name).keys.to_h { |k| [klass.translate_enum(flags_name, k), k] }
  end

  def form_tag_if condition, *options_array, **options_hash
    if condition
      form_tag *options_array, **options_hash do
        yield
      end
    else
      yield
    end
  end

  def list_errors record, **options
    if record&.errors&.any?
      concat tag.span t('general.words.errors'), class: 'errors-title' unless options[:no_title]
      tag.ul class: 'errors' do
        record.errors.full_messages.each do |message|
          concat tag.li message
        end
      end
    end
  end
  
  def general_form_with_fields_for record, fields = nil, &block
    fields ||= GeneralForm.default_fields[record.class]
    concat list_errors record
    form_for record, html: { class: 'general' } do |f|
      concat allFormFields f, record, fields
      concat yield f if block_given?
      concat f.submit
    end
  end

  def enum_options_for_select object, enum
    if object.present?
      model_name = (if object.is_a?(ApplicationRecord)
        record = object
        object.class
      elsif object.is_a?(Class) && object < ApplicationRecord
        object
      end)&.name&.underscore
      enums = t("activerecord.enums.#{model_name}.#{enum}", default: [:"activerecord.enums.#{enum}"])
      if enums.present? && enums.is_a?(Hash)
        options_for_select enums.invert, record&.send(enum)
      end
    end
  end

end
