require 'csv' # CSVファイルを扱うためにCSVライブラリをロード

class BasicCharge < ActiveHash::Base
  include ActiveHash::Associations
  parsed_data = []
  data = CSV.read('config/data/basic_charges.csv', headers: true).map(&:to_hash)
  data.each do |row|
    id = row["id"].to_i
    plan_id = row["plan_id"].to_i
    amp = row["amp"].to_i
    price = row["price"].to_f
    puts row.to_h
    parsed_data << {
                      id: id,
                      plan_id: plan_id,
                      amp: amp, 
                      price: price
                    }
  end
  self.data = parsed_data
end