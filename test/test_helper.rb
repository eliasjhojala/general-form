$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'

# Bring in the minimal Rails surface the gem relies on. We do NOT boot a full
# Rails app: these tests target self-contained bugs (a missing require, a missing
# attribute accessor, a blank-attribute guard, Enumerable#sum seeds) that
# surfaced under Rails 8 and broke consuming apps.
require 'active_support'
require 'active_support/core_ext'
require 'action_view'
require 'action_view/helpers'

# general_form/engine subclasses Rails::Engine. Provide a stub if a full Rails
# install graph isn't booted, so the entrypoint loads in isolation.
require 'rails' rescue nil
unless defined?(Rails::Engine)
  module Rails
    class Engine; end
  end
end

# The multiple-file-field guard (FileHelper#multiple_file_field_options) keys off
# Rails::VERSION::MAJOR. `require 'rails'` defines it, but if the full meta-gem
# isn't resolvable, stub it from the loaded ActionView so the guard evaluates
# deterministically against the actual framework version under test.
unless defined?(Rails::VERSION::MAJOR)
  module Rails
    module VERSION
      MAJOR = ActionView::VERSION::MAJOR
    end
  end
end

GEM_ROOT = File.expand_path('..', __dir__)

# Load the real gem entrypoint so bug #1's `require 'deep_merge/rails_compat'`
# is exercised exactly as consumers load it.
require 'general-form'

# App-side units that aren't auto-required by the engine in this bare harness.
require "#{GEM_ROOT}/app/controllers/concerns/fields"
require "#{GEM_ROOT}/app/helpers/general_form_helper"
require "#{GEM_ROOT}/app/helpers/file_helper"
