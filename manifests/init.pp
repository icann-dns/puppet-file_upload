# @summary Main class for file upload management
# @param upload_script The path to the upload script.
# @param uploads A hash of upload definitions.
#
class file_upload (
  Stdlib::Unixpath $upload_script = '/usr/local/bin/file_upload.sh',
  Hash            $uploads        = {},
) {
  file { $upload_script:
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/file_upload/usr/local/bin/file_upload.sh';
  }
  $uploads.each |$name, $params| {
    file_upload::upload { $name:
      * => $params,
    }
  }
}
