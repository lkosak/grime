module Parsers
  class BoxMonth
    def initialize(doc)
      @doc = doc
    end

    def call
      current_box = 1
      boxes = {}

      @doc.css('#corebody > table:last > tr > td:last .DataList').each do |box|
        boxes[current_box] = {
          players: {}
        }

        player_number = 1
        opponents = box.css('tr.Header > td')[5..-1].map { |td| td.content }

        box.css('tr.tall').each do |tr|
          matches = []
          tr.xpath('./td')[5..-1].each do |td|
            matches << {
              opponent: opponents[matches.length],
              score: td.xpath('text()').text.gsub('&nbsp;', ' ').strip,
            }
          end

          boxes[current_box][:players][player_number] = {
            name: tr.xpath('./td')[1].xpath('./a')[0].content,
            points: tr.xpath('./td')[2].content.to_i,
            won: tr.xpath('./td')[3].content.to_i,
            lost: tr.xpath('./td')[4].content.to_i,
            matches: matches
          }

          player_number += 1
        end

        current_box += 1
      end

      {
        boxes: boxes
      }
    end
  end
end
