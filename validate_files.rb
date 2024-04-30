require "ojxv"


## Parse errors and build legible markdown
def detailed_message(errors)
  msg = ""
  error_msgs = []
  errors.each do |error|
    clean_error = error.to_s.gsub(/'\{[^\}]*\}([^']*)'/, "\\+")
    detail = clean_error.match(/\A.*ERROR: (.*)\z/m)
    error_msgs << detail[1] unless detail.nil?
  end
  error_msgs.compact!
  unless error_msgs.empty?
    msg = <<~ERRORS


    ```yaml
    #{error_msgs.join("\n")}
    ```
    ERRORS
  end
  msg
end

# print errors in the workflow console and post them back to the review issue and raise a failure
def print_errors(errors, schema, filepath)
  system("echo '!! Invalid #{schema} in #{filepath}. Errors: #{errors.size}. '")
  errors.each do |error|
    system("echo '  - #{error}'")
  end

  error_msg = "The generated XML metadata file is invalid."
  File.open('oj_custom_error.txt', 'w') do |f|
    f.write [ENV['DEFAULT_ERROR'], error_msg, detailed_message(errors)].join(" ")
  end
  system("gh issue comment #{ENV['ISSUE_ID']} --body-file oj_custom_error.txt")
  system("echo 'CUSTOM_ERROR_STATUS=sent' >> $GITHUB_ENV")

  raise "   !! ERROR: Invalid #{schema} file"
end

# print errors in the workflow console, post them back to the review issue but dont fail
def ignore_errors(errors, schema, filepath)
  system("echo '!! Invalid #{schema} in #{filepath}. Errors: #{errors.size}. '")
  system("echo '!! Mode: Ignoring errors. '")
  errors.each do |error|
    system("echo '  - #{error}'")
  end

  error_msg = "The generated #{schema} metadata file is invalid."
  File.open('oj_custom_error.txt', 'w') do |f|
    f.write [":warning: Ignoring errors that could prevent acceptance", error_msg, detailed_message(errors)].join(" ")
  end
  system("gh issue comment #{ENV['ISSUE_ID']} --body-file oj_custom_error.txt")
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
  elsif validation_mode == "ignore-errors"
    ignore_errors(crossref_file.errors, "Crossref XML v5.3.1", crossref_path)
  else
    print_errors(crossref_file.errors, "Crossref XML v5.3.1", crossref_path)
  end
end

# Validate JATS file if present
if !jats_path.empty? && File.exist?(jats_path)
  jats_file = OJXV::JatsFile.new(jats_path)

  if jats_file.valid_jats?("1.3")
    system("echo 'Validation successful! The file #{jats_path} contains valid JATS v1.3'")
  elsif validation_mode == "ignore-errors"
    ignore_errors(jats_file.errors, "JATS v1.3", jats_path)
  else
    print_errors(jats_file.errors, "JATS v1.3", jats_path)
  end
end
