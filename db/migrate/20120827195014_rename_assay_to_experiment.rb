class RenameAssayToExperiment < ActiveRecord::Migration
  def self.up
    rename_column :assay_assets, :assay_id, :experiment_id
    rename_table :assay_assets, :experiment_assets
    rename_column :assay_organisms, :assay_id, :experiment_id
    rename_table :assay_organisms, :experiment_organisms
    rename_table :assay_classes, :experiment_classes
    rename_table :assay_auth_lookup, :experiment_auth_lookup
    rename_table :assay_types, :experiment_types
    rename_table :assay_types_edges, :experiment_types_edges
    rename_column :assays, :assay_type_id, :experiment_type_id
    rename_column :assays, :assay_class_id, :experiment_class_id
    rename_table :assays, :experiments
    rename_column :assays_samples, :assay_id, :experiment_id
    rename_table :assays_samples, :experiments_samples
  end

  def self.down
    rename_column :experiment_assets, :experiment_id, :assay_id
    rename_table :experiment_assets, :assay_assets
    rename_column :experiment_organisms, :experiment_id, :assay_id
    rename_table :experiment_organisms, :assay_organisms
    rename_table :experiment_classes, :assay_classes
    rename_table :experiment_auth_lookup, :assay_auth_lookup
    rename_table :experiment_types, :assay_types
    rename_table :experiment_types_edges, :assay_types_edges
    rename_column :experiments, :experiment_type_id, :assay_type_id
    rename_column :experiments, :experiment_class_id, :assay_class_id
    rename_table :experiments, :assays
    rename_column :experiments_samples, :experiment_id, :assay_id
    rename_table :experiments_samples, :assays_samples
  end

end

