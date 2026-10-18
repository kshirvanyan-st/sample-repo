require "rails_helper"

# Every key must exist in all three languages.
RSpec.describe "Translations" do
  def flat_keys(hash, prefix = nil)
    hash.flat_map { |key, value| value.is_a?(Hash) ? flat_keys(value, [ prefix, key ].compact.join(".")) : [ [ prefix, key ].compact.join(".") ] }
  end

  it "has the same keys in hy, ru and en" do
    keys = %w[ hy ru en ].to_h do |locale|
      # hy.yml plus feature files such as drivers.hy.yml
      files = Rails.root.glob("config/locales/{#{locale},*.#{locale}}.yml")
      [ locale, flat_keys(files.map { |file| YAML.load_file(file)[locale] }.reduce(:deep_merge)).sort ]
    end
    expect(keys["ru"]).to eq(keys["en"])
    expect(keys["hy"]).to eq(keys["en"])
  end
end
