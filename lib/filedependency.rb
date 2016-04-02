# This class takes the following arguments:
# search_path = string  # The starting path of the deep search for files, i.e. /myfolder
# files = string(Regex) # A Regex pattern to match files, i.e *.sql or *myfile*.??? ...
# pattern = array       # An array of additional <Regex> patterns to be looked for in the files
#                       # i.e *-dep or *foo.?bar.sh
#
# The class returns a hash of sorted file dependencies using Tsort of the stdlib.
# 
require 'find' # to be removed when bundled
require 'tsort' # to be removed when bundled

class FileDependency
  include TSort

  def initialize(start_path, files, pattern)
    @path = start_path
    @files = find_all_files(start_path, files)
    @pattern = pattern
    @file_dependencies = get_file_dependency
  end

  #takes path and filepattern and returns array of files with full path
  # => [ "path_to_file/file1, "path_to_file/file2" ]

  def get_file_dependency
    deps = {}
    filenames = @files.map { |el| File.basename(el) }
    @files.each do |file|
      temparray = []
      File.readlines(file).each do |line|
        if line =~ match_against(filenames)
          temparray << full_filepath(@path, line.strip)
        end
      end
      deps[file] = temparray if temparray
    end
    return deps
  end

  def sort
    if has_self_referential_files?
      raise FileDependencyError, 'files cannot be self-referntial'
    end
    begin
      self.tsort
    rescue TSort::Cyclic
      raise FileDependencyError, 'files cannot have circular dependencies'
    end
  end

  private

  def find_all_files(path, files)
    matched_files = []
    Find.find(path) do |match|
      matched_files << match if match =~ /.#{files}/
    end
    return matched_files
  end

  def full_filepath(path, file)
    result = ''
    Find.find(path) { |match| result << match if match =~ /.#{file}/ }
    return result
  end

  def match_against(pattern)
    Regexp.union(pattern)
  end

  def has_self_referential_files?
    @file_dependencies.any? { |file, deps| deps.include? file }
  end

  #TSort methods
  def tsort_each_node(&block)
    @file_dependencies.each_key(&block)
  end

  def tsort_each_child(node, &block)
    @file_dependencies[node].each(&block)
  end
end

class FileDependencyError < Exception
end
