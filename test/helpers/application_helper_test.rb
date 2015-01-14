require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  describe 'expander' do
    it 'should truncate strings on a word boundary' do
      text = expander('It was the best of times.', 5, 10)
      text.gsub(/\s/, '')[0..6].must_equal('It<span')
    end

    it 'should truncate strings without leaving a dangling comma' do
      text = expander('It, or something like it, was the best of times.', 5, 10)
      text.gsub(/\s/, '')[0..6].must_equal('It<span')
    end
  end

  describe 'language_color' do
    it 'should return default color when color is not present in list' do
      language_color('test').must_equal 'EEE'
    end

    it 'should return selected color' do
      LANGUAGE_COLORS.each do |name, color|
        language_color(name).must_equal color
      end
    end
  end

  describe 'language_text_color' do
    it 'should return 000 when color is included in list' do
      BLACK_TEXT_LANGUAGES.each do |color|
        language_text_color(color).must_equal '000'
      end
    end

    it 'should return 000 when color is not present in language_color' do
      language_text_color('test').must_equal '000'
    end

    it 'should return FFF when color is not present in BLACK_TEXT_LANGUAGES' do
      language_text_color('xslt').must_equal 'FFF'
    end
  end

  describe 'pluralize_without_count' do
    it 'should pluralize appropriately' do
      pluralize_without_count(3, 'Project').must_equal 'Projects'
      pluralize_without_count(1, 'Project').must_equal 'Project'
      pluralize_without_count(0, 'Project').must_equal 'Projects'
      pluralize_without_count(3, 'Person', 'Accounts').must_equal 'Accounts'
      pluralize_without_count(1, 'Person', 'Accounts').must_equal 'Person'
    end
  end

  describe 'base_url' do
    it 'should return protocol and host_with_port' do
      Object.any_instance.stubs(:protocol).returns('http://')
      Object.any_instance.stubs(:host_with_port).returns('127.0.0.1:3000')

      base_url.must_equal 'http://127.0.0.1:3000'
    end
  end

  describe 'generate_page_name' do
    it 'should return proper page title' do
      stubs(:controller_name).returns('accounts')
      stubs(:action_name).returns('index')

      generate_page_name.must_equal 'accounts_index_page'
    end
  end
end
