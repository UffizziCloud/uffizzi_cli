# frozen_string_literal: true

FactoryBot.define do
  sequence :string, aliases: [:password] do |n|
    "string_#{n}"
  end

  sequence :email do |n|
    "user#{n}@example.com"
  end
end
