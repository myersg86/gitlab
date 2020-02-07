# frozen_string_literal: true

class CreateGroupPushRules < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :group_push_rules do |t|
      t.timestamps_with_timezone null: false
      t.references :group, index: true, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.integer :max_file_size, default: 0, null: false
      t.boolean :deny_delete_tag
      t.boolean :member_check, default: false, null: false
      t.boolean :prevent_secrets, default: false, null: false
      t.boolean :reject_unsigned_commits
      t.boolean :commit_committer_check
      t.boolean :regexp_uses_re2, default: true
      t.string :force_push_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :delete_branch_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :commit_message_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :author_email_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :file_name_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :branch_name_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :commit_message_negative_regex # rubocop:disable Migration/AddLimitToStringColumns
    end
  end
end
