# Copyright 2019 Red Hat, Inc.
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
# == Class: tripleo::certmonger::ceph_dashboard
#
# Request a certificate for Ceph Dashboard and do the necessary setup.
#
# === Parameters
#
# [*hostname*]
#   The hostname of the node. this will be set in the CN of the certificate.
#
# [*service_certificate*]
#   The path to the certificate that will be used for TLS in this service.
#
# [*service_key*]
#   The path to the key that will be used for TLS in this service.
#
# [*certmonger_ca*]
#   (Optional) The CA that certmonger will use to generate the certificates.
#   Defaults to hiera('certmonger_ca', 'local').
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The service principal that is set for the service in kerberos.
#   Defaults to undef
#
# [*key_size*]
#   (Optional) Specifies the private key size used when creating the certificate.
#   Defaults to 2048bits.
#
class tripleo::certmonger::ceph_dashboard (
  $hostname,
  $service_certificate,
  $service_key,
  $postsave_cmd = undef,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $principal     = undef,
  $key_size      = 2048,
) {

  ensure_resource('file', '/usr/bin/certmonger-dashboard-refresh.sh', {
    source  => 'puppet:///modules/tripleo/certmonger-dashboard-refresh.sh',
    mode    => '0700',
    seltype => 'bin_t',
    notify  => Service['certmonger']
  })

  certmonger_certificate { 'ceph_dashboard' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    key_size     => $key_size,
    wait         => true,
    require      => Class['::certmonger'],
  }

  file { $service_certificate :
    require => Certmonger_certificate['ceph_dashboard'],
    owner   => 472,
    group   => 472,
  }
  file { $service_key :
    require => Certmonger_certificate['ceph_dashboard'],
    owner   => 472,
    group   => 472,
  }
}
