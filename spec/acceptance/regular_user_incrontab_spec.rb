# frozen_string_literal: true

require 'spec_helper_acceptance'

# Relies on `sudo` (not installed by default on FreeBSD) and Linux incron's
# allow/deny enforcement + exact denial message; revisit for FreeBSD later.
describe 'incrontab(1)', unless: freebsd_target? do
  context 'luke is not ready yet' do
    pp = <<~PUPPET
      package { 'sudo': ensure => present }
      include incron
      user { 'luke': ensure => present }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe command('sudo -u luke env EDITOR=cat incrontab -e') do
      its(:exit_status) { is_expected.to eq 1 }
      its(:stderr) { is_expected.to match(%r{^user 'luke' is not allowed to use incron$}) }
    end
  end

  context 'luke has force' do
    pp = <<~PUPPET
      package { 'sudo': ensure => present }
      class { 'incron':
        allowed_users => ['luke'],
      }
      user { 'luke': ensure => present }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe command('sudo -u luke env EDITOR=cat incrontab -e') do
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  context 'clean up' do
    pp = <<~PUPPET
      package { 'sudo': ensure => absent }
      include incron
      user { 'luke': ensure => absent }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe user('luke') do
      it { is_expected.not_to exist }
    end
  end
end
