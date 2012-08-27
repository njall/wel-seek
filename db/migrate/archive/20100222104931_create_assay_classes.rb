class CreateExperimentClasses < ActiveRecord::Migration
  def self.up
    create_table :experiment_classes do |t|
      t.string   :title
      t.text     :description
      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_classes
  end
end
