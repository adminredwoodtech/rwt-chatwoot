# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  private

  # Meta may omit both wa_id and from for username-enabled users. A BSUID is
  # an opaque, business-scoped address, never a phone number or a username.
  def set_contact_from_message
    details = @processed_params[:contacts]&.first || {}
    message = messages_data.first
    bind_cloud_contact(details[:wa_id].presence || message[:from],
                       details[:user_id].presence || message[:from_user_id], details.dig(:profile, :name))
    update_contact_with_profile_name(details) if message[:from].present?
  end

  def set_contact_from_echo
    message = messages_data.first
    bind_cloud_contact(message[:to], message[:to_user_id], nil)
  end

  def bind_cloud_contact(phone, user_id, name)
    validate_cloud_user_id!(user_id)
    waid = processed_waid(phone) if phone.present?
    source = user_id.presence || waid
    raise ArgumentError, 'WhatsApp message has no sender identity' if source.blank?

    @contact_inbox = find_cloud_contact_inbox(source, waid, phone) || build_cloud_contact_inbox(source, phone, name)
    update_cloud_identity(phone, user_id)
  end

  def update_cloud_identity(phone, user_id)
    @contact_inbox.update!(source_id: user_id) if user_id.present? && @contact_inbox.source_id != user_id
    @contact = @contact_inbox.contact
    @contact.update!(phone_number: "+#{phone}") if phone.present? && @contact.phone_number.blank?
  end

  def validate_cloud_user_id!(user_id)
    return if user_id.blank? || RegexHelper::WHATSAPP_BSUID_REGEX.match?(user_id)

    raise ArgumentError, 'Invalid WhatsApp business-scoped user ID'
  end

  def find_cloud_contact_inbox(source, waid, phone)
    # Retain the conversation when Meta supplies both identities during the
    # transition from phone-based messaging. Never match by display name.
    existing = inbox.contact_inboxes.find_by(source_id: source)
    existing ||= inbox.contact_inboxes.find_by(source_id: waid) if waid.present?
    return existing if existing || phone.blank?

    inbox.contact_inboxes.joins(:contact).find_by(contacts: { phone_number: "+#{phone}" })
  end

  def build_cloud_contact_inbox(source, phone, name)
    phone_number = "+#{phone}" if phone.present?
    ::ContactInboxWithContactBuilder.new(
      source_id: source, inbox: inbox,
      contact_attributes: { name: name.presence || phone_number, phone_number: phone_number }.compact
    ).perform
  end

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )

    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?

    return unless url_response.success?

    downloaded_file = Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers)
    # WhatsApp Cloud sends the original filename in the payload; preserve it so accented
    # names keep their correct extension instead of relying on the mangled remote metadata.
    filename = attachment_payload[:filename]
    downloaded_file.define_singleton_method(:original_filename) { filename } if filename.present?
    downloaded_file
  end
end
