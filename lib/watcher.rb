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
  if paths.count > 1
    gist_notes.delete_folder(folder)
  else
    gist_notes.change_file(paths.first, delete: true)
  end

  puts "removed: #{paths}"
end

def add_paths(paths)
  return unless is_valid_file_path?(paths.first)

  if paths.count > 1
    gist_notes.add_folder(folder)
  else
    gist_notes.change_file(paths.first, add: true)
  end

  puts "added: #{paths}"
end

def modified_paths(paths)
  return unless is_valid_file_path?(paths.first)

  raise "you can modify multiple paths at once?" if paths.count > 1

  gist_notes.change_file(paths.first, change: true)

  puts "modified: #{paths}"
end

listener = Listen.to(Config::GIST_NOTES_PATH) do |modified, added, removed|
  
  if removed.any?
    remove_paths(removed)
  end
  
  if added.any?
    add_paths(added)
  end

  if modified.any?
    modified_paths(modified)
  end

end
listener.start # not blocking
sleep