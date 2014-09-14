
# API TOKEN
Get your pinboard api token from this URL: https://pinboard.in/settings/password

Put it in ".pinboard_token" in your home directory. That's where the scripts will look for it.

# scripts
* pinboard-digest.rb
  lists most recent pinboard bookmarks and sends them to you via email
  picks random bookmark
## usage
  pinboard-digest.rb --html --maxlinks=100

## .mailer.json

Example for gmail. Make sure to switch to less security enabled mode, otherwise smtp authentication won't work.

  {
    "smtp": {
        "address" : "smtp.gmail.com",
        "port" : "587",
        "enable_starttls_auto" : "true",
        "user_name" : "USERNAME",
        "password" : "PASSWD",
        "authentication" : "plain",
        "domain" :"localhost.localdomain"
      }
  }
