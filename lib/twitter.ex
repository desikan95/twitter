defmodule TwitterEngine do
  use GenServer

  def start_link(_) do
    {:ok,pid} = GenServer.start_link(__MODULE__,[])
    IO.puts "Engine is now running"
    pid
  end

  def init(_) do
  # Create all ets tables
  #Registration table
  #User -> Password mapping





  #Tweets -> User mapping
    :ets.new(:registrations, [:set, :public, :named_table])

    #User -> Tweets he needs to see
    :ets.new(:users, [:bag, :public, :named_table])

    #User -> Following mapping
    :ets.new(:userfollowing, [:bag, :public, :named_table])

    IO.puts "Created tables"
    {:ok,[]}
  end


  def registerUser(username, password) do
    :ets.insert(:registrations, {username,password})
    :ets.insert(:userfollowing, {username,username})
    IO.puts "Added"
  end

  def displayusers() do
    result = :ets.match_object(:registrations,{:'$1',:'$2'})
    value = :ets.lookup(:registrations, "a")
    userb = "b"
    valueb = :ets.lookup(:registrations, userb)
    IO.inspect result
    IO.inspect valueb
  end

  def deleteUser() do
  end

  def getTweets() do
  end

  def storeTweet(user,msg,retweet_ctr \\ 0) do

    hashtags =  Regex.scan(~r/#(\w*)/, msg)
                |> Enum.map(fn(c) -> Enum.at(c,1) end)


    mentions =  Regex.scan(~r/@(\w*)/, msg)
                |> Enum.map( fn(c) -> Enum.at(c,1) end)


    #Getalluserfollowers
    user_followers = :ets.match_object(:userfollowing, {:'$1',:'$2'})
    IO.puts "User followers list is as follows"
    IO.inspect user_followers

    user_followers_map = Enum.map(user_followers,
                            fn (x) -> {key,_} = x
                                      values = Enum.map(user_followers,
                                                fn(x)->
                                                  {newkey, value} = x;
                                                  if (newkey==key)
                                                  do
                                                    value
                                                  end
                                                end)
                                                |> Enum.reject(fn(x) -> x==:nil end)
                                       {key,values}
                                    end)
                           |> Map.new

      users_list = Enum.map(user_followers, fn (user) -> {key,_} = user
                                                          key
                            end)
                   |> Enum.uniq

      followers = Enum.map(users_list, fn (x)->
                    follows = Map.get(user_followers_map,x)
                    if Enum.member?(follows,user) == true
                    do
                        x
                    end
                  end)
                  |> Enum.reject(fn(x) -> x==:nil end)

       IO.puts "List of followers of "
       IO.inspect user
       IO.puts " : "
       IO.inspect followers

       current_time = :calendar.local_time()
       Enum.each(followers,fn(f)->
         :ets.insert(:users, {f,[msg,hashtags,mentions,current_time,retweet_ctr,user]})
       end)


  end

  #this search is public. Can search tweets even if I'm not subscribed to it
  def searchTweetsByHashtag(hashtag) do
    result = :ets.match_object(:users, {:'$1',:'$2'})
    hashtag_tweets = Enum.map(result, fn (r)->
                        {_,tweet} = r
                        hashtags_list = Enum.at(tweet, 1)  #Gets the hashtag list for each result in the table
                        if (Enum.member?(hashtags_list,hashtag) == true)
                        do
                          Enum.at(tweet, 0)  #Return the tweet message, which is stored at 0
                        end
                     end)
                     |> Enum.uniq
                     |> Enum.reject(fn(x) -> x==:nil end)


      IO.puts "List of tweets contains that hashtag are : "
      IO.inspect hashtag_tweets
  end

  #this search is also public
  def getMyMentions(username) do
    result = :ets.match_object(:users, {:'$1',:'$2'})
    my_mentions = Enum.map(result, fn (r)->
                    {_,tweet} = r
                    mentions_list = Enum.at(tweet, 2)   #Gets the mentions list for each result in the table
                    if (Enum.member?(mentions_list,username) == true)
                    do
                      Enum.at(tweet, 0)   #Return the tweet message, which is stored at 0
                    end
                 end)
                 |> Enum.uniq
                 |> Enum.reject(fn(x) -> x==:nil end)

      IO.puts "List of my mentions are : "
      IO.inspect my_mentions
  end

  #private search. Only querying my subscriber's tweets
  def searchTweetsSubscribedTo(username,search) do
    tweets = :ets.lookup(:users,username)
    tweet_msg = Enum.map(tweets, fn (t)->
                  {_,tweet_result} = t
                  Enum.at(tweet_result,0)
                end)

    IO.puts " Here are the list of messages relevant : "
    IO.inspect tweet_msg

    {:ok,regex_string} = Regex.compile(search)
    search_result = Enum.map(tweet_msg,fn (tweet)->


                      if (Regex.match?(regex_string,tweet) == true)
                        do
                        {
                          tweet
                        }
                      end
                    end)
                    |> Enum.reject (fn x -> x==:nil end)
    IO.puts "Here are the list of valid searches"
    IO.inspect search_result
  end

  #public. Can retweet a random message
  def retweets(username) do
    result = :ets.match_object(:users, {:'$1',:'$2'})

    random_result = Enum.map(result, fn (r)->
                      {_,result} = r
                      result
                    end)
                    |> Enum.random
    tweet_msg = Enum.at(random_result,0)
    retweet_ctr = Enum.at(random_result,4)

    IO.puts "Retweeting the following message : "
    IO.inspect tweet_msg

    TwitterEngine.storeTweet(username, tweet_msg, retweet_ctr+1)
  end

  def addFollowing(user1,user2) do
    #Add functionality to add followers
    IO.puts "User 1 is following user 2"
    :ets.insert(:userfollowing, {user1,user2})
  end

  def getFollowing(user1) do
    result = :ets.match_object(:userfollowing,{user1,:_})
    IO.inspect result


  end

  def simulate() do
    #random tweeting
    #random following
  end

  def getTweets(user) do
    value = :ets.lookup(:users,user)
    IO.puts "Messages of this user are "
    IO.inspect value
  end

  def retweet(msg) do
  end



end

defmodule ClientSupervisor do
  use Supervisor

  def start_link(users) do
    {:ok, pid} = Supervisor.start_link(__MODULE__,users,name: __MODULE__)
    displayUsers(pid)
    pid
  end

  def init(users) do

    children = Enum.map(1..(users),fn (x) -> Supervisor.child_spec(Client,id: x) end)
    Supervisor.init(children, strategy: :one_for_one)
  end

  def addNewTweet(pid) do
    user = IO.gets "Which user do you want to tweet as ? "
    user = String.trim(user, "\n")
    #Add functionality to check if user exists
    #Add functinoality to make user log in if he's not logged in already

    proc = Supervisor.which_children(pid)
    Enum.each(proc, fn (x) ->
      {_,node,_,_} = x
      username = GenServer.call(node,{:getUsername})
      IO.puts "username is "
      IO.inspect username
      cond do
        username == user -> msg = IO.gets "Enter tweet msg"
                            msg = String.trim(msg,"\n")
                            GenServer.cast(node,{:addTweet,msg})
        true -> IO.puts "Username not found in DB"
      end
     end)

  end

  def displayUsers(pid) do
    proc = Supervisor.which_children(pid)
    Enum.each(proc,
      fn (x) ->
            IO.inspect x
    end)
  end


end

defmodule Client do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__,[])
  end

  def init(_val) do

    username = IO.gets "Enter preferred username"
    username = String.trim(username, "\n")

    IO.puts "Username "
    IO.inspect username
    IO.puts "created ! "
    TwitterEngine.registerUser(username,username)
    {:ok,username}
  end

  def handle_call({:getUsername},_from,username) do
    {:reply,username,username}
  end


  def handle_cast({:addTweet,msg},username) do
    IO.puts "Tweeting "
    IO.inspect msg

    #If logged in
    TwitterEngine.storeTweet(username,msg)

    #if Not logged in, then make user login. Functionality to be added later.

    {:noreply,username}
  end
end
