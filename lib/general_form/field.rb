module GeneralForm
  class Field
    attr_accessor :field_name, :field_type, :hide_name, :select_options, :text_after, :text, :text_type, :data_for_select_options, :name_after, :associated_model, :privileges, :multiple, :options_name, :associated_fields, :disabled, :policy_scope, :habtm, :prompt, :no_policy_scope
    
    def initialize(**attributes)
      attributes[:field_type] = attributes.delete(:type)
      attributes.each { |key, val| self.send(key.to_s+'=', val) }
    end
  end
end
