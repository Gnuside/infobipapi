lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minitest/autorun'
require 'infobipapi/client'

API_USERNAME = ENV["API_USERNAME"]
API_PASSWORD = ENV["API_PASSWORD"]

if (API_USERNAME.nil? || API_USERNAME == '') || (API_PASSWORD.nil? || API_PASSWORD == '') then
  raise "set environement variable API_USERNAME and API_PASSWORD with an Infobip valid account (see https://dev.infobip.com/docs/getting-started)"
end


NUMBERS = File::readlines(File.expand_path('../../test-numbers.txt', __FILE__)).map { |a| a.strip }

puts ""
puts "Testing API with #{API_USERNAME} / #{API_PASSWORD} credentials"
puts ""
puts "List of numbers used:"
NUMBERS.each { |num|
  puts " - #{num}"
}
puts ""
puts "-------"
puts ""

class InfobipApiTest < MiniTest::Unit::TestCase

    def self.test_order
        return :alpha
    end

    def test_a_empty
        assert_equal InfobipApi::Utils.empty(0), true
        assert_equal InfobipApi::Utils.empty(1), false
        assert_equal InfobipApi::Utils.empty('aaa'), false
        assert_equal InfobipApi::Utils.empty(0.0), true
        assert_equal InfobipApi::Utils.empty([]), true
        assert_equal InfobipApi::Utils.empty([1]), false
        assert_equal InfobipApi::Utils.empty({}), true
        assert_equal InfobipApi::Utils.empty({'a' => 1}), false
        assert_equal InfobipApi::Utils.empty(''), true
    end

    def test_a_json_get
        json = '{"requestError":{"serviceException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":[""]},"policyException":null}}'
        request_error = InfobipApi::JSONUtils.get(json, 'requestError.serviceException.text')
        assert_equal('Request URI missing required component(s): ', request_error)
    end

    def test_a_json_get_hash_result
        json = '{"requestError":{"serviceException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":[""]},"policyException":null}}'
        value = InfobipApi::JSONUtils.get(json, 'requestError.serviceException')
        puts value.inspect
        assert_equal(value, {"messageId"=>"SVC0002", "variables"=>[""], "text"=>"Request URI missing required component(s): "})
    end

    def test_a_json_get_array_in_path
        json = '{"requestError":{"serviceException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":["abc", "cde"]},"policyException":null}}'
        value = InfobipApi::JSONUtils.get(json, 'requestError.serviceException.variables.1')
        assert_equal(value, "cde")
    end

    def test_a_json_get_with_or_paths
        json = '{"requestError":{"serviceException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":["abc", "cde"]},"policyException":null}}'
        value = InfobipApi::JSONUtils.get(json, 'requestError.serviceException.messageId | requestError.policyException.messageId')
        assert_equal(value, "SVC0002")

        json = '{"requestError":{"policyException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":["abc", "cde"]},"serviceException":null}}'
        value = InfobipApi::JSONUtils.get(json, 'requestError.serviceException.messageId | requestError.policyException.messageId')
        assert_equal(value, "SVC0002")
    end

    def test_a_exception_serialization
        json = '{"requestError":{"serviceException":{"text":"Request URI missing required component(s): ","messageId":"SVC0002","variables":[""]},"policyException":null}}'

        sms_exception = InfobipApi::Conversions.from_json(InfobipApi::InfobipApiError, json, nil)

        assert(sms_exception)
        assert_equal(sms_exception.message_id, 'SVC0002')
        assert_equal(sms_exception.text, 'Request URI missing required component(s): ')
    end

    def test_a_exception_object_array
        json = '{"deliveryInfoList":{"deliveryInfo":[{"address":null,"deliveryStatus":"DeliveryUncertain1"},{"address":null,"deliveryStatus":"DeliveryUncertain2"}],"resourceURL":"http://api.infobip.com/sms/1/smsmessaging/outbound/TODO/requests/28drx7ypaqr/deliveryInfos"}}'

        object = InfobipApi::Conversions.from_json(InfobipApi::DeliveryInfoList, json, nil)

        assert(object)
        assert(object.delivery_info)
        assert_equal(2, object.delivery_info.length)
        assert_equal("DeliveryUncertain1", object.delivery_info[0].delivery_status)
        assert_equal("DeliveryUncertain2", object.delivery_info[1].delivery_status)
    end

    def test_a_login
        @@sms_connector = InfobipApi::SmsClient.new(API_USERNAME, API_PASSWORD)
        assert(@@sms_connector)
    end

    # use prefix test_b for any function that needs to be run after test_a_login
    def test_b_simple_sms
        sms = InfobipApi::SimpleTextSMSRequest.new
        sms.from = 'InfobipApiRuby'
        sms.to = NUMBERS[0]
        sms.text = "Unit Testing: #{__method__}"
        puts sms.inspect
        puts @@sms_connector.simple_text_sms(sms).inspect
    end
end
