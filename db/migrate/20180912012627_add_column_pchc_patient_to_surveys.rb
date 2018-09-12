class AddColumnPchcPatientToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :pchc_patient, :boolean
  end
end
