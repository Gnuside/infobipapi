# vim: set sw=4 ts=4 et :

#require 'pry'
require 'net/http'
require 'net/https'
require "base64"
require 'json'
require 'pry'

require_relative 'objects'
require_relative 'models'

module InfobipApi

    class InfobipApiClient

        def initialize(username, password, base_url=nil)
            @username = username
            @password = password
            if base_url
                @base_url = base_url
            else
                @base_url = 'https://api.infobip.com/'
            end

            if @base_url[-1, 1] != '/'
                @base_url += '/'
            end

            @infobipapi_authentication = nil

            login()
        end


        def login()
            params = {
              'username' => @username,
              'password' => @password,
            }

            is_success, result = execute_POST('auth/1/session', params)

            filled = fill_infobipapi_authentication(result, is_success)
            #puts ""
            #puts "login: #{filled.inspect}"
            return filled
        end

        def get_or_create_client_correlator(client_correlator=nil)
            if client_correlator
                return client_correlator
            end

            return Utils.get_random_alphanumeric_string()
        end

        def prepare_headers(request)
            request["User-Agent"] = "InfobipApi-#{InfobipApi::VERSION}"
            request["Content-Type"] = "application/json"
            if @infobipapi_authentication and @infobipapi_authentication.token
                request['Authorization'] = "IBSSO #{@infobipapi_authentication.token}"
            else
                auth_string = Base64.encode64("#{@username}:#{@password}").strip
                request['Authorization'] = "Basic #{auth_string}"
            end
        end

        def is_success(response)
            http_code = response.code.to_i
            is_success = 200 <= http_code && http_code < 300

            is_success
        end

        def urlencode(params)
            if Utils.empty(params)
                return ''
            end
            if params.instance_of? String
                return URI.encode(params)
            end
            result = ''
            params.each_key do |key|
                if ! Utils.empty(result)
                    result += '&'
                end
                result += URI.encode(key.to_s) + '=' + URI.encode(params[key].to_s)
            end

            return result
        end

        def execute_GET(url, params=nil)
            execute_request('GET', url, params)
        end

        def execute_POST(url, params=nil)
            execute_request('POST', url, params)
        end

        def execute_request(http_method, url, params)
            rest_url = get_rest_url(url)
            uri = URI(URI.encode(rest_url))

            if Utils.empty(params)
                params = {}
            end

            if http_method == 'GET'
                request = Net::HTTP::Get.new("#{uri.request_uri}?#{urlencode(params)}")
            elsif http_method == 'POST'
              request = Net::HTTP::Post.new(uri.request_uri)
              #binding.pry if params.has_key?(:binary)
              request.body = params.to_json
            end

            http = Net::HTTP.new(uri.host, uri.port)

            use_ssl = rest_url.start_with? "https"
            if use_ssl
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end

            prepare_headers(request)
            response = http.request(request)

            #puts ""
            #puts "response: #{response.inspect}"
            #puts "body: #{response.body}"
            #puts ""

            return is_success(response), response.body
        end

        def get_rest_url(rest_path)
            if not rest_path
                return @base_url
            end

            if rest_path[0, 1] == '/'
                return @base_url + rest_path[1, rest_path.length]
            end

            @base_url + rest_path
        end

        def fill_infobipapi_authentication(json, is_success)
            @infobipapi_authentication = convert_from_json(AuthenticationAnswer, json, !is_success)


            @infobipapi_authentication = nil if @infobipapi_authentication.token.nil? \
              || @infobipapi_authentication.token.length == 0

            @infobipapi_authentication
        end

        def convert_from_json(classs, json, is_error)
            Conversions.from_json(classs, json, is_error)
        end

    end

    class SmsClient < InfobipApiClient

        def initialize(username, password, base_url=nil)
            super(username, password, base_url)
        end

        # send single sms message to one or many destination addresses.
        # cf: https://dev.infobip.com/docs/send-single-sms
        # param fields names:
        # - from: string
        #   Represents sender ID and it can be alphanumeric or numeric. Alphanumeric sender ID length should be between 3 and 11 characters (Example: CompanyName). Numeric sender ID length should be between 3 and 14 characters.
        # - to: `required` array of strings
        #   Array of message destination addresses. If you want to send a message to one destination, a single String is supported instead of an Array. Destination addresses must be in international format (Example: 41793026727).
        # - text: string
        #   Text of the message that will be sent.
        #   (Developper comment: chars must be 7bits or comportment is not predictable on the receiving phones)
        #
        def single_text_sms(sms)
            params = {
              :from => sms.from,
              :to => sms.to,
              :text => sms.text
            }
            is_success, result = execute_POST( "/sms/1/text/single", params )

            convert_from_json(SimpleSMSAnswer, result, !is_success)
        end

        # send multiple sms message to one or many destination addresses.
        # cf: https://dev.infobip.com/docs/send-multiple-sms
        # param fields names, array of :
        # - from: string
        #   Represents sender ID and it can be alphanumeric or numeric. Alphanumeric sender ID length should be between 3 and 11 characters (Example: CompanyName). Numeric sender ID length should be between 3 and 14 characters.
        # - to: `required` array of strings
        #   Array of message destination addresses. If you want to send a message to one destination, a single String is supported instead of an Array. Destination addresses must be in international format (Example: 41793026727).
        # - text: string
        #   Text of the message that will be sent.
        #   (Developper comment: chars must be 7bits or comportment is not predictable on the receiving phones)
        #
        def multiple_text_sms(smss)
            params = {
              :messages => []
            }
            smss.each { |sms|
              params[:messages].push({
                :from => sms.from,
                :to => sms.to,
                :text => sms.text
              })
            }

            is_success, result = execute_POST( "/sms/1/text/multi", params )

            convert_from_json(SimpleSMSAnswer, result, !is_success)
        end

        # .codepoints.map { |c| "%02x %02x" % [c / 256,c % 256] }.join " "

        def compute_sms_usage(str)
          # single SMS length per SMS (GSM7): 160
          # multiple SMS length per SMS (GSM7): 153
          # single SMS length per SMS (UCS-2): 70
          # multiple SMS length per SMS (UCS-2): 67
          sms_lengths = Hash.new
          # ! has_unicode_char
          sms_lengths[false] = Hash.new
          sms_lengths[false][true] = 153 # need_more_than_one_sms
          sms_lengths[false][false] = 160 # ! need_more_than_one_sms
          # has_unicode_char
          sms_lengths[true] = Hash.new
          sms_lengths[true][true] = 67 # need_more_than_one_sms
          sms_lengths[true][false] = 70 # ! need_more_than_one_sms
          {
              :single_gsm7 => 160,
              :multi_gsm7 => 153,
              :single_ucs2 => 70,
              :multi_ucs2 => 67
            }
            has_unicode_char = false
            need_more_than_one_sms = false
            str.each_char { |c|
              if not Utils.in_gsm7_set?(c) then
                has_unicode_char = true
                break
              end
            }
            if has_unicode_char then
              need_more_than_one_sms = str.length > 70
              format = :unicode
            else
              need_more_than_one_sms = str.length > 160
              format = :gsm7
            end
            return {
              :format => format,
              :length => str.length,
              :length_by_sms => sms_lengths[has_unicode_char][need_more_than_one_sms],
              :number_of_sms => (str.length.to_f / sms_lengths[has_unicode_char][need_more_than_one_sms].to_f).ceil
            }
        end

        # send single sms message to one or many destination addresses.
        # TEXT in UTF-8 format if all chars are gsm7 encoding compatible then
        # the SMS is sent with gsm7 encoding. Else it will be sent in Unicode
        # binary format.
        # cf: https://dev.infobip.com/docs/send-single-sms
        # cf: https://dev.infobip.com/docs/send-single-binary-sms
        # param fields names:
        # - from: string
        #   Represents sender ID and it can be alphanumeric or numeric. Alphanumeric sender ID length should be between 3 and 11 characters (Example: CompanyName). Numeric sender ID length should be between 3 and 14 characters.
        # - to: `required` array of strings
        #   Array of message destination addresses. If you want to send a message to one destination, a single String is supported instead of an Array. Destination addresses must be in international format (Example: 41793026727).
        # - text: string utf-8 encoded
        #   Text of the message that will be sent.
        #   (Developper comment: chars must be 7bits or comportment is not predictable on the receiving phones)
        #
        def single_utf8_sms(sms)
          usage = self.compute_sms_usage(sms.text)
          if usage[:format] == :gsm7 then
            params = {
              :from => sms.from,
              :to => sms.to,
              :text => sms.text
            }
            uri = "/sms/1/text/single"
          else
            text_array = sms.text.force_encoding('utf-8').codepoints.map { |c| sprintf('%02x', c) }
            params = {
              :from => sms.from,
              :to => sms.to,
              :binary => {
                :hex => text_array.join(' '),
                :dataCoding => 8,
                :esmClass => 0
              }
            }
            uri = "/sms/1/binary/single"
          end
          is_success, result = execute_POST(uri , params )
          convert_from_json(SimpleSMSAnswer, result, !is_success)
        end

        # send multiple sms message to one or many destination addresses.
        # TEXT in UTF-8 format if all chars are gsm7 encoding compatible then
        # the SMS is sent with gsm7 encoding. Else it will be sent in Unicode
        # binary format.
        # cf: https://dev.infobip.com/docs/send-multiple-sms
        # param fields names, array of :
        # - from: string
        #   Represents sender ID and it can be alphanumeric or numeric. Alphanumeric sender ID length should be between 3 and 11 characters (Example: CompanyName). Numeric sender ID length should be between 3 and 14 characters.
        # - to: `required` array of strings
        #   Array of message destination addresses. If you want to send a message to one destination, a single String is supported instead of an Array. Destination addresses must be in international format (Example: 41793026727).
        # - text: string utf-8 encoded
        #   Text of the message that will be sent.
        #   (Developper comment: chars must be 7bits or comportment is not predictable on the receiving phones)
        #
        # Return an array of 2 results :
        #   one for a /sms/1/text/multi query (nil if none is sent as text)
        #   second one for a /sms/1/binary/multi query (nil if none is sent as binary)
        def multiple_utf8_sms(smss)
            params = {
              :text => {
                :uri => "/sms/1/text/multi",
                :messages => []
              },
              :binary => {
                :uri => "/sms/1/binary/multi",
                :messages => []
              }
            }
            smss.each { |sms|
              usage = self.compute_sms_usage(sms.text)
              if usage[:format] == :gsm7 then
                params[:text][:messages].push({
                  :from => sms.from,
                  :to => sms.to,
                  :text => sms.text
                })
              else
                text_array = sms.text.force_encoding('utf-8').codepoints.map { |c| sprintf('%02x', c) }
                params[:binary][:messages].push({
                  :from => sms.from,
                  :to => sms.to,
                  :binary => {
                    :hex => text_array.join(' '),
                    :dataCoding => 8,
                    :esmClass => 0
                  }
                })
              end
            }

            results = []
            if params[:text][:messages].length > 0 then
              is_success, result = execute_POST( params[:text][:uri] , params[:text][:messages] )
              results.push(convert_from_json(SimpleSMSAnswer, result, !is_success))
            else
              results.push(nil)
            end

            if params[:binary][:messages].length > 0 then
              is_success, result = execute_POST( params[:binary][:uri] , params[:binary][:messages] )
              results.push(convert_from_json(SimpleSMSAnswer, result, !is_success))
            else
              results.push(nil)
            end
            return results
        end

        # Get delivery reports
        # cf: https://dev.infobip.com/docs/delivery-reports
        # parm fields names :
        # - bulkId: string
        #   The ID that uniquely identifies the request. Bulk ID will be received only when you send a message to more than one destination address.
        # - messageId: string
        # The ID that uniquely identifies the message sent.
        # - limit: string
        #   Number of returned delivery reports. Default value is 50. Max number per request is 10000.
        def delivery_reports(params)
            req = {} # safety parameters treatment
            req[:bulkId] = params[:bulkId] if params.has_key?:bulkId
            req[:messageId] = params[:messageId] if params.has_key?:messageId
            req[:limit] = params[:limit] if params.has_key?:limit
            is_success, result = execute_GET("/sms/1/reports", req)
            convert_from_json(DeliveryReportList,result, !is_success)
        end
    end

end

