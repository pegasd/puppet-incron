# frozen_string_literal: true

require 'spec_helper_acceptance'

etc = freebsd_target? ? '/usr/local/etc' : '/etc'

describe 'incron::whitelist' do
  pp = <<~PUPPET
    include incron

    incron::whitelist { 'cant_touch_this': }
  PUPPET

  context 'whitelist an incron job in incron.d' do
    it 'applies idempotently' do
      idempotent_apply(pp)
    end
  end

  context 'fake the incron job and see that it is not purged' do
    describe command("echo hello > #{etc}/incron.d/cant_touch_this") do
      its(:exit_status) { is_expected.to eq 0 }
    end

    it 'does not bork the whitelisted incron job' do
      apply_manifest(pp, catch_changes: true)
    end

    describe file("#{etc}/incron.d/cant_touch_this") do
      it { is_expected.to exist }
      its(:content) { is_expected.to eq("hello\n") }
    end
  end
end
