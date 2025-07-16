class Api::V1::PlanController < ApplicationController
  def simulate_all
    amps = params[:amps]
    meter_rate = params[:meter_rate]
    data = { privider_name: "test", plan_name: "test", price: "test", amps: amps, meter_rate: meter_rate}
    render json: data
  end
end
