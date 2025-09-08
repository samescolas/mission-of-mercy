class PatientsTable
  include Enumerable

  def initialize(*fields)
    @fields = fields.empty? ? [:chart_number] : fields
  end

  def search(params)
    @patient_search = PatientSearch.new(params)

    @patients = patient_search.patients.
      paginate(per_page: 30, page: params[:page])

    @patient_search
  end

  def each(&block)
    patients.each(&block)
  end


  #def each
    #patients.each {|patient| yield patient, controls_for(patient) }
  #end
	def controls(view_context = nil, &block)
    @patient_controls = block
    @view_context = view_context
  end

  def controls_for(patient)
    return unless @patient_controls
    if @view_context
      @view_context.capture(patient, &@patient_controls)
    else
      @patient_controls.call(patient) # fallback
    end
  end

  def show?(field)
    fields.include?(field)
  end

  # Will Paginate methods

  def total_pages
    patients.total_pages
  end

  def current_page
    (patients.current_page || 1).to_i
  end

  def count
    patients.total_entries
  end

  private

  attr_reader :patients, :fields, :patient_search, :patient_controls, :view_context

end
