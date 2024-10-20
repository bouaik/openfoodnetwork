# frozen_string_literal: true

class UnitPrice
  def initialize(variant)
    @variant = variant
  end

  def denominator
    # catches any case where unit is not kg, lb, or L.
    return @variant.unit_value if @variant.variant_unit == "items"

    case unit
    when "lb"
      @variant.unit_value / 453.6
    when "kg"
      @variant.unit_value / 1000
    else # Liters
      @variant.unit_value
    end
  end

  def unit
    return "lb" if WeightsAndMeasures.new(@variant).system == "imperial"

    case @variant.variant_unit
    when "weight"
      "kg"
    when "volume"
      "L"
    else
      @variant.variant_unit_name.presence || I18n.t("item")
    end
  end
end
