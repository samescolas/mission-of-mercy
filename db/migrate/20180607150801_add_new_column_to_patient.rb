class AddNewColumnToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :has_permanent_residence, :boolean
  end
end
