class TransferExperimentOrganismData < ActiveRecord::Migration
  def self.up
    select_all("SELECT id,organism_id,culture_growth_type_id FROM experiments").each do |values|
      experiment_id=values["id"]
      organism_id=values["organism_id"]
      if (organism_id)
        culture_id=values["culture_growth_type_id"]
        culture_id||="NULL"
        execute("INSERT into experiment_organisms (experiment_id,organism_id,culture_growth_type_id) VALUES (#{experiment_id},#{organism_id},#{culture_id})")
      end      
    end
  end

  def self.down
    execute("DELETE FROM experiment_organisms")
  end
end
