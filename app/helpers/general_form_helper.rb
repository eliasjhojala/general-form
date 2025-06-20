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

  def fields_for_assoc_if_needed(f, record, field, path, **options)
    if path.nil? || path.empty?
      yield f
      return
    end

    if path.is_a?(Array)
      assoc = path[0]
      remaining_path = path[1..]
      f.fields_for assoc do |ff|
        fields_for_assoc_if_needed(ff, record.send(assoc), field, remaining_path, **options) do |f_assoc|
          yield f_assoc
        end
      end
    else
      yield f
    end
  end

  def formFields(f, record, form_fields, **options)
    form_fields = standardize_form_fields form_fields
    if form_fields.count() == 1 && form_fields[0].field_type == :associated_fields
      fields_for_assoc_if_needed f, record, form_fields[0], form_fields[0].association_path do |ff|
        concat (ff.fields_for form_fields[0].field_name do |ff_2|
          associated_fields = form_fields[0].associated_fields
          associated_fields ||= GeneralForm.default_fields[form_fields[0].associated_model]
          allFormFields(ff_2, ff_2.object, associated_fields, **options)
        end)
      end
    else
      if form_fields.count != 1 || !form_fields.first.field_type.in?([:custom, :flags_check_boxes, :localised, :localised_text_area])
        container_contents = capture do
          form_fields.each do |field|
            unless (field.privileges.present? && !current_user.privileges?(field.privileges)) || (field.privileges_strict.present? && !current_user.privileges_strict?(field.privileges_strict))
              concat (fields_for_assoc_if_needed f, record, field, field.association_path do |ff|
                field_html = formField(ff, ff.object, field, **options)
                next if field_html.nil?
                concat beforeFormField(ff, ff.object, field, **options)
                concat field_html
                afterFormField(ff, ff.object, field, **options)
              end)
            end
          end
        end
        if container_contents.present?
          tag.div class: ['input_container', form_fields.map(&:field_name).map{|field| "#{field}_container"}, form_fields.map(&:field_type).map{|field| "#{field}_container"}].flatten.uniq.join(' ') do
            container_contents
          end
        end
      elsif form_fields.first.field_type == :flags_check_boxes
        capture do
          form_fields.each do |field|
            concat (fields_for_assoc_if_needed f, record, field, field.association_path do |ff|
              field_html = formField(ff, ff.object, field, **options)
              next if field_html.nil?
              concat field_html
            end)
          end
        end
      elsif form_fields.first.field_type.in?([:localised, :localised_text_area])
        field = form_fields.first
        unless (field.privileges.present? && !current_user.privileges?(field.privileges)) || (field.privileges_strict.present? && !current_user.privileges_strict?(field.privileges_strict))
          capture do
            (GeneralForm.locales || I18n.available_locales).each do |locale|
              concat (tag.div class: "input_container #{form_fields[0].field_name}_container #{form_fields[0].field_type}_container" do
                field_localised = field.dup
                field_localised.field_name = :"#{field.field_name}_#{locale}"
                field_localised.field_type = {localised: :default, localised_text_area: :text_area}[field.field_type]
                localised_field_name = localised_field_name(record, field) + " (#{locale})"
                options = options.dup.merge(localised_field_name: localised_field_name)
                concat (fields_for_assoc_if_needed f, record, field, field.association_path do |ff|
                  concat beforeFormField(ff, ff.object, field, **options)
                  concat formField(ff, ff.object, field_localised, **options)
                  concat afterFormField(ff, ff.object, field, **options)
                end)
              end)
            end
          end
        end
      elsif form_fields.first.field_type == :custom
        options.dig(:custom_fields, form_fields.first.field_name)
      end
    end
  end

  def textSpan(f, record, field, **options)
    tag.span(label_content(f, record, field, **options), class: "#{field.field_name} text_span", **data_tooltip(f, field, **options))
  end

  def localised_field_name(record, field)
    if field.localised_text.blank?
      text = field.text.present? ? field.text : field.field_name
      if field.text.blank? || text.is_a?(Symbol) || (text.is_a?(String) && text.exclude?('.'))
        record.class.human_attribute_name(text)
      else
        t(text)
      end
    else
      field.localised_text
    end
  end

  def label_content(f, record, field, **options)
    span_content = options[:localised_field_name] || localised_field_name(record, field) unless field.hide_name
    span_content = tag.a(span_content, href: '') if field.text_type == :link
    span_content
  end

  def beforeFormField(f, record, field, **options)
    unless field.hide_name || field.name_after || GeneralForm.use_form_floating || options[:use_form_floating]
      textSpan(f, record, field, **options)
    end
  end

  def afterFormField(f, record, field, **options)
    if field.name_after
      concat textSpan(f, record, field, **options)
    end
    if field.text_after
      concat tag.span(field.text_after.html_safe, class: "#{field.field_name} text_after text_span")
    end
  end

  def formField(f, record, form_field, **options)
    options_ = options
    form_field = standardize_form_field form_field
    field_name = form_field.field_name
    field_type = form_field.field_type || :default
    field_name_translated = options[:localised_field_name] || localised_field_name(record, form_field) unless [:check_box, :only_value, :only_value_as_date, :title_only_value, :hidden].include?(field_type) || record.nil?
    autocomplete = form_field.autocomplete || field_name
    if field_name.present?
      use_select2 = false
      required = { required: form_field.required }
      readonly = { readonly: form_field.readonly }
      autofocus = { autofocus: form_field.autofocus }
      disabled = { disabled: form_field.disabled }
      html = form_field.html || {}
      common = {
        placeholder: field_name_translated,
        **required, **readonly, **autofocus, **disabled, **html
      }
      select_common = { **required, **readonly, **autofocus, **html }
      minmax = {}
      minmax[:min] = form_field.min if form_field.min.present?
      minmax[:max] = form_field.max if form_field.max.present?
      minmax_textarea = {}
      minmax_textarea[:minlength] = form_field.min if form_field.min.present?
      minmax_textarea[:maxlength] = form_field.max if form_field.max.present?
      field_plain = capture do
        case field_type
        when :default; f.text_field field_name, class: field_name, **common, 'autocomplete': autocomplete
        when :password; f.password_field field_name, class: field_name, **common, 'autocomplete': form_field.autocomplete
        when :title; f.text_field field_name, class: "#{field_name} title", **common, 'autocomplete': autocomplete
        when :subtitle; f.text_field field_name, class: "#{field_name} subtitle", **common, 'autocomplete': autocomplete
        when :check_box; f.check_box(field_name, class: field_name, include_hidden: options[:is_part_of_alterable_has_many_association].blank?, **html) + f.label(field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: "material-icons #{field_name}")
        when :text_area; f.text_area field_name, class: field_name, **common, **minmax_textarea
        when :trix_editor; tag.div(f.trix_editor(field_name, class: field_name, **common), class: 'trix-container')
        when :datepicker, :date; f.date_field field_name, class: "#{field_name} datepicker", value: (f.object.send(field_name).strftime('%Y-%m-%d') rescue nil), data: { val: (f.object.send(field_name).strftime('%-d.%-m.%Y') rescue nil) }, **common, **minmax
        when :time; f.time_field field_name, class: "#{field_name} time", value: (f.object.send(field_name).strftime('%H:%M') rescue nil), data: { val: (f.object.send(field_name).strftime('%H:%M') rescue nil) }, **common
        when :date_and_time; [:date, :time].sum { formField(f, record, GeneralForm::Field.new(field_name: "#{field_name}_#{_1}", type: _1, **common, **minmax)) }
        when :datetime; f.datetime_local_field field_name, step: 1, class: "#{field_name} datetime", value: (f.object.send(field_name).strftime('%Y-%m-%dT%H:%M:%S') rescue nil), **common, **minmax
        when :phone_number; f.text_field field_name, class: "#{field_name} phone_number", **common, 'autocomplete': autocomplete, value: Phone.readable(f.object.send(field_name))
        when :disabled; f.text_field field_name, class: "#{field_name} disabled", **html
        when :disabled_date; f.text_field field_name, class: "#{field_name} disabled", value: (f.object.send(field_name).strftime('%-d.%-m.%Y') rescue f.object.send(field_name)), **html
        when :disabled_time; f.text_field field_name, class: "#{field_name} disabled", value: (f.object.send(field_name).strftime('%-d.%-m.%Y %H:%M') rescue f.object.send(field_name)), **html
        when :disabled_datetime; f.text_field field_name, class: "#{field_name} disabled", value: (f.object.send(field_name).strftime('%-d.%-m.%Y %H:%M:%S') rescue f.object.send(field_name)), **html
        when :function; text_field_tag field_name, record.send(field_name), class: "#{field_name} disabled", **html
        when :hidden; f.hidden_field field_name, class: field_name, **html
        when :reset; f.hidden_field field_name, **html
        when :only_text; ""
        when :only_value; tag.span f.object.send(field_name).to_s, class: 'only_value_span'
        when :only_value_as_date; tag.span((l f.object.send(field_name) rescue nil), class: 'only_value_span')
        when :title_only_value; tag.span f.object.send(field_name).to_s, class: 'only_value_span title'
        when :label; f.label field_name, "<span>check_box_outline_blank</span><span>check_box</span>".html_safe, class: 'material-icons', **html
        when :number; f.text_field field_name, class: field_name, **common, **minmax, 'autocomplete': autocomplete, type: 'number', step: 1.0 / (10**(form_field.scale || 0))
        when :range; f.range_field field_name, class: field_name, min: form_field.min, max: form_field.max, step: form_field.step, **html
        when :file; single_file_field(f, record, attachment_name: field_name, replace_instead_of_delete: true, preview: form_field.preview, direct_upload: form_field.direct_upload)
        when :files; default_file_field(f, record, files_name: field_name, direct_upload: form_field.direct_upload)
        when :color; f.color_field field_name, class: field_name, **common
        when :select
          prompt = form_field.prompt_translated
          prompt ||= form_field.prompt.present? ? t("activerecord.prompts.#{record.class.name.underscore}.#{field_name}") : '-'
          x = form_field.no_policy_scope
          use_policy_scope = x.blank? || (x.respond_to?(:call) && x[].blank?)
          unless form_field.select_options.present?
            allowed_keys = if form_field.data_for_allowed_keys.present?
              form_field.allowed_keys[record.send(form_field.data_for_allowed_keys)]
            else
              form_field.allowed_keys&.call
            end
            options = enum_options_for_select(record, field_name, allowed_keys)
            if options.present?
              f.select field_name, options, {include_blank: prompt}, {class: field_name, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled, **select_common }
            end
          else
            form_field.options_name ||= "name"
            if form_field.data_for_select_options.present?
              options = form_field.select_options[*([form_field.data_for_select_options].flatten.map { record.send(_1) })]
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
              if form_field.polymorphic
                options = options.map { |x| policy_scope(x) } if use_policy_scope
                options = options.sum
              elsif use_policy_scope && !options.is_a?(ActiveSupport::SafeBuffer)
                options = policy_scope(options)
              end
            end
            options_length = 0
            unless options.is_a? ActiveSupport::SafeBuffer
              options_length = options.length
              options_value = form_field.options_value || (!form_field.polymorphic ? 'id' : 'global_id')
              if form_field.data_attributes_for_options.present?
                # Generate something like <option value="1" data-foo="bar">Option A</option>
                options = options.map do |option|
                  value = option.send(options_value)
                  name = option.send(form_field.options_name)
                  data_attributes = form_field.data_attributes_for_options.map { |attr| "data-#{attr}=\"#{option.send(attr)}\"" }.join(' ')

                  current_value = record.send(field_name.to_s)
                  selected_attr = if current_value.is_a?(Array)
                                    current_value.include?(value) ? " selected=\"selected\"" : ""
                                  else
                                    current_value.to_s == value.to_s ? " selected=\"selected\"" : ""
                                  end

                  "<option value=\"#{value}\"#{selected_attr} #{data_attributes}>#{name}</option>"
                end.join.html_safe
              else
                options = options_from_collection_for_select(options, options_value, form_field.options_name, record.send(field_name.to_s))
              end
            end
            if options_length > 0 || form_field.show_always
              use_select2 = form_field.select2 || form_field.multiple || (GeneralForm.auto_select2 && !form_field.no_select2 && options_length > 10)
              klass = field_name.to_s
              klass += ' select2' if use_select2
              f.select field_name, options, {include_blank: prompt}, {class: klass, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled, **select_common }
            end
          end
        when :collection_select
          form_field.options_name ||= "name"
          options = form_field.select_options[]
          f.collection_select field_name, options, 'id', form_field.options_name, {}, { multiple: true, class: 'select2', **select_common }
        when :flags_select
          f.collection_select field_name, translated_flag_pairs(record.class, field_name), 'last', 'first', {}, { class: "select2", multiple: true, **select_common }
        when :habtm_select
          value = record.send(form_field.habtm).pluck(:id)
          if form_field.select_options.respond_to? :call
            options = form_field.select_options[]
          else
            options = form_field.select_options
          end
          options = policy_scope(options) if form_field.no_policy_scope.blank?
          form_field.options_name ||= "name"
          f.select field_name, options_from_collection_for_select(options, "id", form_field.options_name, value), {:include_blank => "-"}, {class: field_name, 'autocomplete': autocomplete, multiple: form_field.multiple, disabled: form_field.disabled, **select_common }
        when :flags_check_boxes
          # Use custom checkboxes instead of collection_check_boxes to
          # also work correctly within fields_for with has_many assocication
          # Default collection_check_boxes drops [] from name
          capture do
            collection = translated_flag_pairs(record.class, field_name)
            current_values = record.send(field_name)
            input_name = "#{f.object_name}[#{field_name}][]"

            concat tag.input(type: 'hidden', name: input_name, value: '', autocomplete: 'off')
            collection.each do |label, value|
              checked = current_values.include?(value)
              checkbox_id = sanitize_to_id("#{f.object_name}_#{field_name}_#{value}")

              concat(tag.div(class: ['input_container', "#{field_name}_container", "#{field_type}_container"].flatten.uniq.join(' ')) do
                concat check_box_tag(input_name, value, checked, id: checkbox_id)
                concat label_tag(checkbox_id, class: 'material-icons') { '<span>check_box_outline_blank</span><span>check_box</span>'.html_safe }
                concat tag.span(label, class: 'text_span')
              end)
            end
          end
        end
      end

      return nil if field_plain.blank?

      if GeneralForm.use_form_floating || options_[:use_form_floating]

        if floatable?(form_field, **options_)
          klass = "form-floating for-#{field_name}"
          klass += ' for-select2' if use_select2
          tag.div class: klass, **data_tooltip(f, form_field, **options_) do
            concat field_plain
            if field_type == :text_area
              concat tag.div(class: 'padding')
              concat tag.div(class: 'visual-container')
            end
            concat f.label(field_name, options_[:label_content] || field_name_translated)
          end
        else
          tag.div class: 'non-floatable' do
            unless options_[:is_part_of_alterable_has_many_association]
              concat textSpan(f, record, form_field, **options_)
            end
            concat field_plain
          end
        end
      else
        field_plain
      end

    end

  end

  def input_container
    tag.div(class: 'input_container') do
      yield
    end
  end

  def form_floating_container name, placeholder, type: nil, wrap_with_input_container: true, &block
    div = tag.div class: 'form-floating' do
      yield
      if type == :text_area
        concat tag.div(class: 'padding')
        concat tag.div(class: 'visual-container')
      end
      concat label_tag(name, placeholder)
    end
    wrap_with_input_container ? input_container { concat(div) } : div
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

  def list_errors records, **options
    records = [records] unless records.is_a?(Array)
    if records.any? { _1.errors.any? }
      concat tag.span t('general.words.errors'), class: 'errors-title' unless options[:no_title]
      tag.ul class: 'errors' do
        records.map { _1.errors.full_messages }.flatten.each do |message|
          concat tag.li message
        end
      end
    end
  end

  def general_form_with_fields_for record, fields = nil, **options, &block
    fields ||= GeneralForm.default_fields[record.class]
    concat list_errors record
    form_for record, html: { class: "general#{' floating' if GeneralForm.use_form_floating || options[:use_form_floating]}" } do |f|
      concat allFormFields f, record, fields, **options
      yield f if block_given?
      concat f.submit unless options.key?(:submit) && !options[:submit]
    end
  end

  def enum_options_for_select object, enum, allowed_keys = nil
    if object.present?
      model_name = (if object.is_a?(ApplicationRecord)
        record = object
        object.class
      elsif object.is_a?(Class) && object < ApplicationRecord
        object
      end)&.name&.underscore
      enums = t("activerecord.enums.#{model_name}.#{enum}", default: [:"activerecord.enums.#{enum}"])
      enums = enums.slice(*allowed_keys) unless allowed_keys.nil?
      if enums.present? && enums.is_a?(Hash)
        options_for_select enums.invert, record&.send(enum)
      end
    end
  end

  def floatable? field, **options
    type = field.field_type || :default
    (type.in?([:default, :password, :title, :subtitle, :text_area, :datepicker, :date, :time, :datetime, :phone_number, :disabled, :disabled_date, :disabled_time, :function, :number, :file, :files, :localised, :localised_text_area]) ||
    type == :select) && !options[:is_part_of_alterable_has_many_association]
  end

  def data_tooltip f, field, **options
    tooltip = options[:field_descriptions].present? && options.dig(:field_descriptions, f.object.class.to_s, field.field_name)
    tooltip.present? ? { data: { tooltip: tooltip } } : {}
  end

end
