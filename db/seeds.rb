require_relative 'seeds/users'
require 'highline'

# Custom Settings

console = HighLine.new

if User.count.zero?

  password = console.ask("Default password for all user accounts") do |q|
    q.default = "temp123"
  end
  total_xray_stations = console.ask("Number of X-Ray Stations", Integer) do |q|
    q.default = 5
  end

  Seeds.create_users(:password => password, :xray_stations => total_xray_stations)

  puts "#{User.count} users created"
  puts "Passwords have been set to #{password.bright}".color(:red)
else
  puts "Skip: #{User.count} users already exist"
end

if Treatment.count.zero?
  treatments = [ { :name => "Filling" },
                 { :name => "Partial denture" },
                 { :name => "Denture repair" },
                 { :name => "Extraction" } ]

  treatments.each do |treatment|
    Treatment.create(treatment)
  end
end

if TreatmentArea.count.zero?

  areas = [ { :name => "Radiology",   :capacity => 50 },
            { :name => "Restoration", :capacity => 50,
                :amalgam_composite_procedures => true },
            { :name => "Endodontics", :capacity => 50 },
            { :name => "Surgery",     :capacity => 50 },
            { :name => "Prosthetics", :capacity => 15 } ]

  areas.each do |area|
    TreatmentArea.create(area)
  end

  puts "#{TreatmentArea.count} treatment areas created"
else
  puts "Skip: #{TreatmentArea.count} treatment areas already exist"
end

if Race.count.zero?
  categories = [ { :category => "African American/Black" },
                 { :category => "American Indian/Alaska Native" },
                 { :category => "Asian/Pacific Islander" },
                 { :category => "Caucasian/White" },
                 { :category => "Hispanic" },
                 { :category => "Indian" },
                 { :category => "Other" } ]

  categories.each do |category|
    Race.create(category)
  end

  puts "#{Race.count} race categories created"
else
  puts "Skip: #{Race.count} races already exist"
end

if Prescription.count.zero?
	prescriptions = [
		{:name => "Amoxicillin", :strength => "500mg", :quantity => 21, :dosage => "1 TID x 7 days", :cost => 25},
		{:name => "Clindamycin", :strength => "300mg", :quantity => 21, :dosage => "1 TID x 7 days", :cost => 50},
		{:name => "Ibuprofen", :strength => "800mg", :quantity => 8, :dosage => "1 Q 6h prn pain", :cost => 12.5},
		{:name => "Acetaminophen", :strength => "500mg", :quantity => 12, :dosage => "2 Q 6-8h prn pain", :cost => 7.5}
	]
	prescriptions.each do |prescription|
		Prescription.create(prescription)
	end

	puts "#{Prescription.count} prescriptions created"
else
	puts "Skip: #{Prescription.count} prescriptions already exist"
end

if PreMed.count.zero?
  premeds = [ { :description => "Amoxicillin", :cost => 10.0 },
              { :description => "Clindamycin", :cost => 10.0 } ]
  premeds.each do |premed|
    PreMed.create(premed)
  end
  puts "#{PreMed.count} premeds created"
else
  puts "Skip: #{PreMed.count} premeds already exist"
end

if HeardAboutClinic.count.zero?
  reasons = [ { :reason => "Friend or Family" },
              { :reason => "Media: Newspaper/TV/Radio" },
              { :reason => "Flyer or Poster" },
              { :reason => "Other" } ]

  reasons.each do |reason|
    HeardAboutClinic.create(reason)
  end

  puts "#{HeardAboutClinic.count} heard about clinic methods created"
else
  puts "Skip: #{HeardAboutClinic.count} heard about clinic methods already exist"
end

if !PreviousClinic.any?
  clinics = [ { :year => 2012, :location => "CCRI" },
              { :year => 2013, :location => "CCRI" },
              { :year => 2014, :location => "CCRI" },
              { :year => 2015, :location => "CCRI" },
              { :year => 2016, :location => "CCRI" } ]

  clinics.each {|clinic| PreviousClinic.create(clinic) }

  puts "#{PreviousClinic.count} previous clinics created"
else
  puts "Skip: #{PreviousClinic.count} previous clinics already exist"
end
