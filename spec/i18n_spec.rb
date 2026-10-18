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

  it "uses the same well-formed %{placeholders} in every language" do
    values = %w[ hy ru en ].to_h do |locale|
      files = Rails.root.glob("config/locales/{#{locale},*.#{locale}}.yml")
      [ locale, flat_values(files.map { |file| YAML.load_file(file)[locale] }.reduce(:deep_merge)) ]
    end
    values["en"].each do |key, english|
      expected = english.to_s.scan(/%\{(\w+)\}/).sort
      %w[ hy ru ].each do |locale|
        text = values[locale][key].to_s
        expect(text.scan(/%\{(\w+)\}/).sort).to eq(expected), "#{locale}.#{key} has different placeholders"
        expect(text.scan("%{").size).to eq(text.scan(/%\{\w+\}/).size), "#{locale}.#{key} has a broken placeholder"
      end
    end
  end

  def flat_values(hash, prefix = nil)
    hash.each_with_object({}) do |(key, value), result|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? result.merge!(flat_values(value, path)) : result[path] = value
    end
  end
end
