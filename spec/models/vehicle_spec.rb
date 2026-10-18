require "rails_helper"

RSpec.describe Vehicle, type: :model do
  it "normalizes Armenian plates, including Cyrillic look-alike letters" do
    expect(Vehicle.new(plate_number: "35os555").plate_number).to eq("35 OS 555")
    expect(Vehicle.new(plate_number: "35 ОС 555").plate_number).to eq("35 OC 555")
    expect(Vehicle.new(plate_number: "123-ab-45").plate_number).to eq("123 AB 45")
  end

  it "rejects other plate formats" do
    expect(build(:vehicle, plate_number: "ABC123")).not_to be_valid
  end

  it "keeps plates unique" do
    create(:vehicle, :complete, plate_number: "35 OS 555")
    expect(build(:vehicle, plate_number: "35os555")).not_to be_valid
  end

  it "needs a recent car for Comfort" do
    vehicle = build(:vehicle, :complete, vehicle_class: :comfort, year: Date.current.year - 11)
    expect(vehicle.valid?(:submit)).to be(false)
    expect(vehicle.errors).to be_added(:vehicle_class, :too_old_for_comfort, years: 10)

    vehicle.year = Date.current.year - 5
    expect(vehicle.valid?(:submit)).to be(true)
  end

  it "allows a partial draft but requires everything on submit" do
    vehicle = build(:vehicle, make: "Kia")
    expect(vehicle).to be_valid
    expect(vehicle.valid?(:submit)).to be(false)
    expect(vehicle.errors.attribute_names).to include(:model, :plate_number, *Vehicle::DOCUMENTS)
  end
end
