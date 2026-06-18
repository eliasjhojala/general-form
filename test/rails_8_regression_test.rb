require_relative 'test_helper'

# Regression tests for the Rails-8 breakages found in the deep-testing wave. Each
# bug 500'd in a consuming app (olarfest-intra, visualevents-intra, gvodata) and
# was worked around per-app; these lock in the fix inside the gem itself.

# --- Bug 1: missing deep_merge/rails_compat require -------------------------
# The gem entrypoint must pull in deep_merge/rails_compat so Hash#deeper_merge!
# (used by the Fields concern when building permitted params) exists. Without it
# every form save/create that hit permit_fields raised
# "undefined method `deeper_merge!' for an instance of Hash".
class DeepMergeRequireTest < Minitest::Test
  def test_deeper_merge_bang_is_available_after_loading_the_gem
    assert_respond_to({}, :deeper_merge!,
      'requiring the gem must make Hash#deeper_merge! available')
  end

  def test_deeper_merge_bang_actually_deep_merges
    target = { a: { b: 1 } }
    target.deeper_merge!(a: { c: 2 })
    assert_equal({ a: { b: 1, c: 2 } }, target)
  end
end

# Exercise the real Fields concern path that relies on deeper_merge! (an
# associated_fields field forces the "#{name}_attributes" => ... deep merge).
class FieldsPermitDeepMergeTest < Minitest::Test
  class Host
    include Fields
    # permit_fields consults current_user.privileges? for gated fields; our
    # fields aren't gated, but the method is referenced, so stub a permissive one.
    def current_user
      Class.new { def privileges?(*) = true }.new
    end
  end

  def test_permit_fields_with_associated_fields_uses_deeper_merge
    inner = GeneralForm::Field.new(field_name: :title)
    assoc = GeneralForm::Field.new(field_name: :child, type: :associated_fields,
                                   associated_fields: [inner])
    result = Host.new.permit_fields([assoc])

    hash = result.find { |e| e.is_a?(Hash) }
    refute_nil hash, 'expected a nested permitted-params hash'
    assert_equal [:id, :title], hash['child_attributes'].sort_by(&:to_s)
  end
end

# --- Bug 2: :date_and_time placeholder splat --------------------------------
# Building the date/time sub-Fields splats **common, which contains placeholder:.
# GeneralForm::Field had no placeholder accessor, so it raised NoMethodError
# (500 on visualevents-intra /working_times/new).
class FieldPlaceholderTest < Minitest::Test
  def test_field_accepts_placeholder_keyword
    field = GeneralForm::Field.new(field_name: :starts_at_date, type: :date,
                                   placeholder: 'Alkaa')
    assert_equal 'Alkaa', field.placeholder
  end

  def test_field_accepts_the_full_common_splat_used_for_date_and_time_subfields
    # Mirror the keys formField splats into the sub-Field via **common.
    common = { placeholder: 'x', required: true, readonly: false,
               autofocus: false, disabled: false }
    field = GeneralForm::Field.new(field_name: :starts_at_date, type: :date, **common)
    assert_equal 'x', field.placeholder
    assert field.required
  end
end

# --- Bug 3a: human_attribute_name on a blank/false attribute ----------------
# localised_field_name passes field.text/field_name straight to
# human_attribute_name. On Rails 8 a blank attribute makes human_attribute_name
# fall back to namespace.humanize where namespace is nil -> NoMethodError.
# The gem must not call human_attribute_name with a blank value.
class LocalisedFieldNameBlankTest < Minitest::Test
  class FakeRecordClass
    # Stand in for Rails' human_attribute_name, reproducing the Rails-8 crash on
    # a blank attribute so the test fails if the gem stops guarding it.
    def self.human_attribute_name(attribute, _options = {})
      attribute = attribute.to_s
      namespace = nil
      attribute.present? ? attribute.humanize : namespace.humanize
    end
  end

  class FakeRecord
    def self.klass = FakeRecordClass
    def class = FakeRecordClass
  end

  class Host
    include GeneralFormHelper
    def t(key) = key.to_s   # consuming apps resolve i18n; identity is enough here
  end

  def field(**attrs) = GeneralForm::Field.new(**attrs)

  def test_blank_text_does_not_call_human_attribute_name_with_blank
    # field.text: false is the documented way to suppress a label; field_name
    # also blank -> the value handed to human_attribute_name would be blank.
    f = field(field_name: '', text: false)
    assert_nil Host.new.localised_field_name(FakeRecord.new, f)
  end

  def test_present_field_name_still_humanized
    f = field(field_name: :starts_at)
    assert_equal 'Starts at', Host.new.localised_field_name(FakeRecord.new, f)
  end
end

# --- Bug 3c: human_attribute_name on a non-model (symbol-form) record --------
# A symbol-based form (`form_for :discounts` with no bound @discounts) yields a
# builder whose `object` is `false` (Rails default). formField then renders each
# field with record=false. localised_field_name called `record.class
# .human_attribute_name`, i.e. `FalseClass.human_attribute_name`, which does not
# exist -> NoMethodError (500). This hit any app rendering a select/MULTIPLE
# field set through a symbol form. The gem must humanize the key directly when
# the record's class can't translate attribute names.
class LocalisedFieldNameNonModelRecordTest < Minitest::Test
  class Host
    include GeneralFormHelper
    def t(key) = key.to_s
  end

  def field(**attrs) = GeneralForm::Field.new(**attrs)

  def test_false_record_humanizes_field_name_without_raising
    # `false` is exactly what a symbol form_for hands down as the builder object.
    f = field(field_name: :amount, type: :number)
    assert_equal 'Amount', Host.new.localised_field_name(false, f)
  end

  def test_nil_record_humanizes_field_name_without_raising
    f = field(field_name: :limit_count)
    assert_equal 'Limit count', Host.new.localised_field_name(nil, f)
  end

  def test_blank_text_with_false_record_returns_nil
    f = field(field_name: '', text: false)
    assert_nil Host.new.localised_field_name(false, f)
  end
end

# --- Bug 3b: Enumerable#sum seeded at integer 0 -----------------------------
# Two sites summed non-numeric values starting from the integer 0, which on
# Rails 8 raises TypeError ("0 + ...").
#
# (i) polymorphic select flattened per-type collections with `options.sum`.
# (ii) :date_and_time concatenated two SafeBuffers with `[..].sum { ... }`.
class SumSeedTest < Minitest::Test
  # Minimal stand-in for an ActiveRecord::Relation: enumerable, concatenates via
  # Array#+, but cannot be coerced into an Integer (so an Integer seed fails).
  class RelationLike
    include Enumerable
    def initialize(records) = @records = records
    def each(&block) = @records.each(&block)
    def to_ary = @records
    def to_a = @records
    def coerce(_other) = raise(TypeError, "RelationLike can't be coerced into Integer")
  end

  # On Rails 8 `options.sum` (no seed) over polymorphic per-type relations did
  # `0 + Relation` -> TypeError. The fix seeds with [] so the per-type
  # collections flatten into a single array of records regardless of the
  # ActiveSupport version's Enumerable#sum semantics.
  def test_polymorphic_collection_flatten_uses_array_seed
    per_type = [RelationLike.new([1, 2]), RelationLike.new([3, 4])]
    assert_equal [1, 2, 3, 4], per_type.sum([])

    # And an Integer seed (the old code) is unsafe for relation elements.
    assert_raises(TypeError) { [RelationLike.new([1, 2])].inject(0) { |s, e| s + e } }
  end

  def test_safe_join_concatenates_date_and_time_subfields
    # The :date_and_time branch now uses safe_join over [date, time] sub-fields
    # instead of `.sum` (which seeded at 0 and raised on SafeBuffer concat).
    parts = [ActiveSupport::SafeBuffer.new('<a>'), ActiveSupport::SafeBuffer.new('<b>')]
    joined = ActionView::Helpers::OutputSafetyHelper.instance_method(:safe_join)
                  .bind(Object.new).call(parts)
    assert_equal '<a><b>', joined
    assert joined.html_safe?, 'safe_join must keep the result html_safe'
  end
end
