require "ojxv"

def print_errors(errors, schema, filepath)
  system("echo '!! Invalid #{schema} in #{filepath}. Errors: #{errors.size}. '")
  errors.each do |error|
    system("echo '  - #{error}'")
  end
end

validation_mode = ENV["VALIDATION_MODE"].to_s.strip
jats_path = ENV["JATS_PATH"].to_s.strip
crossref_path = ENV["CROSSREF_PATH"].to_s.strip


# Validate Crossref XML file if present
if !crossref_path.empty? && File.exist?(crossref_path)
  crossref_file = OJXV::CrossrefMetadataFile.new(crossref_path)

  if crossref_file.valid_crossref?("5.3.1")
    system("echo 'Validation successful! The file #{crossref_path} contains valid Crossref XML v5.3.1'")
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
