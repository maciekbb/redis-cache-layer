class AddSpeedToCars < ActiveRecord::Migration
  def change
    add_column :cars, :speed, :integer
  end
end
