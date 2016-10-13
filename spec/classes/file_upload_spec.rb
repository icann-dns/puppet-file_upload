require 'spec_helper'

describe 'file_upload' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera
  let(:node) { 'file_upload.example.com' }

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
      #:upload_script => "/usr/local/bin/file_upload.sh",
      #:uploads => {},

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/usr/local/bin/file_upload.sh')
            .with(
              ensure: 'present',
              mode: '0755',
              source: 'puppet:///modules/file_upload/usr/local/bin/file_upload.sh',
            )
        end
      end
      describe 'Change Defaults' do
        context 'upload_script' do
          before { params.merge!(upload_script: '/tmp/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/tmp/foobar')
              .with(
                ensure: 'present',
                mode: '0755',
                source: 'puppet:///modules/file_upload/usr/local/bin/file_upload.sh',
              )
          end
        end
      end
      describe 'check bad type' do
        context 'upload_script bool' do
          before { params.merge!(upload_script: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'upload_script string' do
          before { params.merge!(upload_script: 'asd') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'uploads' do
          before { params.merge!(uploads: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
