# frozen_string_literal: true

class UserPolicy < BasePolicy
  desc "The current user is the user in question"
  condition(:user_is_self, score: 0) { @subject == @user }

  desc "This is the ghost user"
  condition(:subject_ghost, scope: :subject, score: 0) { @subject.ghost? }

  desc "The profile is private"
  condition(:private_profile, scope: :subject, score: 0) { @subject.private_profile? }

  rule { ~restricted_public_level }.enable :read_user
  rule { ~anonymous }.enable :read_user

  rule { ~subject_ghost & (user_is_self | admin) }.policy do
    enable :destroy_user
    enable :update_user
  end

  rule { default }.enable :read_user_profile
  rule { private_profile & ~(user_is_self | admin) }.prevent :read_user_profile
end
