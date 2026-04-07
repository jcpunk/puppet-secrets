# frozen_string_literal: true

require 'spec_helper'

describe 'secrets::file' do
  context 'with minimal args (path as title)' do
    let(:title) { '/etc/krb5.keytab' }
    let(:params) { { 'content' => 'secret' } }

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('ensure'    => 'file')
        .with('owner'     => 'root')
        .with('group'     => 'root')
        .with('mode'      => '0400')
        .with('force'     => true)
        .with('show_diff' => false)
        .with('backup'    => false)
        .with('content'   => sensitive('secret'))
    }

    it { is_expected.to have_posix_acl_resource_count(0) }
  end

  context 'with Sensitive content' do
    let(:title) { '/etc/krb5.keytab' }
    let(:params) { { 'content' => sensitive('secret') } }

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('show_diff' => false)
        .with('backup'    => false)
        .with('content'   => sensitive('secret'))
    }
    it { is_expected.to have_posix_acl_resource_count(0) }
  end

  context 'with descriptive title and explicit path' do
    let(:title) { 'krb5 keytab for testhost' }
    let(:params) do
      {
        'path'    => '/etc/krb5.keytab',
        'content' => 'secret',
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/etc/krb5.keytab') }
    it { is_expected.not_to contain_file('krb5 keytab for testhost') }
    it { is_expected.to have_posix_acl_resource_count(0) }
  end

  context 'with all file and SELinux attributes' do
    let(:title) { '/etc/krb5.keytab' }
    let(:params) do
      {
        'content'  => 'secret',
        'owner'    => 'root',
        'group'    => 'root',
        'mode'     => '0400',
        'seluser'  => 'system_u',
        'selrole'  => 'object_r',
        'seltype'  => 'krb5_keytab_t',
        'selrange' => 's0',
        'selinux_ignore_defaults' => true,
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('owner'     => 'root')
        .with('group'     => 'root')
        .with('mode'      => '0400')
        .with('ensure'    => 'file')
        .with('show_diff' => false)
        .with('backup'    => false)
        .with('seluser'   => 'system_u')
        .with('selrole'   => 'object_r')
        .with('seltype'   => 'krb5_keytab_t')
        .with('selrange'  => 's0')
        .with('selinux_ignore_defaults' => true)
    }

    it { is_expected.to have_posix_acl_resource_count(0) }
  end

  context 'with integer owner and group' do
    let(:title) { '/etc/krb5.keytab' }
    let(:params) do
      {
        'content' => 'secret',
        'owner'   => 0,
        'group'   => 0,
      }
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file('/etc/krb5.keytab')
        .with('owner' => 0)
        .with('group' => 0)
    }
  end

  context 'with a single posix_acl entry' do
    let(:title) { '/etc/krb5.keytab' }
    let(:params) do
      {
        'content'   => 'secret',
        'posix_acl' => {
          'action'     => 'set',
          'permission' => ['group:wheel:r--'],
        },
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/etc/krb5.keytab') }
    it {
      is_expected.to contain_posix_acl('/etc/krb5.keytab')
        .with('action'     => 'set')
        .with('permission' => ['group:wheel:r--'])
        .that_requires('File[/etc/krb5.keytab]')
    }
  end

  context 'with multiple posix_acl permission entries' do
    let(:title) { '/etc/myapp/db.conf' }
    let(:params) do
      {
        'content'   => 'secret',
        'posix_acl' => {
          'action'     => 'set',
          'permission' => ['group:myapp:r--', 'group:monitoring:r--'],
        },
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/etc/myapp/db.conf') }
    it {
      is_expected.to contain_posix_acl('/etc/myapp/db.conf')
        .with('permission' => ['group:myapp:r--', 'group:monitoring:r--'])
        .that_requires('File[/etc/myapp/db.conf]')
    }
  end

  context 'with explicit path and posix_acl titles agree' do
    let(:title) { 'keytab for testhost' }
    let(:params) do
      {
        'path'      => '/etc/krb5.keytab',
        'content'   => 'secret',
        'posix_acl' => {
          'action'     => 'set',
          'permission' => ['group:wheel:r--'],
        },
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/etc/krb5.keytab') }
    it {
      is_expected.to contain_posix_acl('/etc/krb5.keytab')
        .that_requires('File[/etc/krb5.keytab]')
    }
  end

  context 'with a non-absolute title and no path param' do
    let(:title) { 'not-a-path' }
    let(:params) { { 'content' => 'secret' } }

    it { is_expected.not_to compile }
  end

  context 'with a non-absolute explicit path' do
    let(:title) { 'some descriptor' }
    let(:params) do
      {
        'path'    => 'relative/path',
        'content' => 'secret',
      }
    end

    it { is_expected.not_to compile }
  end
end
