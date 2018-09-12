class AddColumnPchcPatientToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :pchc_patient, :boolean
  end
end
