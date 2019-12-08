module Fields
  
  def flat_fields(fields)
    fields = fields.values unless fields.class == Array
    return fields.flatten.map {|x| [x.field_name, x]}.to_h
  end
  
  def field_names(fields)
    fields = fields.values unless fields.class == Array
    return fields.flatten.map(&:field_name)
  end
  
  def permit_fields(fields)
    fields = fields.values unless fields.class == Array
    permitted_fields = flat_fields(fields).keys.push(:id)
    fields.flatten.map {|x| if ([:collection_select, :flags_select].include? x.field_type) then permitted_fields.push({x.field_name => []}) end}
    associated_fields(fields).each do |name, field|
      field.associated_fields ||= field.associated_model::DEFAULT_FORM_FIELDS
      permitted_fields.push("#{name}_attributes" => permit_fields(field.associated_fields))
    end
    files_fields(fields).each do |name, field|
      permitted_fields.push(name => [])
    end
    return permitted_fields
  end
  
  def associated_fields(fields)
    fields = fields.values unless fields.class == Array
    return fields.flatten.map {|x| if (x.field_type == :associated_fields) then [x.field_name.to_s, x] end}.compact.to_h
  end
  
  def files_fields(fields)
    fields = fields.values unless fields.class == Array
    return fields.flatten.map {|x| if (x.field_type == :files) then [x.field_name.to_s, x] end}.compact.to_h
  end
  
  def associated_field_names(fields)
    associated_fields(fields).keys.compact
  end
  
end
