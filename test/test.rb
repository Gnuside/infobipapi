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
        refute_instance_of(InfobipApi::InfobipApiError, @@sms_connector)
    end

    def test_a_sms_usage_single_gsm7
      test_sms = [
        "Hello",
        "Hello, are you ok ?",
        "Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:gsm7, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        assert_equal(160, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
        assert_equal(1, usage[:number_of_sms], "Failed number of SMS on message '#{message}'")
      }
    end

    def test_a_sms_usage_multi_gsm7
      test_sms = [
        "Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello ",
        "Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? ",
        "Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:gsm7, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        assert_equal(153, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
        assert_equal(
          (message.length.to_f / 153.0).ceil,
          usage[:number_of_sms],
          "Failed number of SMS on message #{message}")
      }
    end

    def test_a_sms_usage_single_utf8
      test_sms = [
        "Hello č",
        "Hello, are you ok ? č",
        "Bonjour, es-tu assoiffé ? œŒ"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:unicode, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        assert_equal(70, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
        assert_equal(1, usage[:number_of_sms], "Failed number of SMS on message '#{message}'")
      }
    end

    def test_a_sms_usage_multi_utf8
      test_sms = [
        "Hellœ Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello ",
        "Hellœ, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? ",
        "Bœnjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:unicode, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        assert_equal(67, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
        assert_equal(
          (message.length.to_f / 67.0).ceil,
          usage[:number_of_sms],
          "Failed number of SMS on message #{message}")
      }
    end

    # use prefix test_b for any function that needs to be run after test_a_login
    def test_b_single_text_sms_00001
        sms = InfobipApi::SimpleTextSMSRequest.new
        sms.from = 'InfobipApiRuby'
        sms.to = NUMBERS[0]
        sms.text = "Unit Testing: #{__method__}"
        response = @@sms_connector.single_text_sms(sms)
        refute_instance_of(InfobipApi::InfobipApiError, response)
        assert_equal(response.messages.length, 1)
    end

    def test_b_single_text_sms_0000n
        sms = InfobipApi::SimpleTextSMSRequest.new
        sms.from = 'InfobipApiRuby'
        sms.to = NUMBERS
        sms.text = "Unit Testing: #{__method__}"
        response = @@sms_connector.single_text_sms(sms)
        refute_instance_of(InfobipApi::InfobipApiError, response)
        assert_equal(response.messages.length, NUMBERS.length)
    end

#    def test_b_single_text_sms_03000
#        sms = InfobipApi::SimpleTextSMSRequest.new
#        sms.from = 'InfobipApiRuby'
#        sms.to = (NUMBERS[0].to_i..(NUMBERS[0].to_i + 2999)).to_a
#        sms.text = "Unit Testing: #{__method__}"
#        response = @@sms_connector.single_text_sms(sms)
#        refute_instance_of(InfobipApi::InfobipApiError, response)
#        assert_equal(response.messages.length, 3000)
#    end


#    def test_b_single_text_sms_10000
#        sms = InfobipApi::SimpleTextSMSRequest.new
#        sms.from = 'InfobipApiRuby'
#        sms.to = (NUMBERS[0].to_i..(NUMBERS[0].to_i + 9999)).to_a
#        sms.text = "Unit Testing: #{__method__}"
#        response = @@sms_connector.single_text_sms(sms)
#        refute_instance_of(InfobipApi::InfobipApiError, response)
#        assert_equal(response.messages.length, 10000)
#    end

    def test_b_multiple_text_sms_00001
      smss = []
      NUMBERS.each { |num|
        sms = InfobipApi::SimpleTextSMSRequest.new
        sms.from = 'InfobipApiRuby'
        sms.to = num
        sms.text = "Unit Testing: #{__method__} for '#{num}'"
        smss.push sms
      }
      response = @@sms_connector.multiple_text_sms(smss)
      refute_instance_of(InfobipApi::InfobipApiError, response)
      assert_equal(smss.length, response.messages.length)
    end

    def test_b_single_utf8_sms_00001
      sms = InfobipApi::SimpleTextSMSRequest.new
      sms.from = 'InfobipApiRuby'
      sms.to = NUMBERS[0]
      sms.text = "Unit Testing: #{__method__}"
      response = @@sms_connector.single_utf8_sms(sms)
      refute_instance_of(InfobipApi::InfobipApiError, response)
      assert_equal(response.messages.length, 1)
    end

    def test_b_single_utf8_sms_0000n
      sms = InfobipApi::SimpleTextSMSRequest.new
      sms.from = 'InfobipApiRuby'
      sms.to = NUMBERS
      sms.text = "Unit Testing: #{__method__}"
      response = @@sms_connector.single_utf8_sms(sms)
      refute_instance_of(InfobipApi::InfobipApiError, response)
      assert_equal(response.messages.length, NUMBERS.length)
    end

    def test_b_multiple_utf8_sms_00001
      smss = []
      NUMBERS.each { |num|
        sms = InfobipApi::SimpleTextSMSRequest.new
        sms.from = 'InfobipApiRuby'
        sms.to = num
        sms.text = "Unit Testing: #{__method__} for '#{num}'"
        smss.push sms
      }
      responses = @@sms_connector.multiple_utf8_sms(smss)
      assert_equal(2, responses.length)
      refute_instance_of(InfobipApi::InfobipApiError, responses[0])
      refute_instance_of(InfobipApi::InfobipApiError, responses[1])
      assert_equal(smss.length, responses[0].messages.length + responses[1].messages.length)
    end

    def test_b_gsm7_cmp_sms_usage_to_realone
      sms = InfobipApi::SimpleTextSMSRequest.new
      sms.from = 'InfobipApiRuby'
      sms.to = NUMBERS[0]
      sms.text = "Unit Testing: #{__method__}"
      test_sms = [
        "Hello",
        "Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? ",
        "Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:gsm7, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        if message.length > 160 then
          assert_equal(153, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(
            (message.length.to_f / 153.0).ceil,
            usage[:number_of_sms],
            "Failed number of SMS on message '#{message}'")
        else
          assert_equal(160, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(1, usage[:number_of_sms], "Failed number of SMS on message '#{message}'")
        end
        sms.text = message
        response = @@sms_connector.single_text_sms(sms)
        refute_instance_of(InfobipApi::InfobipApiError, response)
        assert_equal(1, response.messages.length)
        assert_equal(response.messages[0].sms_count, usage[:number_of_sms], "Failed to match computed usage and API measurement on message '#{message}'")
      }
    end

    def test_b_utf8_cmp_sms_usage_to_realone
      sms = InfobipApi::SimpleTextSMSRequest.new
      sms.from = 'InfobipApiRuby'
      sms.to = NUMBERS[0]
      sms.text = "Unit Testing: #{__method__}"
      test_sms = [
        "Hello œ Œ",
        "Hello œ Œ, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? ",
        "Bonjour œ Œ, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:unicode, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        if message.length > 70 then
          assert_equal(67, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(
            (message.length.to_f / 67.0).ceil,
            usage[:number_of_sms],
            "Failed number of SMS on message '#{message}'")
        else
          assert_equal(70, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(1, usage[:number_of_sms], "Failed number of SMS on message '#{message}'")
        end
        sms.text = message
        response = @@sms_connector.single_utf8_sms(sms)
        refute_instance_of(InfobipApi::InfobipApiError, response)
        assert_equal(1, response.messages.length)
        assert_equal(response.messages[0].sms_count, usage[:number_of_sms], "Failed to match computed usage and API measurement on message '#{message}'")
      }
    end

    def test_b_utf8_as_gsm7_cmp_sms_usage_to_realone
      sms = InfobipApi::SimpleTextSMSRequest.new
      sms.from = 'InfobipApiRuby'
      sms.to = NUMBERS[0]
      sms.text = "Unit Testing: #{__method__}"
      test_sms = [
        "Hello",
        "Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? Hello, are you ok ? ",
        "Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ? Bonjour, es-tu assoiffé ?"
      ].each { |message|
        usage = @@sms_connector.compute_sms_usage(message)
        assert_equal(:gsm7, usage[:format], "Failed to compute the right format on message '#{message}'")
        assert_equal(message.length, usage[:length], "Failed length on message '#{message}'")
        if message.length > 160 then
          assert_equal(153, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(
            (message.length.to_f / 153.0).ceil,
            usage[:number_of_sms],
            "Failed number of SMS on message '#{message}'")
        else
          assert_equal(160, usage[:length_by_sms], "Failed length by SMS on message '#{message}'")
          assert_equal(1, usage[:number_of_sms], "Failed number of SMS on message '#{message}'")
        end
        sms.text = message
        response = @@sms_connector.single_utf8_sms(sms)
        refute_instance_of(InfobipApi::InfobipApiError, response)
        assert_equal(1, response.messages.length)
        assert_equal(response.messages[0].sms_count, usage[:number_of_sms], "Failed to match computed usage and API measurement on message '#{message}'")
      }
    end

end
