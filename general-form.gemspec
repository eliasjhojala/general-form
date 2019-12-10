Gem::Specification.new do |s|
  s.name = %q{general-form}
  s.version = '0.0.15'
  s.date = %q{2019-12-08}
  s.summary = %q{general system for rendering form and handling data in controller}
  s.files = [
    'lib/general-form.rb'
  ]
  s.require_paths = ['lib']
  [
    'activerecord-import',
    'active_flag',
    'select2-rails',
    'jquery-ui-rails'
  ].each { |dep_name| s.add_runtime_dependency(dep_name) }
  s.authors = 'elias'
end
