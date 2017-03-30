require 'spec_helper'
require 'date'

module Markio
  describe Builder do
    it 'should build empty bookmarks' do
      builder = Builder.new
      file_contents = builder.build_string
      expect(file_contents.length).not_to be_nil
      expect(file_contents).to match "DOCTYPE NETSCAPE-Bookmark-file-1"
    end

    it 'should build single bookmark without tags' do
      builder = Builder.new
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark",
        :href => "http://test.com",
        :add_date => Date.parse('2012-01-12 11:22:33').to_datetime,
        :last_visit => Date.parse('2012-01-13 10:20:30').to_datetime,
        :last_modified => Date.parse('2012-01-14 10:21:31').to_datetime
      })
      file_contents = builder.build_string
      expect(file_contents.length).not_to be_nil
      expect(file_contents).to match "Test bookmark"
      expect(file_contents).to match "test\.com"
      expect(file_contents).to match "add_date"
      expect(file_contents).to match "last_visit"
      expect(file_contents).to match "last_modified"
    end


    it 'should be able to parse what it builds' do
      builder = Builder.new
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 1",
        :href => "http://test.com"
      })
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 2",
        :href => "http://test2.com",
        :add_date => Date.parse('2012-01-12 11:22:33').to_datetime,
        :last_visit => Date.parse('2012-01-13 10:20:30').to_datetime,
        :last_modified => Date.parse('2012-01-14 10:21:31').to_datetime
      })
      file_contents = builder.build_string
      bookmarks = Markio.parse file_contents
      expect(bookmarks.length).to eq builder.bookmarks.length
      bookmarks.each do |b|
        expect(builder.bookmarks).to include b
      end
    end

    it 'should be reflexive' do
      builder = Builder.new
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark",
        :href => "http://test1.com"
      })
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 2",
        :href => "http://test2.com",
        :add_date => Date.parse('2012-01-12 11:22:33').to_datetime,
        :last_visit => Date.parse('2012-01-13 10:20:30').to_datetime,
        :last_modified => Date.parse('2012-01-14 10:21:31').to_datetime
      })
      file_contents = builder.build_string
      bookmarks = Markio.parse file_contents
      builder = Builder.new
      builder.bookmarks = bookmarks
      expect(builder.build_string).to eq file_contents
    end

    it 'should group bookmarks into folders' do
      builder = Builder.new
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 1",
        :href => "http://test1.com",
        :folders => ["One"]
      })
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 2",
        :href => "http://test2.com",
        :folders => ["Two"]
      })
      file_contents = builder.build_string
      expect(file_contents).to match "One"
      expect(file_contents).to match "Two"
      bookmarks = Markio.parse file_contents
      expect(bookmarks.length).to eq builder.bookmarks.length
      bookmarks.each do |b|
        expect(builder.bookmarks).to include b
        expect(b.folders.length).to eq 1
      end
    end
    
    it 'should work with multi-folder bookmarks' do
      builder = Builder.new
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 1",
        :href => "http://test1.com",
        :folders => ["One", "Shared"]
      })
      builder.bookmarks << Bookmark.create({
        :title => "Test bookmark 2",
        :href => "http://test2.com",
        :folders => ["Two", "Shared"]
      })
      file_contents = builder.build_string
      expect(file_contents).to match "One"
      expect(file_contents).to match "Two"
      expect(file_contents).to match "Shared"
      bookmarks = Markio.parse file_contents
      expect(bookmarks.length).to eq builder.bookmarks.length
      bookmarks.each do |b|
        expect(builder.bookmarks).to include b
        expect(b.folders.length).to eq 2
        expect(b.folders).to include "Shared"
      end
    end
  end
end
