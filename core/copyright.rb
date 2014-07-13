module ProjectHanlon

  # This implements the logic to build hanlon copyright information from LICENSE file
  #
  # LICENSE File sample
  # ===================
  # Hanlon - Copyright (C) 2012 EMC Corporation
  #          Copyright (C) 2012-2013 Puppet Labs LLC
  #          Copyright (C) 2014 Computer Sciences Corporation
  #
  # This module tries to read LICENSE file line by line until a blank line or a line that
  # does not contain Copyright string and build the copy right string

  Copy_Right = ""
  File.open("LICENSE", "r").each_line do |line|
    break if line.strip == ""
    Copy_Right += line if line.upcase.include? "COPYRIGHT"
  end

end