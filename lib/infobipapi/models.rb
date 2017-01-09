require_relative 'objects'

# ----------------------------------------------------------------------------------------------------
# Generic:
# ----------------------------------------------------------------------------------------------------

module InfobipApi


    class InfobipApiError < InfobipApiModel

        infobipapi_attr_accessor :message_id, FieldConversionRule.new('requestError.serviceException.messageId | requestError.policyException.messageId')
        infobipapi_attr_accessor :text, FieldConversionRule.new('requestError.serviceException.text | requestError.policyException.text')
        infobipapi_attr_accessor :variables, FieldConversionRule.new('requestError.serviceException.variables | requestError.policyException.variables')

    end

    class GenericObject < InfobipApiModel

        # FIXME: WIthout this it is not a valid model
        infobipapi_attr_accessor :ignore, FieldConversionRule.new(:ignore)

    end

    # ----------------------------------------------------------------------------------------------------
    # Messaging:
    # ----------------------------------------------------------------------------------------------------


    class AuthenticationAnswer < InfobipApiModel

        infobipapi_attr_accessor :token, FieldConversionRule.new

    end

    class Language < InfobipApiModel

      infobipapi_attr_accessor :language_code, FieldConversionRule.new(:languageCode)
      infobipapi_attr_accessor :use_single_shift, FieldConversionRule.new(:useSingleShift)
      infobipapi_attr_accessor :use_locking_shift, FieldConversionRule.new(:useLockingShift)

    end

    class StatusAnswer < InfobipApiModel

        infobipapi_attr_accessor :group_id, FieldConversionRule.new(:groupId)
        infobipapi_attr_accessor :group_name, FieldConversionRule.new(:groupName)
        infobipapi_attr_accessor :id, FieldConversionRule.new()
        infobipapi_attr_accessor :name, FieldConversionRule.new()
        infobipapi_attr_accessor :descripton, FieldConversionRule.new()

    end

    class MessageAnswer < InfobipApiModel

      infobipapi_attr_accessor :to, FieldConversionRule.new()
      infobipapi_attr_accessor :status, ObjectFieldConverter.new(StatusAnswer, 'status')
      infobipapi_attr_accessor :sms_count, FieldConversionRule.new(:smsCount)
      infobipapi_attr_accessor :message_id, FieldConversionRule.new(:messageId)

    end

    class SimpleTextSMSRequest < InfobipApiModel

        infobipapi_attr_accessor :from, FieldConversionRule.new()
        infobipapi_attr_accessor :to, FieldConversionRule.new()
        infobipapi_attr_accessor :text, FieldConversionRule.new()

    end

    class SimpletextSMSAnswer < InfobipApiModel
      infobipapi_attr_accessor :messages, ObjectArrayConversionRule.new(MessageAnswer, 'messages')
    end

    class AdvancedTextSMSRequest < SimpleTextSMSRequest

        infobipapi_attr_accessor :bulk_id, FieldConversionRule.new(:bulkId)
        infobipapi_attr_accessor :message_id, FieldConversionRule.new(:messageId)
        infobipapi_attr_accessor :flash, FieldConversionRule.new()
        infobipapi_attr_accessor :transliteration, FieldConversionRule.new()
        infobipapi_attr_accessor :language_code, FieldConversionRule.new(:languageCode)
        infobipapi_attr_accessor :intermediate_report, FieldConversionRule.new(:intermediateReport)
        infobipapi_attr_accessor :notify_url, FieldConversionRule.new(:notifyUrl)
        infobipapi_attr_accessor :notify_content_type, FieldConversionRule.new(:notifyContentType)
        infobipapi_attr_accessor :callback_data, FieldConversionRule.new(:callbackData)
        infobipapi_attr_accessor :language, ObjectFieldConverter.new(Language,'language')

    end

    class ResourceReference < InfobipApiModel

        infobipapi_attr_accessor :client_correlator, PartOfUrlFieldConversionRule.new('resourceReference.resourceURL',-2)

    end

    class DeliveryInfo < InfobipApiModel

        infobipapi_attr_accessor :address, FieldConversionRule.new(:address)
        infobipapi_attr_accessor :delivery_status, FieldConversionRule.new(:deliveryStatus)

    end

    class DeliveryInfoList < InfobipApiModel

        infobipapi_attr_accessor :delivery_info, ObjectArrayConversionRule.new(DeliveryInfo, 'deliveryInfoList.deliveryInfo')

    end

    class DeliveryInfoNotification < InfobipApiModel

        infobipapi_attr_accessor :delivery_info, ObjectFieldConverter.new(DeliveryInfo, 'deliveryInfoNotification.deliveryInfo')
        infobipapi_attr_accessor :callback_data, FieldConversionRule.new('deliveryInfoNotification.callbackData')

    end

    # ----------------------------------------------------------------------------------------------------
    # HLR:
    # ----------------------------------------------------------------------------------------------------

    class ServingMccMnc < InfobipApiModel

        infobipapi_attr_accessor :mcc, FieldConversionRule.new(:mcc)
        infobipapi_attr_accessor :mnc, FieldConversionRule.new(:mnc)

    end

    class TerminalRoamingExtendedData < InfobipApiModel

        infobipapi_attr_accessor :destination_address, FieldConversionRule.new('destinationAddress')
        infobipapi_attr_accessor :status_id, FieldConversionRule.new('statusId')
        infobipapi_attr_accessor :done_time, FieldConversionRule.new('doneTime')
        infobipapi_attr_accessor :price_per_message, FieldConversionRule.new('pricePerMessage')
        infobipapi_attr_accessor :mcc_mnc, FieldConversionRule.new('mccMnc')
        infobipapi_attr_accessor :serving_msc, FieldConversionRule.new('servingMsc')
        infobipapi_attr_accessor :censored_serving_msc, FieldConversionRule.new('censoredServingMsc')
        infobipapi_attr_accessor :gsm_error_code, FieldConversionRule.new('gsmErrorCode')
        infobipapi_attr_accessor :original_network_name, FieldConversionRule.new('originalNetworkName')
        infobipapi_attr_accessor :ported_network_name, FieldConversionRule.new('portedNetworkName')
        infobipapi_attr_accessor :serving_hlr, FieldConversionRule.new('servingHlr')
        infobipapi_attr_accessor :imsi, FieldConversionRule.new('imsi')
        infobipapi_attr_accessor :original_network_prefix, FieldConversionRule.new('originalNetworkPrefix')
        infobipapi_attr_accessor :original_country_prefix, FieldConversionRule.new('originalCountryPrefix')
        infobipapi_attr_accessor :original_country_name, FieldConversionRule.new('originalCountryName')
        infobipapi_attr_accessor :is_number_ported, FieldConversionRule.new('isNumberPorted')
        infobipapi_attr_accessor :ported_network_prefix, FieldConversionRule.new('portedNetworkPrefix')
        infobipapi_attr_accessor :ported_country_prefix, FieldConversionRule.new('portedCountryPrefix')
        infobipapi_attr_accessor :ported_country_name, FieldConversionRule.new('portedCountryName')
        infobipapi_attr_accessor :number_in_roaming, FieldConversionRule.new('numberInRoaming')

    end

    class TerminalRoamingStatus < InfobipApiModel

        infobipapi_attr_accessor :servingMccMnc, ObjectFieldConverter.new(ServingMccMnc, 'servingMccMnc')
        infobipapi_attr_accessor :address, FieldConversionRule.new()
        infobipapi_attr_accessor :currentRoaming, FieldConversionRule.new('currentRoaming')
        infobipapi_attr_accessor :resourceURL, FieldConversionRule.new('resourceURL')
        infobipapi_attr_accessor :retrievalStatus, FieldConversionRule.new('retrievalStatus')
        infobipapi_attr_accessor :callbackData, FieldConversionRule.new('callbackData')
        infobipapi_attr_accessor :extendedData, ObjectFieldConverter.new(TerminalRoamingExtendedData, 'extendedData')

    end


    class TerminalRoamingStatusNotification < InfobipApiModel

        infobipapi_attr_accessor :delivery_info, ObjectFieldConverter.new(TerminalRoamingStatus, 'terminalRoamingStatusList.roaming')
        infobipapi_attr_accessor :callback_data, FieldConversionRule.new('terminalRoamingStatusList.roaming.callbackData')

    end

    # ----------------------------------------------------------------------------------------------------
    # Customer profile:
    # ----------------------------------------------------------------------------------------------------

    class CustomerProfile < InfobipApiModel

        infobipapi_attr_accessor :id, FieldConversionRule.new()
        infobipapi_attr_accessor :username, FieldConversionRule.new()
        infobipapi_attr_accessor :forename, FieldConversionRule.new()
        infobipapi_attr_accessor :surname, FieldConversionRule.new()
        infobipapi_attr_accessor :street, FieldConversionRule.new()
        infobipapi_attr_accessor :city, FieldConversionRule.new()
        infobipapi_attr_accessor :zip_code, FieldConversionRule.new('zipCode')
        infobipapi_attr_accessor :telephone, FieldConversionRule.new()
        infobipapi_attr_accessor :gsm, FieldConversionRule.new()
        infobipapi_attr_accessor :fax, FieldConversionRule.new()
        infobipapi_attr_accessor :email, FieldConversionRule.new()
        infobipapi_attr_accessor :msn, FieldConversionRule.new()
        infobipapi_attr_accessor :skype, FieldConversionRule.new()
        infobipapi_attr_accessor :country_id, FieldConversionRule.new('countryId')
        infobipapi_attr_accessor :timezone_id, FieldConversionRule.new('timezoneId')
        infobipapi_attr_accessor :primary_language_id, FieldConversionRule.new('primaryLanguageId')
        infobipapi_attr_accessor :secondary_language_id, FieldConversionRule.new('secondaryLanguageId')

    end

    class Currency < InfobipApiModel

        infobipapi_attr_accessor :id, FieldConversionRule.new()
        infobipapi_attr_accessor :currency_name, FieldConversionRule.new('currencyName')
        infobipapi_attr_accessor :symbol, FieldConversionRule.new()

    end

    class Currency < InfobipApiModel

        infobipapi_attr_accessor :id, FieldConversionRule.new()
        infobipapi_attr_accessor :currency_name, FieldConversionRule.new('currencyName')
        infobipapi_attr_accessor :symbol, FieldConversionRule.new()

    end

    class AccountBalance < InfobipApiModel

        infobipapi_attr_accessor :balance, FieldConversionRule.new()
        infobipapi_attr_accessor :currency, ObjectFieldConverter.new(Currency)

    end

end
