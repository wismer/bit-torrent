require 'sinatra'
require 'sinatra/base'
require 'json'
require 'torrenter'
require "net/http"

# class TorrenterViz < Sinatra::Base; end

# class TorrenterViz
get '/' do
  erb :index
end

get '/test' do
  $torrent.class.inspect
end

get '/torrent' do
  $status
end

get '/filer' do
  $torrent = Torrenter::Torrent.new
  Thread.new { $torrent.start(params[:torrent]) }.run
  redirect to('/')
end
# end