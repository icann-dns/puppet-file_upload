# frozen_string_literal: true

require 'spec_helper'

describe 'file_upload::upload' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'XXreplace_meXX' }

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
      # :ensure => "present",
      # :key_dir => "/root/.ssh/",
      # :clean_known_hosts => false,
      # :delete => false,
      # :remove_source_files => false,
      # :patterns => ["*.pcap.bz2", "*.pcap.xz"],
      # :bwlimit => "100",
      # :destination_host => :undef,
      # :destination_path => :undef,
      # :ssh_key_source => :undef,
      # :ssh_user => :undef,
      # :log_file => "/var/log/file_upload-$name.log",
      # :logrotate_enable => true,
      # :logrotate_rotate => "5",
      # :logrotate_size => "100M",
      # :data => "/opt/pcap",

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let(:pre_condition) { "class {'::file_upload': }" }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it do
          is_expected.to compile.with_all_deps
        end

        it do
          is_expected.to contain_cron('file_upload-XXreplace_meXX').with(
            ensure: 'present',
            command: "/usr/bin/flock -n /var/lock/file_upload-XXreplace_meXX.lock /usr/local/bin/file_upload.sh -P '*.pcap.bz2 *.pcap.xz' -s /opt/pcap -k /root/.ssh/XXreplace_meXX -b 100 -L /var/log/file_upload-XXreplace_meXX.log",
          )
        end
      end
    end
  end
end
