Gem::Specification.new do |s|
  s.name = %q{general-form}
  s.version = '0.0.133'
  s.date = %q{2025-09-04}
  s.summary = %q{general system for rendering forms and handling data in controllers}
  s.files = [
    'lib/general-form.rb'
  ]
  s.require_paths = ['lib']
  [
    'activerecord-import',
    'active_flag',
    'select2-rails',
    'jquery-ui-rails',
    'deep_merge'
  ].each { |dep_name| s.add_runtime_dependency(dep_name) }
  s.authors = 'elias'
end
