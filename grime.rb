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

class BoxMonthPresenter
  def initialize(record)
    @record = record
  end

  def date
    @record.date
  end

  def month
    @record.data['month']
  end

  def boxes
    @record.data['boxes']
  end

  def winners
    @record.data['boxes'].map do |box|
      {
        'box_number' => box['number'],
        'name' => box['players']['1']['name'],
      }
    end
  end
end

class Grime
  BASE_URL = "http://grime.herokuapp.com"

  class Web < Sinatra::Application
    get '/' do
      erb :home
    end

    get '/current' do
      box_month = BoxMonth.where(date: Date.today).last

      unless box_month
        box_id = client.current_box_id
        data = client.box_data(box_id)
        box_month = BoxMonth.create!({ date: Date.today, data: data })
      end

      presenter = BoxMonthPresenter.new(box_month)
      erb :box_month, locals: { presenter: presenter }
    end

    get '/winners' do
      box_id = client.previous_box_id
      data = client.box_data(box_id)
      box_month = BoxMonth.new({ date: Date.today, data: data })

      presenter = BoxMonthPresenter.new(box_month)
      erb :winners, locals: { presenter: presenter}
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

    private

    def client
      @client ||= Clients::USSquash.new(ENV['USS_USERNAME'],
                                        ENV['USS_PASSWORD'],
                                        ENV['USS_PLAYER_ID'])
    end
  end
end
