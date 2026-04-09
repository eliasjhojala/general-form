class ApplicationFields
  def self.X(p1, **args)
    GeneralForm::Field.new(field_name: p1, **args)
  end
end
