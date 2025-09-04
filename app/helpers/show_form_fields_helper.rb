module ShowFormFieldsHelper

  def show_all_form_fields(record, fields, fields_name = nil, **opts)
    fields.each do |field|
      concat show_form_fields(record, field, fields_name, **opts)
    end
    return
  end

  def show_form_fields(record, form_fields, fields_name = nil, **opts)
    form_fields = standardize_form_fields form_fields
    if form_fields.count() == 1 && form_fields[0].field_type == :associated_fields
      associated_fields = form_fields[0].associated_fields
      associated_fields ||= GeneralForm.default_fields[form_fields[0].associated_model]
      show_all_form_fields((form_fields[0].associated_model.find(record["#{form_fields[0].field_name}_id"]) rescue form_fields[0].associated_model.new), associated_fields)
    elsif form_fields.count == 1 && form_fields.first.field_type.in?([:localised, :localised_text_area])
      field = form_fields.first
      unless (field.privileges.present? && !current_user.privileges?(field.privileges)) || (field.privileges_strict.present? && !current_user.privileges_strict?(field.privileges_strict))
        capture do
          (GeneralForm.locales || I18n.available_locales).each do |locale|
            concat (tag.div class: "input_container #{field.field_name}_container #{field.field_type}_container" do
              # Label
              unless opts[:only_value].present?
                span_content = localised_field_name(record, field)
                span_content = content_tag(:a, span_content, href: "") if field.text_type == :link
                localised_label = "#{span_content} (#{locale})"
                concat content_tag(:span, localised_label, class: "#{field.field_name} text_span") unless field.hide_name || field.name_after
              end
              # Value
              field_localised = field.dup
              field_localised.field_name = :"#{field.field_name}_#{locale}"
              field_localised.field_type = {localised: :default, localised_text_area: :text_area}[field.field_type]
              concat tag.span(show_form_field(record, field_localised, fields_name) || "", class: field_localised.field_name)
              unless opts[:only_value].present?
                span_content = localised_field_name(record, field)
                span_content = content_tag(:a, span_content, href: "") if field.text_type == :link
                concat content_tag(:span, "#{span_content} (#{locale})", class: "#{field.field_name} text_span") if field.name_after
                concat content_tag(:span, field.text_after, class: "#{field.field_name.to_s} text_after text_span") if field.text_after
              end
            end)
          end
        end
      end
    elsif form_fields.count == 1 && form_fields.first.field_type == :flags_check_boxes
      field = form_fields.first
      unless (field.privileges.present? && !current_user.privileges?(field.privileges)) || (field.privileges_strict.present? && !current_user.privileges_strict?(field.privileges_strict))
        values = Array(record.send(field.field_name))
        labels = begin
          translated_flag_pairs(record.class, field.field_name).select { |_, v| values.include?(v) }.map(&:first)
        rescue
          values
        end
        fields_name ||= "fields"
        toReturn = '<div class="input_container '+[field.field_name, field.field_type].map{|fn| "#{fn}_container"}.join(" ")+'">'
        unless opts[:only_value].present?
          span_content = localised_field_name(record, field)
          toReturn += content_tag(:span, span_content, class: "#{field.field_name} text_span") unless field.hide_name || field.name_after
        end
        toReturn += tag.span(labels.join(', '), class: field.field_name)
        unless opts[:only_value].present?
          span_content = localised_field_name(record, field)
          toReturn += content_tag(:span, span_content, class: "#{field.field_name} text_span") if field.name_after
          toReturn += content_tag(:span, field.text_after, class: "#{field.field_name.to_s} text_after text_span") if field.text_after
        end
        toReturn += '</div>'
        return toReturn.html_safe
      end
    elsif form_fields.count == 1 && form_fields.first.field_type == :custom
      field = form_fields.first
      content = opts.dig(:custom_fields, field.field_name)
      if content.present?
        return tag.div(content, class: "input_container #{field.field_name}_container #{field.field_type}_container")
      else
        return nil
      end
    else
      fields_name ||= "fields"
      toReturn = '<div class="input_container '+(form_fields.map(&:field_name).map{|field| "#{field}_container"} + form_fields.map(&:field_type).map{|field| "#{field}_container"}).flatten.uniq.join(" ")+'">'
      form_fields.each do |field|
        next if field.field_type == :hidden
        unless (field.privileges.present? && !current_user.privileges?(field.privileges)) || (field.privileges_strict.present? && !current_user.privileges_strict?(field.privileges_strict))
          one_field_html = ''
          unless opts[:only_value].present?
            span_content = localised_field_name(record, field)
            span_content = content_tag(:a, span_content, href: "") if field.text_type == :link
            one_field_html += content_tag(:span, span_content, class: "#{field.field_name} text_span") unless field.hide_name || field.name_after
          end
          one_field_html += tag.span(show_form_field(record, field, fields_name) || "", class: field.field_name)
          unless opts[:only_value].present?
            one_field_html += content_tag(:span, span_content, class: "#{field.field_name} text_span") if   field.name_after
            one_field_html += content_tag(:span, field.text_after, class: "#{field.field_name.to_s} text_after text_span") if field.text_after
          end
        end
        if opts[:floating]
          toReturn += tag.div(one_field_html.html_safe)
        else
          toReturn += one_field_html
        end
      end
      toReturn += '</div>'
      return toReturn.html_safe
    end
  end

  def show_form_field(record, form_field, fields_name = nil)
    form_field = standardize_form_field form_field
    fields_name ||= "fields"
    field_name = form_field.field_name
    field_type = form_field.field_type || :default

    if record.present? && field_name.present?

      case field_type
      when :default, :password, :title, :subtitle; record[field_name] or record.send(field_name).to_s
      when :check_box; (record[field_name] or record.send(field_name)) ? 'x' : '-'
      when :text_area, :trix_editor; record[field_name] or record.send(field_name).to_s
      when :datepicker, :date; date (record[field_name] or record.send(field_name).to_s)
      when :datetime; time (record[field_name] or record.send(field_name)), :long
      when :time; (record[field_name] or record.send(field_name))&.strftime("%H:%M")
      when :date_and_time
        d = (record["#{field_name}_date"] or record.send("#{field_name}_date").to_s rescue nil)
        t = (record["#{field_name}_time"] or record.send("#{field_name}_time").to_s rescue nil)
        [date(d), t&.respond_to?(:strftime) ? t.strftime('%H:%M') : t].compact.join(' ')
      when :phone_number; Phone.readable(record.send(field_name)) rescue (record[field_name] or record.send(field_name).to_s)
      when :disabled; record[field_name] or record.send(field_name).to_s
      when :disabled_date; date (record[field_name] or record.send(field_name).to_s)
      when :disabled_time; (record[field_name] or record.send(field_name))&.strftime('%-d.%-m.%Y %H:%M') rescue (record[field_name] or record.send(field_name).to_s)
      when :disabled_datetime; (record[field_name] or record.send(field_name))&.strftime('%-d.%-m.%Y %H:%M:%S') rescue (record[field_name] or record.send(field_name).to_s)
      when :function; record.send(field_name).to_s
      when :hidden; ""
      when :reset; ""
      when :only_text; ""
      when :only_value; record[field_name].to_s or record.send(field_name).to_s
      when :only_value_as_date; (l record.send(field_name) rescue nil).to_s
      when :title_only_value; record[field_name] or record.send(field_name).to_s
      when :label; record[field_name] or record.send(field_name).to_s
      when :number; (record[field_name] or record.send(field_name)).to_s
      when :range; (record[field_name] or record.send(field_name)).to_s
      when :color; (record[field_name] or record.send(field_name)).to_s
      when :collection_select
        form_field.options_name ||= "name"
        options = form_field.select_options[]
        selected = Array(record.send(field_name)).map(&:to_s)
        options.select { |o| selected.include?(o.id.to_s) }.map { |o| o.send(form_field.options_name).to_s }.join(', ')
      when :flags_select
        values = Array(record.send(field_name))
        begin
          translated_flag_pairs(record.class, field_name).select { |_, v| values.include?(v) }.map(&:first).join(', ')
        rescue
          values.join(', ')
        end
      when :habtm_select
        form_field.options_name ||= "name"
        associated = record.send(form_field.habtm)
        associated.map { |o| o.send(form_field.options_name).to_s }.join(', ')
      when :select
        unless form_field.select_options.present?
          # Enum display with allowed_keys support
          begin
            allowed_keys = if form_field.data_for_allowed_keys.present?
              form_field.allowed_keys[record.send(form_field.data_for_allowed_keys)]
            else
              form_field.allowed_keys&.call
            end
            current = record.send(field_name)
            if allowed_keys.present? && !Array(allowed_keys).map(&:to_s).include?(current.to_s)
              ""
            else
              record.translate_enum(field_name)
            end
          rescue
            record.translate_enum(field_name) rescue ''
          end
        else
          form_field.options_name ||= "name"
          begin
            # Build options collection
            options = nil
            if form_field.data_for_select_options.present?
              args = Array(form_field.data_for_select_options).map { |attr| record[attr] }
              options = form_field.select_options[*args]
            else
              options = form_field.select_options.respond_to?(:call) ? form_field.select_options[] : form_field.select_options
            end
            # Handle ranges directly
            if options.is_a?(Range)
              return (record[field_name] || record.send(field_name.to_s)).to_s
            end
            selected_id = (record[field_name] || record.send(field_name.to_s))
            selected = nil
            if options.respond_to?(:find_by)
              selected = options.find_by(id: selected_id)
              selected ||= (options.respond_to?(:find) ? (options.find(selected_id) rescue nil) : nil)
            elsif options.is_a?(Array)
              selected = options.find { |o| (o.respond_to?(:id) && o.id.to_s == selected_id.to_s) || o.to_s == selected_id.to_s }
            end
            selected ? selected.send(form_field.options_name).to_s : ""
          rescue
            ""
          end
        end
      else
        "#{field_type} not supported"

      end

    end

  end

  def translated_flag_pairs klass, flags_name
    klass.send(flags_name).keys.to_h { |k| [klass.translate_enum(flags_name, k), k] }
  end

end
