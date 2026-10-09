# == Class:file_upload
#
class file_upload (
  Tea::Absolutepath $upload_script = '/usr/local/bin/file_upload.sh',
  Optional[Hash]    $uploads       = {},
) {
  file {
    $upload_script:
      ensure => present,
      mode   => '0755',
      source => 'puppet:///modules/file_upload/usr/local/bin/file_upload.sh';
  }
  create_resources(file_upload::upload, $uploads)
}
