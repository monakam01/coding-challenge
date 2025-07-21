require 'csv' # CSVファイルを扱うためにCSVライブラリをロード

class MeterRateCharge < ActiveHash::Base
  include ActiveHash::Associations
  parsed_data = []
  data = CSV.read('config/data/meter_rate_charges.csv', headers: true).map(&:to_hash)
  data.each do |row|
    id = row["id"].to_i
    plan_id = row["plan_id"].to_i
    min_meter_rate = row["min_meter_rate"].to_i
    max_meter_rate = row["max_meter_rate"].nil? ? nil : row["max_meter_rate"].to_i
    price = row["price"].to_f
    puts row.to_h
    parsed_data << {
                      id: id,
                      plan_id: plan_id,
                      min_meter_rate: min_meter_rate, 
                      max_meter_rate: max_meter_rate, 
                      price: price
                    }
  end
  self.data = parsed_data
end