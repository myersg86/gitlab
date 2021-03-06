# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ProvisioningService
        include ::Gitlab::Utils::StrongMemoize

        PASSWORD_AUTOMATICALLY_SET = true
        SKIP_EMAIL_CONFIRMATION = false
        DEFAULT_ACCESS = :guest

        def initialize(group, parsed_hash)
          @group = group
          @parsed_hash = parsed_hash.dup
        end

        def execute
          return error_response(errors: ["Missing params: #{missing_params}"]) unless missing_params.empty?
          return success_response if existing_identity_and_member?

          clear_memoization(:identity)

          return create_identity if create_identity_only?
          return create_identity_and_member if existing_user?

          create_user_and_member
        rescue => e
          logger.error(error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          error_response(errors: [e.message])
        end

        private

        def create_identity
          return success_response if identity.save

          error_response(objects: [identity])
        end

        def create_identity_and_member
          return success_response if identity.save && member.errors.empty?

          error_response(objects: [identity, member])
        end

        def create_user_and_member
          return success_response if user.save && member.errors.empty?

          error_response(objects: [user, identity, member])
        end

        def scim_identities_enabled?
          strong_memoize(:scim_identities_enabled) do
            ::EE::Gitlab::Scim::Feature.scim_identities_enabled?(@group)
          end
        end

        def identity_provider
          strong_memoize(:identity_provider) do
            next ::Users::BuildService::GROUP_SCIM_PROVIDER if scim_identities_enabled?

            ::Users::BuildService::GROUP_SAML_PROVIDER
          end
        end

        def identity
          strong_memoize(:identity) do
            next saml_identity unless scim_identities_enabled?

            identity = @group.scim_identities.with_extern_uid(@parsed_hash[:extern_uid]).first
            next identity if identity

            build_scim_identity
          end
        end

        def saml_identity
          ::Identity.with_extern_uid(identity_provider, @parsed_hash[:extern_uid]).first
        end

        def user
          strong_memoize(:user) do
            next build_user unless scim_identities_enabled?

            user = ::User.find_by_any_email(@parsed_hash[:email])
            next user if user

            build_user
          end
        end

        def build_user
          ::Users::BuildService.new(nil, user_params).execute(skip_authorization: true)
        end

        def build_scim_identity
          @scim_identity ||=
            @group.scim_identities.new(
              user: user,
              extern_uid: @parsed_hash[:extern_uid],
              active: true
            )
        end

        def success_response
          ProvisioningResponse.new(status: :success, identity: identity)
        end

        def error_response(errors: nil, objects: [])
          errors ||= objects.compact.flat_map { |obj| obj.errors.full_messages }
          conflict = errors.any? { |error| error.include?('has already been taken') }

          ProvisioningResponse.new(status: conflict ? :conflict : :error, message: errors.to_sentence)
        rescue => e
          logger.error(error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          ProvisioningResponse.new(status: :error, message: e.message)
        end

        def logger
          ::API::API.logger
        end

        def user_params
          @parsed_hash.tap do |hash|
            hash[:skip_confirmation] = SKIP_EMAIL_CONFIRMATION
            hash[:saml_provider_id] = @group.saml_provider&.id
            hash[:group_id] = @group.id
            hash[:provider] = identity_provider
            hash[:email_confirmation] = hash[:email]
            hash[:username] = valid_username
            hash[:password] = hash[:password_confirmation] = random_password
            hash[:password_automatically_set] = PASSWORD_AUTOMATICALLY_SET
          end
        end

        def random_password
          ::User.random_password
        end

        def valid_username
          clean_username = ::Namespace.clean_path(@parsed_hash[:username])

          Uniquify.new.string(clean_username) { |s| !NamespacePathValidator.valid_path?(s) }
        end

        def missing_params
          @missing_params ||= ([:extern_uid, :email, :username] - @parsed_hash.keys)
        end

        def member
          strong_memoize(:member) do
            next @group.group_member(user) if existing_member?(user)

            @group.add_user(user, DEFAULT_ACCESS) if user.valid?
          end
        end

        def create_identity_only?
          scim_identities_enabled? && existing_user? && existing_member?(user)
        end

        def existing_identity_and_member?
          identity&.persisted? && existing_member?(identity.user)
        end

        def existing_member?(user)
          ::GroupMember.member_of_group?(@group, user)
        end

        def existing_user?
          user&.persisted?
        end
      end
    end
  end
end
