# frozen_string_literal: true

require 'spec_helper_acceptance'

etc = freebsd_target? ? '/usr/local/etc' : '/etc'
servicename = case os[:family]
              when 'redhat', 'fedora', 'freebsd'
                'incrond'
              else
                'incron'
              end

describe 'incron' do
  context 'installs?' do
    it 'applies idempotently' do
      idempotent_apply('include incron')
    end

    describe package('incron') do
      it { is_expected.to be_installed }
    end
    describe service(servicename) do
      it { is_expected.to be_running }
    end
    describe file("#{etc}/incron.d") do
      it { is_expected.to be_directory }
    end
  end

  context 'removes?' do
    it 'applies idempotently' do
      idempotent_apply("class { 'incron': ensure => absent }")
    end

    describe package('incron') do
      it { is_expected.not_to be_installed }
    end
    describe service(servicename) do
      it { is_expected.not_to be_running }
    end

    [
      "#{etc}/incron.allow",
      "#{etc}/incron.deny",
      "#{etc}/incron.conf",
      "#{etc}/incron.d",
      '/var/spool/incron',
    ].each do |absent_file|
      describe file(absent_file) do
        it { is_expected.not_to exist }
      end
    end
  end
end
