# grok

Regexes for mere mortals!

This is heavily influenced by the grok processor in Elasticsearch and
the grok filter in logstash.

Grok has been written by Jordan Sissel (the creator logstash). Grok serves as
a library for regular expressions so you do not have to remember all the
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
   ```

2. Run `shards install`

## Usage

```crystal
require "grok"
```

TODO: Write usage instructions here

## Bugs and issues

If you find a bug, please ensure to provide a reproducible example.

## Contributing

1. Fork it (<https://github.com/spinscale/grok.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alexander Reelsen](https://github.com/spinscale) - creator and maintainer
