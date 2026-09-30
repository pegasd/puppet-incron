# frozen_string_literal: true

require 'spec_helper'

describe 'incron' do
  on_supported_os.each do |os_name, os_facts|
    context "on #{os_name}" do
      let(:facts) { os_facts }

      # FreeBSD keeps incron config under /usr/local/etc and uses the `wheel`
      # group; the per-user spool stays at /var/spool/incron everywhere. The
      # service is `incron` on Debian-family and `incrond` elsewhere.
      freebsd      = os_facts[:os]['family'] == 'FreeBSD'
      etc          = freebsd ? '/usr/local/etc' : '/etc'
      conf_file    = "#{etc}/incron.conf"
      allow_file   = "#{etc}/incron.allow"
      deny_file    = "#{etc}/incron.deny"
      incrond_dir  = "#{etc}/incron.d"
      spool_dir    = '/var/spool/incron'
      root_group   = freebsd ? 'wheel' : 'root'
      service_name = (os_facts[:os]['family'] == 'RedHat') ? 'incrond' : 'incron'

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('incron') }
        it { is_expected.to contain_class('incron::install') }
        it { is_expected.to contain_class('incron::config') }
        it { is_expected.to contain_class('incron::service') }
        it { is_expected.to contain_class('incron::purge') }

        describe 'incron::install' do
          it { is_expected.to contain_package('incron').only_with_ensure(:installed) }
        end

        describe 'incron::config' do
          it {
            is_expected.to contain_file(conf_file).only_with(
              ensure:  :file,
              force:   true,
              content: '',
              owner:   'root',
              group:   root_group,
              mode:    '0644',
            )
          }
          it {
            is_expected.to contain_file(allow_file).only_with(
              ensure:  :file,
              force:   true,
              content: "root\n",
              owner:   'root',
              group:   root_group,
              mode:    '0644',
            )
          }
          it {
            is_expected.to contain_file(deny_file).only_with(
              ensure:  :absent,
              force:   true,
              content: '',
              owner:   'root',
              group:   root_group,
              mode:    '0644',
            )
          }
        end

        describe 'incron::service' do
          it {
            is_expected.to contain_service('incron').only_with(
              name:       service_name,
              ensure:     :running,
              enable:     true,
              hasrestart: true,
              hasstatus:  true,
            )
          }
        end

        describe 'incron::purge' do
          it {
            is_expected.to contain_file(incrond_dir).only_with(
              ensure:  :directory,
              recurse: true,
              purge:   true,
              force:   true,
              owner:   'root',
              group:   root_group,
              mode:    '0755',
            )
          }
          it {
            is_expected.to contain_file(spool_dir).only_with(
              ensure:  :directory,
              recurse: true,
              purge:   true,
              force:   true,
              owner:   'root',
              mode:    '1731',
            )
          }
        end
      end

      context 'with purge_noop => true' do
        let(:params) { { purge_noop: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(incrond_dir).with_noop(true) }
        it { is_expected.to contain_file(spool_dir).with_noop(true) }
      end

      context 'with custom allowed_users' do
        let(:params) { { allowed_users: ['nice_guy', 'nice_girl'] } }

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file(allow_file)
            .with_ensure(:file)
            .with_content("root\nnice_guy\nnice_girl\n")
        }
        it { is_expected.to contain_file(deny_file).with_ensure(:absent) }
      end

      context 'with custom denied_users' do
        let(:params) { { denied_users: ['bad_guy', 'bad_girl'] } }

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file(deny_file)
            .with_ensure(:file)
            .with_content("bad_guy\nbad_girl\n")
        }
        it { is_expected.to contain_file(allow_file).with_ensure(:absent) }
      end

      context 'fail when both allowed_users and denied_users are specified' do
        let(:params) do
          {
            allowed_users: ['nice_guy'],
            denied_users:  ['bad_guy'],
          }
        end

        it { is_expected.to compile.and_raise_error(%r{Either allowed or denied incron users must be specified, not both.}) }
      end

      context 'with custom package version' do
        let(:params) { { package_version: '0.5.12-1' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('incron').with_ensure('0.5.12-1') }
      end

      context 'service management' do
        context 'no management at all' do
          let(:params) { { service_manage: false } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_service('incron') }
        end

        context 'ensure => stopped' do
          let(:params) { { service_ensure: :stopped } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_service('incron').with_ensure(:stopped) }
        end

        context 'enable => false' do
          let(:params) { { service_enable: false } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_service('incron').with_enable(false) }
        end
      end

      context 'with ensure => absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('incron::remove') }

        it { is_expected.not_to contain_class('incron::install') }
        it { is_expected.not_to contain_class('incron::config') }
        it { is_expected.not_to contain_class('incron::service') }

        describe 'incron::remove' do
          it { is_expected.to contain_package('incron').only_with_ensure(:absent) }

          [
            "#{etc}/incron.d",
            conf_file,
            allow_file,
            deny_file,
            spool_dir,
          ].each do |removed_file|
            it { is_expected.to contain_file(removed_file).only_with(ensure: :absent, force: true) }
          end

          # remove.pp branches on service_provider (systemd -> service resource,
          # freebsd -> idempotent exec), so key the expectation off the same fact.
          if os_facts[:service_provider] == 'freebsd'
            it { is_expected.to contain_exec('stop incrond') }
          else
            it { is_expected.to contain_service(service_name).with_ensure(:stopped) }
          end
        end
      end
    end
  end
end
