#!/usr/bin/env ruby

# This script patches the BoringSSL-GRPC podspec file to remove problematic flags

require 'fileutils'

# Find BoringSSL-GRPC podspec file in ~/.cocoapods/repos
def find_podspec_file
  cocoapods_dir = File.expand_path('~/.cocoapods/repos')
  podspec_path = nil
  
  # Search for the BoringSSL-GRPC podspec file
  Dir.glob("#{cocoapods_dir}/**/BoringSSL-GRPC.podspec").each do |file|
    podspec_path = file
    break
  end
  
  # If we can't find it in the repos, look in the local Pods directory
  if podspec_path.nil?
    ios_dir = ENV['IOS_DIR'] || File.expand_path('../ios', __dir__)
    Dir.glob("#{ios_dir}/Pods/BoringSSL-GRPC/BoringSSL-GRPC.podspec").each do |file|
      podspec_path = file
      break
    end
  end
  
  podspec_path
end

# Patch the podspec file
def patch_podspec(file_path)
  return false unless file_path && File.exist?(file_path)
  
  # Read the podspec file
  content = File.read(file_path)
  
  # Make a backup
  FileUtils.cp(file_path, "#{file_path}.bak")
  
  # Remove -G flags from compiler flags
  modified_content = content.gsub(/'-G', /, '')
  modified_content = modified_content.gsub(/, '-G'/, '')
  modified_content = modified_content.gsub(/'-G'/, '')
  
  # Write the modified content back to the file
  File.write(file_path, modified_content)
  
  # Check if we made changes
  content != modified_content
end

# Patch BoringSSL-GRPC podspec
podspec_file = find_podspec_file
if podspec_file
  puts "Found BoringSSL-GRPC podspec at: #{podspec_file}"
  if patch_podspec(podspec_file)
    puts "Successfully patched BoringSSL-GRPC podspec"
  else
    puts "No changes needed or could not patch BoringSSL-GRPC podspec"
  end
else
  puts "Could not find BoringSSL-GRPC podspec file"
end

# Also patch Pods directory directly if it exists
ios_dir = ENV['IOS_DIR'] || File.expand_path('../ios', __dir__)
local_podspec = "#{ios_dir}/Pods/BoringSSL-GRPC/BoringSSL-GRPC.podspec"
if File.exist?(local_podspec)
  puts "Found local BoringSSL-GRPC podspec at: #{local_podspec}"
  if patch_podspec(local_podspec)
    puts "Successfully patched local BoringSSL-GRPC podspec"
  else
    puts "No changes needed or could not patch local BoringSSL-GRPC podspec"
  end
end
