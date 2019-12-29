# grok.cr

Regexes for mere mortals!

This is heavily influenced by the grok processor in Elasticsearch and
the grok filter in logstash.

Grok has been written by Jordan Sissel (the creator of logstash). Grok serves
as a library for regular expressions so you do not have to remember all the
awkward regex syntaxes and just need to remember names that get mapped to
patterns.

This is a port of the functionality to crystal that uses the same grok
patterns in its standard library than logstash or the Elasticsearch grok
processor.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  grok:
    github: spinscale/grok.cr
    version: 0.0.1
```

2. Run `shards install`

## Usage

This is the easiest usage

```crystal
require "grok"

grok = Grok.new [ "This is a %{DATA:my_field}" ]
map = grok.parse "This is a test"
map["my_field"] == "test"
```

This is a simple example, but take a log line from an http log file like

```
1.1.1.1 - auth_user [12/Dec/2019:12:45:45 -0700] "GET / HTTP/1.1" 200 633 "http://referer.org" "Secret Browser"
```

This one can easily be parsed into a map by using

```crystal
grok = Grok.new ["%{COMBINEDAPACHELOG}"]
result = grok.parse %q(1.1.1.1 - auth_user [12/Dec/2019:12:45:45 -0700] "GET / HTTP/1.1" 200 633 "http://referer.org" "Secret Browser")

# result will be a map of
# {"clientip" => "1.1.1.1", "ident" => "-", "auth" => "auth_user",
# "timestamp" => "12/Dec/2019:12:45:45 -0700", "verb" => "GET",
# "request" => "/", "httpversion" => "1.1", "rawrequest" => nil,
# "response" => "200", "bytes" => "633",
# "referrer" => "\"http://referer.org\"", 
# "agent" => "\"Secret Browser\""
# }
```

You can also come up with parsing your custom log lines from your own applications

```crystal
grok = Grok.new [ "%{SYSLOGBASE2} %{WORD:action} on %{WORD:interface} to %{IP:ip} port %{INT:port} interval %{INT:interval} %{GREEDYDATA:message}" ]
result = grok.parse "Dec 29 22:41:02 mako dhclient[11675]: DHCPDISCOVER on enp59s0f1 to 255.255.255.255 port 67 interval 3 (xid=0x4d444363)"

# {
# "timestamp" => "Dec 29 22:41:02", "timestamp8601" => nil, 
# "facility" => nil, "priority" => nil, "logsource" => "mako",
# "program" => "dhclient", "pid" => "11675", "action" => "DHCPDISCOVER", 
# "interface" => "enp59s0f1", "ip" => "255.255.255.255", "port" => "67", 
# "interval" => "3", "message" => "(xid=0x4d444363)"
# }
```

You can also directly convert to types if you want

```crystal
grok = Grok.new [ "This is a %{INT:my_field:integer}" ]
map = grok.parse "This is a 123"
map["my_field"] == 123_i32
```

Supported types are `integer`, `long`, `double`, `float` and `boolean` to
support the existing types of other implementations.

## Bugs and issues

If you find a bug, please ensure to provide a reproducible example.

## Contributing

1. Fork it (<https://github.com/spinscale/grok.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Ensure that `./bin/ameba` passes
6. Create a new Pull Request

## Contributors

- [Alexander Reelsen](https://github.com/spinscale) - creator and maintainer
