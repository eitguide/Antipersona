# How Shadowing Works

To reconstruct the timeline for the Shadowed User, we create a
private list that contains all the users that user follows. Then the
list timeline given with `lists/statuses` should be the same as the
timeline that the Shadowed User sees (except for tweets made by
protected users).

# Workers

Multiple workers are timed to retrieve different data about the Twitter
user that's being shadowed. The frequency of calls is such that the
[API rate limits](https://dev.twitter.com/rest/public/rate-limits) are
never reached.

### ListWorker

This worker is triggered when the user chooses to shadow a new Twitter
account. It populates our private list with the ids of the Twitter users that the
Shadowed User is following. This is at most triggered once per
day. This constraint arises both due to limitations of the Twitter API
(updating a list often causes the `lists` API to enter a
weird undocumented state where you can't add anyone to a list)
and to force the person using the app to be more thoughtful about who
they want to become.

- Frequency: at most once a day, user-initiated
- API call: POST lists/destroy.json
- Parameters:
  * list_id=[old_list_id]

Followed by:

- API call: POST lists/create
- Parameters:
  * name=peopleportal
  * mode=private

Followed by:

- Frequency: at most once a day
- API call: POST lists/members/create_all
- Parameters:
  * list_id=[current_list_id]
  * user_id=...

### TimelineWorker

Populates the Shadowed User's timeline.

- Frequency: every 60s
- API call: GET lists/statuses
- Parameters:
  * list_id=[current_list_id]
  * count=200
  * since_id=[last_id_in_current_home_timeline]

### ProfileWorker

Populates the view of Shadowed User's own tweets.

- Frequency: every 60s
- API call: GET statuses/user_timeline
- Parameters:
  * list_id=[current_user_id]
  * count=200
  * since_id=[last_id_in_current_user_timeline]

### MentionsWorker

Listens for new mentions for the Shadowed User.

- Frequency: every 30s
- API call: GET search/tweets.json
- Parameters:
  * q=%40[username]
  * result_type=recent
  * count=100

### RetweetsWorker

Listens for new retweets of the Shadowed User.

- Frequency: every 30s
- API call: GET search/tweets.json
- Parameters:
  * q=RT%20%40[username]
  * result_type=recent
  * count=100

### FollowsWorker

Listens for new follows of the Shadowed User.

Consists of two calls:

- Frequency: every 60s
- API Call: GET followers/ids.json
- Parameters:
  * user_id=[user_id]
  * count=5000

If there are any new recent ids, then this is followed by:

- API Call: GET followers/list.json
- Parameters:
  * user_id=[user_id]
  * count=20
  * skip_status=true
  * include_user_entities=false

to get a few of the new follows (so we have a few screennames to show
a notification like "X, Y, and 10 others followed you")
