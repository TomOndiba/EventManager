require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(raw_number)
	clean_number = raw_number.gsub /[^0-9]/,""
	bad_number = "0000000000"
	if clean_number.size < 10
		bad_number
	elsif clean_number.size == 10
		clean_number
	elsif clean_number.size == 11 and clean_number[0] != 1
		clean_number[1..-1]
	else
		bad_number
	end

end

def string_to_date date_registered
	DateTime.strptime date_registered, "%m/%d/%Y  %k:%M"
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

reg_hours_tally = Hash.new(0)
reg_days_of_week_tally = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  date_registered = string_to_date(row[:regdate])
  reg_hours_tally[date_registered.hour] += 1
  reg_days_of_week_tally[Date::DAYNAMES[date_registered.wday]] += 1

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id,form_letter)
end

puts "No. of Registrations by Hour: "
p reg_hours_tally.sort_by { |_,count| count }.reverse.to_h
puts "No. of Registrations by Day of Week: "
p reg_days_of_week_tally.sort_by { |_,count| count }.reverse.to_h