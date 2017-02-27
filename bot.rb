require 'facebook/messenger'
require 'httparty'
require 'json' 
require 'forecast_io'
# require 'dotenv/load'
ForecastIO.configure do |configuration|
  configuration.api_key = ENV["CONFIG_KEY"]
end

include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='.freeze

# def wait_for_user_input
Bot.on :message do |message|
  parsed_response = get_parsed_response(API_URL, message.text) # talk to Google API
  message.type # make bot appear to be typing
  if message.text == "hi"
    message.reply(text: 'Hello! Where are you?')
  elsif !parsed_response
    message.reply(text: 'Sorry I don\'t know that location. Try typing your city and country, please')
    return # we need an early return if something went wrong, though your bot server will complain
  else
    coord = extract_coordinates(parsed_response) # we have a separate method for that
    forecast = ForecastIO.forecast(coord['lat'], coord['lng'], params: { units: 'si' }).currently
    if forecast.temperature > 30
      message.reply(text: "Wow - It's pretty hot there! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    elsif forecast.temperature > 15
      message.reply(text: "I love day's like this! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    elsif forecast.temperature > 10
      message.reply(text: "It's getting a little cool now! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    elsif forecast.temperature > 4
      message.reply(text: "It's starting to feel chilly! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    elsif forecast.temperature > -5
      message.reply(text: "Watch out for ice today! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    else
      message.reply(text: "You really might want to stay inside today! It's #{forecast.summary.upcase} and #{forecast.temperature}C in #{message.text}")
    end
  end
end

def get_parsed_response(url, query)
  # Use HTTParty gem to make a get request
  response = HTTParty.get(url + query)
  # Parse the resulting JSON so it's now a Ruby Hash
  parsed = JSON.parse(response.body)
  # Return nil if we got no results from the API.
  parsed['status'] != 'ZERO_RESULTS' ? parsed : nil
end

# Look inside the hash to find coordinates
def extract_coordinates(parsed)
  parsed['results'].first['geometry']['location']
end

