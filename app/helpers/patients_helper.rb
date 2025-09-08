module PatientsHelper

  def reprint_controls_lambda
    ->(patient) do
      link_to(
        patient.chart_printed ? "Reprint" : "Print",
        chart_patient_path(patient),
        class: 'primary',
        data: { chart_number: patient.id }
      )
    end
  end

  def pharmacy_controls_lambda
    ->(patient) { link_to "Check out", pharmacy_check_out_path(patient), class: 'primary' }
  end

  def checkout_controls_lambda(area)
      area_id = area.respond_to?(:id) ? area.id : area
      ->(patient) { link_to_checkout(area_id, patient) }
    end

    def checkin_controls_lambda
      ->(patient) { link_to("Check-in",
                            new_patient_path(patient: { previous_chart_number: patient }),
                            class: 'primary') }
    end

    def admin_controls_lambda
      ->(patient) do
        safe_join([
          link_to('Edit',   edit_admin_patient_path(patient)),
          link_to('Print',  chart_patient_path(patient, format: 'pdf')),
          link_to('Destroy', admin_patient_path(patient), data: { confirm: 'Are you sure?' }, method: :delete)
        ], ' ')
      end
    end


    def link_to_checkout(area, patient)
      puts "XXX inside checkout for #{area} and #{patient}"
      if area == TreatmentArea.radiology
        radiology_link(patient)
      else
        name = TreatmentArea.find(area).name
        link_to "#{name} Checkout", checkout_path(area, patient), class: 'primary'
      end
    end

  def show_previous_mom(patient)
    "display:none;" unless patient.attended_previous_mom_event
  end

  def yes_no_group(f, attribute, options = {})
    [
      f.radio_button(attribute, true, options),
      f.label(attribute, "Yes", :value => true),
      f.radio_button(attribute, false, options),
      f.label(attribute, "No", :value => false)
    ].join("\n").html_safe
  end

  def languages
    [
      "Spanish or Spanish Creole",
      "Portuguese or Portuguese Creole",
      "French",
      "Italian",
      "Mon-Khmer, Cambodian",
      "Vietnamese",
      "French Creole",
      "Chinese",
      "Laotian",
      "Hmung",
      "Polish",
      "German",
      "African languages",
      "Arabic",
      "Other"
    ]
  end
end
