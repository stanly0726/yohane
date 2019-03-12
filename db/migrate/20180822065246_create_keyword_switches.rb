class CreateKeywordSwitches < ActiveRecord::Migration[5.2]
  def change
    create_table :keyword_switches do |t|
      t.string :channel_id
      t.string :switch

      t.timestamps
    end
  end
end
