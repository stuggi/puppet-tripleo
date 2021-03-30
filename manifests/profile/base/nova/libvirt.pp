# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::nova::libvirt
#
# Libvirt profile for tripleo. It will deploy Libvirt service and configure it.
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*libvirtd_config*]
#   (Optional) Overrides for libvirtd config options
#   Defaults to {}
#
# [*virtlogd_config*]
#   (Optional) Overrides for virtlogd config options
#   Defaults to {}
#
# [*tls_password*]
#   (Optional) SASL Password for libvirtd TLS connections
#   Defaults to '' (disabled)
#
# [*modular_libvirt*]
#   (Optional) Enable SASL Password for libvirtd TLS connections
#   Defaults to false
#
# [*virtproxyd_config*]
#   (Optional) Overrides for virtproxyd config options
#   Defaults to {}
#
# [*virtqemud_config*]
#   (Optional) Overrides for virtqemud config options
#   Defaults to {}
#
# [*virtnodedevd_config*]
#   (Optional) Overrides for virtnodedevd config options
#   Defaults to {}
#
# [*virtstoraged_config*]
#   (Optional) Overrides for virtstoraged config options
#   Defaults to {}
#
# [*virtsecretd_config*]
#   (Optional) Overrides for virtsecretd config options
#   Defaults to {}
#
class tripleo::profile::base::nova::libvirt (
  $step = Integer(hiera('step')),
  $libvirtd_config = {},
  $virtlogd_config = {},
  $virtproxyd_config = {},
  $virtqemud_config = {},
  $virtnodedevd_config = {},
  $virtstoraged_config = {},
  $virtsecretd_config = {},
  $tls_password    = '',
  $modular_libvirt = false,
) {
  include tripleo::profile::base::nova::compute_libvirt_shared

  if $step >= 4 {
    include tripleo::profile::base::nova
    include tripleo::profile::base::nova::migration::client
    include nova::compute::libvirt::virtlogd
    include nova::compute::libvirt::services

    if $modular_libvirt {
      include nova::compute::libvirt::virtproxyd
      include nova::compute::libvirt::virtqemud
      include nova::compute::libvirt::virtnodedevd
      include nova::compute::libvirt::virtstoraged
      include nova::compute::libvirt::virtsecretd

      $virtproxyd_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      $virtqemud_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      $virtnodedevd_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      $virtstoraged_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      $virtsecretd_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      class { 'nova::compute::libvirt::virtproxyd::config':
        virtproxyd_config => merge($virtproxyd_config_default, $virtproxyd_config)
      }

      class { 'nova::compute::libvirt::virtqemud::config':
        virtqemud_config => merge($virtqemud_config_default, $virtqemud_config)
      }

      class { 'nova::compute::libvirt::virtnodedevd::config':
        virtnodedevd_config => merge($virtnodedevd_config_default, $virtnodedevd_config)
      }

      class { 'nova::compute::libvirt::virtstoraged::config':
        virtstoraged_config => merge($virtstoraged_config_default, $virtstoraged_config)
      }

      class { 'nova::compute::libvirt::virtsecretd::config':
        virtsecretd_config => merge($virtsecretd_config_default, $virtsecretd_config)
      }

    } else {
      $libvirtd_config_default = {
        unix_sock_group    => {value => '"libvirt"'},
        auth_unix_ro       => {value => '"none"'},
        auth_unix_rw       => {value => '"none"'},
        unix_sock_ro_perms => {value => '"0777"'},
        unix_sock_rw_perms => {value => '"0770"'}
      }

      class { 'nova::compute::libvirt::config':
        libvirtd_config => merge($libvirtd_config_default, $libvirtd_config)
      }
    }

    class { 'nova::compute::libvirt::virtlogd::config':
      virtlogd_config => $virtlogd_config
    }

    # This removal of files in /etc/libvirt/qemu should not happen inside containers
    # Avoids LP#1819482
    if $::deployment_type != 'containers' {
      file { ['/etc/libvirt/qemu/networks/autostart/default.xml',
              '/etc/libvirt/qemu/networks/default.xml']:
        ensure  => absent,
        require => Package['libvirt'],
        before  => Service['libvirt'],
      }
    }

    # in case libvirt has been already running before the Puppet run, make
    # sure the default network is destroyed
    exec { 'libvirt-default-net-destroy':
      command => '/usr/bin/virsh net-destroy default',
      onlyif  => '/usr/bin/virsh net-info default | /bin/grep -i "^active:\s*yes"',
      require => Package['libvirt'],
      before  => Service['libvirt'],
    }

    include nova::compute::libvirt::qemu
    include nova::migration::qemu

    $libvirt_sasl_conf = "
mech_list: scram-sha-1
sasldb_path: /etc/libvirt/passwd.db
"

    package { 'cyrus-sasl-scram':
      ensure => present
    }
    ->file { '/etc/sasl2/libvirt.conf':
      content => $libvirt_sasl_conf,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['libvirt'],
      notify  => Service['libvirt'],
    }

    if !empty($tls_password) {
      $libvirt_sasl_command = "echo \"\${TLS_PASSWORD}\" | saslpasswd2 -p -a libvirt -u overcloud migration"
      $libvirt_auth_ensure = present
      $libvirt_auth_conf = "
[credentials-overcloud]
authname=migration@overcloud
password=${tls_password}

[auth-libvirt-default]
credentials=overcloud
"
    }
    else {
      $libvirt_sasl_command = 'saslpasswd2 -d -a libvirt -u overcloud migration'
      $libvirt_auth_ensure = absent
      $libvirt_auth_conf = ''
    }

    exec{ 'set libvirt sasl credentials':
      environment => ["TLS_PASSWORD=${tls_password}"],
      command     => $libvirt_sasl_command,
      path        => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
      require     => File['/etc/sasl2/libvirt.conf'],
      tag         => ['libvirt_tls_password']
    }

    file { '/etc/libvirt/auth.conf':
      ensure  => $libvirt_auth_ensure,
      content => $libvirt_auth_conf,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      notify  => Service['libvirt']
    }
  }
}
