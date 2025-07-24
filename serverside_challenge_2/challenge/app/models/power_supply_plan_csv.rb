require 'csv' # CSVファイルを扱うためにCSVライブラリをロード

class PowerSupplyPlanCsv < ActiveHash::Base
  include ActiveHash::Associations
  self.data = CSV.read('config/data/power_supply_plans.csv', headers: true).map(&:to_hash)
end