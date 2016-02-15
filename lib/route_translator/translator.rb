# frozen_string_literal: true

require File.expand_path('../translator/route_helpers', __FILE__)
require File.expand_path('../translator/path_translator', __FILE__)

module RouteTranslator
  module Translator
    class << self
      private

      def available_locales
        locales = RouteTranslator.available_locales
        locales.push(*RouteTranslator.native_locales) if RouteTranslator.native_locales.present?
        # Make sure the default locale is translated in last place to avoid
        # problems with wildcards when default locale is omitted in paths. The
        # default routes will catch all paths like wildcard if it is translated first.
        locales.delete I18n.default_locale
        locales.push I18n.default_locale
      end

      def host_locales_option?
        RouteTranslator.config.host_locales.present?
      end

      def translate_name(name, locale, named_routes_names)
        return unless name.present?
        translated_name = "#{name}_#{locale.to_s.underscore}"
        if named_routes_names.include?(translated_name.to_sym)
          nil
        else
          translated_name
        end
      end

      def host_locales_option?
        RouteTranslator.config.host_locales.present?
      end
    end

    module_function

    def translations_for(app, conditions, requirements, defaults, route_name, anchor, route_set)
      RouteTranslator::Translator::RouteHelpers.add route_name, route_set.named_routes

      available_locales.each do |locale|
        begin
          translated_path = RouteTranslator::Translator::PathTranslator.translate(conditions[:path_info], locale)
        rescue I18n::MissingTranslationData => e
          raise e unless RouteTranslator.config.disable_fallback
          next
        end

        new_conditions = translate_conditions(conditions, translated_path)

        new_defaults = defaults.merge(RouteTranslator.locale_param_key => locale.to_s.gsub('native_', ''))
        new_requirements = requirements.merge(RouteTranslator.locale_param_key => locale.to_s)
        new_route_name = translate_name(route_name, locale, route_set.named_routes.routes)
        yield app, new_conditions, new_requirements, new_defaults, new_route_name, anchor
      end
    end

    def route_name_for(args, old_name, suffix, kaller)
      args_hash           = args.detect { |arg| arg.is_a?(Hash) }
      args_locale         = host_locales_option? && args_hash && args_hash[:locale]
      current_locale_name = I18n.locale.to_s.underscore

      locale = if args_locale
                 args_locale.to_s.underscore
               elsif kaller.respond_to?("#{old_name}_native_#{current_locale_name}_#{suffix}")
                 "native_#{current_locale_name}"
               elsif kaller.respond_to?("#{old_name}_#{current_locale_name}_#{suffix}")
                 current_locale_name
               else
                 I18n.default_locale.to_s.underscore
               end

      "#{old_name}_#{locale}_#{suffix}"
    end
  end
end
