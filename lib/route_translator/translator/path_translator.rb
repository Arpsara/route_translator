require File.expand_path('../segment_translator', __FILE__)

module RouteTranslator
  module Translator
    module PathTranslator
      class << self
        private

        def display_locale?(locale)
          !RouteTranslator.config.hide_locale && !RouteTranslator.native_locale?(locale) &&
            (!default_locale?(locale) ||
             RouteTranslator.config.force_locale ||
             RouteTranslator.config.generate_unlocalized_routes ||
             RouteTranslator.config.generate_unnamed_unlocalized_routes)
        end

        def default_locale?(locale)
          I18n.default_locale.to_sym == locale.to_sym
        end

        def locale_param_present?(path)
          !path.split('/').detect { |segment| segment.to_s == ":#{RouteTranslator.locale_param_key}" }.nil?
        end
      end

      module_function

      # Translates a path and adds the locale prefix.
      def translate(path, locale)
        new_path = path.dup
        final_optional_segments = new_path.slice!(%r{(\([^\/]+\))$})
        translated_segments = new_path.split('/').map do |seg|
          seg.split('.').map { |phrase| RouteTranslator::Translator::SegmentTranslator.translate(phrase, locale) }.join('.')
        end
        translated_segments.reject!(&:empty?)

        if display_locale?(locale) && !locale_param_present?(new_path)
          translated_segments.unshift(locale.to_s.downcase)
        end

        joined_segments = translated_segments.join('/')

        "/#{joined_segments}#{final_optional_segments}".gsub(%r{\/\(\/}, '(/')
      end
    end
  end
end
