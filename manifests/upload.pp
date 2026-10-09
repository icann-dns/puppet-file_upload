# @summary upload files to specific destination
# @param ensure Whether the file should be present or absent.
# @param key_dir The directory containing the SSH key.
# @param clean_known_hosts Whether to clean known hosts.
# @param delete Whether to delete the file after upload.
# @param remove_source_files Whether to remove the source files after upload.
# @param patterns The file patterns to upload.
# @param bwlimit The bandwidth limit for the upload.
# @param destination_host The destination host for the upload.
# @param destination_path The destination path for the upload.
# @param ssh_key_source The source of the SSH key.
# @param ssh_user The SSH user for the upload.
# @param log_file The log file for the upload.
# @param logrotate_enable Whether to enable log rotation.
# @param logrotate_rotate The number of log rotations to keep.
# @param logrotate_size The size of the log file before rotation.
# @param data The source data directory for the upload.
# @param create_parent Whether to create the parent directory on the destination.
# @param minute_frequency The minute frequency for the cron job.
# @param hour_frequency The hour frequency for the cron job.
# @param cron_env The environment for the cron job.
#
define file_upload::upload (
  Enum['present', 'absent']    $ensure              = present,
  Stdlib::Absolutepath         $key_dir             = '/root/.ssh',
  Boolean                      $clean_known_hosts   = false,
  Boolean                      $delete              = false,
  Boolean                      $remove_source_files = false,
  Array[String]                $patterns            = ['*.pcap.bz2', '*.pcap.xz'],
  Integer[0, 10000]            $bwlimit             = 100,
  Stdlib::Absolutepath         $log_file            = "/var/log/file_upload-${name}.log",
  Boolean                      $logrotate_enable    = true,
  Integer[1, 100]              $logrotate_rotate    = 5,
  String                       $logrotate_size      = '100M',
  Stdlib::Absolutepath         $data                = '/opt/pcap',
  Boolean                      $create_parent       = false,
  String                       $cron_env            = 'MAILTO=""',
  Array[Integer]               $minute_frequency    = [fqdn_rand(60)],
  Array[Integer]               $hour_frequency      = [],
  Optional[Stdlib::Host]       $destination_host    = undef,
  Optional[String[1]]          $destination_path    = undef,
  Optional[Stdlib::Filesource] $ssh_key_source      = undef,
  Optional[String]             $ssh_user            = undef,
) {
  $ssh_key_file = "${key_dir}/${name}"
  $arguments = {
    's' => $data,
    'D' => $destination_host,
    'd' => $destination_path,
    'u' => $ssh_user,
    'k' => $ssh_key_file,
    'b' => $bwlimit,
    'L' => $log_file,
    'C' => $clean_known_hosts,
    'e' => $delete,
    'E' => $remove_source_files,
    'p' => $create_parent,
  }.filter |$k, $v| { $v =~ NotUndef }
  $flock_command = file_upload::argparse({ 'n' => "/var/lock/file_upload-${name}.lock" }, '/usr/bin/flock')
  # We add patternes manually as we dont want them to be shell escaped as they can contain globs
  $command = file_upload::argparse($arguments, "${flock_command} ${file_upload::upload_script} -P '${patterns.join(' ')}'")

  file { $ssh_key_file:
    ensure => $ensure,
    mode   => '0600',
    source => $ssh_key_source,
  }

  $_hour_frequency = $hour_frequency.empty ? {
    true    => '*',
    default => $hour_frequency,
  }

  cron { "file_upload-${name}":
    ensure      => $ensure,
    command     => $command,
    minute      => $minute_frequency,
    hour        => $_hour_frequency,
    environment => $cron_env,
  }

  unless $facts['kernel'] == 'FreeBSD' {
    $_ensure = $ensure ? {
      'absent' => 'absent',
      default  => stdlib::ensure($logrotate_enable)
    }
    logrotate::rule { "file_upload-${name}":
      ensure      => $_ensure,
      path        => $log_file,
      rotate      => $logrotate_rotate,
      size        => $logrotate_size,
      compress    => true,
      create_mode => '0644',
      create      => true,
    }
  }
}
