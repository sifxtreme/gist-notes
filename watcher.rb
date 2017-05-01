require 'listen'

NOTES_FILE_PATH='../gist-note-files'

listener = Listen.to(NOTES_FILE_PATH) do |modified, added, removed|
  puts "modified absolute path: #{modified}"
  puts "added absolute path: #{added}"
  puts "removed absolute path: #{removed}"
end
listener.start # not blocking
sleep