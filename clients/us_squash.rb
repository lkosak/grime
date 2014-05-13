module Clients
  class USSquash
    include HTTParty
    base_uri 'http://www.ussquash.com'
    follow_redirects false

    def initialize(username, password)
      @jar = HTTP::CookieJar.new
      perform_login(username, password)
    end

    def box_ids
      response = get("http://modules.ussquash.com/ssm/pages/" \
                     "player_profile.asp?wmode=transparent&program=player&id=79799")
      doc = Nokogiri::HTML.parse(response.body)

      box_ids = []

      leagues = doc.css('#competitions a').each do |a|
        next unless a['href'] =~ /^boxleague\//
        box_ids << a['href'][/boxid=([0-9]+)/, 1]
      end

      box_ids
    end

    def current_box_id
      box_ids.max
    end

    def box_data(id)
      response = get("http://modules.ussquash.com/ssm/pages/boxleague/" \
                     "BoxLeague.asp?boxID=#{id}&currentbox=0")
      doc = Nokogiri::HTML.parse(response.body)
      data = Parsers::BoxMonth.new(doc).call
    end

    private

    def perform_login(username, password)
      # get Session ID
      response = get('https://api.ussquash.com/verify_login?redirectTo=https://modules.ussquash.com/ssm/pages/verify_login.asp')

      # Login
      response = post(
        'https://api.ussquash.com/embedded_login',
        {
          :username => username,
          :password => password,
        }
      )

      # Post Login Redirect (get URL for additional redirect)
      response = get('https://api.ussquash.com/verify_login?redirectTo=https://modules.ussquash.com/ssm/pages/verify_login.asp')

      # Get additional auth cookies
      response = get(response.headers['Location'])

      raise AuthFailure unless response.include?("Will redirect you automatically")
    end

    def get(url)
      make_request(:get, url, {})
    end

    def post(url, params={})
      make_request(:post, url, params)
    end

    def make_request(action, url, params)
      cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
      response = self.class.send(action, url, body: params, headers: { 'Cookie' => cookie })

      unless response.headers['Set-Cookie'].nil?
        @jar.parse(response.headers['Set-Cookie'], url)
      end

      response
    end

    class Error < StandardError; end
    class AuthFailure < Error; end
  end
end
