# frozen_string_literal: true

module Api
  module V1
    class PowerSupplyPlanController < ApplicationController
      def simulate_all
        amp = params[:amp]
        meter_rate = params[:meter_rate]
        bad_request_result = build_200_message(amp, meter_rate)
        return render json: bad_request_result, status: 400 if bad_request_result.present?

        amp = amp.to_i
        meter_rate = meter_rate.to_i
        plans = PowerSupplyPlan.all
        result = []
        plans.each do |plan|
          basic_charge = plan.basic_charges.where(amp: amp)
          next if basic_charge.blank?

          meter_charge_price = meter_charge(plan, meter_rate)
          next if meter_charge_price.negative?

          result << {
            provider_name: plan.provider.provider_name,
            plan_name: plan.plan_name.to_s,
            price: (basic_charge.first.price.to_f + meter_charge_price).floor(0).to_i
          }
        end
        render json: result
      end

      private

      def meter_charge(plan, meter_rate)
        price = 0
        plan.meter_rate_charges.each do |step|
          price += calculate_if_step_applicable(step, meter_rate)
        end
        price
      end

      def calculate_if_step_applicable(step, meter_rate)
        max_rate = step.max_meter_rate
        min_rate = step.min_meter_rate
        price = step.price

        # 最小ステップ かつ 最大ステップ
        return meter_rate * price if max_rate.nil?

        # 使用量がステップ請求額に満たない場合0を返す
        return 0 if meter_rate < min_rate
        if max_rate.nil? && min_rate <= meter_rate
          # 最大料金ステップの計算
          return (meter_rate - min_rate + 1) * price
        end

        if min_rate.zero?
          # 最小料金ステップの計算
          if max_rate <= meter_rate
            # 該当ステップの満額請求計算
            max_rate * price
          else
            # 該当ステップの使用量までを計算
            meter_rate * price
          end
        elsif (min_rate..max_rate).include?(meter_rate)
          # 中間料金ステップの計算
          # 該当ステップの使用量までを計算
          (meter_rate - min_rate + 1) * price
        else
          # 該当ステップの満額請求計算
          (max_rate - min_rate + 1) * price
        end
      end

      def build_200_message(amp, meter_rate)
        message = ''
        if amp.blank?
          message += "リクエストパラメータ 'amp' が不足しています。\n"
        else
          unless valid_amp?(amp)
            message += "リクエストパラメータ 'amp' の値が不正です。'10 / 15 / 20 / 30 / 40 / 50 / 60' のいずれかの値を指定してください。\n"
          end
        end
        if meter_rate.blank?
          message += "リクエストパラメータ 'meter_rate' が不足しています。\n"
        else
          unless numeric?(meter_rate) && meter_rate.to_i >= 0
            message += "リクエストパラメータ 'meter_rate' の値が不正です。0以上の整数を指定してください。\n"
          end
        end
        return errro_result(message) if message.present?

        []
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
  end
end
