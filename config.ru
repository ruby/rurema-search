# -*- ruby -*-

require 'pathname'

base_dir = Pathname.new(__FILE__).dirname.cleanpath.realpath
lib_dir = base_dir + "lib"

bitclust_dir = base_dir.parent + "bitclust"
bitclust_lib_dir = bitclust_dir + "lib"

$LOAD_PATH.unshift(bitclust_lib_dir.to_s)
$LOAD_PATH.unshift(lib_dir.to_s)

require 'rurema_search'
require 'rurema_search/groonga_searcher'

database = RuremaSearch::GroongaDatabase.new
database.open((base_dir + "groonga-database").to_s, "utf-8")

environment = ENV["RACK_ENV"] || "development"

use Rack::CommonLogger
use Rack::ShowExceptions
use Rack::Runtime
case environment
when "development"
  class DirectoryIndex
    def initialize(app, options={})
      @app = app
      @urls = options[:urls]
    end

    def call(env)
      path = env["PATH_INFO"]
      can_serve = @urls.any? { |url| path.index(url) == 0 }
      env["PATH_INFO"] += "index.html" if can_serve and /\/\z/ =~ path
      @app.call(env)
    end
  end

  urls = ["/favicon.ico", "/css/", "/images/", "/js/", "/1.8.", "/1.9"]
  use DirectoryIndex, :urls => urls
  use Rack::Static, :urls => urls, :root => (base_dir + "public").to_s
end

use Rack::Lint
run RuremaSearch::GroongaSearcher.new(database, base_dir.to_s)