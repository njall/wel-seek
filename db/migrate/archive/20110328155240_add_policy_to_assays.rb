class AddPolicyToExperiments < ActiveRecord::Migration

  def self.up
    add_column :experiments, :policy_id, :integer, :default => nil
  end

  def self.down
    remove_column :experiments, :policy_id
  end
end
