# systemd input plugin for [Fluentd](http://github.com/fluent/fluentd)

[<img src="https://travis-ci.org/reevoo/fluent-plugin-systemd.svg?branch=master"
alt="Build Status" />](https://travis-ci.org/reevoo/fluent-plugin-systemd) [<img
src="https://codeclimate.com/github/reevoo/fluent-plugin-systemd/badges/gpa.svg"
/>](https://codeclimate.com/github/reevoo/fluent-plugin-systemd)

## Overview

**systemd** input plugin reads logs from the systemd journal

## Installation

Simply use RubyGems:

    gem install fluent-plugin-systemd

    or

    fluent-gem install fluent-plugin-systemd

    or

    td-agent-gem install fluent-plugin-systemd

## Configuration

    <source>
      type systemd
      path /var/log/journal
      filters [{ "_SYSTEMD_UNIT": "kube-proxy.service" }]
      pos_file kube-proxy.pos
      tag kube-proxy
      read_from_head true
    </source>

** path **

Path to the systemd journal, defaults to `/var/log/journal`

** filters **

Array of filters, see [here](http://www.rubydoc.info/gems/systemd-journal/Systemd%2FJournal%2FFilterable%3Afilter) for futher
documentation, defaults to no filtering.

** pos file **

Path to pos file, stores the journald cursor. File is created if does not exist.

** read_from_head **

If true reads all avalible journal from head, otherwise starts reading from tail,
 ignored if pos file exists. Defaults to false.

** tag **

Required the tag for events generated by this input plugin.

## Licence etc

[MIT](LICENCE)

Issues and pull requests welcome
