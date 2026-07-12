require 'rails_helper'

describe Whatsapp::IncomingMessageServiceHelpers do
  let(:helper_class) do
    Class.new do
      include Whatsapp::IncomingMessageServiceHelpers
    end
  end

  let(:helper) { helper_class.new }

  describe '#format_nfm_reply_content' do
    it 'formats HappSea contact flow fields into readable text' do
      raw = {
        full_name: 'Lujoso Gonzales',
        email: 'admin@lujoso.com',
        phone: '3004441111',
        flow_token: 'happsea_contact'
      }.to_json

      result = helper.format_nfm_reply_content(raw)

      expect(result).to eq(
        "📝 Datos de contacto\n" \
        "• Nombre: Lujoso Gonzales\n" \
        "• Email: admin@lujoso.com\n" \
        "• Teléfono: 3004441111"
      )
    end

    it 'returns the original payload when JSON is invalid' do
      raw = 'not-json'
      expect(helper.format_nfm_reply_content(raw)).to eq(raw)
    end
  end

  describe '#message_content' do
    it 'prefers formatted nfm_reply content over raw JSON' do
      message = {
        interactive: {
          nfm_reply: {
            response_json: {
              full_name: 'Lujoso Gonzales',
              email: 'admin@lujoso.com',
              phone: '3004441111'
            }.to_json
          }
        }
      }

      expect(helper.message_content(message)).to include('📝 Datos de contacto')
      expect(helper.message_content(message)).to include('Lujoso Gonzales')
      expect(helper.message_content(message)).not_to include('flow_token')
    end
  end
end
