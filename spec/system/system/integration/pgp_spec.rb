# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > PGP', type: :system do
  before do
    visit 'system/integration/pgp'
  end

  describe 'adding a new key' do
    let(:key_base)    { 'spec/fixtures/files/pgp/zammad@localhost' }
    let(:key_private) { Rails.root.join("#{key_base}.asc").read }
    let(:key_public)  { Rails.root.join("#{key_base}.pub.asc").read }
    let(:passphrase)  { Rails.root.join("#{key_base}.passphrase").read }
    let(:fingerprint) { Rails.root.join("#{key_base}.fingerprint").read }
    let(:keygrip)     { format('%s %s %s %s %s  %s %s %s %s %s', *fingerprint.scan(%r{.{1,4}})) } # rubocop:disable Style/FormatStringToken

    it 'adds a public key by uploading' do
      click '.js-addKey'

      in_modal do
        find('[type=file]').attach_file "#{key_base}.pub.asc"

        click '.js-submit'
      end

      expect(page).to have_text(keygrip)
        .and have_no_text('Including private key')
    end

    it 'adds a private key by pasting' do
      click '.js-addKey'

      in_modal do
        fill_in 'Paste key', with: key_private
        fill_in 'Passphrase', with: passphrase

        click '.js-submit'
      end

      expect(page).to have_text(keygrip)
        .and have_text('Including private key')
    end

    context 'with an existing key' do
      before do
        create(:pgp_key)
      end

      it 'shows error that fingerprint is already present' do
        click '.js-addKey'

        in_modal do
          fill_in 'Paste key', with: key_public

          click '.js-submit'

          expect(page).to have_text('There is already a PGP key with the same fingerprint.')
        end
      end
    end

    context 'with active domain alias feature', authenticated_as: :authenticate do
      def authenticate
        Setting.set('pgp_recipient_alias_configuration', true)

        true
      end

      it 'adds a private key by pasting and enter domain alias' do
        click '.js-addKey'

        in_modal do
          fill_in 'Paste key', with: key_private
          fill_in 'Passphrase', with: passphrase
          fill_in 'Domain Alias', with: 'simple-example.com'

          click '.js-submit'
        end

        expect(page).to have_text(keygrip)
          .and have_text('Including private key')
          .and have_text('simple-example.com')
      end
    end
  end

  context 'with a private key', authenticated_as: :authenticate do
    let(:pgp_key) { create(:pgp_key, :with_private) }

    def authenticate
      pgp_key

      true
    end

    it 'has download links' do
      click 'td .js-action'

      expect(page).to have_css('[data-table-action="download-private"] a')
        .and have_css('[data-table-action="download-public"] a')
    end

    it 'removes a key' do
      click 'td .js-action'
      click '.js-remove'

      in_modal do
        click '.js-submit'
      end

      expect(page).to have_no_css('td .js-action')
    end
  end

  context 'with group settings', authenticated_as: :authenticate do
    def authenticate
      Setting.set('pgp_config',
                  { group_id: { default_sign: { '1': true }, default_encryption: { '1': false } } })

      true
    end

    it 'manages group settigns' do
      expect(find('select[name="group_id::default_sign::1"]'))
        .to have_css('[selected][value=true]')
      expect(find('select[name="group_id::default_encryption::1"]'))
        .to have_css('[selected][value=false]')

      find('select[name="group_id::default_encryption::1"]')
        .find('option', text: 'yes')
        .select_option

      find('select[name="group_id::default_sign::1"]')
        .find('option', text: 'no')
        .select_option

      find('.js-updateGroup').click

      expect(Setting.get('pgp_config'))
        .to include(
          group_id: include(
            default_sign:       include('1': be_falsey),
            default_encryption: include('1': be_truthy)
          )
        )

    end
  end

  context 'with a never expiring key', authenticated_as: :authenticate do
    let(:pgp_key) { create(:'pgp_key/noexpirepgp1@example.com') }

    def authenticate
      pgp_key

      true
    end

    it 'shows dash instead of a date' do
      expect(page).to have_css("tr[data-id='#{pgp_key.id}'] td:nth-child(5)", text: '-')
    end
  end

  it 'enables PGP integration' do
    click 'label[for=setting-switch]'

    expect(Setting.get('pgp_integration')).to be_truthy
  end
end
