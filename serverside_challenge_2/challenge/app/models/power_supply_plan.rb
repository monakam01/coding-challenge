# frozen_string_literal: true

class PowerSupplyPlan < ApplicationRecord
  belongs_to :provider
  has_many :meter_rate_charges
  has_many :basic_charges
end
