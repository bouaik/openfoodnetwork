# frozen_string_literal: true

require "system_helper"

RSpec.describe "Shops caching", caching: true do
  include WebHelper
  include UIComponentHelper

  let!(:distributor) {
    create(:distributor_enterprise, with_payment_and_shipping: true, is_primary_producer: true)
  }
  let!(:order_cycle) {
    create(:open_order_cycle, distributors: [distributor], coordinator: distributor)
  }

  describe "caching enterprises AMS data" do
    before do
      # Trigger lengthy tasks like JS compilation before testing caching:
      visit shops_path
      Rails.cache.clear
    end

    it "caches data for all enterprises, with the provided options" do
      visit shops_path

      key, options = CacheService::FragmentCaching.ams_shops
      expect_cached "views/#{key}", options
    end

    it "keeps data cached for a short time on subsequent requests" do
      # Ensure sufficient time for requests to load and timed caches to expire
      Timecop.travel(10.minutes.ago) do
        visit shops_path

        expect(page).to have_content distributor.name

        distributor.name = "New Name"
        distributor.save!

        visit shops_path

        expect(page).not_to have_content "New Name" # Displayed name is unchanged
      end

      # A while later...
      visit shops_path
      expect(page).to have_content "New Name" # Displayed name is now changed
    end
  end

  describe "API action caching on taxons and properties" do
    let!(:taxon) { create(:taxon, name: "Cached Taxon") }
    let!(:taxon2) { create(:taxon, name: "New Taxon") }
    let!(:property) { create(:property, presentation: "Cached Property") }
    let!(:property2) { create(:property, presentation: "New Property") }
    let!(:product) {
      create(:product, primary_taxon_id: taxon.id, properties: [property])
    }
    let(:variant) { product.variants.first }
    let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }

    let(:test_domain) {
      "#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
    }
    let(:taxons_key) {
      "views/#{test_domain}/api/v0/order_cycles/#{order_cycle.id}/" \
        "taxons.json?distributor=#{distributor.id}"
    }
    let(:properties_key) {
      "views/#{test_domain}/api/v0/order_cycles/#{order_cycle.id}/" \
        "properties.json?distributor=#{distributor.id}"
    }
    let(:options) { { expires_in: CacheService::FILTERS_EXPIRY } }

    before do
      exchange.variants << product.variants.first

      # Trigger lengthy tasks like JS compilation before testing caching:
      visit enterprise_shop_path(distributor)
      Rails.cache.clear
    end

    it "caches rendered response for taxons and properties, with the provided options" do
      visit enterprise_shop_path(distributor)

      # Ensure we test for the right text after AJAX loads filters:
      within(".sticky-shop-filters-container", text: "Filter by") do
        expect(page).to have_content "Cached Taxon"
        expect(page).to have_content "Cached Property"
      end

      expect_cached taxons_key, options
      expect_cached properties_key, options
    end

    it "keeps data cached for a short time on subsequent requests" do
      # Ensure sufficient time for requests to load and timed caches to expire
      Timecop.travel(10.minutes.ago) do
        visit enterprise_shop_path(distributor)

        # The page HTML contains the cached text but we need to test for the
        # visible filters which are loaded asynchronously.
        # Otherwise we may update the database before the AJAX requests
        # and cache the new data.
        within(".sticky-shop-filters-container", text: "Filter by") do
          expect(page).to have_content taxon.name
          expect(page).to have_content property.presentation
        end

        variant.update_attribute(:primary_taxon, taxon2)
        product.update_attribute(:properties, [property2])

        visit enterprise_shop_path(distributor)

        within(".sticky-shop-filters-container", text: "Filter by") do
          expect(page).to have_content taxon.name # Taxon list is unchanged
          expect(page).to have_content property.presentation # Property list is unchanged
        end
      end

      # A while later...
      visit enterprise_shop_path(distributor)

      within(".sticky-shop-filters-container", text: "Filter by") do
        expect(page).to have_content taxon2.name
        expect(page).to have_content property2.presentation
      end
    end
  end

  def expect_cached(key, options = {})
    expect(Rails.cache.exist?(key, options)).to be true
  end
end
