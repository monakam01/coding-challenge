class Api::V1::PowerSupplyPlanController < ApplicationController
  def simulate_all
    amp = params[:amp]
    meter_rate = params[:meter_rate]
    bad_request_result = build_bad_request_resut(amp, meter_rate)
    return render json: bad_request_result, status: 400 if bad_request_result.present?
    
    amp = amp.to_i
    meter_rate = meter_rate.to_i
    
    # 各プランの基本料金を取得
    plans = PowerSupplyPlan.all
    result = []
    for plan in plans do
      basic_charge = plan.basic_charges.where(amp: amp)
      next if basic_charge.blank?

      meter_charge_price = meter_charge(plan, meter_rate)
      next if meter_charge_price < 0
      
      result << {
        provider_name: plan.provider.provider_name,
        plan_name: plan.plan_name.to_s,
        price: round_expense((basic_charge.first.price.to_f + meter_charge_price), plan)
      }
    end
    
    render json: result
  end
  
  private

  def round_expense(price, plan)
    round_method = plan.provider.rounding_amount_method
    if round_method == "round"

      return price.round(0).to_i
    elsif round_method == "off"
      return price.floor(0).to_i
    end
  end

  def meter_charge(plan, meter_rate)
    result_plan = plan.meter_rate_charges.where(
                                                  min_meter_rate: ..meter_rate, 
                                                  max_meter_rate: meter_rate..
                                               )

    if result_plan.blank?
      maximum_plan = plan.meter_rate_charges.where(
                                                    min_meter_rate: ..meter_rate, 
                                                    max_meter_rate: nil
                                                  )
      if maximum_plan.blank?
        return -1
      else
        maximum_plan.first.price * meter_rate.to_f
      end
    else

      return result_plan.first.price * meter_rate.to_f
    end
  end

  def build_bad_request_resut(amp, meter_rate)
    message = ""
    if amp.blank? 
      message = message + "リクエストパラメータ 'amp' が不足しています。\n" 
    else
      message = message + "リクエストパラメータ 'amp' の値が不正です。'10 / 15 / 20 / 30 / 40 / 50 / 60' のいずれかの値を指定してください。\n" unless valid_amp?(amp)
    end
    if meter_rate.blank?
      message = message + "リクエストパラメータ 'meter_rate' が不足しています。\n"
    else
      message = message + "リクエストパラメータ 'meter_rate' の値が不正です。0以上の整数を指定してください。\n" unless numeric?(meter_rate) && meter_rate.to_i >= 0
    end

    if message.present?
      return errro_result(message)
    end

    return []
  end

  def numeric?(string)
    Integer(string)
    true
  rescue ArgumentError, TypeError
    false
  end

  def valid_amp?(amp)
    [10, 15, 20, 30, 40, 50, 60].include?(amp.to_i)
  end

  def errro_result(result)
    [
      {
        error: {
          code: 400,
          message: result
        }
      }
    ]
  end
end
