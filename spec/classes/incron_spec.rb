# frozen_string_literal: true

require 'spec_helper'

describe 'incron' do
  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_class('incron') }

    it { is_expected.to contain_class('incron::install') }
    it { is_expected.to contain_class('incron::config') }
    it { is_expected.to contain_class('incron::service') }

    it { is_expected.to contain_class('incron::purge') }

    describe 'incron::install' do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_package('incron').only_with_ensure(:installed) }
    end

    describe 'incron::config' do
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_file('/etc/incron.conf').only_with(
          ensure:  :file,
          force:   true,
          content: '',
          owner:   'root',
          group:   'root',
          mode:    '0644',
        )
      }
      it {
        is_expected.to contain_file('/etc/incron.allow').only_with(
          ensure:  :file,
          force:   true,
          content: "root\n",
          owner:   'root',
          group:   'root',
          mode:    '0644',
        )
      }
      it {
        is_expected.to contain_file('/etc/incron.deny').only_with(
          ensure:  :absent,
          force:   true,
          content: '',
          owner:   'root',
          group:   'root',
          mode:    '0644',
        )
      }
    end

    describe 'incron::service' do
      on_supported_os.each do |os_name, facts|
        context "on #{os_name}" do
          let(:facts) { facts }

          it { is_expected.to compile.with_all_deps }

          facts[:os]['family'] == 'RedHat' ? service_name = 'incrond' : service_name = 'incron'

          it {
            is_expected.to contain_service('incron')
              .only_with(
                name:       service_name,
                ensure:     :running,
                enable:     true,
                hasrestart: true,
                hasstatus:  true,
              )
          }
        end
      end
    end

    describe 'incron::purge' do
      it {
        is_expected.to contain_file('/etc/incron.d').only_with(
          ensure:  :directory,
          recurse: true,
          purge:   true,
          force:   true,
          owner:   'root',
          group:   'root',
          mode:    '0755',
        )
      }

      it {
        is_expected.to contain_file('/var/spool/incron').only_with(
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
    it { is_expected.to contain_file('/etc/incron.d').with_noop(true) }
    it { is_expected.to contain_file('/var/spool/incron').with_noop(true) }
  end

  context 'with custom allowed_users' do
    let(:params) { { allowed_users: ['nice_guy', 'nice_girl'] } }

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_file('/etc/incron.allow')
        .with_ensure(:file)
        .with_content("root\nnice_guy\nnice_girl\n")
    }
    it { is_expected.to contain_file('/etc/incron.deny').with_ensure(:absent) }
  end

  context 'with custom denied_users' do
    let(:params) { { denied_users: ['bad_guy', 'bad_girl'] } }

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_file('/etc/incron.deny')
        .with_ensure(:file)
        .with_content("bad_guy\nbad_girl\n")
    }
    it { is_expected.to contain_file('/etc/incron.allow').with_ensure(:absent) }
  end

  context 'fail when both allowed_users and denied_users are specified' do
    let(:params) do
      {
        allowed_users: ['nice_guy'],
        denied_users:  ['bad_guy'],
      }
    end

    it { is_expected.to compile.and_raise_error(/Either allowed or denied incron users must be specified, not both./) }
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

    context 'incron::remove' do
      it { is_expected.to contain_package('incron').only_with_ensure(:purged) }

      removed_files = [
        '/etc/incron.d',
        '/etc/incron.conf',
        '/etc/incron.allow',
        '/etc/incron.deny',
        '/var/spool/incron',
      ]

      removed_files.each do |removed_file|
        it { is_expected.to contain_file(removed_file).only_with(ensure: :absent, force: true) }
      end

      it { is_expected.to contain_service('incron').with_ensure(:stopped).with_provider(:systemd) }
    end
  end
end
