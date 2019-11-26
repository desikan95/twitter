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

    :ets.new(:userfollowers, [:set, :public, :named_table])

    IO.puts "Created tables"
    {:ok,[]}
  end



  def registerUser(username, password) do
    :ets.insert(:registrations, {username,password})
    :ets.insert(:userfollowing, {username,username})
    IO.puts "Added"
  end

  def loginUser(username,password)do
    searchresultofusername = :ets.lookup(:registrations,username)
    #IO.inspect username
    #IO.inspect password
    #IO.inspect searchresultofusername
    cond do
      Enum.empty?(searchresultofusername)->0

      true -> [head|_tail] = searchresultofusername
              cond do
                elem(head,0) == username && elem(head,1) == password ->1
                true->0
              end
    end

  end





  def displayusers() do
    result = :ets.match_object(:registrations,{:'$1',:'$2'})
    #value = :ets.lookup(:registrations, "a")
    #userb = "b"
    #valueb = :ets.lookup(:registrations, userb)
    #IO.inspect result
    #IO.inspect valueb
  end

  def deleteUser(username) do
    :ets.delete(:registrations, username)
    :ets.delete(:users, username)
    :ets.delete(:userfollowing, username)
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

      def sendToLiveNode(user,list,msg) do
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
                        |> Enum.reject(fn(x) -> x==user end)

        IO.inspect followers
        #if any of the followers are live, change their process state to include the message
       livenodepids =  Enum.map(followers,fn(follower)-> pids= Enum.map(list, fn(item_in_list)->
                                                                                                                #IO.inspect follower
                                                                                                                #IO.inspect item_in_list
                                                                                                                #IO.inspect Enum.at(item_in_list,1)
                                                                                                                #IO.inspect Enum.at(item_in_list,0)
                                                                                                              ids= cond do
                                                                                                               follower == Enum.at(item_in_list,1)-> id=  Enum.at(item_in_list,0)
                                                                                                                                                    id


                                                                                                               true-> []
                                                                                                                end
                                                                                                                ids
                                                                                        end )
                                                                                        IO.inspect pids


                                        end)
        IO.inspect livenodepids
        IO.puts "List of live nodes are"

        livepids = List.flatten(livenodepids)
        IO.inspect livepids

        Enum.each(livepids, fn(pid)->
                                  loginstatus =  GenServer.call(pid,{:getloginStatus})
                                          IO.inspect loginstatus
                                          cond do
                                            loginstatus == 1 -> GenServer.cast(pid, {:notifylivenode,msg})
                                                                #GenServer.call(pid,{:printstate})
                                            true->[]
                                          end
                                 end)
        #for every follower in the followers list
                  #retreive the pid-username mapping from the list
                      #get the loginstatus from the pid
                        #if login status is 1
                         #update the state to include the message

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
    #IO.puts "User 1 is following user 2"
    :ets.insert(:userfollowing, {user1,user2})
  end

  def displayFollowingTable do
    records =:ets.match_object(:userfollowing,{:"$1",:"$2"})
    records
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
    list = mapUserTopid(pid)
    #addNewTweet(pid,list)
    pid
  end



  @spec init(integer) :: {:ok, {map, [any]}}
  def init(users) do
    children = Enum.map(1..(users),fn (x) -> Supervisor.child_spec({Client,x},id: x) end)
    Supervisor.init(children, strategy: :one_for_one)
  end

  def simulate(num_user, num_msg) do
      pid = ClientSupervisor.start_link(num_user)
      proc = Supervisor.which_children(pid)
      usernames = Enum.map(proc, fn (x) ->
                    {_,node,_,_} = x
                    username = GenServer.call(node,{:getUsername})
                  end)
      IO.puts "The following usernames have been created"
      IO.inspect usernames
      following_count = Enum.random(1..num_user)
      Enum.each(usernames,fn (user)->
        #Each user follows random usernames
        Enum.each(1..following_count, fn _ ->
          new_following = Enum.random(usernames)
          TwitterEngine.addFollowing(user,new_following)
        end)
      end)

      IO.puts "Followers added"
      Enum.each(usernames, fn (user) ->
        TwitterEngine.getFollowing(user)
      end)

      msg_generator = Enum.map(1..num_msg, fn i ->
                        msg = "Tweet "<>Kernel.inspect(i)<>" from "
                        msg
                      end)
      user_msg_mapping = Enum.map(usernames, fn (user)->
                            msg_to_be_sent = Enum.map(msg_generator, fn (msg)->
                                                msg<>Kernel.inspect(user)
                                             end)


                            {user,msg_to_be_sent}
                          end)
                         |> Map.new

      IO.puts "The user msg mapping is as follows"
      IO.inspect user_msg_mapping

      Enum.each(usernames, fn (user)->
    #    Task.async(fn ->
              to_send_list = Map.get(user_msg_mapping, user)
              Enum.each(to_send_list, fn (msg)->
              #  Task.async(fn ->
                #  addNewTweet(pid,user,msg)
                  addNewTweetForSimulator(pid,user,msg,usernames)
            #    end)
              end)
    #    end)
      end)

     #Async task example
  #   1..100 |> Enum.each(fn x -> Task.async(fn -> IO.puts x end) end)





  end


  def mapUserTopid(pid) do
    processes = Supervisor.which_children(pid)
    list =Enum.map(processes, fn (x) ->
      {_,node,_,_} = x
      IO.inspect x
      IO.inspect node
      username = GenServer.call(node,{:getUsername})
      IO.inspect username
    #  IO.inspect [node,username]
      [node,username] end)
    list
  end

  def addNewTweetForSimulator(pid,user,msg,all_users) do

    list = mapUserTopid(pid)
    username_pid_map = Enum.map(list,fn (item)->
                          {Enum.at(item,1),Enum.at(item,0)}
                       end)
                       |> Map.new

    if (Enum.member?(all_users,user)==true) do
        userpid = Map.get(username_pid_map,user)
        GenServer.cast(userpid,{:addTweet,msg})
        GenServer.cast(userpid,{:sendNotificationToLiveNodes,user,list,msg})
    end

  end



  def addNewTweet(pid,user,msg) do
  #  user = IO.gets "Which user do you want to tweet as ? "
  #  IO.inspect user
  #  user = String.trim(user, "\n")
  #  IO.inspect user
    #Add functionality to check if user exists
    #Add functinoality to make user log in if he's not logged in already

    list = mapUserTopid(pid)

    proc = Supervisor.which_children(pid)
    Enum.each(proc, fn (x) ->
      {_,node,_,_} = x
      #IO.inspect (GenServer.call(node,{:getUsername}))
      username = GenServer.call(node,{:getUsername})
      IO.puts "username is "
      IO.inspect username
      cond do
        username == user ->
                        #    msg = IO.gets "Enter tweet msg"
                        #    msg = String.trim(msg,"\n")
                            GenServer.cast(node,{:addTweet,msg})
                            GenServer.cast(node,{:sendNotificationToLiveNodes,user,list,msg})
        true -> IO.puts "Username not found in DB"
      end
     end)
  end

  def login(pid)do
    username = IO.gets "Enter your username"
    username = String.trim(username, "\n")

    password = IO.gets "Enter your password "
    password = String.trim(password,"\n")
    result = TwitterEngine.loginUser(username,password)
    cond do
      result == 1 -> IO.puts "Login Successful"
                    GenServer.call(pid,{:updateLoginState,result})
      true-> IO.puts "Login Unsuccessful"
    end
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

  def start_link(num) do
    GenServer.start_link(__MODULE__,num,[])
  end

  def init(num) do

  #  username = IO.gets "Enter preferred username"
  #  username = String.trim(username, "\n")

  #  password = IO.gets "Enter the password "
  #  password = String.trim(password,"\n")

  #  IO.puts "Username "
  #  IO.inspect username
    IO.puts "Created ! "
    TwitterEngine.registerUser(num,num)
    state = {num,1,[]}
  #  state= {username,1,[]}
    IO.inspect state
    {:ok,state} #state = {username,loginstatus,livenotifications}
  end

  def handle_call({:getUsername},_from,state) do
  #  IO.inspect "state is"
  #  IO.inspect state
    {username,_loginstatus,_livemsgs}=state
    {:reply,username,state}

  #  spawn fn ->
  #    {username,_loginstatus,_livemsgs}=state
  #    GenServer.reply(from,username)
  #  end

  #  {:noreply,state}
  end

  def handle_call({:getloginStatus},_from,state) do
    {_username,loginstatus,_}=state
    {:reply,loginstatus,state}
  end

  def handle_call({:printstate},_from,state) do
    {username,loginstatus,livemessage}=state
    IO.inspect username
    IO.inspect loginstatus
    IO.inspect livemessage
    {:reply,state,state}
  end

  def handle_call({:updateLoginState,result},_from,state) do
    {username,_loginstatus,list}=state
    state={username,result,list}
    {:reply,result,state}
  end

  def handle_cast({:notifylivenode,msg},state) do
    {username,loginstatus,livemsgs}=state
    state = {username,loginstatus,[livemsgs]++[msg]}
    IO.inspect "notification recieved"
    IO.inspect msg
   {:noreply,state}
  end





  def handle_cast({:addTweet,msg},state) do
    IO.puts "Tweeting "
    IO.inspect msg

    {username,_,_}=state

    #If logged in
    TwitterEngine.storeTweet(username,msg)

    IO.puts "Tweet stored in DB"

    #if Not logged in, then make user login. Functionality to be added later.

    {:noreply,state}
  end

  def handle_cast({:sendNotificationToLiveNodes,user,list,msg},state) do
    IO.puts "Tweeting "

    #If logged in
    TwitterEngine.sendToLiveNode(user,list,msg)

    #if Not logged in, then make user login. Functionality to be added later.

    {:noreply,state}
  end
end
