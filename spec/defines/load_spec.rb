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

  context 'with minimal args' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/krb5.keytab' }

    it { is_expected.to compile }
  end

  context 'not mandatory is not a failure' do
    let(:title) { '/etc/krb5.keytab' }

    let(:params) do
      {
        'mandatory' => false,
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
        'posix_acl' => { 'action' => 'set',
                         'permission' => ['group:wheel:r--'] },
      }
    end

    it { is_expected.to compile }

    it { is_expected.not_to contain_notify('missing /etc/krb5.keytab for testhost.example.com') }

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

    it {
      is_expected.to contain_posix_acl('/etc/krb5.keytab')
        .with('action' => 'set')
        .with('permission' => ['group:wheel:r--'])
    }
  end

  context 'integer ownership' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/krb5.keytab' }
    let(:params) do
      {
        'owner' => 0,
        'group' => 0,
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('owner' => 0)
        .with('group' => 0)
    }
  end

  context 'Try to subscribe to the ssh service' do
    let(:pre_condition) do
      <<-PRECOND
        function file($name) { return 'testdata' }
        service {'sshd.service': }
      PRECOND
    end

    let(:title) { '/./etc/./krb5.keytab' }

    let(:params) do
      {
        'notify_services' => ['sshd.service'],
      }
    end

    # it { pp catalogue.resources }
    it { is_expected.to contain_file('/etc/krb5.keytab').with_notify(['Service[sshd.service]']) }
  end

  context 'Try to subscribe to two services' do
    let(:pre_condition) do
      <<-PRECOND
        function file($name) { return 'testdata' }
        service {'sshd.service': }
        service {'httpd.service': }
      PRECOND
    end

    let(:title) { '/etc/./krb5.keytab' }

    let(:params) do
      {
        'notify_services' => ['sshd.service', 'httpd.service'],
      }
    end

    it { is_expected.to contain_file('/etc/krb5.keytab').with_notify(['Service[sshd.service]', 'Service[httpd.service]']) }
  end

  context 'Try to use relative paths' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/.././krb5.keytab' }

    it { is_expected.to raise_error(Puppet::PreformattedError, %r{forbids use of relative paths}) }
  end

  context 'Try to swap in $::hostname' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/${::hostname}.crt' }

    it { is_expected.to compile }

    it { is_expected.not_to contain_notify('missing /etc/${::hostname}.crt for testhost.example.com') }
    it { is_expected.not_to contain_notify('missing /etc/testhost.crt for testhost.example.com') }

    it { is_expected.not_to contain_file('/etc/${::hostname}.crt') }
    it { is_expected.to contain_file('/etc/testhost.crt') }
  end

  context 'Try to swap in $::fqdn' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/${::fqdn}.crt' }

    it { is_expected.to compile }

    it { is_expected.not_to contain_notify('missing /etc/${::fqdn}.crt for testhost.example.com') }
    it { is_expected.not_to contain_notify('missing /etc/testhost.example.com.crt for testhost.example.com') }

    it { is_expected.not_to contain_file('/etc/${::fqdn}.crt') }
    it { is_expected.to contain_file('/etc/testhost.example.com.crt') }
  end

  context 'Try to swap in $::domain' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/${::domain}.ca' }

    it { is_expected.to compile }

    it { is_expected.not_to contain_notify('missing /etc/${::domain}.ca for testhost.example.com') }
    it { is_expected.not_to contain_notify('missing /etc/example.com.ca for testhost.example.com') }

    it { is_expected.not_to contain_file('/etc/${::domain}.ca') }
    it { is_expected.to contain_file('/etc/example.com.ca') }
  end

  context 'Try to swap in $::hostname $::domain and $::fqdn' do
    let(:pre_condition) do
      'function file($name) { return \'testdata\' }'
    end

    let(:title) { '/etc/${::domain}/${::hostname}/${::fqdn}' }

    it { is_expected.to compile }

    it { is_expected.not_to contain_notify('missing /etc/${::domain}/${::hostname}/${::fqdn} for testhost.example.com') }
    it { is_expected.not_to contain_notify('missing /etc/example.com/testhost/testhost.example.com for testhost.example.com') }

    it { is_expected.not_to contain_file('/etc/${::domain}/${::hostname}/${::fqdn}') }
    it { is_expected.to contain_file('/etc/example.com/testhost/testhost.example.com') }
  end
end
