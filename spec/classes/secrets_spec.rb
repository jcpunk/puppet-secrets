# frozen_string_literal: true

require 'spec_helper'

describe 'secrets' do
  let(:trusted_facts) do
    {
      'hostname' => 'testhost',
      'domain'   => 'example.com',
    }
  end
  let(:node) { 'testhost.example.com' }

  let(:pre_condition) do
    'function binary_file($name) { return \'testdata\' }'
  end

  # it { pp catalogue.resources }

  # The real interesting stuff is all tested in the define
  # This just tests that init.pp takes an install argument
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'With a secret' do
        let(:params) do
          {
            install: { '/etc/krb5.keytab' => {
              'group'      => 'oot',
              'mode'       => '1400',
            } },
            'defaults' => { 'owner' => 'test' },
          }
        end

        it { is_expected.to compile }
        it { is_expected.to have_posix_acl_count(0) }
        it {
          is_expected.to contain_secrets__load('/etc/krb5.keytab')
            .with('owner' => 'test')
            .with('group' => 'oot')
            .with('mode' => '1400')
            .with('mandatory' => true)
        }
      end
    end
  end
end
