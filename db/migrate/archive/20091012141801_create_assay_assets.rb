class CreateExperimentAssets < ActiveRecord::Migration
  def self.up
    create_table :experiment_assets do |t|
      t.integer :experiment_id
      t.integer :asset_id
      t.integer :version

      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_assets
  end
end
