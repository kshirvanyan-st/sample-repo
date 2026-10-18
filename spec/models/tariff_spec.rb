require "rails_helper"

RSpec.describe Tariff, type: :model do
  let(:tariff) { Tariff.new(vehicle_class: :economy, base_fare: 500, per_km: 100, per_minute: 15, minimum_fare: 600) }

  it "comes with Economy and Comfort tariffs" do
    expect(Tariff.ordered.pluck(:vehicle_class)).to eq(%w[ economy comfort ])
  end

  it "charges base + distance + time, rounded up to 10 drams" do
    # 500 + 100 × 4.2 + 15 × 11 = 1085 → 1090
    expect(tariff.fare_for(distance_m: 4200, duration_s: 660)).to eq(1090)
  end

  it "never charges less than the minimum" do
    expect(tariff.fare_for(distance_m: 300, duration_s: 60)).to eq(600)
  end

  it "rejects negative amounts" do
    tariff.per_km = -1
    expect(tariff).not_to be_valid
  end
end
