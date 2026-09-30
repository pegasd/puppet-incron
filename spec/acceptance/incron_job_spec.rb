# frozen_string_literal: true

require 'spec_helper_acceptance'

etc = freebsd_target? ? '/usr/local/etc' : '/etc'
servicename = case os[:family]
              when 'redhat', 'fedora'
                'incrond'
              else
                'incron'
              end

describe 'incron::job' do
  context 'creates incron::job' do
    pp = <<~PUPPET
      file { '/usr/local/bin/test_notify':
        ensure  => file,
        mode    => '0775',
        owner   => 'root',
        content => "#!/bin/sh\necho $1 >> /tmp/notify\n",
      }

      file { '/watched_directory':
        ensure => directory,
        mode   => '0777',
        owner  => 'root',
      }

      include incron

      incron::job { 'notify_me_please':
        path    => '/watched_directory',
        event   => 'IN_CLOSE_WRITE',
        command => '/usr/local/bin/test_notify $#',
      }
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end
  end

  context 'incron job works' do
    before(:all) do
      # incrond only acts on events once it has (re)loaded the freshly written
      # user table, so restart it and give it a moment before triggering the
      # watched directory.
      run_shell("service #{servicename} restart")
      sleep 3
      run_shell('echo hello > /watched_directory/notify_about_me_pretty_plz')
      sleep 5
    end

    describe file('/tmp/notify') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{^notify_about_me_pretty_plz$}) }
    end
  end

  context 'clean up after myself' do
    pp = <<~PUPPET
      file {
        [
          '/usr/local/bin/test_notify',
          '/watched_directory',
          '/tmp/notify',
        ]:
          ensure  => absent,
          recurse => true,
          force   => true,
      }

      include incron
    PUPPET

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    [
      '/usr/local/bin/test_notify',
      '/watched_directory',
      '/tmp/notify',
      "#{etc}/incron.d/notify_me_please",
    ].each do |cleaned_up_file|
      describe file(cleaned_up_file) do
        it { is_expected.not_to exist }
      end
    end
  end
end
