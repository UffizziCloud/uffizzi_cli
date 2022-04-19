# frozen_string_literal: true

require 'time'

module Uffizzi
  module DateHelper
    TWO_MINUTES = 120
    TWO_HOURS = 120
    TWO_DAYS = 48
    TWO_WEEKS = 14
    TWO_MONTHS = (365 / 12 * 2)
    TWO_YEARS = 730

    class << self
      def count_distanse(now, previous_date)
        seconds = (now - previous_date).round
        return convert_to_words(seconds, 'seconds') if seconds < TWO_MINUTES

        minutes = seconds / 60
        return convert_to_words(minutes, 'minutes') if minutes < TWO_HOURS

        hours = minutes / 60
        return convert_to_words(hours, 'hours') if hours < TWO_DAYS

        days = hours / 24
        return convert_to_words(days, 'days') if days < TWO_WEEKS

        weeks = days / 7
        return convert_to_words(weeks, 'weeks') if days < TWO_MONTHS

        months = (days / (365 / 12)).round
        return convert_to_words(months, 'months') if days < TWO_YEARS

        years = days / 365
        convert_to_words(years, 'years')
      end

      private

      def convert_to_words(value, unit)
        "#{value} #{unit} ago"
      end
    end
  end
end
