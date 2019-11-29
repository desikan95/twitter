defmodule TwitterTest do
  use ExUnit.Case
  doctest TwitterApp, async: false


  test "storeTweet" do
    IO.puts "test 2"
    TwitterEngine.addFollowing(1,1)
    user = TwitterEngine.storeTweet(1,"tweet from user 1")
    value2 = :ets.match_object(:users,{:"$1",:"$2"})

    assert true
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
    TwitterEngine.registerUser(10000,10000)
    TwitterEngine.addFollowing(9000,9000)
    TwitterEngine.addFollowing(10000,10000)
    TwitterEngine.addFollowing(9000,10000)

    #User 10 retweeting
    TwitterEngine.retweets(10000)
    #After 10 retweets a message, 10's followers should be able to see the message

    [{10000,user10_tweet}] = TwitterEngine.getTweets(10000)
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
end
