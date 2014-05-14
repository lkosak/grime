$LOAD_PATH << File.dirname(__FILE__)

require 'httparty'
require 'http-cookie'
require 'nokogiri'
require 'erb'
require 'mongoid'
require 'sinatra'
require 'pony'
require 'pry'

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

  class Mailer
    RECIPIENTS = %W(lkosak@gmail.com)

    def self.new_box_email(box_month)
      # Hack to deal with symbol vs. string keys in the data hash
      box_month.reload

      url = "#{BASE_URL}/date/#{box_month.date}"
      month = box_month.data['month']
      html_body = ERB.new(File.read('views/new_box_email.erb')).result(binding)

      Pony.mail(to: RECIPIENTS,
                subject: 'New UBL report available',
                html_body: html_body)
    end
  end

  class Fetcher
    def call
      client = Clients::USSquash.new(ENV['USS_USERNAME'], ENV['USS_PASSWORD'])
      box_id = client.current_box_id
      data = client.box_data(box_id)
      box_month = BoxMonth.create!({ date: Date.today, data: data })
      Grime::Mailer.new_box_email(box_month)
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
