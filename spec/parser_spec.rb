require 'spec_helper'

module Markio
  describe Parser do
    it 'should parse single bookmark' do
      bookmarks = Markio.parse File.open "spec/assets/one_bookmark.html"

      expect(bookmarks).not_to be_nil
      expect(bookmarks.class).to be Array
      expect(bookmarks.length).to eq 1
      bookmark = bookmarks[0]
      expect(bookmark.title).to eq 'Save It - Simple, secure bookmarks'
      expect(bookmark.href).to eq 'https://saveit.in/'
      expect(bookmark.folders.length).to eq 1
      expect(bookmark.folders.first).to eq "Bookmarking"
      expect(bookmark.add_date).not_to be_nil
      expect(bookmark.last_visit).not_to be_nil
      expect(bookmark.last_modified).not_to be_nil
      expect(bookmark.add_date.class).to be DateTime
      expect(bookmark.last_visit.class).to be DateTime
      expect(bookmark.last_modified.class).to be DateTime
    end

    it 'should parse multiple bookmarks' do
      bookmarks = Markio.parse File.open "spec/assets/many_bookmarks.html"
      expect(bookmarks.length).to eq 11
      expect(bookmarks.first.folders.length).to eq 1
      expect(bookmarks.first.folders.first).to eq "Bookmarks Bar"
      expect(bookmarks.last.folders.length).to eq 2
    end

    it 'should parse delicious bookmarks' do
      bookmarks = Markio.parse File.open "spec/assets/delicious_bookmarks.html"
      expect(bookmarks.length).to eq 5
      expect(bookmarks.first.folders.length).to eq 5
      expect(bookmarks.first.folders.first).to eq "food"
      expect(bookmarks.last.folders.length).to eq 3
    end

    it 'should parse nested bookmarks' do
      bookmarks = Markio.parse File.open "spec/assets/nested_bookmarks.html" 

      expect(bookmarks.length).to eq 10
      expect(bookmarks.first.folders.length).to eq 0
      expect(bookmarks.last.folders.length).to eq 2
      expect(bookmarks[5].href).to eq "http://www.yahoo.com/"
      expect(bookmarks[5].icon).to eq "icon-data"
      expect(bookmarks[5].folders).to eq ["Bookmarks Toolbar", 'Nest 1', 'Nest 2', 'tag1', 'tag2']
      expect(bookmarks[5].description).to match(/Welcome to Yahoo!/)
    end

    it 'should parse instapaper exports' do
      bookmarks = Markio.parse File.open "spec/assets/instapaper-export.html" 

      expect(bookmarks.length).to eq 5
      expect(bookmarks.first.folders.length).to eq 0
      expect(bookmarks.last.folders.length).to eq 0

      [ ["https://ja.wikipedia.org/", "Wikipedia"],
        ["https://soundcloud.com/", "soundcloud"],
        ["http://www.codinghorror.com/blog/2012/05/please-dont-learn-to-code.html", "Coding Horror: Please Don't Learn to Code"],
        ["http://www.codinghorror.com/blog/2012/05/so-you-want-to-be-a-programmer.html", "Coding Horror: So You Want to be a Programmer"],
        ["http://www.google.com/", "Google"] ].each_with_index do |data, index|
        url, title = data
        expect(bookmarks[index].href).to eq url
        expect(bookmarks[index].title).to eq title
      end
    end

    it 'should parse pocket exports' do
      bookmarks = Markio.parse File.open "spec/assets/pocket_export.html" 

      expect(bookmarks.length).to eq 5
      expect(bookmarks.first.folders.length).to eq 0
      expect(bookmarks.last.folders.length).to eq 0

      [ ["http://bliki-ja.github.io/RollerSkateImplementation/", "ローラースケート実装", []],
        ["https://en.wikipedia.org/wiki/Zaouli", "Zaouli - Wikipedia", ["Zaouli"]],
        ["http://www.paulgraham.com/spam.html", "A Plan for Spam", []],
        ["https://ja.wikipedia.org/", "Wikipedia", []],
        ["https://soundcloud.com/", "soundcloud", []] ].each_with_index do |data, index|
        url, title, tags = data
        expect(bookmarks[index].href).to eq url
        expect(bookmarks[index].title).to eq title
        expect(bookmarks[index].folders).to eq tags
      end
    end

    it 'should raise error for non existing files' do
      expect { Markio.parse File.open "spec/assets/not_found.html" }.to raise_error Errno::ENOENT
    end

    it 'should handle corrupted data' do
      bookmarks = Markio.parse File.open "spec/assets/corrupted.html"
      expect(bookmarks).to eq []
    end

  end
end
