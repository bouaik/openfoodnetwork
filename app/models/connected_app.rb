# frozen_string_literal: true

# An enterprise can be connected to other apps.
#
# Here we store keys and links to access the app.
class ConnectedApp < ApplicationRecord
  belongs_to :enterprise

  scope :discover_regen, -> { where(type: "ConnectedApp") }

  def connecting?
    data.nil?
  end

  def ready?
    !connecting?
  end
end
