module GeneralForm
  class Field
    attr_accessor :field_name, :field_type, :hide_name, :select_options, :text_after, :text, :text_type, :data_for_select_options, :name_after, :associated_model, :privileges, :privileges_strict, :multiple, :options_name, :options_value, :associated_fields, :disabled, :habtm, :prompt, :prompt_translated, :no_policy_scope, :replace_instead_of_delete, :direct_upload, :autocomplete, :scale, :preview, :required, :min, :max, :step, :polymorphic, :select2, :no_select2, :localised_text, :allowed_keys, :association_path, :readonly, :autofocus

    def initialize(**attributes)
      attributes[:field_type] = attributes.delete(:type)
      attributes.each { |key, val| self.send(key.to_s+'=', val) }
    end
  end
end
