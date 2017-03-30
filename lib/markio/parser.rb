require 'nokogiri'
require 'date'
module Markio
  class Parser

    def initialize(data)
      @data = data
    end

    def parse
      sax_document = SAXDocument.new
      parser = Nokogiri::HTML::SAX::Parser.new(sax_document)
      parser.parse(@data) do |ctx|
        ctx.recovery = true
      end
      sax_document.bookmarks
    end

    private

    class SAXDocument < Nokogiri::XML::SAX::Document
      attr_accessor :bookmarks
      
      def initialize
        @bookmarks = []
        @cached_bookmark = nil
        @folders = []
        @a_attrs = nil
        @a_string = nil
        @in_a = false
        @in_h3 = false
        @in_dd = false
      end

      def bookmarks
        consolidate(@bookmarks)
      end

      def start_element(name, attrs = [])
        STDERR.puts("### #{__LINE__}: start_element #{name} #{attrs.inspect}")
        case name.downcase
        when 'a'
          @a_attrs = Hash[attrs]
          @in_a = true
        when 'dd'
          @in_dd = true
        when 'dt'
          add_bookmark
        when 'h3'
          @in_h3 = true
        else
          @in_dd = false
        end
      end

      def characters(string)
        STDERR.puts("### #{__LINE__}: characters #{string}") unless string.strip == ""
        if @in_dd
          if @cached_bookmark
            @cached_bookmark.description = string
          end
        elsif @in_h3
          @folders.push(string)
        elsif @in_a
          @a_text = string
        end
      end

      def end_element(name)
        STDERR.puts("### #{__LINE__}: end_element #{name}")
        case name.downcase
        when 'a'
          @in_a = false
          parse_bookmark
        when 'dl'
          @folders.pop
          add_bookmark
        when 'dd'
          @in_dd = false
        when 'h3'
          @in_h3 = false
        end
      end

      def end_document
        STDERR.puts("### #{__LINE__}: end_document")
        add_bookmark
      end

      def error(string)
        STDERR.puts("### #{__LINE__}: error(string) #{(string)}") 
      end

      private

      def add_bookmark
        STDERR.puts("### #{__LINE__}: add_bookmark @cached_bookmark = #{@cached_bookmark.inspect}")
        unless @cached_bookmark.nil?
          @bookmarks.push(@cached_bookmark)
          @cached_bookmark = nil
        end
      end

      def parse_bookmark
        STDERR.puts("### #{__LINE__}: parse_bookmark")
        data = {}
        @a_attrs.each do |k, a|
          data[k.downcase] = a
        end
        bookmark = Bookmark.new
        bookmark.href = data['href']
        bookmark.title = @a_text
        bookmark.folders = (Array.new(@folders) + parse_tags(data['tags'])).uniq
        bookmark.add_date = parse_timestamp(data['add_date'])
        bookmark.last_visit = parse_timestamp(data['last_visit'])
        bookmark.last_modified = parse_timestamp(data['last_modified'])
        @a_text = @a_attrs = nil
        @cached_bookmark = bookmark
      end

      def parse_timestamp(timestamp)
        Time.at(timestamp.to_i).to_datetime if timestamp
      end

      def parse_tags(tags)
        tags ? tags.split(/,/x) : []
      end

      def consolidate(bookmarks)
        consolidated = []
        bookmarks.each do |b|
          index = consolidated.index b
          unless index.nil?
            consolidated[index].folders += b.folders
          else
            consolidated << b
          end
        end
        consolidated
      end
    end
  end
end
