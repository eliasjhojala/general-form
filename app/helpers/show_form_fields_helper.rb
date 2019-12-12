module ShowFormFieldsHelper
  
  def show_all_form_fields(record, fields, fields_name = nil)
    fields.each do |field|
      concat show_form_fields(record, field, fields_name)
    end
    return
  end
  
  def show_form_fields(record, form_fields, fields_name = nil, **opts)
    form_fields = standardize_form_fields form_fields
    if form_fields.count() == 1 && form_fields[0].field_type == :associated_fields
      associated_fields = form_fields[0].associated_fields
      associated_fields ||= form_fields[0].associated_model::DEFAULT_FORM_FIELDS
      show_all_form_fields((form_fields[0].associated_model.find(record["#{form_fields[0].field_name}_id"]) rescue form_fields[0].associated_model.new), associated_fields)
    else
      fields_name ||= "fields"
      toReturn = '<div class="input_container '+form_fields.map(&:field_name).map{|field| "#{field}_container"}.join(" ")+'">'
      form_fields.each do |field|
        next if field.field_type == :hidden
        unless field.privileges.present? && !@current_user.privileges?(field.privileges)
          unless opts[:only_value].present?
            text = field.text.present? ? field.text : field.field_name
            span_content = record.class.human_attribute_name text
            span_content = content_tag(:a, span_content, href: "") if field.text_type == :link
            toReturn += content_tag(:span, span_content, class: "#{field.field_name} text_span") unless field.hide_name || field.name_after
          end
          toReturn += tag.span(show_form_field(record, field, fields_name) || "", class: field.field_name)
          unless opts[:only_value].present?
            toReturn += content_tag(:span, span_content, class: "#{field.field_name} text_span") if   field.name_after
            toReturn += content_tag(:span, field.text_after, class: "#{field.field_name.to_s} text_after text_span") if field.text_after
          end
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
      when :default; record[field_name] or record.send(field_name).to_s
      when :check_box; record[field_name] or record.send(field_name).to_s
      when :text_area; record[field_name] or record.send(field_name).to_s
      when :datepicker; date (record[field_name] or record.send(field_name).to_s)
      when :disabled; record[field_name] or record.send(field_name).to_s
      when :disabled_date; date (record[field_name] or record.send(field_name).to_s)
      when :function; record.send(field_name).to_s
      when :hidden; ""
      when :reset; ""
      when :only_text; ""
      when :only_value; record[field_name].to_s or record.send(field_name).to_s
      when :select
        unless form_field.select_options.present?
          record.translate_enum(field_name) rescue ''
        else
          form_field.options_name ||= "name"
          if form_field.data_for_select_options.present?
            form_field.select_options[record[form_field.data_for_select_options]].find(record[field_name]).send(form_field.options_name) rescue ""
          else
            if form_field.select_options.respond_to? :call
              form_field.select_options[].find(record.send(field_name.to_s)).send(form_field.options_name) rescue ""
            else
              form_field.select_options.find(record.send(field_name.to_s)).send(form_field.options_name) rescue ""
            end
          end
        end
        
      end
      
    end
    
  end
  
end
