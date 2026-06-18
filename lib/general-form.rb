require 'general_form/engine'
require 'general_form/field'
require 'activerecord-import'
require 'active_flag'
require 'select2-rails'
require 'jquery-ui-rails'
# The Fields concern builds permitted params via Hash#deeper_merge!, which the
# deep_merge gem only defines in its rails_compat module. Plain `require
# 'deep_merge'` loads the core + Hash#deep_merge but NOT deeper_merge!, so on
# Rails 8 every form save/create that hits permit_fields raised
# "undefined method `deeper_merge!' for an instance of Hash" (500). Require it
# here so the gem is self-contained and consumers don't have to patch it in.
require 'deep_merge/rails_compat'

module GeneralForm
end
