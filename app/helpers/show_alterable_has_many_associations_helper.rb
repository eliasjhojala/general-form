module ShowAlterableHasManyAssociationsHelper
  
  def show_one_item(**options)
    item_class = options[:item_class]
    item = options[:item]
    fields = options[:fields]
    fields ||= item_class::DEFAULT_FORM_FIELDS

    tag.tr do
      fields.each do |field|
        concat tag.td(show_form_fields(item, field, only_value: true))
      end
    end
  end

  def show_alterable_has_many_associations_form_contents (**options)

    item_class = options[:item_class]
    associated_object = options[:associated_object]
    subjects = options[:subjects]
    form_name = options[:form_name]
    form_url = options[:form_url]
    
    tag.span(class: "show_alterable_has_many_associations_form") do
      general_table do
        tag.tbody(class: "fields") do
          tag.tr(class: "subjectRow") do
            subjects.each do |subject, field|
              concat tag.th(item_class.human_attribute_name(subject), class: subject)
            end
          end + capture do
            associated_object.each do |item|
              concat show_one_item(item: item, item_class: item_class, fields: options[:fields])
            end
          end
        end
      end
    end
    
  end
  
end
