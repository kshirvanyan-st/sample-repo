# Starting tariffs and the Yerevan service zone. Loaded by db/seeds.rb (and the specs); admins
# change them afterwards in Admin → Tariffs and Admin → Zones. Safe to run again.
module MapDefaults
  TARIFFS = {
    economy: { base_fare: 500, per_km: 100, per_minute: 15, minimum_fare: 600 },
    comfort: { base_fare: 700, per_km: 150, per_minute: 20, minimum_fare: 900 }
  }.freeze

  # Yerevan city and Zvartnots airport, roughly. Longitude first.
  YEREVAN = "MULTIPOLYGON(((44.36 40.13, 44.40 40.07, 44.48 40.05, 44.56 40.07, 44.63 40.12, 44.64 40.19, " \
            "44.60 40.25, 44.52 40.27, 44.43 40.25, 44.37 40.20, 44.36 40.13)))"

  def self.load!
    TARIFFS.each { |vehicle_class, amounts| Tariff.find_or_create_by!(vehicle_class: vehicle_class) { |tariff| tariff.assign_attributes(amounts) } }
    ServiceZone.find_or_create_by!(name: "Yerevan") { |zone| zone.area = Geo::FACTORY.parse_wkt(YEREVAN) }
  end
end
