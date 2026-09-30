# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'incron::purge' do
  context 'manage two incron jobs' do
    pp = <<~PUPPET
      include incron

      incron::job { 'job_one':
        path    => '/nonexistant',
        event   => 'IN_MOVED_TO',
        command => '/bin/echo one',
      }

      incron::job { 'job_two':
        path    => '/nonexistant',
        event   => 'IN_MOVED_TO',
        command => '/bin/echo two',
      }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe file('/var/spool/incron/root') do
      it { is_expected.to exist }
      its(:content) { is_expected.to match %r{/bin/echo one$} }
      its(:content) { is_expected.to match %r{/bin/echo two$} }
    end
  end

  context 'manage only one incron job' do
    pp = <<~PUPPET
      include incron

      incron::job { 'job_one':
        path    => '/nonexistant',
        event   => 'IN_MOVED_TO',
        command => '/bin/echo one',
      }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe file('/var/spool/incron/root') do
      it { is_expected.to exist }
      its(:content) { is_expected.to match %r{/bin/echo one$} }
      its(:content) { is_expected.not_to match %r{/bin/echo two$} }
    end
  end
end
