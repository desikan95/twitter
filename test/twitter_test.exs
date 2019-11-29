defmodule TwitterTest do
  use ExUnit.Case
  doctest TwitterApp, async: false

  test "registration" do
    username="username"
    password="password"
    TwitterEngine.registerUser(username, password)
    assert  [{"username", "password"}] ==:ets.lookup(:registrations, username)
  end

  test "delete users" do
    username="username"
    password="password"
    TwitterEngine.registerUser(username, password)
    TwitterEngine.deleteUser(username)
    assert [] == :ets.lookup(:registrations, username)
  end

  test "add following to users  " do
    username1="user1"
    username2="user2"
    TwitterEngine.addFollowing(username1,username2)
    assert [{"user1", "user2"}] == :ets.lookup(:userfollowing,username1)
  end



  #storeTweet function collects all the subscribers of a particular user and when a tweet is made by the user the tweet
  #is stored agaisnt each of its subscriber in the database.
  test " storing tweets to the  database" do
    TwitterEngine.addFollowing(40000,30000)
    TwitterEngine.addFollowing(10000,30000) # user 1 and User 4 are subscribed to tweets of User 3
    msg = "Hii "
    TwitterEngine.storeTweet(30000,msg)
     # when user 3 publishes a tweet, the tweet is stored against all of it subscribers in the database(in this case user 1 and user 4)
    record4 = :ets.lookup(:users,40000)
    record1 = :ets.lookup(:users,10000)
    record = :ets.lookup(:users,40000)
    [{40000,record4}] = :ets.lookup(:users,40000)
    [{10000,record1}] = :ets.lookup(:users,10000)
    result_msg4 =  Enum.at(record4,0)
    result_msg1 = Enum.at(record1,0)
    # The message retrived against User 1 and User 4 from the database must be the same as the mesage tweeted by User 3
    assert result_msg4 == msg
    assert result_msg1 == msg
  end



  #storeTweet function collects all the subscribers of a particular user and when a tweet is made by the user the tweet
  #is stored agaisnt each of its subscriber in the database.
  test "storing tweets to the database - user specific" do
    TwitterEngine.addFollowing(50000,100000) # User 5 is subscribed to User 10
    TwitterEngine.addFollowing(70000,140000) # User 7 is subscribed to User 14
    msg = "Hii"
    TwitterEngine.storeTweet(140000,msg) # User 14 send out a tweet
    [{70000,record7}] = :ets.lookup(:users,70000)
    result_msg7 =  Enum.at(record7,0)
    record5 = :ets.lookup(:users,50000)
    assert result_msg7 == msg # Tweet sent out by User 14 must be saved against User 7(its subscriber) in the database
    assert record5 == [] # Whereas against User 5 no tweet must be stored, returns a empty list
  end

  test "Search Tweets Subscribed To" do
    IO.puts "Search Tweet Subscribed to"
    TwitterEngine.addFollowing(1,2)
    TwitterEngine.addFollowing(1,3)
    TwitterEngine.storeTweet(4,"Hello")
    TwitterEngine.storeTweet(2,"Hey! How are you guys doing")
    TwitterEngine.storeTweet(3,"Hello guys !")

    result = TwitterEngine.getTweets(1)
    IO.inspect result

    search_results = TwitterEngine.searchTweetsSubscribedTo(1,"guys")
    IO.inspect search_results
    #Even though all three tweets contain the term "guys", here we only search for tweets by followers we are subscribed to
    assert search_results == [{"Hey! How are you guys doing"},{"Hello guys !"}]
  end

  test "Search my mentions" do
    IO.puts "Search my mentions"
    #Even though 8 doesn't follow 5, we get

    TwitterEngine.addFollowing(5,6)
    TwitterEngine.addFollowing(5,8)
    TwitterEngine.registerUser(7,7)
    TwitterEngine.addFollowing(7,7)
    TwitterEngine.addFollowing(5,5)
    TwitterEngine.storeTweet(5,"I am user 5 #firsttweet")
    TwitterEngine.storeTweet(6,"Hey @5")
    TwitterEngine.storeTweet(7,"Hello @5 I want to follow you")
    TwitterEngine.storeTweet(8,"Tweet from user 8")

    search_results = TwitterEngine.getMyMentions(5)
    IO.inspect search_results

    assert length(search_results)==2
  end

  test "Search by hashtags" do
    IO.puts "Search by Hashtags"
  #  TwitterEngine.addFollowing(5,6)
    TwitterEngine.addFollowing(5,7)
    TwitterEngine.registerUser(7,7)
    TwitterEngine.registerUser(6,6)
    TwitterEngine.addFollowing(6,6)
    TwitterEngine.addFollowing(7,7)
    TwitterEngine.addFollowing(5,5)
    TwitterEngine.storeTweet(5,"I love dogs #pets")
    TwitterEngine.storeTweet(6,"I love cats #cats #pets")
    TwitterEngine.storeTweet(7,"I hate animals #pets")

    search_results = TwitterEngine.searchTweetsByHashtag("#pets")
    IO.inspect search_results

    assert length(search_results)==3
  end

  test "Retweets" do
    IO.puts "Retweeting"
    TwitterEngine.registerUser(9000,9000)
    TwitterEngine.registerUser(10001,10001)
    TwitterEngine.addFollowing(9000,9000)
    TwitterEngine.addFollowing(10001,10001)
    TwitterEngine.addFollowing(9000,10001)

    #User 10 retweeting
    TwitterEngine.retweets(10001)
    #After 10 retweets a message, 10's followers should be able to see the message

    [{10001,user10_tweet}] = TwitterEngine.getTweets(10001)
    user10_tweet = Enum.at(user10_tweet,0)
    IO.puts "Ten's tweets are : "
    IO.inspect user10_tweet

    [{9000,user9_tweet}] = TwitterEngine.getTweets(9000)
    user9_tweet = Enum.at(user9_tweet,0)
    IO.puts "Nine's tweets are : "
    IO.inspect user9_tweet

    #Thus 9 can see it 10's retweet because it is a follower
    assert user9_tweet==user10_tweet
end








#sendToLiveNode(user,list,msg) function sends a live notification msg tweeted by the 'user' if any of the user's subscribers are in live state
# The notification message is added to the list of live notifications that is held in the state of the live client for easy retrieval of those
#messages without any querying

  test "sending messages to live nodes" do
    IO.inspect "Entering the test case"
    {:ok,pid} = Client.start_link(10) # start a new client - user 10  whose default setting is set to live.
    TwitterEngine.addFollowing(10,20) # user 10 is subscribed to user 20.
    list= [[pid,10]]
    msg = "live notification"
    TwitterEngine.sendToLiveNode(20, list, msg) # User 10 sends out a tweet
    notification_list = GenServer.call(pid,{:getlivenotificationlist})
    assert List.last(notification_list) == msg # The message sent out by user 20 is the same message the exists in the notification list in the state of user 10
  end


  test "sending messages to live nodes - checking non-live nodes" do
    IO.inspect "Entering the test case"
    {:ok,spid} = Client.start_link(50) # start a new client
    GenServer.call(spid,{:setToOfflineMode}) # user is set to be in offline mode
    TwitterEngine.addFollowing(50,100) # user 50 is subscribed to user 100
    list= [[spid,50]]
    msg = "tweet"
    TwitterEngine.sendToLiveNode(100, list, msg) # User 100 sends out a tweet
    notification = GenServer.call(spid,{:getlivenotificationlist})

    assert notification == [] # The notification list in the state of the user remians empty even though one of its subscriber has sent a tweet.
    # The tweet is instead stored in the databse for retreival upon querying
  end
end
