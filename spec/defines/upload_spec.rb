require 'spec_helper'
require 'shared_contexts'

describe 'file_upload::upload' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

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
      #:ensure => "present",
      #:key_dir => "/root/.ssh/",
      #:clean_known_hosts => false,
      #:delete => false,
      #:remove_source_files => false,
      #:patterns => ["*.pcap.bz2", "*.pcap.xz"],
      #:bwlimit => "100",
      #:destination_host => :undef,
      #:destination_path => :undef,
      #:ssh_key_source => :undef,
      #:ssh_user => :undef,
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
  
  it do
    is_expected.to contain_file("/root/.ssh//$name")
        .with({
          "ensure" => "present",
          "mode" => "0600",
          "source" => :undef,
          })
  end
    
  it do
    is_expected.to contain_cron("file_upload-$name")
        .with({
          "ensure" => "present",
          "command" => "/usr/bin/flock -n /var/lock/file_upload-$name.lock $::file_upload::upload_script -s /opt/pcap -D undef -d undef -u undef -k /root/.ssh//$name -b 100 -L /var/log/file_upload-$name.log    -P '$_patterns'",
          "minute" => [[], []],
          })
  end
    
  it do
    is_expected.to contain_logrotate__rule("file_upload-$name")
        .with({
          "path" => "/var/log/file_upload-$name.log",
          "rotate" => "5",
          "size" => "100M",
          "compress" => true,
          "create_mode" => "0644",
          "create" => true,
          })
  end
    
end
