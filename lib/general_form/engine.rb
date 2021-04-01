module GeneralForm
  class Engine < Rails::Engine
  end

  mattr_accessor :default_fields

   def self.setup(&block)
     yield self
     self.default_fields ||= -> (klass) { klass::DEFAULT_FORM_FIELDS rescue nil }
   end
end
