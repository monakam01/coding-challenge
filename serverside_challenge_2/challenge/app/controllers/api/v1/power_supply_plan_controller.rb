class Api::V1::PowerSupplyPlanController < ApplicationController
  def simulate_all
    amp = params[:amp]
    meter_rate = params[:meter_rate]
    bad_request_result = build_bad_request_resut(amp, meter_rate)
    return render json: bad_request_result, status: 400 if bad_request_result.present?
    
    amp = amp.to_i
    meter_rate = meter_rate.to_i
    
    # 各プランの基本料金を取得
    plans = PowerSupplyPlanCsv.all
    result = []
    for plan in plans do
      id = plan.id
      basic_charge_price = basic_charge(id, amp)
      if basic_charge_price == -1
        next
      end
      meter_charge_price = meter_charge(id, meter_rate)
      if meter_charge_price == -1
        next
      end
      
      result << {
        provider_name: ProviderCsv.find(plan.provider_id.to_s).provider_name,
        plan_name: plan.plan_name.to_s,
        price: round_expense((basic_charge_price + meter_charge_price), plan)
      }
    end
    
    render json: result
  end
  
  private

def round_expense(price, plan)
  round_method = ProviderCsv.find(plan.provider_id.to_s).rounding_amount_method
  if round_method == "round"
    return price.round(0)
  elsif round_method == "off"
    return price.floor(0)
  end
end

  def basic_charge(plan_id, amp)
    basic_charge_record = BasicChargeCsv.where(plan_id: plan_id, amp: amp)
    if basic_charge_record.count == 1
      price = basic_charge_record.first.price
    elsif basic_charge_record.count == 0
      return -1
    end

    return price
  end

  def meter_charge(plan_id, meter_rate)
    plan = MeterRateChargeCsv.where(
                                  plan_id: plan_id,
                                  min_meter_rate: ..meter_rate, 
                                  max_meter_rate: meter_rate..
                                )
    logger.debug "plan.bank?: #{plan.blank?}"

    if plan.blank?
      maximum_plan = MeterRateChargeCsv.where(
                                            plan_id: plan_id, 
                                            max_meter_rate: nil
                                          )
      if maximum_plan.first.min_meter_rate <= meter_rate
        return maximum_plan.first.price * meter_rate.to_f
      else
        return -1
      end
    else

      return plan.first.price * meter_rate.to_f
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
