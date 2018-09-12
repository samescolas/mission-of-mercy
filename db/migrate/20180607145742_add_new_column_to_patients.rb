class AddNewColumnToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :veteran_status, :boolean
  end
end
