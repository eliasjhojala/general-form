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
  
  def allFormFields(f, record, fields)
    fields.each do |field|
      concat formFields(f, record, field)
    end
    return
  end
  
  def formFields(f, record, form_fields)
    form_fields = standardize_form_fields form_fields
    if form_fields.count() == 1 && form_fields[0].field_type == :associated_fields
      f.fields_for form_fields[0].field_name do |ff|
        associated_fields = form_fields[0].associated_fields
        associated_fields ||= form_fields[0].associated_model::DEFAULT_FORM_FIELDS
        allFormFields(ff, record.send(form_fields[0].field_name), associated_fields)
      end
    else
      tag.div class: ['input_container', form_fields.map(&:field_name).map{|field| "#{field}_container"}, form_fields.map(&:field_type).map{|field| "#{field}_container"}].flatten.uniq.join(' ') do
        form_fields.each do |field|
          unless field.privileges.present? && !@current_user.privileges?(field.privileges)
            text = field.text.present? ? field.text : field.field_name
            span_content = record.class.human_attribute_name(text) unless field.hide_name
            span_content = tag.a(span_content, href: '') if field.text_type == :link
            text_span = tag.span(span_content, class: "#{field.field_name} text_span")
            
            concat text_span unless field.hide_name || field.name_after
            concat formField(f, record, field)
            concat text_span if field.name_after
            concat tag.span(field.text_after.html_safe, class: "#{field.field_name} text_after text_span") if field.text_after
          end
        end
      end
    end
  end

  def formField(f, record, form_field)
    form_field = standardize_form_field form_field
    field_name = form_field.field_name
    field_type = form_field.field_type || :default
    field_name_translated = record.class.human_attribute_name(field_name) unless [:check_box, :only_value, :only_value_as_date, :title_only_value, :hidden].include?(field_type) || record.nil?
    if field_name.present?

      case field_type
      when :default; f.text_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': field_name
      when :password; f.password_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': field_name
      when :title; f.text_field field_name, class: "#{field_name} title", placeholder: field_name_translated, 'autocomplete': field_name
      when :subtitle; f.text_field field_name, class: "#{field_name} subtitle", placeholder: field_name_translated, 'autocomplete': field_name
      when :check_box; f.check_box(field_name, class: field_name) + f.label(field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: "material-icons #{field_name}")
      when :text_area; f.text_area field_name, class: field_name, placeholder: field_name_translated
      when :trix_editor; tag.div(f.trix_editor(field_name, class: field_name, placeholder: field_name_translated), class: 'trix-container')
      when :datepicker; f.text_field field_name, class: "#{field_name} datepicker", value: (f.object[field_name].strftime('%-d.%-m.%Y') rescue f.object[field_name]), placeholder: field_name_translated
      when :phone_number; f.text_field field_name, class: "#{field_name} phone_number", placeholder: field_name_translated, 'autocomplete': field_name, value: Phone.readable(f.object[field_name])
      when :disabled; f.text_field field_name, class: "#{field_name} disabled"
      when :disabled_date; f.text_field field_name, class: "#{field_name} disabled", value: (f.object[field_name].strftime('%-d.%-m.%Y') rescue f.object[field_name])
      when :function; text_field_tag field_name, record.send(field_name), class: "#{field_name} disabled"
      when :hidden; f.hidden_field field_name, class: field_name
      when :reset; f.hidden_field field_name
      when :only_text; ""
      when :only_value; tag.span f.object[field_name].to_s, class: 'only_value_span'
      when :only_value_as_date; tag.span((l f.object[field_name] rescue nil), class: 'only_value_span')
      when :title_only_value; tag.span f.object.send(field_name).to_s, class: 'only_value_span title'
      when :label; f.label field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: 'material-icons'
      when :number; f.text_field field_name, class: field_name, placeholder: field_name_translated, 'autocomplete': field_name, type: 'number'
      when :file; single_file_field(f, record, attachment_name: field_name)
      when :files; default_file_field(f, record, files_name: field_name)
      when :select
        prompt = form_field.prompt.present? ? t("activerecord.prompts.#{record.class.name.underscore}.#{field_name}") : '-'
        use_policy_scope = form_field.no_policy_scope.blank?
        unless form_field.select_options.present?
          options = enum_options_for_select(record, field_name)
          if options.present?
            f.select field_name, options, {include_blank: prompt}, {class: field_name, 'autocomplete': field_name, multiple: form_field.multiple, disabled: form_field.disabled }
          end
        else
          form_field.options_name ||= "name"
          if form_field.data_for_select_options.present?
            options = form_field.select_options[record[form_field.data_for_select_options]]
            options = policy_scope(options) if use_policy_scope
          else
            if form_field.select_options.respond_to? :call
              options = form_field.select_options[]
              options = policy_scope(options) if use_policy_scope
            elsif form_field.select_options.is_a? Range
              options = options_for_select(form_field.select_options.map {|i| [i,i] }, record.send(field_name.to_s))
            else
              options = form_field.select_options
              options = policy_scope(options) if use_policy_scope
            end
          end
          unless options.is_a? ActiveSupport::SafeBuffer
            options = options_from_collection_for_select(options, "id", form_field.options_name, record.send(field_name.to_s))
          end
          f.select field_name, options, {include_blank: prompt}, {class: field_name, 'autocomplete': field_name, multiple: form_field.multiple, disabled: form_field.disabled }
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
        f.select field_name, options_from_collection_for_select(options, "id", form_field.options_name, value), {:include_blank => "-"}, {class: field_name, 'autocomplete': field_name, multiple: form_field.multiple, disabled: form_field.disabled }
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

  def translated_flag_pairs class_, flags_name
    flag_pairs = class_.send(flags_name).pairs
    flag_pairs = flag_pairs.invert
    flag_pairs.each { |k, v| flag_pairs[k] = class_.translate_enum(flags_name, k) }
    flag_pairs.invert
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

  def list_errors record
    if record&.errors&.any?
      concat tag.span t('general.words.errors'), class: 'errors-title'
      tag.ul class: 'errors' do
        record.errors.full_messages.each do |message|
          concat tag.li message
        end
      end
    end
  end
  
  def general_form_with_fields_for record, fields = nil, &block
    fields ||= record.class::DEFAULT_FORM_FIELDS
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
      enums = t("activerecord.enums.#{model_name}.#{enum}", default: [:"activerecord.enums.#{field_name}"])
      if enums.present? && enums.is_a?(Hash)
        options_for_select enums.invert, record&.send(enum)
      end
    end
  end

end
