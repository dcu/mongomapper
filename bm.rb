$:.unshift File.dirname(__FILE__)+"/lib"
require 'mongomapper'
require 'benchmark'

MongoMapper.database = "testing"

class Thing
  include MongoMapper::Document
  key :name, String, :required => true
  key :date, Time
end

Thing.collection.drop
Benchmark.bm(2) do |r|
  r.report("MM INSERT") do
    50000.times do |i|
      Thing.create(:name => "thing#{i}", :date => Time.now)
    end
  end
  r.report("RAW INSERT") do
    50000.times do |i|
      Thing.collection.insert(:name => "thing#{i}", :date => Time.now)
    end
  end
end

Thing.collection.drop

