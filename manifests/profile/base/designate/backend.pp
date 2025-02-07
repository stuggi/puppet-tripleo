# Copyright 2021 Red Hat, Inc.
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
# == Class: tripleo::profile::base::designate::backend
#
# Designate backend profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*backend*]
#   (Optional) Specify a backend used.
#   Defaults to 'bind9'
#
class tripleo::profile::base::designate::backend (
  $step    = Integer(hiera('step')),
  $backend = hiera('designate_backend', 'bind9'),
) {
  if $step >= 4 {
    if $backend == 'bind9' {
      include designate::backend::bind9
    } else {
      fail("${backend} is not supported by designate")
    }
  }
}
