# systemd plugin for [Fluentd](http://github.com/fluent/fluentd)

[![Build Status](https://travis-ci.org/reevoo/fluent-plugin-systemd.svg?branch=master)](https://travis-ci.org/reevoo/fluent-plugin-systemd) [![Code Climate GPA](https://codeclimate.com/github/reevoo/fluent-plugin-systemd/badges/gpa.svg)](https://codeclimate.com/github/reevoo/fluent-plugin-systemd) [![Gem Version](https://badge.fury.io/rb/fluent-plugin-systemd.svg)](https://rubygems.org/gems/fluent-plugin-systemd)

## Overview

* **systemd** input plugin to read logs from the systemd journal
* **systemd** filter plugin for basic manipulation of systemd journal entries

## Support

[![Fluentd Slack](http://slack.fluentd.org/badge.svg)](http://slack.fluentd.org/)

Join the #plugin-systemd channel on the [Fluentd Slack](http://slack.fluentd.org/)


## Requirements

|fluent-plugin-systemd|fluentd|td-agent|ruby|
|----|----|----|----|
| > 0.1.0 | >= 0.14.11, < 2 | 3 | >= 2.1 |
| 0.0.x | ~> 0.12.0       | 2 | >= 1.9  |

* The 1.x.x series is developed from this branch (master)
* The 0.0.x series (compatible with fluentd v0.12, and td-agent 2) is maintained on the [0.0.x branch](https://github.com/reevoo/fluent-plugin-systemd/tree/0.0.x)

## Installation

Simply use RubyGems:

    gem install fluent-plugin-systemd -v 1.0.0

or

    td-agent-gem install fluent-plugin-systemd -v 1.0.0

## Upgrading

If you are upgrading to version 1.0 from a previous version of this plugin take a look at the [upgrade documentation](docs/upgrading.md). A number of deprecated config options were removed so you might need to update your configuration.

## Input Plugin Configuration

    <source>
      @type systemd
      tag kube-proxy
      path /var/log/journal
      matches [{ "_SYSTEMD_UNIT": "kube-proxy.service" }]
      read_from_head true
      <storage>
        @type local
        persistent false
        path kube-proxy.pos
      </storage>
      <entry>
        fields_strip_underscores true
        fields_lowercase true
      </entry>
    </source>

    <match kube-proxy>
      @type stdout
    </match>

**`path`**

Path to the systemd journal, defaults to `/var/log/journal`

**`filters`**

_This parameter name is depreciated and should be renamed to `matches`_

**`matches`**

Expects an array of hashes defining desired matches to filter the log
messages with. When this property is not specified, this plugin will default to
reading all logs from the journal.

See [matching details](docs/matching.md) for a more exhaustive
description of this property and how to use it.

**`storage`**

Configuration for a [storage plugin](http://docs.fluentd.org/v0.14/articles/storage-plugin-overview) used to store the journald cursor.

**`read_from_head`**

If true reads all available journal from head, otherwise starts reading from tail,
 ignored if cursor exists in storage (and is valid). Defaults to false.

**`entry`**

Optional configuration for an embedded systemd entry filter. See the  [Filter Plugin Configuration](#filter-plugin-configuration) for config reference.

**`tag`**

_Required_

A tag that will be added to events generated by this input.


## Filter Plugin Configuration

```
<filter kube-proxy>
  @type systemd_entry
  field_map {"MESSAGE": "log", "_PID": ["process", "pid"], "_CMDLINE": "process", "_COMM": "cmd"}
  field_map_strict false
  fields_lowercase true
  fields_strip_underscores true
</filter>
```

_Note that the following configurations can be embedded in a systemd source block, within an entry block, you only need to use a filter directly for more complicated workflows._

**`field_map`**

Object / hash defining a mapping of source fields to destination fields. Destination fields may be existing or new user-defined fields. If multiple source fields are mapped to the same destination field, the contents of the fields will be appended to the destination field in the order defined in the mapping. A field map declaration takes the form of:

    {
      "<src_field1>": "<dst_field1>",
      "<src_field2>": ["<dst_field1>", "<dst_field2>"],
      ...
    }
Defaults to an empty map.

**`field_map_strict`**

If true, only destination fields from `field_map` are included in the result. Defaults to false.

**`fields_lowercase`**

If true, lowercase all non-mapped fields. Defaults to false.

**`fields_strip_underscores`**

If true, strip leading underscores from all non-mapped fields. Defaults to false.

### Filter Example

Given a systemd journal source entry:
```
{
  "_MACHINE_ID": "bb9d0a52a41243829ecd729b40ac0bce"
  "_HOSTNAME": "arch"
  "MESSAGE": "this is a log message",
  "_PID": "123"
  "_CMDLINE": "login -- root"
  "_COMM": "login"
}
```
The resulting entry using the above sample configuration:
```
{
  "machine_id": "bb9d0a52a41243829ecd729b40ac0bce"
  "hostname": "arch",
  "msg": "this is a log message",
  "pid": "123"
  "cmd": "login"
  "process": "123 login -- root"
}
```

## Common Issues

> ### When I look at fluentd logs, everything looks fine but no journal logs are read ?

This is commonly caused when the user running fluentd does not have the correct permissions
to read the systemd journal.

According to the [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html):
> Journal files are, by default, owned and readable by the "systemd-journal" system group but are not writable. Adding a user to this group thus enables her/him to read the journal files.

> ### How can I deal with multi-line logs ?

Ideally you want to ensure that your logs are saved to the systemd journal as a single entry regardless of how many lines they span.

It is possible for applications to naively support this (but only if they have tight integration with systemd it seems) see: https://github.com/systemd/systemd/issues/5188.

Typically you would not be able to this, so another way is to configure your logger to replace newline characters with something else. See this blog post for an example configuring a Java logging library to do this https://fabianlee.org/2018/03/09/java-collapsing-multiline-stack-traces-into-a-single-log-event-using-spring-backed-by-logback-or-log4j2/

Another strategy would be to use a plugin like [fluent-plugin-concat](https://github.com/fluent-plugins-nursery/fluent-plugin-concat) to combine multi line logs into a single event, this is more tricky though because you need to be able to identify the first and last lines of a multi line message with a regex.

> ### How can I use this plugin inside of a docker container ?

* Install the [systemd dependencies](#dependencies) if required
* You can use an [offical fluentd docker](https://github.com/fluent/fluentd-docker-image) image as a base, (choose the debian based version, as alpine linux doesn't support systemd).
* Bind mount `/var/log/journal` into your container.

> ### I am seeing lots of logs being generated very rapidly!

This commonly occurs when a loop is created when fluentd is logging to STDOUT, and the collected logs are then written to the systemd journal. This could happen if you run fluentd as a systemd serivce, or as a docker container with the systemd log driver.

Workarounds include:

* Use another fluentd output
* Don't read every message from the journal, set some `matches` so you only read the messages you are interested in.
* Disable the systemd log driver when you launch your fluentd docker container, e.g. by passing `--log-driver json-file`

### Example

For an example of a full working setup including the plugin, take a look at [the fluentd kubernetes daemonset](https://github.com/fluent/fluentd-kubernetes-daemonset)

## Dependencies

This plugin depends on libsystemd

On Debian or Ubuntu you might need to install the libsystemd0 package:

```
apt-get install libsystemd0
```

On CentOS or RHEL you might need to install the systemd package:

```
yum install -y systemd
```

If you want to do this in a CentOS docker image you might first need to remove the `fakesystemd` package.

```
yum remove -y fakesystemd
```

## Running the tests

To run the tests with docker on several distros simply run `rake`

For systems with systemd installed you can run the tests against your installed libsystemd with `rake test`

## License

[Apache-2.0](LICENCE)

## Contributions

Issues and pull requests are very welcome.

If you want to make a contribution but need some help or advice feel free to message me @errm on the [Fluentd Slack](http://slack.fluentd.org/), or send me an email edward-robinson@cookpad.com

We have adopted the [Contributor Covenant](CODE_OF_CONDUCT.md) and thus expect anyone interacting with contributors, maintainers and users of this project to abide by it.

## Maintainer

* [Ed Robinson](https://github.com/errm)

## Contributors

Many thanks to our fantastic contributors

* [Hiroshi Hatake](https://github.com/cosmo0920)
* [Erik Maciejewski](https://github.com/emacski)
* [Masahiro Nakagawa](https://github.com/repeatedly)
* [Richard Megginson](https://github.com/richm)
* [Mike Kaplinskiy](https://github.com/mikekap)
* [neko-neko](https://github.com/neko-neko)
* [Sadayuki Furuhashi](https://github.com/frsyuki)
* [Jesus Rafael Carrillo](https://github.com/jescarri)
* [John Thomas Wile II](https://github.com/jtwile2)
* [Kazuhiro Suzuki](https://github.com/ksauzz)
* [Joel Gerber](https://github.com/Jitsusama)
