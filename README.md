
# GENERAL INFO
## Intro
I like my pinboard account, but sometimes things get messy and I lose track and focus. So I forget about cool links or ideas that I had. 
These simple scripts didn't feel complete or worthy enough to put them in a gem. I feel their natural habitat is ~/bin where all the neat selfwritten software resides.  

Developed with Ruby 2.0.0

## API TOKEN
All scripts use the pinboard api token to authenticate the api calls. 
Get your pinboard api token from this URL: https://pinboard.in/settings/password
Put it in ".pinboard_token" in your home directory. That's where the scripts will look for it.

---

# SCRIPTS

## pinboard-digest.rb
This is some sort of reminder script, to remember what you bookmarked recently.

It's built to send you your X most recent bookmarks via email. It also picks a random bookmark from your account.
Can send html or text. Can send email through an smtp server (see .mailer.json). Looks best, when I send the html version to my gmail account. 

Intended to be run by cron. Whenever you feel it's necessary. I run the script once a day, to keep track of the last few days of bookmarks.

### usage

      $ pinboard-digest.rb [--html] --max 100 [--receiver EMAIL] -> maximum amount of bookmarks is 100
      
      $ pinboard-digest.rb --html --max 15 -> dumps html version to console, doesn't send email
      $ pinboard-digest.rb --max 15 --receiver some.dude@domain.com -> sends email with 15 links to the receiver
      
Doesn't limit the amount of requests. Therefore don't run it every second. Be gentle and kind to the pinboard api server. Otherwise you might be blocked.

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
