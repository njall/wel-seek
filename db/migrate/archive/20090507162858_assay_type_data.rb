require 'default_data_migration'


class ExperimentTypeData < DefaultDataMigration
  def self.model_class_name
    "ExperimentType"
  end
end
