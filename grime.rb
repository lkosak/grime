$LOAD_PATH << File.dirname(__FILE__)

require 'httparty'
require 'http-cookie'
require 'nokogiri'
require 'clients/us_squash'
require 'parsers/box_month'
require 'erb'
require 'pdfkit'
require 'mongoid'
require 'sinatra'

Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])

class BoxMonth
  include Mongoid::Document

  field :date, type: Date
  field :data, type: Hash
end

class Grime
  class Fetcher
    def self.call
      client = Clients::USSquash.new('lkosak', 'lk0sak')
      box_id = client.current_box_id
      data = client.box_data(box_id)
      BoxMonth.create({ date: Date.today, data: data })
    end
  end

  class Web < Sinatra::Application
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
