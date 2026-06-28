# frozen_string_literal: true

require "rails/engine"

module Ledger
  # A model-only Rails engine. It carries the schema migrations into the host
  # app and lets Zeitwerk autoload the models from app/models/ledger.
  class Engine < ::Rails::Engine
    initializer "ledger.append_migrations" do |app|
      next if app.root.to_s.start_with?(root.to_s)

      config.paths["db/migrate"].expanded.each do |path|
        app.config.paths["db/migrate"] << path
      end
    end
  end
end
