# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
#
# See LEGAL and LICENSE for licensing information.

require 'rcov/version'

module Rcov

module RCOV__
  COVER = {}
  begin
    require 'rcovrt'
    abi = [0,0,0]
    begin
      abi = RCOV__.ABI
      raise if abi[0] != RCOVRT_ABI[0] || abi[1] < RCOVRT_ABI[1]
    rescue
      $stderr.puts <<-EOF
The rcovrt extension I found was built for a different version of rcov.
The required ABI is:              #{RCOVRT_ABI.join(".")}
Your current rcovrt extension is: #{abi.join(".")}

Please delete rcovrt.{so,bundle,dll,...} and install the required one.
      EOF
      raise LoadError
    end
  rescue LoadError
    $stderr.puts <<-EOF

Since the rcovrt extension couldn't be loaded, rcov will run in pure-Ruby
mode, which is about two orders of magnitude slower.

If you're on win32, you can find a pre-built extension (usable with recent
One Click Installer and mswin32 builds) at http://eigenclass.org/hiki.rb?rcov .

    EOF

    methods = %w[install_hook remove_hook reset generate_coverage_info]
    sklass = class << self; self end
    (methods & sklass.instance_methods).each do |meth|
      sklass.class_eval{ remove_method meth }
    end

    def self.install_hook
      set_trace_func lambda {|event, file, line, id, binding, klass|
        case event
        when 'c-call', 'c-return', 'class'
          return
        end
        COVER[file] ||= []
        COVER[file][line - 1] ||= 0
        COVER[file][line - 1] += 1
      }
    end

    def self.remove_hook
      set_trace_func(nil)
    end

    def self.reset
      COVER.replace {}
    end

    def self.generate_coverage_info
      COVER
    end
  end
end # RCOV__

end # Rcov

# vi: set sw=2: