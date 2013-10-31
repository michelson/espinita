class CreateGeneralModels < ActiveRecord::Migration
  def change
    create_table :general_models do |t|
      t.references :user, index: true
      t.string :name
      t.text :settings
      t.integer :position

      t.timestamps
    end
  end
end
