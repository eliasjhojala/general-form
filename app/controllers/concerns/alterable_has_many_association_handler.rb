module AlterableHasManyAssociationHandler
  
  def handle_alterable_has_many_association(**options)
    associated_object = options[:associated_object]
    associated_object ||= options[:association]
    associated_object ||= options[:assoc]
    items = options[:items]
    options[:id_field_name] ||= :id
    item_class = options[:item_class]
    item_class ||= associated_object.klass
    item_array_name = options[:item_array_name]
    item_array_name ||= "#{associated_object.klass.name.pluralize.underscore}"
    existence_field_name = options[:existence_field_name]
    existence_field_name ||= options[:existence_field]
    id_field_name = options[:id_field_name]
    params_to_permit = options[:params_to_permit]
    params_to_permit ||= permit_fields(item_class::DEFAULT_FORM_FIELDS)
    
    items[item_array_name].each do |item|
      item_id = item[id_field_name]
      form_fields_flat = flat_fields(item_class::DEFAULT_FORM_FIELDS)
      habtm_fields = form_fields_flat.map do |key, val|
        key if(val.field_type == :habtm_select && val.multiple == true)
      end.compact
      puts habtm_fields
      
      permitted_params = item.permit(params_to_permit).except(habtm_fields)
      
      if item_id.present?
        if item[existence_field_name].present?
          item_class.find(item_id).update(permitted_params)
          habtm_fields.each do |habtm_field|
            item_class.find(item_id).send("#{form_fields_flat[habtm_field].habtm}=", form_fields_flat[habtm_field].select_options[].where(id: item[habtm_field]))
          end
        else
          item_class.find(item_id).delete
        end
      elsif (options.keys & [:associated_object, :association, :assoc]).any?
        new_item = item_class.new(permitted_params)
        associated_object << new_item
        habtm_fields.each do |habtm_field|
          new_item.send("#{form_fields_flat[habtm_field].habtm}=", form_fields_flat[habtm_field].select_options[].where(id: item[habtm_field]))
        end
      else
        new_item = item_class.create(permitted_params)
        habtm_fields.each do |habtm_field|
          new_item.send("#{form_fields_flat[habtm_field].habtm}=", form_fields_flat[habtm_field].select_options[].where(id: item[habtm_field]))
        end
      end
    end
  end
  
end
