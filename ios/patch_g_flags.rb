#!/usr/bin/env ruby

# Paths to search for files
pod_dir = File.expand_path('../Pods', __FILE__)
build_dir = File.expand_path('../build', __FILE__)

# List of file extensions to check for text-based files
text_extensions = %w[.c .cpp .cc .cxx .h .hpp .m .mm .swift .podspec .pbxproj .xcconfig .cmake]

# Count of fixed files
files_fixed = 0

def fix_file(file_path)
  if !File.file?(file_path) || File.binary?(file_path)
    return false
  end
  
  original_content = File.read(file_path)
  # Only modify if it contains the -G flag
  if original_content.include?('-G')
    # Apply multiple replacements to catch different -G flag variations
    modified_content = original_content.gsub(/ -G /, ' ')
                                     .gsub(/ -G,/, ',')
                                     .gsub(/,-G /, ',')
                                     .gsub(/,-G,/, ',')
                                     .gsub(/"-G"/, '""')
                                     .gsub(/ -G$/, '')
                                     .gsub(/^-G /, '')
    
    # Only write if we actually made changes
    if modified_content != original_content
      File.write(file_path, modified_content)
      puts "Fixed -G flag in #{file_path}"
      return true
    end
  end
  false
end

# Special handler for BoringSSL-GRPC xcconfig files
Dir.glob("#{pod_dir}/Target Support Files/BoringSSL-GRPC/*.xcconfig").each do |config_file|
  contents = File.read(config_file)
  
  # Remove any -G flags in the OTHER_CFLAGS
  if contents.include?('OTHER_CFLAGS')
    new_contents = contents.gsub(/OTHER_CFLAGS = (.*)-G(.*)/, 'OTHER_CFLAGS = \1\2')
                         .gsub(/OTHER_CFLAGS = (.*) -G /, 'OTHER_CFLAGS = \1 ')
                         .gsub(/OTHER_CFLAGS = (.*) -G$/, 'OTHER_CFLAGS = \1')
    if new_contents != contents
      File.write(config_file, new_contents)
      puts "Fixed -G flag in #{config_file}"
      files_fixed += 1
    end
  end
  
  # Also apply for OTHER_CPLUSPLUSFLAGS
  if contents.include?('OTHER_CPLUSPLUSFLAGS')
    new_contents = contents.gsub(/OTHER_CPLUSPLUSFLAGS = (.*)-G(.*)/, 'OTHER_CPLUSPLUSFLAGS = \1\2')
                         .gsub(/OTHER_CPLUSPLUSFLAGS = (.*) -G /, 'OTHER_CPLUSPLUSFLAGS = \1 ')
                         .gsub(/OTHER_CPLUSPLUSFLAGS = (.*) -G$/, 'OTHER_CPLUSPLUSFLAGS = \1')
    if new_contents != contents
      File.write(config_file, new_contents)
      puts "Fixed -G flag in #{config_file}"
      files_fixed += 1
    end
  end
  
  # Add safe compiler flags
  if !contents.include?('-DOPENSSL_NO_ASM')
    new_contents = contents + "\nOTHER_CFLAGS = $(inherited) -DOPENSSL_NO_ASM\n"
    File.write(config_file, new_contents)
    puts "Added safe compiler flags to #{config_file}"
    files_fixed += 1
  end
end

# Process the main project.pbxproj file 
pbxproj_path = "#{pod_dir}/Pods.xcodeproj/project.pbxproj"
if File.exist?(pbxproj_path)
  if fix_file(pbxproj_path)
    files_fixed += 1
  end
end

# Search all other files in pods directory for -G flags
Dir.glob("#{pod_dir}/**/*").each do |file_path|
  next unless File.file?(file_path) 
  next if File.binary?(file_path)
  next unless text_extensions.any? { |ext| file_path.end_with?(ext) }
  
  if fix_file(file_path)
    files_fixed += 1
  end
end

puts "Total files fixed: #{files_fixed}"
