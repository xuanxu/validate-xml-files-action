require "ojxv"

def print_errors(errors, schema, filepath)
  system("echo 'CUSTOM_ERROR=The generated XML metadata file is invalid.' >> $GITHUB_ENV")
  system("echo '!! Invalid #{schema} in #{filepath}. Errors: #{errors.size}. '")
  errors.each do |error|
    system("echo '  - #{error}'")
  end
  raise "   !! ERROR: Invalid #{schema} file"
end

def only_allowed_errors?(error_list)
  allowed_errors_for_drafts = ["doi: [facet minLength]", "doi: [facet pattern]"]
  error_list.all? { |e| allowed_errors_for_drafts.any?{ |allowed| e.match?(allowed) }}
end

validation_mode = ENV["VALIDATION_MODE"].to_s.strip
jats_path = ENV["JATS_PATH"].to_s.strip
crossref_path = ENV["CROSSREF_PATH"].to_s.strip


# Validate Crossref XML file if present
if !crossref_path.empty? && File.exist?(crossref_path)
  crossref_file = OJXV::CrossrefMetadataFile.new(crossref_path)

  if crossref_file.valid_crossref?("5.3.1")
    system("echo 'Validation successful! The file #{crossref_path} contains valid Crossref XML v5.3.1'")
  elsif validation_mode == "draft" && only_allowed_errors?(crossref_file.errors)
    system("echo 'Validation successful! The draft file #{crossref_path} contains no DOI but otherwise valid Crossref XML v5.3.1'")
  else
    print_errors(crossref_file.errors, "Crossref XML v5.3.1", crossref_path)
  end
end

# Validate JATS file if present
if !jats_path.empty? && File.exist?(jats_path)
  jats_file = OJXV::JatsFile.new(jats_path)

  if jats_file.valid_jats?("1.3")
    system("echo 'Validation successful! The file #{jats_path} contains valid JATS v1.3'")
  else
    print_errors(jats_file.errors, "JATS v1.3", jats_path)
  end
end
