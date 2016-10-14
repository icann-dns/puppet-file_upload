[![Build Status](https://travis-ci.org/icann-dns/puppet-file_upload.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-file_upload)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/file_upload.svg?maxAge=2592000)](https://forge.puppet.com/icann/file_upload)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/file_upload.svg?maxAge=2592000)](https://forge.puppet.com/icann/file_upload)
# file_upload

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with file_upload](#setup)
    * [What file_upload affects](#what-file_upload-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with file_upload](#beginning-with-file_upload)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Manage client and server](#manage-client-and-server)
    * [Ansible client](#file_upload-client)
    * [Ansible Server](#file_upload-server)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs provides mnages cron jobs to copy files to an ofline location

## Setup

### What file_upload affects

* installs an upload script
* manages cron jobs to upload files

### Setup Requirements

* puppetlabs-stdlib 4.12.0
* icann-tea 0.2.4
* icann-logrotate v1.4.0-ICANN-1

### Beginning with file_upload

just add the file_upload class.  This just installes the script required by file_upload::upload

```puppet
class {'::file_upload' }
```

## Usage

### Add an upload job

You can pass URI's which will be handed to puppet and passed to a file type source parameter.

```puppet
class {'::file_upload' 
  uploads => { 
    'test' => {
      destination_host => 'upload.example.com',
      destination_path => '/srv/upload',
      ssh_key_source   => 'puppet:///modules/module_files/id_rsa',
      ssh_user         => 'upload',

    }
  }
}
```

of with hiera

```yaml
file_upload::uploads:
  test:
    destination_host: 'upload.example.com'
    destination_path: '/srv/upload'
    ssh_key_source: 'puppet:///modules/module_files/id_rsa'
    ssh_user: upload
```

## Reference

### Classes

#### Public Classes

* [`file_upload`](#class-file_upload)

#### Private Classes

* [`file_upload::params`](#class-file_uploadparams)

#### Class: `file_upload`

Main class, includes all other classes

##### Parameters 

* `upload_script` (Tea::Puppetsource, Default: '/usr/local/bin/file_upload.sh'): Where to install the upload script
* `modules` (Hash[file_upload::upload], Default: {}): A Hash of file_upload::upload objects to be passtd to `create_resources()`

### Defines

* [`file_upload::upload`](#define-file_uploadupload)

#### Define: `file_upload::upload`

Used to create upload jobs

##### Parameters

* `ensure` (Enum['present', 'absent'], Default: present): Enable or disable this upload task
* `key_dir` (Tea::Absolutepath, Default: '/root/.ssh'): Where to stor the ssh key used for updates
* `clean_know_hosts` (Boolean, Default: false): whether to remove entries from the know hosts entry.  WARNING enableing this function makes uploads open to MITM attacks
* `delete` (Boolean, Default: false): delete extraneous files from dest dirs
* `remove_source_files` (Boolean, Default: false): This tells rsync to remove from the sending side the files (meaning non-directories) that are a part of the transfer and have been successfully duplicated on the receiving side.
* `patters` (Array[String], Default: ['*.pcap.bz2', '*.pcap.xz']): Array of bash globs used to recursevly search the source folder for files to sync
* `bwlimit` (Integer[0,10000], Default: 100): bandwith in kbps to limit the transfer to transfer
* `destination_host` (Variant[Tea::Fqdn, Tea::Ip_address]: The host to send the files to
* `destination_path` (Tea::Absolutepath): The destination path to send files to
* `ssh_key_source` (Tea::Puppetsource): This will be bassed to a file type and used as the source attribute for the ssh key to use for transfers
* `ssh_user` (String): The user to use to set oup an ssh connection to the destination host
* `log_file` (Tea::Absolutepath, Default: "/var/log/file_upload-${name}.log"): location of the logfile
* `logrotate_enable` (Boolean, Default: true): whether to enable logrotate
* `logrotate_rotate` (Integer[1,100], Default: 5): maximum amount of rotated files to keep
* `location_size` (Strind, Default: 100M): Rotate the log files when it reaches this size
* `data` (Tea::Absolutepath, Default: '/opt/pcap'): the source directory to copy files from

## Limitations

This module is tested on Ubuntu 12.04, and 14.04 and FreeBSD 10 
