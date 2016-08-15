require 'active_support/core_ext/numeric/time'
require 'csv'
require 'faker'
require 'tmdb'

# genres = Tmdb::Genre.movie_list
# [#<Tmdb::Genre id=28, name="Action">,
   #<Tmdb::Genre id=12, name="Adventure">,
   #<Tmdb::Genre id=16, name="Animation">,
   #<Tmdb::Genre id=35, name="Comedy">,
   #<Tmdb::Genre id=80, name="Crime">,
   #<Tmdb::Genre id=99, name="Documentary">,
   #<Tmdb::Genre id=18, name="Drama">,
   #<Tmdb::Genre id=10751, name="Family">,
   #<Tmdb::Genre id=14, name="Fantasy">,
   #<Tmdb::Genre id=10769, name="Foreign">,
   #<Tmdb::Genre id=36, name="History">,
   #<Tmdb::Genre id=27, name="Horror">,
   #<Tmdb::Genre id=10402, name="Music">,
   #<Tmdb::Genre id=9648, name="Mystery">,
   #<Tmdb::Genre id=10749, name="Romance">,
   #<Tmdb::Genre id=878, name="Science Fiction">,
   #<Tmdb::Genre id=10770, name="TV Movie">,
   #<Tmdb::Genre id=53, name="Thriller">,
   #<Tmdb::Genre id=10752, name="War">,
   #<Tmdb::Genre id=37, name="Western">]

# Set our constants
ACTION    = { tmdb: 28, wsb: "Action" }.freeze
ADVENTURE = { tmdb: 12, wsb: "Adventure" }.freeze
COMEDY    = { tmdb: 35, wsb: "Comedy" }.freeze
CRIME     = { tmdb: 80, wsb: "Crime" }.freeze
DRAMA     = { tmdb: 18, wsb: "Drama" }.freeze
EPICS     = { tmdb: 99, wsb: "Epics" }.freeze # Documentary
FANTASY   = { tmdb: 14, wsb: "Fantasy" }.freeze
HORROR    = { tmdb: 27, wsb: "Horror" }.freeze
MUSICAL   = { tmdb: 10402, wsb: "Musical" }.freeze # Music
SCIFI     = { tmdb: 878, wsb: "Sci-Fi" }.freeze # Science Fiction
WAR       = { tmdb: 10752, wsb: "War" }.freeze
WESTERNS  = { tmdb: 37, wsb: "Westerns" }.freeze # Western

GENRES = [ ACTION, ADVENTURE, COMEDY, CRIME, DRAMA, EPICS, FANTASY, HORROR, MUSICAL, SCIFI, WAR, WESTERNS ].freeze
CLASSIFICATIONS = %w{G PG M MA15+ R18+}.freeze
VIDEO_CSV_FILE = "video.csv".freeze
CUSTOMER_CSV_FILE = "customer.csv".freeze
PAYMENT_CSV_FILE = "payment.csv".freeze
TRANSACTION_CSV_FILE = "transaction.csv".freeze
TRANSACTION_REQUEST_CSV_FILE = "transaction_request.csv".freeze

PAYMENT_METHODS = ["Cash", "EFTPOS", "Credit Card"].freeze
PICK_UP_DELIVERY = ["pick-up", "delivery"].freeze
VIDEO_TYPES = ["DVD", "Blu-ray"].freeze
SUBURBS = ["Kingaroy", "Gordonbrook", "Taabinga", "Coolabunia", "Booie"].freeze
POSTCODE = 4610
QUEENSLAND = "Queensland".freeze
PHONE_NUMBERS = [4160, 4162, 4142, 4168, 4172, 4630, 4633].freeze

Tmdb::Api.key("#{ENV['TMDB_API_KEY']}")

# Set our variables
customers = []
payments = []
transactions = []
transaction_requests = []
videos = []

# Get the movies for each genre to add to our videos array
GENRES.each do |genre|
  movies = Tmdb::Genre.movies(genre[:tmdb]).results
  videos << movies.collect do |movie|
    { video_id: movie.id,
      title: movie.title,
      description: movie.overview,
      year_released: Date.parse(movie.release_date).year,
      price: Random.new.rand(1..12),
      quantity: Random.new.rand(1..50),
      genre: genre[:wsb],
      classification: CLASSIFICATIONS.sample
    }
  end
end

# De-dupe the array so only unique videos in each genre
videos.flatten!
videos.uniq! { |video| video[:video_id] }

# Reassign video_id with sequential index
videos.each_with_index do |video, index|
  video[:video_id] = index + 1
end

# Create 50 customers
50.times do |index|
  first_name = Faker::Name.first_name
  customers << {
    customer_id: index + 1,
    first_name: first_name,
    last_name: Faker::Name.last_name,
    street_address: Faker::Address.street_address,
    suburb: SUBURBS.sample,
    state: QUEENSLAND,
    postcode: POSTCODE,
    contact_number: "7#{PHONE_NUMBERS.sample}#{"%04d" % Random.new.rand(1..9999)}".to_i,
    email: Faker::Internet.free_email("#{first_name.downcase}#{Random.new.rand(1..99)}"),
    date_joined: Faker::Date.backward(365)
  }
end

# Grab a sample of 10 customers and videos
video_samples = videos.sample(10)
customer_samples = customers.sample(10)

# Create 10 matching transactions, transaction_requests and payments
10.times do |index|
  date = Faker::Date.between(customer_samples[index][:date_joined], Date.today)

  payment = {
    payment_id: index + 1,
    payment_method: PAYMENT_METHODS.sample,
    payment_amount: video_samples[index][:price],
    date_paid: date
  }

  transaction = {
    transaction_id: index + 1,
    customer_id: customer_samples[index][:customer_id],
    payment_id: payment[:payment_id],
    date_rented: date,
    date_due: date + 7.days,
    pick_up_delivery: PICK_UP_DELIVERY.sample,
    transaction_note: Faker::Hipster.sentence
  }

  transaction_request = {
    transaction_request_id: index + 1,
    transaction_id: transaction[:transaction_id],
    video_id: video_samples[index][:video_id],
    video_type: VIDEO_TYPES.sample,
    request_note: Faker::Hipster.sentence
  }

  payments << payment
  transactions << transaction
  transaction_requests << transaction_request
end

# Delete the video.csv if it already exists
File.delete(VIDEO_CSV_FILE) if File::exists?(VIDEO_CSV_FILE)

# Build and write out the video.csv file
file = CSV.open(VIDEO_CSV_FILE, "w") do |csv|
  videos.each_with_index do |video, index|
    csv << [ video[:video_id],
             video[:title],
             video[:description],
             video[:year_released],
             video[:price],
             video[:quantity],
             video[:genre],
             video[:classification]
           ]
  end
end

begin
  file.close
rescue
end

# Delete the customer.csv if it already exists
File.delete(CUSTOMER_CSV_FILE) if File::exists?(CUSTOMER_CSV_FILE)

# Build and write out the customer.csv file
file = CSV.open(CUSTOMER_CSV_FILE, "w") do |csv|
  customers.each do |customer|
    csv << [ customer[:customer_id],
             customer[:first_name],
             customer[:last_name],
             customer[:street_address],
             customer[:suburb],
             customer[:state],
             customer[:postcode],
             customer[:contact_number],
             customer[:email],
             customer[:date_joined]
           ]
  end
end

begin
  file.close
rescue
end

# Delete the payment.csv if it already exists
File.delete(PAYMENT_CSV_FILE) if File::exists?(PAYMENT_CSV_FILE)

# Build and write out the payment.csv file
file = CSV.open(PAYMENT_CSV_FILE, "w") do |csv|
  payments.each do |payment|
    csv << [ payment[:payment_id],
             payment[:payment_method],
             payment[:payment_amount],
             payment[:date_paid]
           ]
  end
end

begin
  file.close
rescue
end

# Delete the transaction.csv if it already exists
File.delete(TRANSACTION_CSV_FILE) if File::exists?(TRANSACTION_CSV_FILE)

# Build and write out the transaction.csv file
file = CSV.open(TRANSACTION_CSV_FILE, "w") do |csv|
  transactions.each do |transaction|
    csv << [ transaction[:transaction_id],
             transaction[:customer_id],
             transaction[:payment_id],
             transaction[:date_rented],
             transaction[:date_due],
             transaction[:pick_up_delivery],
             transaction[:transaction_note]
           ]
  end
end

begin
  file.close
rescue
end

# Delete the transaction_request.csv if it already exists
File.delete(TRANSACTION_REQUEST_CSV_FILE) if File::exists?(TRANSACTION_REQUEST_CSV_FILE)

# Build and write out the transaction_request.csv file
file = CSV.open(TRANSACTION_REQUEST_CSV_FILE, "w") do |csv|
  transaction_requests.each do |transaction_request|
    csv << [ transaction_request[:transaction_request_id],
             transaction_request[:transaction_id],
             transaction_request[:video_id],
             transaction_request[:video_type],
             transaction_request[:request_note]
           ]
  end
end

begin
  file.close
rescue
end

# Report
puts "--------------------------------------------------------------------------------"
puts "Westside Brothers Video Store Sample Data"
puts "--------------------------------------------------------------------------------"
puts "Videos per genre:"
GENRES.each do |genre|
  puts "  * #{genre[:wsb]}: #{videos.select { |video| video[:genre] == genre[:wsb] }.count} videos"
end
puts "--------------------------------------------------------------------------------"
puts "Added #{videos.count} Videos (video.csv)"
puts "Added 50 Customers (customer.csv)"
puts "Added 10 Transactions (transaction.csv)"
puts "Added 10 Transaction Requests (transaction_request.csv)"
puts "Added 10 Payments (payment.csv)"
puts "--------------------------------------------------------------------------------"
