module Filterable::Models
  module Base
    
    def self.included(recipient)
      recipient.extend(ModelClassMethods)
      recipient.class_eval do
        include ModelInstanceMethods
      end
    end

    module ModelClassMethods

      def filters(filters)
        @filters = {}
        @filterable = {}
        @sorted_filterable = []
        @filters = filters

        if filters.is_a?(Array)
          # Ruby 1.8 hash sorting is unpredictable, so we can use an array 
          # to take care of the order and make it behave as expected
          filters.each do |hash|
            prepare_filters(hash)
          end          
        else
          # Filters is a hash, so lets just move on
          prepare_filters(filters)
        end
      end
      
      def prepare_filters(hash)
        hash.map do |key, value| 
          if value.is_a?(Hash)
            value.map do |v_key, v_value|
              @filterable["#{key.to_s.pluralize}.#{v_key}".to_sym] = v_value
              @sorted_filterable << {"#{key.to_s.pluralize}.#{v_key}".to_sym => v_value}
            end
          else
            @filterable[key] = value
              @sorted_filterable << {key => value}            
          end
        end
      end

      def filter_options_for(attribute_name, options = [])
        @filter_options ||= {}
        @filter_options[attribute_name] = options
      end

      def filter_fields_per_column(fields_per_column = 5)
        @fields_per_column = fields_per_column
      end

      def filter(filters = {})
        filters ||= {}
        filters ||= filters[self.to_s.underscore.to_sym] ||= {}
        @filter_conditions = []
        @filter_conditions_values = []
        @current_joins = []

        keys = []

        filters.map do |key, value|

          unless value.blank?

            if value.is_a?(Hash)
              value.keys.collect{|k| k.to_s}.sort.each do |v_key|
                v_key = v_key.to_sym
                v_value = value[v_key]

                keys << "#{key.to_s.pluralize}.#{v_key}".to_sym
              end
              @current_joins = build_joins(@current_joins, filters)
            else
              keys << key.to_sym
            end

            keys.each do |key|

              if key.to_s =~ /_from/
                key = key.to_s.gsub("_from", "").to_sym
              elsif key.to_s =~ /_to/
                key = key.to_s.gsub("_to", "").to_sym
              end

              if @filterable.has_key?(key)
                filter_type = @filterable[key]

                # related object attribute
                if key.to_s =~ /\./
                  v_keys = key.to_s.split(".")
                  if filter_type =~ /_range/
                    value_from  = filters[v_keys[0].singularize.to_sym]["#{v_keys[1]}_from".to_sym]
                    value_to    = filters[v_keys[0].singularize.to_sym]["#{v_keys[1]}_to".to_sym]
                  else
                    value = filters[v_keys[0].singularize.to_sym][v_keys[1].to_sym]
                  end
                else
                  if filter_type =~ /_range/
                    value_from  = filters["#{key}_from".to_sym]
                    value_to    = filters["#{key}_to".to_sym]
                  else
                    value = filters[key]
                  end
                end

                unless value.blank?
                  if value == 'false'
                    value = false
                  end

                  if value == 'true'
                    value = true
                  end

  								compare_key = key.to_s
  								unless key.to_s =~ /\./
  									compare_key = "#{self.name.to_s.tableize}.#{key.to_s}"
  								end
                  case filter_type
                  when "string"
                    @filter_conditions << "#{compare_key} LIKE ?"
                    @filter_conditions_values << "%#{value}%"
                  when "exact_string"
                    @filter_conditions << "#{compare_key} = ?"
                    @filter_conditions_values << value
                  when "date_range", "float_range"
                    if value_from != "" && value_to != ""
                      @filter_conditions << "(#{compare_key} >= ? and #{compare_key} <= ?)"
                      @filter_conditions_values << value_from
                      @filter_conditions_values << value_to
                    elsif value_from != ""
                      @filter_conditions << "#{compare_key} >= ?"
                      @filter_conditions_values << value_from
                    elsif value_to != ""
                      @filter_conditions << "#{compare_key} <= ?"
                      @filter_conditions_values << value_to                      
                    end
                  when "drop_down"
                    @filter_conditions << "#{compare_key} = ?"
                    @filter_conditions_values << value
                  end
                end
              end
            end
          end
        end

        filter_scope = where([@filter_conditions.join(" AND ")] + @filter_conditions_values).group("#{self.name.tableize}.id")
        if @current_joins.any?
          filter_scope = filter_scope.joins(@current_joins)
        end
        
        filter_scope
      end

      def build_joins(current_joins = {}, filters = {})
        @self_object_name = self.name.underscore
        @self_table_name = @self_object_name.pluralize
        @self_filter_joins = []

        filters.map do |key, value|

          if value.is_a?(Hash)
            unless filters_are_empty(value)

              @self_object = self.new

              if @self_object.attributes.include?("#{key}_id")
                # belogns to
  							@self_filter_joins += [key.to_sym]
              else
                @related_object = key.to_s.camelize.constantize.new

                if @related_object.attributes.include?("#{@self_object_name}_id")
                  # has many - need to figure out how to solve it for has one.
                  @self_filter_joins += ["#{key.to_s.pluralize}".to_sym]
                elsif @self_object.methods.include?("#{key}_ids")
                  # has and_belongs_to_many
                  @self_filter_joins += ["#{key.to_s.pluralize}".to_sym]
                end

              end
            end
          end

        end

        if @self_filter_joins.size > 0
          current_joins ||= []
          current_joins += @self_filter_joins
        end

        current_joins
      end

      def filters_are_empty(filters)
        filters.map do |key, value|
          return false unless value.blank?
        end
        true
      end

      def filterable
        @filterable
      end

      def filter_options
        @filter_options
      end

      def fields_per_column
        @fields_per_column ||= 5
      end

      def filters_hash
        @filters
      end

      def sorted_filterable
        @sorted_filterable
      end

    end

    module ModelInstanceMethods
    end
  end    
end