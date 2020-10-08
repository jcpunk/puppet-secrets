# frozen_string_literal: true

require 'spec_helper'

describe 'secrets::load' do
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
      let(:title) { '/etc/krb5.keytab' }

      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end

  # context 'Minimum options' do
  # let(:title) { '/etc/krb5.keytab' }
  # it { is_expected.to compile }
  # end
  #
  # context 'lots of options' do
  # let(:title) { '/etc/krb5.keytab' }
  # let(:params) do
  #   {
  #     'owner' => 'root',
  #     'group' => 'root',
  #     'mode'  => '0400',
  #     'mandatory'  => true,
  #     'secretbase' => '/etc/puppet/secrets',
  #     'posix_acl'  => {'action' => 'set',
  #                      'permission' => ['group:wheel:r--', ],},
  #     'selrange'   => 's0',
  #     'seluser'    => 'system_u',
  #     'selrole'    => 'object_r',
  #     'seltype'    => 'krb5_keytab_t',
  #     'notify_services'         => ['sshd'],
  #     'selinux_ignore_defaults' => false,
  #   }
  # end
  #
  # it { is_expected.to compile }
  # end
end
