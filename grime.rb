$LOAD_PATH << File.dirname(__FILE__)

require 'httparty'
require 'http-cookie'
require 'nokogiri'
require 'erb'
require 'mongoid'
require 'sinatra'
require 'pony'

require 'clients/us_squash'
require 'parsers/box_month'

Dir["config/initializers/**/*.rb"].each { |f| require(f) }

Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])

class BoxMonth
  include Mongoid::Document

  field :date, type: Date
  field :data, type: Hash
end

class Grime
  BASE_URL = "http://grime.herokuapp.com"

  class Fetcher
    def call
      client = Clients::USSquash.new(ENV['USS_USERNAME'], ENV['USS_PASSWORD'])
      box_id = client.current_box_id
      data = client.box_data(box_id)
      BoxMonth.create!({ date: Date.today, data: data })
    end
  end

  class Web < Sinatra::Application
    get '/' do
      box_month = BoxMonth.where(date: Date.today).last
      box_month ||= Grime::Fetcher.new.call
      erb :box_month, locals: { date: box_month.date, data: box_month.data }
    end

    get '/date/:date' do |d|
      date = Date.strptime(d, "%Y-%m-%d")
      box_month = BoxMonth.where(date: date).last

      if box_month.nil?
        status 404
        body "No summary found for #{date}"
      else
        erb :box_month, locals: { date: box_month.date, data: box_month.data }
      end
    end
  end
end
