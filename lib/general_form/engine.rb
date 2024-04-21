module GeneralForm
  class Engine < Rails::Engine
  end

  mattr_accessor :default_fields, :use_form_floating, :auto_select2, :locales

   def self.setup(&block)
     yield self
     self.default_fields ||= -> (klass) { klass::DEFAULT_FORM_FIELDS rescue nil }
     self.locales ||= nil
   end
end
