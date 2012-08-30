class AddTechnicalReportLinkToExperiments < ActiveRecord::Migration
  def self.up
	add_column :experiments, :technical_report, :string
  end

  def self.down
	remove_column :experiments, :technical_report 
  end
end
