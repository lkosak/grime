require 'pry'
require 'minitest/autorun'
require 'nokogiri'
require_relative '../../parsers/box_month'

FIXTURE_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures"))

class TestBoxMonth < MiniTest::Unit::TestCase
  def setup
    @doc = Nokogiri::HTML.parse(open(File.join(FIXTURE_PATH, 'box_month.html')))
    @data = Parsers::BoxMonth.new(@doc).call
  end

  def test_box_structure
    assert_equal 16, @data[:boxes].length
  end

  def test_name_parsing
    assert_equal "Katherine Sapinski", @data[:boxes][5][:players][3][:name]
  end

  def test_count_parsing
    assert_equal 5, @data[:boxes][3][:players][1][:points]
    assert_equal 1, @data[:boxes][3][:players][1][:won]
    assert_equal 0, @data[:boxes][3][:players][1][:lost]
  end

  def test_match_parsing
    assert_equal 'Blake Cutler', @data[:boxes][5][:players][3][:matches][0][:opponent]
    assert_equal '0-3(1)', @data[:boxes][5][:players][3][:matches][0][:score]
  end
end
