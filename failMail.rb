begin
  require 'rubygems'
  require 'tlsmail'
  require 'mail'     # http://github.com/mikel/mail
  require 'yaml'
  
rescue LoadError => e
  puts "Missing dependency #{e.message}"
  exit 1
end

# TODO: did the build pass/fail?

# Find an appropriate image based on the build status
parsedImages = begin
  YAML.load(File.open("reactionImages.yaml"))
rescue Exception => e
  puts "Error parsing images YAML: #{e.message}"
end

# args from Jenkis
jobName = ARGV[0]
buildURL = ARGV[1]
buildNumber = ARGV[2]

failImage = parsedImages['failImages'].sample(1)[0]

# build the email to send
emailHTML = File.read('msg_fail.html')

emailHTML.gsub! '[IMAGE_LINK]', failImage

emailHTML.gsub! '[JOB_NAME]', jobName
emailHTML.gsub! '[BUILD_URL]', buildURL
emailHTML.gsub! '[BUILD_DISPLAY_NAME]', buildNumber


# send the email
Mail.defaults do
  delivery_method :smtp, { 
    :address => 'MAIL_SERVER',
    :port => '587',
    :user_name => 'MAIL_USERNAME',
    :password => 'MAIL_PASSWORD',
    :authentication => :plain,
    :enable_starttls_auto => true,
    :domain => 'MAIL_DOMAIN',
    :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
  }
end

Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
mail = Mail.new do
    from "MAIL_SENDER"
    to "MAIL_GETTER"
    subject "testing 1, 2, 3"
    
    text_part do
        body 'Jenkins failed. Fix it.'
    end

    html_part do
        content_type 'text/html; charset=UTF-8'
        body emailHTML
    end
end

mail.deliver!