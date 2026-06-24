require_relative 'test_helper'
require 'active_model'

# FIX A: the multiple file field (type: :files / default_file_field) must not
# emit the blank hidden companion ActionView adds for `file_field multiple: true`
# when config.active_storage.multiple_file_field_include_hidden is true (the
# Rails 7.0+ default). On Rails 8.1 (replace-on-assign) that companion makes an
# untouched edit submit attr=[""], purging every existing attachment. Rendering
# with include_hidden: false drops the companion so an untouched field submits
# nothing and the association is left alone. include_hidden: for file_field only
# exists on Rails >= 7, so the option is guarded.
class MultipleFileFieldTest < Minitest::Test
  include FileHelper # exposes multiple_file_field_options for the unit tests

  # --- unit: the option-builder is the load-bearing guard ----------------------
  def test_options_request_no_hidden_companion_on_rails_7_plus
    skip 'covers the Rails >= 7 path' unless Rails::VERSION::MAJOR >= 7
    assert_equal({ include_hidden: false }, multiple_file_field_options)
  end

  def test_options_pass_nothing_unsupported_on_older_rails
    # Simulate an older Rails by stubbing the major version the guard reads; the
    # method must then omit include_hidden entirely (older file_field rejects it,
    # and append-mode makes a blank array harmless anyway).
    original = Rails::VERSION::MAJOR
    Rails::VERSION.send(:remove_const, :MAJOR)
    Rails::VERSION.const_set(:MAJOR, 6)
    assert_equal({}, multiple_file_field_options,
      'older Rails must not be handed the unsupported include_hidden: option')
  ensure
    Rails::VERSION.send(:remove_const, :MAJOR)
    Rails::VERSION.const_set(:MAJOR, original)
  end

  # --- integration: real ActionView render through default_file_field ----------
  # Reproduce a consuming app's config, then prove default_file_field emits NO
  # blank hidden companion while a raw file_field(multiple: true) still does.
  class FakeAttachable
    include ActiveModel::Model
    def attachments = nil
  end

  # View context with FileHelper mixed in; list_attached_files is the attachment
  # listing (irrelevant to the companion) so stub it to contribute nothing.
  def build_view
    view_class = Class.new(ActionView::Base) do
      include FileHelper
      def list_attached_files(*) = ''.html_safe
    end
    view_class.new(ActionView::LookupContext.new([]), {}, nil)
  end

  def with_app_default_include_hidden
    helper = ActionView::Helpers::FormHelper
    return yield unless helper.respond_to?(:multiple_file_field_include_hidden)
    original = helper.multiple_file_field_include_hidden
    helper.multiple_file_field_include_hidden = true # Rails 7.0+ default in apps
    yield
  ensure
    helper.multiple_file_field_include_hidden = original if helper.respond_to?(:multiple_file_field_include_hidden=) && !original.nil?
  end

  def test_default_file_field_renders_without_blank_hidden_companion
    skip 'covers the Rails >= 7 path' unless Rails::VERSION::MAJOR >= 7
    with_app_default_include_hidden do
      view = build_view
      obj = FakeAttachable.new
      f = ActionView::Helpers::FormBuilder.new(:doc, obj, view, {})

      rendered = view.default_file_field(f, obj).to_s

      refute_includes rendered, 'type="hidden"',
        'default_file_field must not emit a blank hidden companion that would purge attachments on a blank edit'
      assert_includes rendered, 'type="file"', 'the file input itself must still render'
      assert_includes rendered, 'multiple="multiple"', 'the field must still accept multiple files'

      # Guard the test itself: prove the companion WOULD appear without the fix,
      # so this test fails loudly if the include_hidden: false guard is removed.
      raw = f.file_field(:attachments, multiple: true).to_s
      assert_includes raw, 'type="hidden"',
        'sanity: with the app default on, a raw multiple file_field still emits the companion the fix removes'
    end
  end
end
