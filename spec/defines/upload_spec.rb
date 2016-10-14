require 'spec_helper'
require 'pp'

describe 'file_upload::upload' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  let(:title) { 'test_upload' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #:ensure => "present",
      #:key_dir => "/root/.ssh/",
      #:clean_known_hosts => false,
      #:delete => false,
      #:remove_source_files => false,
      #:patterns => ["*.pcap.bz2", "*.pcap.xz"],
      #:bwlimit => "100",
      destination_host: 'upload.example.com',
      destination_path: '/opt/upload',
      ssh_key_source: 'puppet:///modules/module_files/id_rsa',
      ssh_user: 'dns-oarc',
      #:log_file => "/var/log/file_upload-$name.log",
      #:logrotate_enable => true,
      #:logrotate_rotate => "5",
      #:logrotate_size => "100M",
      #:data => "/opt/pcap",

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let (:pre_condition) {
    "class {'::file_upload': }"
  }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('file_upload') }
        
        it do
          is_expected.to contain_file('/root/.ssh/test_upload')
          .with(
            ensure: 'present',
            mode: '0600',
            source: 'puppet:///modules/module_files/id_rsa',
          )
        end
                
        it do
          is_expected.to contain_cron('file_upload-test_upload')
          .with(
            ensure: 'present',
            command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
          )
        end
                
        if facts[:kernel] != 'FreeBSD' then
          it do
            is_expected.to contain_logrotate__rule('file_upload-test_upload')
            .with(
              path: '/var/log/file_upload-test_upload.log',
              rotate: 5,
              size: '100M',
              compress: true,
              create_mode: '0644',
              create: true,
            )
          end
        else
          it do
             is_expected.to_not contain_logrotate__rule('file_upload-test_upload')
          end
        end
      end
      describe 'Change Defaults' do
        context 'ensure' do
          before { params.merge!(ensure: 'absent') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload').with_ensure(
              'absent'
            )
          end
          it do
            is_expected.to contain_file('/root/.ssh/test_upload').with_ensure(
              'absent'
            )
          end
        end
        context 'key_dir' do
          before { params.merge!(key_dir: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foo/bar/test_upload')
            .with(
              ensure: 'present',
              mode: '0600',
              source: 'puppet:///modules/module_files/id_rsa',
            )
          end
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /foo/bar/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'clean_known_hosts' do
          before { params.merge!(clean_known_hosts: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log -C   -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'delete' do
          before { params.merge!(delete: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log  -e  -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'remove_source_files' do
          before { params.merge!(remove_source_files: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log   -E -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'patterns' do
          before { params.merge!(patterns: ['foo', 'bar']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'foo bar\'',
            )
          end
        end
        context 'bwlimit' do
          before { params.merge!(bwlimit: 1234) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 1234 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'destination_host' do
          before { params.merge!(destination_host: 'foobar.example.com') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D foobar.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'destination_path' do
          before { params.merge!(destination_path: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /foo/bar -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'ssh_key_source' do
          before { params.merge!(ssh_key_source: 'puppet:///modules/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/root/.ssh/test_upload')
            .with(
              ensure: 'present',
              mode: '0600',
              source: 'puppet:///modules/foo/bar',
            )
          end
        end
        context 'ssh_user' do
          before { params.merge!(ssh_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u foobar -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'log_file' do
          before { params.merge!(log_file: '/tmp/log') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /opt/pcap -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /tmp/log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
        context 'logrotate_enable' do
          before { params.merge!(logrotate_enable: false) }
          it { is_expected.to compile }
          it do
            is_expected.not_to contain_logrotate__rule('file_upload-test_upload')
          end
        end
        context 'logrotate_rotate' do
          before { params.merge!(logrotate_rotate: 1) }
          it { is_expected.to compile }
          if facts[:kernel] != 'FreeBSD' then
            it do
              is_expected.to contain_logrotate__rule('file_upload-test_upload')
              .with(
                path: '/var/log/file_upload-test_upload.log',
                rotate: 1,
                size: '100M',
                compress: true,
                create_mode: '0644',
                create: true,
              )
            end
          end
        end
        context 'logrotate_size' do
          before { params.merge!(logrotate_size: '1G') }
          it { is_expected.to compile }
          if facts[:kernel] != 'FreeBSD' then
            it do
              is_expected.to contain_logrotate__rule('file_upload-test_upload')
              .with(
                path: '/var/log/file_upload-test_upload.log',
                rotate: '5',
                size: '1G',
                compress: true,
                create_mode: '0644',
                create: true,
              )
            end
          end
        end
        context 'data' do
          before { params.merge!(data: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_cron('file_upload-test_upload')
            .with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/file_upload-test_upload.lock /usr/local/bin/file_upload.sh -s /foo/bar -D upload.example.com -d /opt/upload -u dns-oarc -k /root/.ssh/test_upload -b 100 -L /var/log/file_upload-test_upload.log    -P \'*.pcap.bz2 *.pcap.xz\'',
            )
          end
        end
      end
      describe 'check bad type' do
        context 'ensure' do
          before { params.merge!(ensure: false) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ensure' do
          before { params.merge!(ensure: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'key_dir' do
          before { params.merge!(key_dir: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'clean_known_hosts' do
          before { params.merge!(clean_known_hosts: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'delete' do
          before { params.merge!(delete: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'remove_source_files' do
          before { params.merge!(remove_source_files: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'patterns' do
          before { params.merge!(patterns: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'bwlimit' do
          before { params.merge!(bwlimit: 10001) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'bwlimit' do
          before { params.merge!(bwlimit: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'destination_host' do
          before { params.merge!(destination_host: 'http://foo.bar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'destination_host' do
          before { params.merge!(destination_host: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'destination_path' do
          before { params.merge!(destination_path: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssh_key_source' do
          before { params.merge!(ssh_key_source: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssh_user' do
          before { params.merge!(ssh_user: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'log_file' do
          before { params.merge!(log_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_enable' do
          before { params.merge!(logrotate_enable: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_rotate' do
          before { params.merge!(logrotate_rotate: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logrotate_size' do
          before { params.merge!(logrotate_size: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'data' do
          before { params.merge!(data: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
