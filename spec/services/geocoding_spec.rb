require "rails_helper"

RSpec.describe Geocoding do
  it "searches the configured adapter and caches the answer" do
    expect(Geocoding.search("cascade").map(&:name)).to eq([ "Cascade" ])
    allow(Geocoding::TestAdapter).to receive(:new).and_raise("should be cached")
    expect(Geocoding.search("Cascade").map(&:name)).to eq([ "Cascade" ])
  end

  it "ignores one-letter searches" do
    expect(Geocoding.search("c")).to eq([])
  end

  describe Geocoding::NominatimAdapter do
    it "builds a short name and address, and asks only within Armenia" do
      allow(HttpJson).to receive(:get).and_return([
        { "name" => "Cascade", "lat" => "40.19", "lon" => "44.51",
          "address" => { "road" => "Tamanyan Street", "house_number" => "10", "suburb" => "Kentron" }, "display_name" => "Cascade, Tamanyan Street, Kentron, Yerevan" }
      ])
      place = described_class.new.search("Cascade", locale: "en").first
      expect(place).to have_attributes(name: "Cascade", address: "Tamanyan Street 10, Kentron", lat: 40.19, lon: 44.51)
      expect(HttpJson).to have_received(:get).with(%r{/search\z}, hash_including(countrycodes: "am", bounded: 1, "accept-language": "en"), headers: hash_including("User-Agent"))
    end

    it "doesn't repeat the name in the address" do
      allow(HttpJson).to receive(:get).and_return(
        "name" => "Republic Square", "lat" => "40.17", "lon" => "44.51", "address" => { "road" => "Republic Square", "suburb" => "Kentron" })
      expect(described_class.new.reverse(point(Places::REPUBLIC_SQUARE), locale: "en").address).to eq("Kentron")
    end
  end
end
