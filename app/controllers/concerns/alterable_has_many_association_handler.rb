module AlterableHasManyAssociationHandler

  def handle_alterable_has_many_association **options
    association = options[:associated_object] || options[:association] || options[:assoc]
    is_real_association = (options.keys & [:associated_object, :association, :assoc]).any?
    items = options[:items]
    item_class = options[:item_class] || association.klass
    association ||= item_class.all
    item_array_name = options[:item_array_name] || "#{association.klass.name.demodulize.pluralize.underscore}"
    existence_field_name = options[:existence_field_name] || options[:existence_field] || :any_field
    id_field_name = options[:id_field_name] || :id
    fields = options[:item_fields] || GeneralForm.default_fields[item_class]
    params_to_permit = (options[:params_to_permit] || permit_fields(fields)) | [:id]
    run_callbacks = options[:run_callbacks]

    return if items.blank? || items[item_array_name].blank?

    ActiveRecord::Base.transaction do

      # Initialize arrays for inserts, updates and deletes
      items_to_save = []
      saved_items = []
      item_ids_to_delete = []

      flat_fields_ = flat_fields(fields)
      habtm_field_names_ = habtm_field_names(fields)
      flags_select_field_names_ = flags_select_fields(fields).keys
      file_and_files_fields_names_ = file_and_files_fields(fields).keys
      check_box_fields_names_ = check_box_fields(fields).keys

      prevent_activerecord_import = run_callbacks || habtm_field_names_.any? || flags_select_field_names_.any? || file_and_files_fields_names_.any?

      if prevent_activerecord_import
        items_association_by_id = association.map { |item| [item.id, item] }.to_h
      else
        # Define objects to store items to save and delete. These are needed only if callbaks haven't to be run.
        # Load all items
        items_relation = item_class.all.where(id: items[item_array_name].map{|obj|obj[:id]}.compact)
        items_relation_hash = items_relation.map { |obj| [obj.id, obj] }.to_h
      end

      # Loop through all the items and either run commands on them or just initialize them for commands to be run later
      items[item_array_name].each do |item|
        item_id = item[id_field_name].present? ? item[id_field_name].to_i : nil
        permitted_params = item.permit(params_to_permit).except(habtm_field_names_)
        check_box_fields_names_.each { |field| permitted_params[field] ||= false } # In normal form there would be hidden 0-field to do this, but it doesn't work correct with form containing has-many-association
        should_be_kept = !ActiveModel::Type::Boolean.new.cast(item[:_delete])
        should_be_kept &&= (existence_field_name == :any_field && item.except(:id).values.any?(&:present?)) || item[existence_field_name].present?
        if item_id.present? # If item is not new --> update it
          if should_be_kept # If item should be kept --> update it
            unless prevent_activerecord_import
              items_relation_hash[item_id]&.assign_attributes(permitted_params)
              items_to_save << items_relation_hash[item_id] if items_relation_hash[item_id]&.changed?
            else
              items_to_save << items_association_by_id[item_id]
              items_association_by_id[item_id]&.update permitted_params
            end
          elsif options[:only_insert].blank? # If item should be deleted --> delete it
            item_ids_to_delete << item_id
          end
        elsif should_be_kept # If item is new and not empty --> create it
          new_item = item_class.new(permitted_params)
          if is_real_association # If item should be associated to parent object
            association << new_item
            saved_items << new_item
          else # If item shouldn't be associated to parent object
            items_to_save << new_item
            # If callbacks should be ran save item now
            new_item.save if prevent_activerecord_import
          end
        end
      end # items.each

      # Run all inserts, updates and deletes
      if !prevent_activerecord_import && items_to_save.any?
        item_class.import params_to_permit, items_to_save, on_duplicate_key_update: :all
      end
      if item_ids_to_delete.any?
        unless run_callbacks
          item_class.where(id: item_ids_to_delete).delete_all
        else
          item_class.where(id: item_ids_to_delete).destroy_all
        end
      end

      items_to_save + saved_items

    end # transaction
  end # method

end # module
