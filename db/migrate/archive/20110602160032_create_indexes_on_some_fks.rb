class CreateIndexesOnSomeFks < ActiveRecord::Migration
  def self.up

    add_index :experiment_assets, [:asset_id, :asset_type]
    add_index :experiment_assets, :experiment_id

    add_index :experiment_organisms, :experiment_id
    add_index :experiment_organisms, :organism_id

    add_index :data_file_versions, :data_file_id
    add_index :data_file_versions, :project_id
    add_index :data_file_versions, [:contributor_id, :contributor_type]


    add_index :data_files, :project_id
    add_index :data_files, [:contributor_id, :contributor_type]

    add_index :disciplines_people, :person_id

    add_index :group_memberships, :person_id


    add_index :model_versions, :model_id
    add_index :model_versions, :project_id
    add_index :model_versions, [:contributor_id, :contributor_type]

    add_index :models, :project_id    
    add_index :models, [:contributor_id, :contributor_type]

    add_index :permissions, :policy_id

    add_index :publications, :project_id
    add_index :publications, [:contributor_id, :contributor_type]

    add_index :protocol_versions, :protocol_id
    add_index :protocol_versions, :project_id
    add_index :protocol_versions, [:contributor_id, :contributor_type]

    add_index :protocols, :project_id
    add_index :protocols, [:contributor_id, :contributor_type]

    add_index :synonyms, [:substance_id, :substance_type]

    add_index :studied_factors, :data_file_id
    add_index :experimental_conditions, :protocol_id

    add_index :work_groups, :project_id

  end

  def self.down
    
    remove_index :experiment_assets, :column=>[:asset_id, :asset_type]
    remove_index :experiment_assets, :experiment_id

    remove_index :experiment_organisms, :experiment_id
    remove_index :experiment_organisms, :organism_id

    remove_index :data_file_versions, :data_file_id
    remove_index :data_file_versions, :project_id
    remove_index :data_file_versions, :column=>[:contributor_id, :contributor_type]


    remove_index :data_files, :project_id
    remove_index :data_files, :column=>[:contributor_id, :contributor_type]

    remove_index :disciplines_people, :person_id

    remove_index :group_memberships, :person_id


    remove_index :model_versions, :model_id
    remove_index :model_versions, :project_id
    remove_index :model_versions, :column=>[:contributor_id, :contributor_type]

    remove_index :models, :project_id    
    remove_index :models, :column=>[:contributor_id, :contributor_type]

    remove_index :permissions, :policy_id

    remove_index :publications, :project_id
    remove_index :publications, :column=>[:contributor_id, :contributor_type]

    remove_index :protocol_versions, :protocol_id
    remove_index :protocol_versions, :project_id
    remove_index :protocol_versions, :column=>[:contributor_id, :contributor_type]

    remove_index :protocols, :project_id
    remove_index :protocols, :column=>[:contributor_id, :contributor_type]

    remove_index :synonyms, :column=>[:substance_id, :substance_type]

    remove_index :studied_factors, :data_file_id
    remove_index :experimental_conditions, :protocol_id

    remove_index :work_groups, :project_id
    
  end
end
