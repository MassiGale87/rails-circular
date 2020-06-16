class CreateOwners < ActiveRecord::Migration[6.0]
  def change
    create_table :owners do |t|
      t.string :name
      t.string :description
      t.string :object

      t.timestamps
    end
  end
end
