require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_uniqueness_of(:phone).case_insensitive }
  it { is_expected.to define_enum_for(:role).with_values(rider: 0, driver: 1, dispatcher: 2, admin: 3).validating }

  it "defaults to rider" do
    expect(User.new.role).to eq("rider")
  end

  describe "phone numbers" do
    it "normalizes Armenian numbers to E.164" do
      expect(User.new(phone: "091 123456").phone).to eq("+37491123456")
      expect(User.new(phone: "+374 (77) 12-34-56").phone).to eq("+37477123456")
    end

    it "accepts foreign mobile numbers" do
      expect(build(:user, phone: "+7 916 123-45-67")).to be_valid
    end

    it "rejects numbers that aren't mobile" do
      expect(build(:user, phone: "+374 10 123456")).not_to be_valid # Yerevan landline
      expect(build(:user, phone: "12345")).not_to be_valid
    end
  end

  it "requires a name only on the profile form" do
    user = build(:user, name: nil)
    expect(user).to be_valid
    expect(user.valid?(:profile)).to be(false)
  end

  it "only allows the supported locales" do
    expect(build(:user, locale: "fr")).not_to be_valid
    expect(build(:user, locale: "hy")).to be_valid
  end

  it "keeps banned users out of .active" do
    active = create(:user)
    create(:user, :banned)
    expect(User.active).to contain_exactly(active)
  end
end
