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

  on_supported_os.each do |os, os_facts|
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    context "on #{os} with minimal args" do
      let(:facts) { os_facts }

      let(:title) { '/etc/krb5.keytab' }

      it { is_expected.to compile }
    end
  end

  context 'not mandatory is not a failure' do
    let(:title) { '/etc/krb5.keytab' }

    let(:params) do
      {
        'owner' => 'root',
        'group' => 'root',
        'mode'  => '0400',
        'mandatory'  => false,
        'secretbase' => '/etc/puppet/secrets',
        'seluser'    => 'system_u',
        'selrole'    => 'object_r',
        'seltype'    => 'krb5_keytab_t',
        'selrange'   => 's0',
        'selinux_ignore_defaults' => true,
      }
    end

    it { is_expected.to compile }
  end

  context 'lots of internal options' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/krb5.keytab' }
    let(:params) do
      {
        'owner' => 'root',
        'group' => 'root',
        'mode'  => '0400',
        'mandatory'  => true,
        'secretbase' => '/etc/puppet/secrets',
        'seluser'    => 'system_u',
        'selrole'    => 'object_r',
        'seltype'    => 'krb5_keytab_t',
        'selrange'   => 's0',
        'selinux_ignore_defaults' => true,
      }
    end

    it { is_expected.to compile }
    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('owner' => 'root')
        .with('group' => 'root')
        .with('mode'  => '0400')
        .with('seluser'   => 'system_u')
        .with('selrole'   => 'object_r')
        .with('seltype'   => 'krb5_keytab_t')
        .with('selrange'  => 's0')
        .with('selinux_ignore_defaults' => true)
    }
  end
end

# 'notify_services' => ['sshd'],
# 'posix_acl'  => { 'action' => 'set',
#                   'permission' => ['group:wheel:r--'] },
