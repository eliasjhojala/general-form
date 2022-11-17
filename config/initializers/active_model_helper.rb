module ActionView
  module Helpers
    module ActiveModelInstanceTag
      def error_message
        object.errors[@method_name] + object.errors[@method_name.gsub(/_id$/, '')]
      end
    end
  end
end
