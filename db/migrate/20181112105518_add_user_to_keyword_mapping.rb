class AddUserToKeywordMapping < ActiveRecord::Migration[5.2]
  def change
add_column :keyword_mappings, :user_id, :string
add_column :keyword_mapping_includes, :user_id, :string
end
end
