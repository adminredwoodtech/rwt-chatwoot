require 'rails_helper'

describe Whatsapp::IncomingMessageWhatsappCloudService do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:inbox) { channel.inbox }
  let(:bsuid) { 'CO.testUser123' }
  let(:value) do
    { contacts: [{ profile: { name: 'Example customer', username: 'example' }, user_id: bsuid }],
      messages: [{ from_user_id: bsuid, id: SecureRandom.uuid, timestamp: Time.current.to_i.to_s, type: 'text', text: { body: 'hola como estas' } }] }
  end

  # The application exposes its Redis pool as $alfred; replace it only for these
  # examples because MockRedis cannot execute the atomic compare/delete script.
  # rubocop:disable Style/GlobalVars
  around do |example|
    original_pool = $alfred
    namespace = "identity-spec:#{SecureRandom.hex(8)}"
    # MockRedis does not implement Lua. Exercise the actual atomic lock release.
    $alfred = ConnectionPool.new do
      Redis::Namespace.new(namespace, redis: Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/14')))
    end
    example.run
  ensure
    $alfred.shutdown(&:close)
    $alfred = original_pool
  end
  # rubocop:enable Style/GlobalVars

  def ingest(value)
    service_for(value).perform
  end

  def service_for(value)
    params = { entry: [{ changes: [{ value: value }] }] }.with_indifferent_access
    described_class.new(inbox: inbox, params: params)
  end

  it 'creates a contact without inventing a phone and deduplicates repeated delivery' do
    ingest(value)
    ingest(value)
    expect(inbox.messages.count).to eq(1)
    expect(inbox.contact_inboxes.first.source_id).to eq(bsuid)
    expect(inbox.contact_inboxes.first.contact.phone_number).to be_nil
    expect(inbox.messages.first.content).to eq('hola como estas')
  end

  it 'preserves a phone-based conversation when both identities become available' do
    value[:contacts][0][:wa_id] = '573001234567'
    value[:messages][0][:from] = '573001234567'
    phone_value = Marshal.load(Marshal.dump(value))
    phone_value[:contacts][0].delete(:user_id)
    phone_value[:messages][0].delete(:from_user_id)
    ingest(phone_value)
    conversation = inbox.conversations.first
    value[:messages][0][:id] = SecureRandom.uuid
    ingest(value)
    expect(inbox.conversations.pluck(:id)).to eq([conversation.id])
    expect(conversation.contact_inbox.reload.source_id).to eq(bsuid)
    value[:contacts][0].delete(:wa_id)
    value[:messages][0].delete(:from)
    value[:messages][0][:id] = SecureRandom.uuid
    ingest(value)
    expect(inbox.contact_inboxes.count).to eq(1)
    expect(inbox.messages.count).to eq(3)
  end

  it 'releases the dedup lock after a processing failure so the job can retry' do
    service = service_for(value)
    allow(service).to receive(:set_contact).and_raise('temporary failure')
    expect { service.perform }.to raise_error('temporary failure')
    allow(service).to receive(:set_contact).and_call_original
    expect { service.perform }.to change { inbox.messages.count }.by(1)
  end

  it 'rejects malformed identities without creating fake phone contacts' do
    value[:contacts][0][:user_id] = 'not-a-valid-id'
    expect { ingest(value) }.to raise_error(ArgumentError)
    expect(inbox.contact_inboxes.count).to eq(0)
  end

  it 'uses recipient, not to, when replying to a BSUID' do
    ingest(value)
    conversation = inbox.conversations.first
    message = create(:message, conversation: conversation, inbox: inbox, content: 'Hola', message_type: :outgoing)
    stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
      .with { |request| JSON.parse(request.body)['recipient'] == bsuid && !JSON.parse(request.body).key?('to') }
      .to_return(status: 200, body: { messages: [{ id: 'reply-id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
    expect(Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel).send_message(bsuid, message)).to eq('reply-id')
  end

  %w[image interactive template].each do |type|
    it "addresses #{type} messages to the BSUID without a fake phone" do
      ingest(value)
      conversation = inbox.conversations.first
      message = create(:message, conversation: conversation, inbox: inbox, content: 'Hola', message_type: :outgoing)
      if type == 'image'
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      elsif type == 'interactive'
        message.update!(content_type: 'input_select', content_attributes: { items: [{ title: 'Si', value: 'yes' }] })
      end
      stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
        .with do |request|
          payload = JSON.parse(request.body)
          payload['recipient'] == bsuid && !payload.key?('to') && payload['type'] == type
        end
        .to_return(status: 200, body: { messages: [{ id: 'reply-id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
      provider = Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
      result = if type == 'template'
                 provider.send_template(bsuid, { name: 'followup', lang_code: 'es', parameters: [] }, message)
               else
                 provider.send_message(bsuid, message)
               end
      expect(result).to eq('reply-id')
    end
  end
end
