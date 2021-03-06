# frozen_string_literal: true

require 'spec_helper_acceptance'

case os[:family]
when 'redhat', 'fedora'
  servicename = 'incrond'
else
  servicename = 'incron'
end

describe 'incron' do
  context 'installs?' do
    pp = <<~PUPPET

      include incron

    PUPPET

    apply_and_test_idempotence pp

    # Installs and runs
    describe package('incron') do
      it { is_expected.to be_installed }
    end
    describe service(servicename) do
      it { is_expected.to be_running }
    end
    describe file('/etc/incron.d') do
      it { is_expected.to be_directory }
    end
  end

  context 'removes?' do
    pp = <<~PUPPET
      class { 'incron':
        ensure => absent
      }
    PUPPET

    apply_and_test_idempotence pp

    # Uninstalls and cleans up
    describe package('incron') do
      it { is_expected.not_to be_installed }
    end
    describe service(servicename) do
      it { is_expected.not_to be_running }
    end

    absent_files = [
      '/etc/incron.allow',
      '/etc/incron.deny',
      '/etc/incron.conf',
      '/etc/incron.d',
      '/var/spool/incron',
    ]

    absent_files.each do |absent_file|
      describe file(absent_file) do
        it { is_expected.not_to exist }
      end
    end
  end
end
