module Clients
  class USSquash
    include HTTParty
    base_uri 'http://www.ussquash.com'
    follow_redirects false
    ssl_ca_file File.expand_path(File.join(File.dirname(__FILE__), '..', 'ca-bundle.crt'))

    def initialize(username, password, player_id)
      @jar = HTTP::CookieJar.new
      @player_id = player_id
      perform_login(username, password)
    end

    def box_ids
      url = "http://modules.ussquash.com/ssm/pages/" \
            "player_profile.asp?wmode=transparent&program=player" \
            "&id=#{@player_id}"

      # for some reason, the first time we request this it returns
      # a 301 redirect, but the second time, it works.
      get(url)

      response = get(url)
      doc = Nokogiri::HTML.parse(response.body)

      box_ids = []

      leagues = doc.css('#competitions a').each do |a|
        next unless a['href'] =~ /^boxleague\//
        box_ids << a['href'][/boxid=([0-9]+)/, 1]
      end

      box_ids.sort
    end

    def current_box_id
      box_ids.last
    end

    def previous_box_id
      box_ids[-2]
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
