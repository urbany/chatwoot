## the older specs are covered in send in spec/services/whatsapp/send_on_whatsapp_service_spec.rb
require 'rails_helper'

describe Whatsapp::Providers::Whatsapp360DialogService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                     content_attributes: { whatsapp_agent_header_enabled: true })
  end
  let(:phone_messages_url) { 'https://waba.360dialog.io/v1/messages' }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#send_message' do
    context 'when called' do
      before do
        message.sender.update!(display_name: 'Maddu')
      end

      it 'calls message endpoints for normal messages' do
        stub_request(:post, phone_messages_url)
          .with(
            body: {
              to: '+123456789',
              text: { body: "*Maddu:*\n#{message.content}" },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for document attachment messages' do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample.pdf').open, filename: 'sample.pdf', content_type: 'application/pdf')

        stub_request(:post, phone_messages_url)
          .with(
            body: hash_including({
                                   to: '+123456789',
                                   type: 'document',
                                   document: WebMock::API.hash_including(
                                     {
                                       filename: 'sample.pdf',
                                       caption: "*Maddu:*\n#{message.content}",
                                       link: anything
                                     }
                                   )
                                 })
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'falls back to sender name when display_name is blank' do
        message.sender.update!(display_name: '')

        stub_request(:post, phone_messages_url)
          .with(
            body: {
              to: '+123456789',
              text: { body: "*#{message.sender.name}:*\n#{message.content}" },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'does not prefix messages when the dashboard UI flag is missing' do
        api_message = create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox)
        api_message.sender.update!(display_name: 'Maddu')

        stub_request(:post, phone_messages_url)
          .with(
            body: {
              to: '+123456789',
              text: { body: api_message.content },
              type: 'text'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        expect(service.send_message('+123456789', api_message)).to eq 'message_id'
      end
    end
  end

  describe '#sync_templates' do
    context 'when called' do
      it 'updates message_templates_last_updated even when template request fails' do
        stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
          .to_return(status: 401)

        timstamp = whatsapp_channel.reload.message_templates_last_updated
        subject.sync_templates
        expect(whatsapp_channel.reload.message_templates_last_updated).not_to eq(timstamp)
      end
    end
  end

  describe '#send_interactive message' do
    context 'when called' do
      it 'calls message endpoints with button payload when number of items is less than or equal to 3' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   inbox: whatsapp_channel.inbox, content_type: 'input_select',
                                   content_attributes: {
                                     whatsapp_agent_header_enabled: true,
                                     items: [
                                       { title: 'Burito', value: 'Burito' },
                                       { title: 'Pasta', value: 'Pasta' },
                                       { title: 'Sushi', value: 'Sushi' }
                                     ]
                                   })
        message.sender.update!(display_name: 'Maddu')

        stub_request(:post, phone_messages_url)
          .with(
            body: {
              to: '+123456789',
              interactive: {
                type: 'button',
                body: {
                  text: "*Maddu:*\ntest"
                },
                action: '{"buttons":[{"type":"reply","reply":{"id":"Burito","title":"Burito"}},{"type":"reply",' \
                        '"reply":{"id":"Pasta","title":"Pasta"}},{"type":"reply","reply":{"id":"Sushi","title":"Sushi"}}]}'
              }, type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints with list payload when number of items is greater than 3' do
        items = %w[Burito Pasta Sushi Salad].map { |i| { title: i, value: i } }
        message = create(:message, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox,
                                   content_type: 'input_select',
                                   content_attributes: { items: items, whatsapp_agent_header_enabled: true })
        message.sender.update!(display_name: 'Maddu')

        expected_action = {
          button: I18n.t('conversations.messages.whatsapp.list_button_label'),
          sections: [{ rows: %w[Burito Pasta Sushi Salad].map { |i| { id: i, title: i } } }]
        }.to_json

        stub_request(:post, phone_messages_url)
          .with(
            body: {
              to: '+123456789',
              interactive: {
                type: 'list',
                body: {
                  text: "*Maddu:*\ntest"
                },
                action: expected_action
              },
              type: 'interactive'
            }.to_json
          ).to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end
end
