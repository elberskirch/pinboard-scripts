
# GENERAL INFO
## Intro
I like my pinboard account, but sometimes things get messy and I lose track and focus. So I forget about cool links or ideas that I had. 
These simple scripts didn't feel complete or worthy enough to put them in a gem. I feel their natural habitat is ~/bin where all the neat selfwritten software resides.  

## API TOKEN
All scripts use the pinboard api token to authenticate the api calls. 
Get your pinboard api token from this URL: https://pinboard.in/settings/password
Put it in ".pinboard_token" in your home directory. That's where the scripts will look for it.

# SCRIPTS

## pinboard-digest.rb
* lists most recent pinboard bookmarks and can optionally send them to you via email as text or html 
* picks random bookmark

Intended to be run by cron. Whenever you feel it's necessary. I run the script once a day, to keep track of the last few days of bookmarks.

### usage
   pinboard-digest.rb [--html] --max 100 [--receiver EMAIL]

### .mailer.json
Put this in your home directory. If --receiver is set pinboard-digest.rb will try to load the file.

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
