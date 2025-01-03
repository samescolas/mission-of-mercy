class SurveysController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_patient
  before_filter :set_tab
  before_filter :find_survey, only: [:edit, :update]

  def new
    @survey = Survey.new
  end

  def create
    @patient.survey = Survey.new(survey_params)

    if @patient.save
      route_request
    else
      render :new
    end
  end

 def update
    if @survey.update_attributes(survey_params)
      route_request
    else
      render :edit
    end
  end

  private

  def find_patient
    @patient = Patient.find(params[:patient_id])
  end

  def find_survey
    @survey = Survey.find(params[:id])
  end

  def set_tab
    @current_tab = "new"
  end

  def route_request
    if params[:commit] == "Back"
      redirect_to edit_patient_path(@patient)
    else
      stats.patient_checked_in
      redirect_to new_patient_path(last_patient_id:  @patient.id)
    end
  end

  def survey_params
    params.require(:survey).permit(*%w[heard_about_clinic heard_about_other
      has_place_to_be_seen_for_dental_care no_insurance insurance_from_job
      medicaid_or_chp_plus self_purchase_insurance is_enrolled_in_medicare_medicaid
      dental_insurance medical_insurance has_place_to_be_seen_for_medical_care
      er_last_year er_last_6_months has_permanent_residence veteran_status pchc_patient
      covid_vaccinated covid_boosters
    ])
  end
end
