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


            @infobipapi_authentication = nil if @infobipapi_authentication.token.nil? || @infobipapi_authentication.token.length == 0

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

        def simple_text_sms(sms)
            params = {
              :from => sms.from,
              :to => sms.to,
              :text => sms.text
            }
            is_success, result = execute_POST( "/sms/1/text", params )

            convert_from_json(SimpletextSMSAnswer, result, !is_success)
        end

    end

end

