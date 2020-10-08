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
    'function file($name) { return \'testdata\' }'
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'With a secret' do
        let(:params) do
          {
            install: { '/etc/krb5.keytab' => {
              'group'      => 'root',
              'mode'       => '0400',
              'mandatory'  => true,
            } },
            'defaults' => { 'owner' => 'root' },
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_secrets__load('/etc/krb5.keytab').with('owner' => 'root') }
      end
    end
  end
end
