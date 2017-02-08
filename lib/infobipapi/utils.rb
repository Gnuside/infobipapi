# vim: set sw=4 ts=4 et :

#require 'pry'
require 'json'
require 'socket'

module InfobipApi

    class JSONUtils

        def self.get_json(json)
            if json.instance_of? String
                return JSON.parse(json)
            end

            return json
        end

        def self.get(json, field)
            json = JSONUtils.get_json(json)

            if not field
                return nil
            end

            if field.instance_of? Symbol
                field = field.to_s
            end

            if field.include?('|') then
                field_parts = field.split('|')
                for field_part in field_parts
                    value = JSONUtils.get(json, field_part.strip)
                    if value
                        return value
                    end
                end
                return nil
            end

            result = nil
            parts = field.split('.')
            result = json
            for part in parts
                if result == nil
                    return nil
                end

                if part.to_i.to_s == part
                    # Int index => array:
                    result = result[part.to_i]
                else
                    # Hash:
                    result = result[part]
                end
            end

            result
        end

    end

    class Utils

        @@gsm7_set = {
          '@' => 0x00, 'Δ' => 0x10, ' ' => 0x20, '0' => 0x30, '¡' => 0x40, 'P' => 0x50, '¿' => 0x60, 'p' => 0x70,
          '£' => 0x01, '_' => 0x11, '!' => 0x21, '1' => 0x31, 'A' => 0x41, 'Q' => 0x51, 'a' => 0x61, 'q' => 0x71,
          '$' => 0x02, 'Φ' => 0x12, '"' => 0x22, '2' => 0x32, 'B' => 0x42, 'R' => 0x52, 'b' => 0x62, 'r' => 0x72,
          '¥' => 0x03, 'Γ' => 0x13, '#' => 0x23, '3' => 0x33, 'C' => 0x43, 'S' => 0x53, 'c' => 0x63, 's' => 0x73,
          'è' => 0x04, 'Λ' => 0x14, '¤' => 0x24, '4' => 0x34, 'D' => 0x44, 'T' => 0x54, 'd' => 0x64, 't' => 0x74,
          'é' => 0x05, 'Ω' => 0x15, '%' => 0x25, '5' => 0x35, 'E' => 0x45, 'U' => 0x55, 'e' => 0x65, 'u' => 0x75,
          'ù' => 0x06, 'Π' => 0x16, '&' => 0x26, '6' => 0x36, 'F' => 0x46, 'V' => 0x56, 'f' => 0x66, 'v' => 0x76,
          'ì' => 0x07, 'Ψ' => 0x17, '\'' => 0x27, '7' => 0x37, 'G' => 0x47, 'W' => 0x57, 'g' => 0x67, 'w' => 0x77,
          'ò' => 0x08, 'Σ' => 0x18, '(' => 0x28, '8' => 0x38, 'H' => 0x48, 'X' => 0x58, 'h' => 0x68, 'x' => 0x78,
          'Ç' => 0x09, 'Θ' => 0x19, ')' => 0x29, '9' => 0x39, 'I' => 0x49, 'Y' => 0x59, 'i' => 0x69, 'y' => 0x79,
          '\n' => 0x0a, 'Ξ' => 0x1a, '*' => 0x2a, ':' => 0x3a, 'J' => 0x4a, 'Z' => 0x5a, 'j' => 0x6a, 'z' => 0x7a,
          'Ø' => 0x0b, '\a' => 0x1b, '+' => 0x2b, ';' => 0x3b, 'K' => 0x4b, 'Ä' => 0x5b, 'k' => 0x6b, 'ä' => 0x7b,
          'ø' => 0x0c, 'Æ' => 0x1c, ',' => 0x2c, '<' => 0x3c, 'L' => 0x4c, 'Ö' => 0x5c, 'l' => 0x6c, 'ö' => 0x7c,
          '\r' => 0x0d, 'æ' => 0x1d, '-' => 0x2d, '=' => 0x3d, 'M' => 0x4d, 'Ñ' => 0x5d, 'm' => 0x6d, 'ñ' => 0x7d,
          'Å' => 0x0e, 'ß' => 0x1e, '.' => 0x2e, '>' => 0x3e, 'N' => 0x4e, 'Ü' => 0x5e, 'n' => 0x6e, 'ü' => 0x7e,
          'å' => 0x0f, 'É' => 0x1f, '/' => 0x2f, '?' => 0x3f, 'O' => 0x4f, '§' => 0x5f, 'o' => 0x6f, 'à' => 0x7f
        }
        def self.empty(obj)
            if obj == nil
                return true
            end

            if obj.instance_of? Hash or obj.instance_of? Array or obj.instance_of? String
                return obj.size == 0
            end

            return obj == 0
        end

        def self.get_random_string(length, chars)
            if not length
                raise "Invalid random string length: #{length}"
            end
            if not chars
                raise "Invalid random chars: #{chars}"
            end

            result = ''

            length.times do
                result += chars[rand(chars.length - 1), 1]
            end

            result
        end

        def self.get_random_alphanumeric_string(length=10)
            get_random_string(length, 'qwertzuiopasdfghjklyxcvbnm123456789')
        end

        def self.in_gsm7_set?(c)
            @@gsm7_set.has_key?(c)
        end

    end


end
