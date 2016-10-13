# upload files to specific destination
#
define file_upload::upload (
  Enum['present', 'absent']           $ensure              = present,
  Tea::Absolutepath                   $key_dir             = '/root/.ssh/',
  Boolean                             $clean_known_hosts   = false,
  Boolean                             $delete              = false,
  Boolean                             $remove_source_files = false,
  Array[String]                       $patterns            = ['*.pcap.bz2', '*.pcap.xz'],
  Integer[0,10000]                    $bwlimit             = 100,
  Variant[Tea::Fqdn, Tea::Ip_address] $destination_host    = undef,
  Tea::Absolutepath                   $destination_path    = undef,
  String                              $ssh_key_source      = undef,
  String                              $ssh_user            = undef,
  Tea::Absolutepath                   $log_file            = "/var/log/file_upload-${name}.log",
  Boolean                             $logrotate_enable    = true,
  Integer[1,100]                      $logrotate_rotate    = 5,
  String                              $logrotate_size      = '100M',
  Tea::Absolutepath                   $data                = '/opt/pcap',
) {

  $_remove_source_files = $remove_source_files ? {
    true    => '-E',
    default => '',
  }
  $_delete = $delete ? {
    true    => '-e',
    default => '',
  }
  $_clean_known_hosts = $clean_known_hosts ? {
    true    => '-C',
    default => '',
  }
  $_patterns = join($patterns, ' ')

  $ssh_key_file = "${key_dir}/${name}"
  $command = "/usr/bin/flock -n /var/lock/file_upload-${name}.lock ${::file_upload::upload_script} -s ${data} -D ${destination_host} -d ${destination_path} -u ${ssh_user} -k ${ssh_key_file} -b ${bwlimit} -L ${log_file} ${_clean_known_hosts} ${_delete} ${_remove_source_files} -P '${_patterns}'"

  file {$ssh_key_file:
    ensure => $ensure,
    mode   => '0600',
    source => $ssh_key_source,
  }
  cron {"file_upload-${name}":
    ensure  => $ensure,
    command => $command,
    minute  => [fqdn_rand(30), fqdn_rand(30) + 30],
  }

  if $logrotate_enable and $::kernel != 'FreeBSD' {
    logrotate::rule { "file_upload-${name}":
      path        => $log_file,
      rotate      => $logrotate_rotate,
      size        => $logrotate_size,
      compress    => true,
      create_mode => '0644',
      create      => true,
    }
  }
}
