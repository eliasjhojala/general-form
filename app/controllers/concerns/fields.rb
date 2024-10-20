module Fields

  def flat_fields(fields, **opts)
    fields = fields.values unless fields.class == Array
    return_with_names = !opts.key?(:name) || opts[:name]
    return_as_hash = return_with_names && (!opts.key?(:hash) || opts[:hash])
    fields = fields.flatten.map do |x|
      if x.is_a? Symbol
        x = GeneralForm::Field.new(field_name: x)
      end
      return_with_names ? [x.field_name, x] : x
    end
    return_as_hash ? fields.to_h : fields
  end

  def field_names(fields)
    flat_fields(fields).keys
  end

  def permit_fields(fields, skip_disabled: false)
    permitted_hash_fields = {}
    permitted_fields = [:id]
    flat_fields(fields).each do |name, field|
      next if field.privileges.present? && !current_user.privileges?(field.privileges)
      next if skip_disabled && field.field_type == :disabled || field.disabled
      if field.association_path.present?
        cur = field.association_path.dup
        if cur.length > 0
          dup = field.dup
          dup.association_path = nil
          x = permit_fields([dup])
        end
        while cur.length > 0
          x = { "#{cur.shift}_attributes" => x }
        end
        permitted_hash_fields.deeper_merge! x
      else
        permitted_fields << name
      end
    end
    localised_fields(fields).each do |name, field|
      next if field.association_path.present?
      unless field.privileges.present? && !current_user.privileges?(field.privileges)
        permitted_fields += (GeneralForm.locales || I18n.available_locales).map { |locale| "#{field.field_name}_#{locale}" }
      end
    end
    associated_fields(fields)&.each do |name, field|
      field = [field] unless field.class == Array
      filtered = field.reject { _1.association_path.present? }
      filtered.each { |f| f.associated_fields ||= GeneralForm.default_fields[f.associated_model] }
      permitted_hash_fields.deeper_merge! "#{name}_attributes" => permit_fields(filtered.map(&:associated_fields))
    end
    date_and_time_fields(fields)&.each do |name, field|
      next if field.association_path.present?
      permitted_fields += [:date, :time].map { "#{name}_#{_1}" }
    end
    special_fields = [
      files_fields(fields),
      multiple_select_fields(fields),
      collection_select_fields(fields),
      flags_select_fields(fields),
      flags_check_boxes_fields(fields)
    ]
    special_fields.each do |fields|
      fields&.each do |name, field|
        next if field.association_path.present?
        unless field.privileges.present? && !current_user.privileges?(field.privileges)
          permitted_hash_fields.deeper_merge! name => []
        end
      end
    end
    if permitted_hash_fields.present?
      permitted_fields << permitted_hash_fields
    end
    return permitted_fields.uniq
  end

  def associated_fields(fields)
    flat_fields(fields, hash: false).select do |k,v|
      v.field_type == :associated_fields
    end.group_by(&:first).map{|k,v| Hash[k, v.map(&:last)]}.inject(&:merge)
  end

  def file_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :file }
  end

  def files_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :files }
  end

  def file_and_files_fields(fields)
    flat_fields(fields).select { |k,v| [:file, :files].include?(v.field_type) }
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

  def check_box_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :check_box }
  end

  def flags_check_boxes_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :flags_check_boxes }
  end

  def date_and_time_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type == :date_and_time }
  end

  def localised_fields(fields)
    flat_fields(fields).select { |k,v| v.field_type.in?([:localised, :localised_text_area]) }
  end

  # Works currently only with fields that have association_path
  # Not with associated_fields
  def fields_for_association_experimental fields, association_path
    return [] unless association_path.present? && association_path.is_a?(Array)
    association_path = association_path.dup
    cur = association_path.shift
    result = flat_fields(fields, hash: false).select { |k,v| v.association_path.first == cur }.map(&:last).flatten.map(&:dup)
    result.each do
      _1.association_path = _1.association_path.dup
      _1.association_path.shift
    end
    if association_path.length > 0
      fields_for_association_experimental(result, association_path)
    else
      result
    end
  end

end
