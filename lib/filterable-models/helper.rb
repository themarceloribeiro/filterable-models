module Filterable::Models
  module Helper
    def filter_form_for(object, params = {}, options = {})
      @params       = params
      form_html     = %{<form action="" method="get">} + "\n"
      elements_html = ""

      klass = object.to_s.camelize.constantize

      return if klass.filterable.blank?

      filter_fields_count = 1

      klass.sorted_filterable.each do |filterable|

        filterable.map do |key, value|
          key = key.to_sym
          value = klass.filterable[key]

          case value
          when 'string'
            elements_html += text_filter_tag(object, key) + "\n"
          when 'exact_string'
            elements_html += text_filter_tag(object, key) + "\n"
          when 'date_range', 'float_range'
            elements_html += text_filter_tag(object, key, "from") + "\n"
            elements_html += text_filter_tag(object, key, "to") + "\n"
            filter_fields_count += 1
          when 'drop_down'
            elements_html += select_filter_tag(object, key) + "\n"
          end
        end

        if filter_fields_count >= (klass.fields_per_column)
          elements_html += "</ul><ul>" + "\n"
          filter_fields_count  = 1
        else
          filter_fields_count += 1
        end

      end

      form_html += content_tag(:ul, elements_html.html_safe) + "\n"
      form_html += %{<div style="clear:both;"><!-- --></div>}.html_safe
      form_html += submit_tag(t("Filter").html_safe)
      form_html += "</form>"

      content_tag(:div, form_html.html_safe, {:class => "filter-form"}.merge(options)).html_safe
    end

    def text_filter_tag(object, key, extra = nil)
      filter_element_data     = get_filter_element_data(object, key, extra)
      filter_field_label_text = filter_element_data[:label_text]
      filter_field_id         = filter_element_data[:element_id]
      filter_field_name       = filter_element_data[:element_name]
      filter_field_value      = filter_element_data[:element_value]

      content_tag(:li, 
                  label_tag(filter_field_id, filter_field_label_text) + "<br/>".html_safe + 
                  text_field_tag(filter_field_name, filter_field_value)).html_safe
    end

    def select_filter_tag(object, key, extra = nil)
      filter_element_data     = get_filter_element_data(object, key, extra)
      filter_field_label_text = filter_element_data[:label_text]
      filter_field_id         = filter_element_data[:element_id]
      filter_field_name       = filter_element_data[:element_name]
      filter_field_value      = filter_element_data[:element_value]

      content_tag(:li, 
                  label_tag(filter_field_id, filter_field_label_text) + "<br/>".html_safe + 
                  select_tag(filter_field_name, select_values_for(object, key, filter_field_value))).html_safe
    end

    def select_values_for(object, key, value)
      klass = object.to_s.camelize.constantize
      filter_options = klass.filter_options[key]

      options_html = content_tag(:option, t("Please Select"), :value => "")

      if filter_options.is_a?(Hash)
        filter_options.keys.collect{|k| k.to_s}.sort.each do |option_key|
          selected = {}
          if value == filter_options[option_key]
            selected = {:selected => "selected"}
          end
          options_html += content_tag(:option, t(option_key.to_s.titleize), {:value => filter_options[option_key]}.merge(selected))
        end
      elsif filter_options.is_a?(Array)
        filter_options.each do |option|
          selected = {}
          if value == option
            selected = {:selected => "selected"}
          end
          options_html += content_tag(:option, t(option.titleize), {:value => option}.merge(selected))
        end
      end

      options_html.html_safe
    end

    def get_filter_element_data(object, key, extra)
      params_prefix                   = :filters
      @params                         ||= {}
      @params[params_prefix]          ||= {}
      @params[params_prefix][object]  ||= {}

      if key.to_s =~ /\./
        key_parts = key.to_s.split(".")
        key_object = key_parts.first.singularize.to_sym
        key_object_att = key_parts.last.to_sym

        @params[params_prefix][object][key_object] ||= {}
        key = "#{key_object}_#{key_object_att}"

        if extra.nil?
          element_name = "#{params_prefix}[#{object}][#{key_object}][#{key_object_att}]"
          element_value = @params[params_prefix][object][key_object][key_object_att]
          element_id = "#{params_prefix}_#{object}_#{key}"
        else
          element_name = "#{params_prefix}[#{object}][#{key_object}][#{key_object_att}_#{extra}]"
          element_value = @params[params_prefix][object][key_object]["#{key_object_att}_#{extra}"]
          element_id = "#{params_prefix}_#{object}_#{key}_#{extra}"
        end
      else
        if extra.nil?
          element_name = "#{params_prefix}[#{object}][#{key}]"
          element_value = @params[params_prefix][object][key]
          element_id = "#{params_prefix}_#{object}_#{key}"
        else
          element_name = "#{params_prefix}[#{object}][#{key}_#{extra}]"
          element_value = @params[params_prefix][object]["#{key}_#{extra}".to_sym]
          element_id = "#{params_prefix}_#{object}_#{key}_#{extra}"
        end
      end

      element_data = {}
      element_data[:label_text]     = t("#{key.to_s.humanize}#{extra ? "_#{extra}" : ""}".to_s.titleize) + ": "
      element_data[:element_id]     = element_id
      element_data[:element_name]   = element_name
      element_data[:element_value]  = element_value
      element_data
    end
  end
end