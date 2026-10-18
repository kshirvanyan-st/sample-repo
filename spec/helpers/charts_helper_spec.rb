require "rails_helper"

RSpec.describe ChartsHelper, type: :helper do
  it "draws one bar per point with a tooltip and a table view" do
    html = helper.bar_chart([ [ "1 Oct", 500 ], [ "2 Oct", 0 ], [ "3 Oct", 1200 ] ], title: "Revenue per day")
    doc = Nokogiri::HTML5.fragment(html)
    expect(doc.css("path.viz-bar").size).to eq(2) # zero values draw no bar
    expect(doc.css("title").map(&:text)).to include("3 Oct: 1,200")
    expect(doc.css("details table tr").size).to eq(3)
    expect(doc.at("svg")["aria-label"]).to eq("Revenue per day")
  end

  it "colors retention cells by value and prints the number" do
    cell = Nokogiri::HTML5.fragment("<table><tr>#{helper.retention_cell(0.62)}</tr></table>").at("td")
    expect(cell.text).to eq("62%")
    expect(cell["style"]).to include("#104281")
    expect(helper.retention_cell(nil)).to include("–")
  end
end
