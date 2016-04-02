#!/usr/bin/env ruby
$LOAD_PATH << './lib'

require 'filedependency'

dep = FileDependency.new('/Users/mario/apps', '*.sql', [ "test1", "test2" ])
puts dep.get_file_dependency
puts dep.sort
