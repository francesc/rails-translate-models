# coding: UTF-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'minitest/autorun'
require 'active_record'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rails-translate-models'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :articles, :force => true do |t|
        t.timestamps
      end
    end

    ActiveRecord::Schema.define(:version => 1) do
      create_table :article_translations, :force => true do |t|
        t.integer    :article_id
        t.string     :language_code
        t.string     :title
        t.text       :body
        t.timestamps
      end
    end
  end
end

class Article < ActiveRecord::Base
  has_translations :title, :body
end

class RailsTranslateModelsTest < MiniTest::Unit::TestCase

  def setup

    setup_db

    Article.create :title_in_en => "Title",
                :title_in_es => "Título",
                :body_in_en => "Content",
                :body_in_es => "Contenido",
                :created_at => Time.now - 60

    Article.create :title_in_en => "Second title",
                :title_in_es => "Segundo título",
                :body_in_en => "Second content",
                :body_in_es => "Segundo contenido",
                :created_at => Time.now

    I18n.default_locale = :en
    I18n.locale = :en

  end

  def teardown
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  def test_should_get_title_in_en_of_the_article
    article = Article.first
    assert_equal article.send('title_in_en'), article.title
  end

  def test_should_get_title_in_es_of_the_article
    I18n.locale = :es
    article = Article.first
    assert_equal article.send('title_in_es'), article.title
  end

  def test_should_return_title_in_es_as_fallback_locale
    I18n.default_locale = :es
    I18n.locale = :undefined
    article = Article.first
    assert_equal article.send('title_in_es'), article.title
  end

  def test_wrong_method_should_raise_nomethod_error
    assert_raises NoMethodError do
      Article.foo_bar
    end
  end

end