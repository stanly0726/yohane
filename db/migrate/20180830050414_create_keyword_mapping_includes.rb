class CreateKeywordMappingIncludes < ActiveRecord::Migration[5.2]
  def change
    create_table :keyword_mapping_includes do |t|
      t.string :channel_id
      t.string :keyword
      t.string :message

      t.timestamps
    end
  end
end
