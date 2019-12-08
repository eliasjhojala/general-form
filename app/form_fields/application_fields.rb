class ApplicationFields
  def self.X(p1, **args)
    GeneralForm::Fields.new(field_name: p1, **args)
  end
end
