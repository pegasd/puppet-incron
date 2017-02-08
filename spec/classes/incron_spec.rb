require 'spec_helper'

describe 'incron' do
  let(:facts) { { :is_virtual => 'false' } }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('incron') }

    it { is_expected.to contain_class('incron::install') }
    it { is_expected.to contain_class('incron::config') }
    it { is_expected.to contain_class('incron::service') }

    describe 'incron::install' do
      it { is_expected.to contain_package('incron').with_ensure(:present) }
    end

    describe 'incron::config' do
      context 'with default parameters' do
        it { is_expected.to contain_file('/etc/incron.conf').with({
          :ensure  => :present,
          :content => /^$/,
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0644',
        }) }
        it { is_expected.to contain_file('/etc/incron.allow').with({
          :ensure  => :present,
          :content => /^$/,
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0640',
        }) }
        it { is_expected.to contain_file('/etc/incron.deny').with({
          :ensure  => :present,
          :content => /^$/,
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0640',
        }) }
        it { is_expected.to contain_file('/etc/incron.d').with({
          :ensure  => :directory,
          :recurse => true,
          :purge   => true,
          :force   => true,
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0644',
        }) }
      end

    end

  end

  context 'with custom dir_mode' do
    let(:params) { { :dir_mode => '0600' } }

    describe 'incron::config' do
      it { is_expected.to contain_file('/etc/incron.d').with({
        :ensure  => :directory,
        :recurse => true,
        :purge   => true,
        :force   => true,
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0600',
      }) }
    end
  end

  context 'with ensure => absent' do
    let(:params) { { :ensure => 'absent' } }

    it { is_expected.to contain_package('incron').with_ensure(:absent) }
    it { is_expected.to contain_file('/etc/incron.d').with({
      :ensure => :absent,
      :force  => true,
    }) }
    it { is_expected.to contain_file('/etc/incron.conf').with_ensure(:absent) }
    it { is_expected.to contain_file('/etc/incron.allow').with_ensure(:absent) }
    it { is_expected.to contain_file('/etc/incron.deny').with_ensure(:absent) }
  end
end