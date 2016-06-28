#!/usr/bin/env ruby
require 'pry'
require './lib/lees_cli.rb'
require 'minitest/autorun'

class CliTest < MiniTest::Test

  def setup
    @args = []
    args = ["csv","ecimap","images","markdown","md","database","db"]
    args.each do |arg|
      @args << [arg]
    end
  end

  def test_simple
    @args.each do |arg|
      assert_kind_of String, LeesCLI::CLI.start(arg)
    end
  end
end
