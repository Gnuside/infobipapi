InfobipApi ruby client
============================

Basic messaging example
-----------------------

First initialize the messaging client using your username and password:

    sms_connector = InfobipApi::SmsClient.new(username, password)


An exception will be thrown if your username and/or password are incorrect.

Prepare the message:

    sms = InfobipApi::SMSRequest.new
    sms.sender_address = '38598123456'
    sms.address = destination_address
    sms.message = 'Test message'
    sms.callback_data = 'Any string'


Send the message:

    result = sms_connector.send_sms(sms)

    # Store the client correlator to be able to query for the delivery status later:
    client_correlator = result.client_correlator


Later you can query for the delivery status of the message:

    delivery_status = sms_connector.query_delivery_status(client_correlator)


Possible statuses are: **DeliveredToTerminal**, **DeliveryUncertain**, **DeliveryImpossible**, **MessageWaiting** and **DeliveredToNetwork**.

Messaging with notification push example
-----------------------

Same as with the standard messaging example, but when preparing your message:

    sms = InfobipApi::SMSRequest.new
    sms.sender_address = '38598123456'
    sms.address = '38598123456'
    sms.message = 'Test message'
    sms.callback_data = 'Any string'
    sms.notify_url = "http://#{public_ip_address}:#{port}"


When the delivery notification is pushed to your server as a HTTP POST request, you must process the body of the message with the following code:

    delivery_info = InfobipApi::SmsClient.unserialize_delivery_status(body)


Sending message with special characters example
-----------------------

If you want to send message with special characters, this is how you prepare your message:

	#Create Language object
	language = InfobipApi::Language.new

	#set specific language code
	language.language_code = 'TR'

	#use single shift table for specific language ('false' or 'true')
	language.use_single_shift = true

	#use locking shift table for specific language ('false' or 'true')
	language.use_locking_shift = false

	sms = InfobipApi::SMSRequest.new
	sms.sender_address = '38598123456'
	sms.address = destination_address
	sms.message = 'Some text in Turkish'
	sms.callback_data = 'Any string'
	sms.language = language

Currently supported languages (with their language codes) are: `Spanish - "SP"`, `Portuguese - "PT"`, `Turkish - "TR"`.


Testing Library
---------------

To test the library, run :

    API_USERNAME="Toto" API_PASSWORD="Titi" bundle exec ruby test/test.rb

API_USERNAME and API_PASSWORD must be valid account credentials for the Infobip API. For more information, go to https://dev.infobip.com/docs/getting-started

You must also provide a text file containing sms numbers where you can receive messages (one by line) :

    echo "33123456789" > test-numbers.txt
    echo "33012345678" >> test-numbers.txt

These numbers must be in international format (used by the API).


License
-------

This library is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
