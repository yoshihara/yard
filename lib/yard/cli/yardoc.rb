require 'optparse'

module YARD
  module CLI
    class Yardoc
      attr_reader :options, :visibilities
      attr_accessor :files, :reload
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        @options = SymbolHash[
          :format => :html, 
          :template => :default, 
          :serializer => YARD::Serializers::FileSystemSerializer.new, 
          :verifier => lambda do |gen, obj| 
            return false if gen.respond_to?(:visibility) && visibilities.include?(gen.visibility) 
          end
        ]
        @visibilities = [:public]
        @reload = true
      end
      
      def run(*args)
        optparse(*args)
        Registry.load(files, reload)
        Generators::FullDocGenerator.new(options).generate Registry.all(:module, :class)
      end
      
      private
      
      def optparse(*args)
        serialopts = SymbolHash.new
        
        opts = OptionParser.new
        opts.on('--use-cache', 
                'Use the cached .yardoc file to generate documentation (defaults to no cache)') do 
          self.reload = false
        end
        
        opts.on('-d', '--output-dir [DIR]', 
                'The output directory (defaults to ./doc)') do |dir|
          serialopts[:basepath] = dir
        end
        
        opts.on('-t', '--template [TEMPLATE]', 
                'The template to use (defaults to "default")') do |template|
          options[:template] = template.to_sym
        end
        
        opts.on('-f', '--format [FORMAT]', 
                'The output format for the template (defaults to html)') do |format|
          options[:format] = format
        end
        
        opts.on('--[no-]public', "Show or don't show public methods (default shows public)") do |value|
          visibilities.send(value ? :push : :delete, :public) 
        end

        opts.on('--[no-]protected', "Show or don't show protected methods (default hides protected)") do |value|
          visibilities.send(value ? :push : :delete, :protected) 
        end

        opts.on('--[no-]private', "Show or don't show private methods (default hides private)") do |value|
          visibilities.send(value ? :push : :delete, :private) 
        end
        
        opts.on('=[FILES]', 'files to parse')           { }
        opts.on_tail('-v', '--version', 'Show version') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help')  { puts opts; exit }
        opts.parse!(args)
        
        # Last minute modifications
        self.files = args
        visibilities.uniq!
        options[:serializer] = Serializers::FileSystemSerializer.new(serialopts)
      end
    end
  end
end