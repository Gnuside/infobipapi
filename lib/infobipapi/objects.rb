# vim: set sw=4 ts=4 et :

=begin
require_relative 'rubygems'
require_relative 'ruby-debug'
=end

require_relative 'utils'

module InfobipApi

    class FieldConversionRule

        attr_accessor :object_field_name
        attr_accessor :json_field_name

        def initialize(json_field_name=nil)
            @json_field_name = json_field_name
            @object_field_name = nil
        end

        def from_json(value)
            value
        end

        def to_json(value)
            value
        end

    end


    class ObjectFieldConverter < FieldConversionRule

        def initialize(classs, json_field_name=nil)
            super(json_field_name)
            @classs = classs
        end

        def from_json(value)
            if value == nil
                return nil
            end

            return Conversions.from_json(@classs, value, nil)
        end

        def to_json(value)

            # TODO
        end

    end

    class ObjectArrayConversionRule < FieldConversionRule

        def initialize(classs, json_field_name = nil)
            super(json_field_name)
            @classs = classs
        end

        def from_json(values)
            if not values
                return []
            end

            result = []

            for value in values
                result.push(Conversions.from_json(@classs, value, nil))
            end

            return result
        end

        def to_json(value)
            # TODO
        end

    end

    class LastPartOfUrlFieldConversionRule < FieldConversionRule

        def initialize(json_field_name: nil)
            super(json_field_name)
        end

        def from_json(value)
            if ! value
                return nil
            end

            parts = value.split('/')

            parts[-1]
        end

        def to_json(value)
            value
        end

    end

    class PartOfUrlFieldConversionRule < FieldConversionRule
        def initialize(json_field_name=nil, part_index=nil)
            super(json_field_name)
            @part_index = part_index;
        end

        def from_json(value)
            if ! value
                return nil
            end

            parts = value.split('/')

            parts[@part_index]
        end

        def to_json(value)
            value
        end

    end


    class Conversions

        def self.from_json(classs, json, is_error = nil)
            object = classs.new

            Conversions.fill_from_json(object, json, is_error)
        end

        def self.fill_from_json(object, json, is_error = nil)
            if is_error
                return Conversions.from_json(InfobipApiError, json, false)
            end

            json = JSONUtils.get_json(json)
            conversion_rules = InfobipApiAccessorModifier.get_field_conversion_rules(object.class)
            for conversion_rule in conversion_rules
                json_value = JSONUtils.get(json, conversion_rule.json_field_name)
                value = conversion_rule.from_json(json_value)
                object.instance_variable_set("@#{conversion_rule.object_field_name}", value)
            end
            object
        end

        def self.to_json
            # TODO(TK)
        end

    end

    module InfobipApiAccessorModifier

        @@field_conversion_rules = {}

        def infobipapi_attr_accessor(attr, field_conversion_rule)
            attr_accessor attr

            field_conversion_rule.object_field_name = attr

            if Utils.empty(field_conversion_rule.json_field_name)
                field_conversion_rule.json_field_name = attr
            end

            if not @@field_conversion_rules.has_key? self then
                @@field_conversion_rules[self] = []
            end

            @@field_conversion_rules[self].push field_conversion_rule
            #puts "field_conversion_rules is now #{@@field_conversion_rules}"
        end

        def InfobipApiAccessorModifier.get_field_conversion_rules(classs)
            @@field_conversion_rules[classs]
        end

    end

    class InfobipApiModel

        extend InfobipApiAccessorModifier

        attr_accessor :exception

        def initialize
        end

        def is_success
            return @exception == nil
        end

    end

end
