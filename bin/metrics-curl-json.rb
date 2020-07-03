#!/usr/bin/env ruby
#
#   metrics-curl-json
#
# DESCRIPTION:
#   Simple wrapper around curl for querying a JSON endpoint and return metrics.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: oj
#   gem: socket
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2020 Nicolas Boutet
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'socket'
require 'English'
require 'sensu-plugin/metric/cli'
require 'oj'

#
# Curl Metrics
#
class CurlMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
         short: '-u URL',
         long: '--url URL',
         description: 'valid cUrl url to connect',
         default: 'http://127.0.0.1:80/'

  option :curl_args,
         short: '-a "CURL ARGS"',
         long: '--curl_args "CURL ARGS"',
         description: 'Additional arguments to pass to curl',
         default: ''

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         required: true,
         default: Socket.gethostname.to_s

  def deep_value(hash, scheme = '')
    hash.each do |key, value|
      if value.is_a?(Hash)
        deep_value(value, "#{scheme}.#{key}")
      else
        output "#{scheme}.#{key}", value
      end
    end
  end

  def run
    cmd = "curl --silent #{config[:curl_args]} "
    cmd += config[:url]

    output = `#{cmd}`

    metrics = Oj.load(output, mode: :compat)
    deep_value(metrics, config[:scheme])

    if $CHILD_STATUS.to_i == 0
      ok
    else
      warning
    end
  end
end
