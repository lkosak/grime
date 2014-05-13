module Parsers
  class BoxMonth
    def initialize(doc)
      @doc = doc
    end

    def call
      current_box = 1
      boxes = []

      month = @doc.xpath('.//font[@size=2][1]/br[1]/preceding-sibling::text()').text.strip

      @doc.css('#corebody > table:last > tr > td:last .DataList').each do |table|
        opponents = table.css('tr.Header > td')[5..-1].map { |td| td.content }

        box = {
          number: current_box,
          opponents: opponents,
          players: {},
        }

        player_number = 1

        table.css('tr.tall').each do |tr|
          scores = tr.xpath('./td')[5..-1].map do |td|
                     td.xpath('text()').text.gsub('&nbsp;', ' ').
                                             gsub(/[^-*\(\)0-9]/, '')
                   end

          box[:players][player_number] = {
            name: tr.xpath('./td')[1].xpath('./a')[0].content,
            points: tr.xpath('./td')[2].content.to_i,
            won: tr.xpath('./td')[3].content.to_i,
            lost: tr.xpath('./td')[4].content.to_i,
            scores: scores
          }

          player_number += 1
        end

        boxes << box
        current_box += 1
      end

      {
        month: month,
        boxes: boxes,
      }
    end
  end
end
