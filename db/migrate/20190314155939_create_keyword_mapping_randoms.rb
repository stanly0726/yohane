class CreateKeywordMappingRandoms < ActiveRecord::Migration[5.2]
  def change
    create_table :keyword_mapping_randoms do |t|
      t.string :channel_id
      t.string :keyword
      t.string :message
      t.string :user

      t.timestamps
    end
  end
end
