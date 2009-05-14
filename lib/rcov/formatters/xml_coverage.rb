module Rcov

  class XMLCoverage < BaseFormatter # :nodoc:
    require 'fileutils'
    require 'rexml/document'
    include REXML

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
end
