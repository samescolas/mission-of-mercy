class AddCustomSurveyQuestions < ActiveRecord::Migration
  def up
    add_column :surveys, :is_enrolled_in_medicare_medicaid,                           :boolean
    add_column :surveys, :dental_insurance,                      :boolean
    add_column :surveys, :medical_insurance,                     :boolean
    add_column :surveys, :has_place_to_be_seen_for_medical_care, :boolean
  end

  def down
    remove_column :surveys, :is_enrolled_in_medicare_medicaid
    remove_column :surveys, :dental_insurance
    remove_column :surveys, :medical_insurance
    remove_column :surveys, :has_place_to_be_seen_for_medical_care
  end
end
