# frozen_string_literal: true

require_relative './config'
require_relative './uploader'

require 'listen'
require 'pry'

def gist_notes
  GistNotes::Uploader.new
end

def valid_file_path?(path)
  [1, 2].include?(path.gsub(Config::GIST_NOTES_PATH, '').split('/').count)
end

def remove_paths(paths)
  return unless valid_file_path?(paths.first)

  puts "removed: #{paths}"
  paths.each do |path|
    File.directory?(path) ? gist_notes.delete_folder(path) : gist_notes.add_folder(path)
  end
end

def add_paths(paths)
  return unless valid_file_path?(paths.first)

  puts "added: #{paths}"
  paths.each do |path|
    gist_notes.add_folder(path)
  end
end

def modified_paths(paths)
  return unless valid_file_path?(paths.first)

  puts "modified: #{paths}"
  paths.each do |path|
    gist_notes.add_folder(path)
  end
end

listener = Listen.to(Config::GIST_NOTES_PATH) do |modified, added, removed|
  remove_paths(removed) if removed.any?
  add_paths(added) if added.any?
  modified_paths(modified) if modified.any?
end

listener.start # not blocking
sleep
