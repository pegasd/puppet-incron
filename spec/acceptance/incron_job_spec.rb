# frozen_string_literal: true

require 'spec_helper_acceptance'

servicename = case os[:family]
              when 'redhat', 'fedora'
                'incrond'
              else
                'incron'
              end

describe 'incron::job' do
  context 'creates incron::job' do
    pp = <<~'PUPPET'
      file { ['/watched_directory', '/incron_test']:
        ensure => directory,
        mode   => '0777',
        owner  => 'root',
      }

      file { '/usr/local/bin/test_notify':
        ensure  => file,
        mode    => '0775',
        owner   => 'root',
        content => "#!/bin/sh\necho \$1 >> /incron_test/notify\n",
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

    # The module's own job is to render the incrontab entry correctly.
    describe file('/var/spool/incron/root') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{^/watched_directory IN_CLOSE_WRITE /usr/local/bin/test_notify \$#$}) }
    end
  end

  # Skipped on FreeBSD: incron there relies on the libinotify kqueue shim, which
  # does not reliably deliver IN_CLOSE_WRITE, so the event never fires in the CI
  # VM. The module's output is still verified by the incrontab content check above.
  context 'incron job works end to end', unless: freebsd_target? do
    before(:all) do
      # incrond only acts on events once it has (re)loaded the freshly written
      # table, so restart it and give it a moment before triggering the watch.
      # Output goes to /incron_test rather than /tmp: incrond runs under systemd
      # with PrivateTmp, so a /tmp (or /var/tmp) write would be invisible here.
      run_shell("service #{servicename} restart")
      sleep 3
      run_shell('echo hello > /watched_directory/notify_about_me_pretty_plz')
      sleep 5
    end

    describe file('/incron_test/notify') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{^notify_about_me_pretty_plz$}) }
    end
  end

  context 'clean up after myself' do
    pp = <<~PUPPET
      file {
        [
          '/watched_directory',
          '/incron_test',
          '/usr/local/bin/test_notify',
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
      '/watched_directory',
      '/incron_test',
      '/usr/local/bin/test_notify',
    ].each do |cleaned_up_file|
      describe file(cleaned_up_file) do
        it { is_expected.not_to exist }
      end
    end
  end
end
