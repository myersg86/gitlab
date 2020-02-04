# frozen_string_literal: true

class CreateGroupPushRules < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :group_push_rules do |t|
      t.references  :group, references: :namespace,
                    column: :group_id,
                    type: :integer,
                    null: false,
                    index: true
      t.string :force_push_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :delete_branch_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.string :commit_message_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.boolean :deny_delete_tag
      t.string :author_email_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.boolean :member_check, default: false, null: false
      t.string :file_name_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.integer :max_file_size, default: 0, null: false
      t.boolean :prevent_secrets, default: false, null: false
      t.string :branch_name_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.boolean :reject_unsigned_commits
      t.boolean :commit_committer_check
      t.boolean :regexp_uses_re2, default: true
      t.string :commit_message_negative_regex # rubocop:disable Migration/AddLimitToStringColumns
      t.timestamps_with_timezone null: false
    end

    add_foreign_key(:group_push_rules, :namespaces, column: :group_id, on_delete: :cascade) # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
