require 'csv' # CSVファイルを扱うためにCSVライブラリをロード

class ProviderCsv < ActiveHash::Base
  include ActiveHash::Associations
  self.data = CSV.read('config/data/providers.csv', headers: true).map(&:to_hash)
end