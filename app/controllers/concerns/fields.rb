module Fields
  
  def flat_fields(fields, **opts)
    fields = fields.values unless fields.class == Array
    return_with_names = !opts.key?(:name) || opts[:name]
    return_as_hash = return_with_names && (!opts.key?(:hash) || opts[:hash])
    fields = fields.flatten.map do |x|
      if x.is_a? Symbol
        x = UsesFormField::FormField.new(field_name: x)
      end
      return_with_names ? [x.field_name, x] : x
    end
    return_as_hash ? fields.to_h : fields
  end

  def field_names(fields)
    flat_fields(fields).keys
  end

  def permit_fields(fields)
    permitted_fields = field_names(fields).push(:id)
    associated_fields(fields)&.each do |name, field|
      field = [field] unless field.class == Array
      field.each { |f| f.associated_fields ||= f.associated_model::DEFAULT_FORM_FIELDS }
      permitted_fields.push("#{name}_attributes" => permit_fields(field.map(&:associated_fields)))
    end
    files_fields(fields).each do |name, field|
      permitted_fields.push(name => [])
    end
    multiple_select_fields(fields).each do |name, field|
      permitted_fields.push(name => [])
    end
    collection_select_fields(fields).each do |name, field|
      permitted_fields.push(name => [])
    end
    flags_select_fields(fields).each do |name, field|
      permitted_fields.push(name => [])
    end
    return permitted_fields
  end

  def associated_fields(fields)
    flat_fields(fields, hash: false).select do |k,v|
      v.field_type == :associated_fields
    end.group_by(&:first).map{|k,v| Hash[k, v.map(&:last)]}.inject(&:merge)
  end

  def files_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :files }
  end

  def multiple_select_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :select && v.multiple }
  end
  
  def collection_select_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :collection_select }
  end

  def associated_field_names(fields)
    associated_fields(fields).keys
  end
  
  def habtm_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :habtm_select && v.multiple }
  end
  
  def habtm_field_names(fields)
    habtm_fields(fields).keys
  end
  
  def flags_select_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :flags_select }
  end
  
end
