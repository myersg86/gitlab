# frozen_string_literal: true

module PushRuleLike
  extend ActiveSupport::Concern

  REGEX_COLUMNS = %i[
    force_push_regex
    delete_branch_regex
    commit_message_regex
    commit_message_negative_regex
    author_email_regex
    file_name_regex
    branch_name_regex
  ].freeze

  included do
    validates :max_file_size, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates(*REGEX_COLUMNS, untrusted_regexp: true)

    before_update :convert_to_re2
  end

  def convert_to_re2
    self.regexp_uses_re2 = true
  end
end
