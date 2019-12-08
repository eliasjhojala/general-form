Gem::Specification.new do |s|
  s.name = %q{general-form}
  s.version = "0.0.06"
  s.date = %q{2019-12-08}
  s.summary = %q{general system for rendering form and handling data in controller}
  s.files = [
    "lib/general-form.rb"
  ]
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'activerecord-import'
  s.add_runtime_dependency 'active_flag'
  s.authors = "elias"
end
