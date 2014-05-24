class CreateCars < ActiveRecord::Migration
  def change
    create_table :cars do |t|
      t.string :name
      t.string :color
      t.belongs_to :owner, index: true

      t.timestamps
    end
  end
end
