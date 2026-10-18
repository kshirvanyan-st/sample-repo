# Records A/B test conversions (config/field_test.yml) for goals that happen outside a
# request, like a purchase paid through the Stripe webhook.
module Experiments
  GOALS = { purchase: %i[ coin_store_highlight ] }.freeze

  def self.converted(user, goal:)
    GOALS.fetch(goal).each { |experiment| FieldTest::Experiment.find(experiment).convert(user) }
  end
end
