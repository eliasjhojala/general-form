require_relative 'test_helper'

# permit_fields must honor privileges_strict: exactly like the view helpers do.
# A field gated solely by privileges_strict: (no privileges:) was permitted for
# everyone, because permit_fields only ever checked field.privileges. The view
# helpers hid the field, masking a real strong-parameters privilege escalation in
# a consuming app (menddie's privileges_strict: :organisation_admin field).
class PermitFieldsPrivilegesStrictTest < Minitest::Test
  # Stand-in current_user whose strict privilege is configurable. Mirrors the
  # consumer User API: privileges?(*type) and privileges_strict?(*type).
  class StrictUser
    def initialize(strict:) = @strict = strict
    def privileges?(*) = true            # not strict-gated here; permissive
    def privileges_strict?(*type) = type.flatten.map(&:to_s).include?(@strict.to_s)
  end

  # A current_user that, like some consumers, has no privileges_strict? at all.
  # permit_fields must fail closed (exclude the field) without raising.
  class UserWithoutStrict
    def privileges?(*) = true
  end

  class Host
    include Fields
    def initialize(user) = @user = user
    def current_user = @user
  end

  def strict_field
    GeneralForm::Field.new(field_name: :privileges_for_org_admin,
                           privileges_strict: :organisation_admin)
  end

  def test_excludes_strict_field_for_user_lacking_the_strict_privilege
    host = Host.new(StrictUser.new(strict: :something_else))
    refute_includes host.permit_fields([strict_field]), :privileges_for_org_admin,
      'a privileges_strict-gated field must NOT be permitted for a user without that strict privilege'
  end

  def test_includes_strict_field_for_user_holding_the_strict_privilege
    host = Host.new(StrictUser.new(strict: :organisation_admin))
    assert_includes host.permit_fields([strict_field]), :privileges_for_org_admin,
      'a privileges_strict-gated field must be permitted for a user with that strict privilege'
  end

  def test_fails_closed_when_current_user_has_no_privileges_strict_method
    host = Host.new(UserWithoutStrict.new)
    permitted = nil
    permitted = host.permit_fields([strict_field]) # must not raise NoMethodError
    refute_includes permitted, :privileges_for_org_admin,
      'fail closed: exclude a strict-gated field when the user cannot evaluate privileges_strict?'
  end

  def test_unaffected_for_fields_without_privileges_strict
    # A plain field (no privileges/privileges_strict) is permitted as before;
    # consumers with no privileges_strict fields (e.g. gvodata) see zero change.
    plain = GeneralForm::Field.new(field_name: :name)
    host = Host.new(UserWithoutStrict.new)
    assert_includes host.permit_fields([plain]), :name,
      'a field with no privileges_strict must be unaffected by the strict gate'
  end

  def test_strict_gate_combines_with_an_unmet_plain_privileges_gate
    # privileges: still excludes independently; the strict check is additive.
    gated = GeneralForm::Field.new(field_name: :secret, privileges: :admin)
    denying_user = Class.new do
      def privileges?(*) = false
      def privileges_strict?(*) = true
    end.new
    refute_includes Host.new(denying_user).permit_fields([gated]), :secret,
      'an unmet privileges: gate must still exclude the field'
  end
end
