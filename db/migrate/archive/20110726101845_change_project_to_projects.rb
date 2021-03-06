class ChangeProjectToProjects < ActiveRecord::Migration
  TABLES = %w[data_files data_file_versions events investigations model_versions models publications samples protocol_versions protocols specimens]
  def self.up
    TABLES.each do |table|
      create_table ChangeProjectToProjects.link_name(table).to_sym, :id => false do |t|
        t.integer :project_id
        t.integer ChangeProjectToProjects.foreign_key(table).to_sym
      end

      select_all("SELECT project_id, id FROM #{table}").each do |item_hash|
        execute "INSERT INTO #{ChangeProjectToProjects.link_name(table)} (project_id, #{ChangeProjectToProjects.foreign_key(table)}) VALUES (#{item_hash['project_id']}, #{item_hash['id']})" unless item_hash['project_id'].blank?
      end

      remove_column table.to_sym, :project_id
    end
  end

  def self.link_name table
    [table, 'projects'].sort.join('_')
  end

  def self.foreign_key(table)
    if table.match /version/
      'version_id'
    else
      "#{table.gsub(/s$/, '')}_id"
    end
  end

  def self.down
    TABLES.each do |table|
      add_column table.to_sym, :project_id, :integer

      select_all("SELECT project_id, #{ChangeProjectToProjects.foreign_key(table)} FROM #{ChangeProjectToProjects.link_name(table)}").each do |item_hash|
        execute "UPDATE #{table} SET project_id=#{item_hash['project_id']} WHERE id=#{item_hash[ChangeProjectToProjects.foreign_key(table)]}"
      end

      drop_table ChangeProjectToProjects.link_name(table)
    end
  end
end
