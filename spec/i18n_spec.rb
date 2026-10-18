require "rails_helper"

# Every key must exist in all three languages.
RSpec.describe "Translations" do
  def flat_keys(hash, prefix = nil)
    hash.flat_map { |key, value| value.is_a?(Hash) ? flat_keys(value, [ prefix, key ].compact.join(".")) : [ [ prefix, key ].compact.join(".") ] }
  end

  it "has the same keys in hy, ru and en" do
    keys = %w[ hy ru en ].to_h { |locale| [ locale, flat_keys(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml"))[locale]).sort ] }
    expect(keys["ru"]).to eq(keys["en"])
    expect(keys["hy"]).to eq(keys["en"])
  end
end
