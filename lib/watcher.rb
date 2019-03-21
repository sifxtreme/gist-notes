require_relative './config'
require_relative './uploader'

require 'listen'
require 'pry'

def gist_notes
  GistNotes::Uploader.new
end

def is_valid_file_path?(path)
  [1,2].include?(path.gsub(Config::GIST_NOTES_PATH, "").split("/").count)
end

def remove_paths(paths)
  return unless is_valid_file_path?(paths.first)
  
  paths.each { |path| gist_notes.delete_folder(path) }

  puts "removed: #{paths}"
end

def add_paths(paths)
  return unless is_valid_file_path?(paths.first)

  paths.each { |path| gist_notes.add_folder(path) }

  puts "added: #{paths}"
end

def modified_paths(paths)
  return unless is_valid_file_path?(paths.first)

  paths.each { |path| gist_notes.add_folder(path) }

  puts "modified: #{paths}"
end

listener = Listen.to(Config::GIST_NOTES_PATH) do |modified, added, removed|
  remove_paths(removed) if removed.any?
  add_paths(added) if added.any?
  modified_paths(modified) if modified.any?
end

listener.start # not blocking
sleep