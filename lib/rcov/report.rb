# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
# See LEGAL and LICENSE for additional licensing information.

require 'pathname'


module Rcov

# Try to fix bugs in the REXML shipped with Ruby 1.8.6
# They affect Mac OSX 10.5.1 users and motivates endless bug reports.
begin
    require 'rexml/formatters/transitive'
    require 'rexml/formatter/pretty'
rescue LoadError
end

require File.expand_path(File.join(File.dirname(__FILE__), 'rexml_extensions' ))

if (RUBY_VERSION == "1.8.6" || RUBY_VERSION == "1.8.7") && defined? REXML::Formatters::Transitive
    class REXML::Document
        remove_method :write rescue nil
        def write( output=$stdout, indent=-1, trans=false, ie_hack=false )
            if xml_decl.encoding != "UTF-8" && !output.kind_of?(Output)
                output = Output.new( output, xml_decl.encoding )
            end
            formatter = if indent > -1
                #if trans
                    REXML::Formatters::Transitive.new( indent )
                #else
                #    REXML::Formatters::Pretty.new( indent, ie_hack )
                #end
            else
                REXML::Formatters::Default.new( ie_hack )
            end
            formatter.write( self, output )
        end
    end

    class REXML::Formatters::Transitive
        remove_method :write_element rescue nil
        def write_element( node, output )
            output << "<#{node.expanded_name}"

            node.attributes.each_attribute do |attr|
                output << " "
                attr.write( output )
            end unless node.attributes.empty?

            if node.children.empty?
                output << "/>"
            else
                output << ">"
                # If compact and all children are text, and if the formatted output
                # is less than the specified width, then try to print everything on
                # one line
                skip = false
                @level += @indentation
                node.children.each { |child|
                    write( child, output )
                }
                @level -= @indentation
                output << "</#{node.expanded_name}>"
            end
            output << "\n"
            output << ' '*@level
        end
    end
    
end
    
class XMLCoverage < Formatter # :nodoc:
    require 'fileutils'

    DEFAULT_OPTS = {:color => false, :fsr => 30, :destdir => "coverage",
                    :callsites => false, :cross_references => false,
                    :validator_links => true, :charset => nil
                   }
    def initialize(opts = {})
      options = DEFAULT_OPTS.clone.update(opts)
      super(options)
      @dest = options[:destdir]
    end

    def execute
      summary = Document.new
      coverage_element = Element.new "code_coverage"

      
      coverage_element.add_attributes( { "total_coverage" => self.total_coverage.to_s,
                                "num_lines" => self.num_lines.to_s,
                              "num_code_lines" => self.num_code_lines.to_s})

      each_file_pair_sorted do |filename, fileinfo|
        file_element = Element.new("file")
        name = file_element.add_element("name")
        name.text = filename

        lines_element = Element.new("lines")
        fileinfo.num_lines.times do |i|
            line_element = Element.new("line")
            line_element.add_attributes( { "number" => i.to_s })
            code = line_element.add_element("code")
            code.text = fileinfo.lines[i].chomp

            count = line_element.add_element("count")
            count.text = fileinfo.counts[i]

            status = line_element.add_element("status")
            case fileinfo.coverage[i]
            when true
              status.text = "covered"
            when :inferred
              status.text = "inferred"
            else
              status.text = "uncovered"
            end

            lines_element.elements << line_element
        end
        file_element.elements << lines_element

        file_element.add_attributes( { "total_coverage" => fileinfo.total_coverage.to_s,
                              "num_lines" => fileinfo.num_lines.to_s,
                              "num_code_lines" => fileinfo.num_code_lines.to_s})

        coverage_element.elements << file_element
      end
      summary.elements << coverage_element

      FileUtils.mkdir_p @dest
      File.open(File.join(@dest, "coverage.xml"),'w') {|file| file.write(summary) }

      puts "View xml report at <file://#{File.join(@dest, "coverage.xml")}>"
    end
end



end # Rcov

# vi: set sw=4:
# Here is Emacs setting. DO NOT REMOVE!
# Local Variables:
# ruby-indent-level: 4
# End:
