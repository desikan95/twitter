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

  def storeTweet(user,msg) do

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
         :ets.insert(:users, {f,[msg,current_time,user]})
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

        IO.inspect followers
        #if any of the followers are live, change their process state to include the message
       livenodepids =  Enum.map(followers,fn(follower)-> pids= Enum.map(list, fn(item_in_list)->
                                                                                                                #IO.inspect follower
                                                                                                                #IO.inspect item_in_list
                                                                                                                #IO.inspect Enum.at(item_in_list,1)
                                                                                                                #IO.inspect Enum.at(item_in_list,0)
                                                                                                              ids= cond do
                                                                                                               to_string(follower) == Enum.at(item_in_list,1)-> id=  Enum.at(item_in_list,0)
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
    #IO.inspect result
    result
  end

  def simulate() do
    #random tweeting
    #random following
  end

  def showmessages(user) do
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
    children = Enum.map(1..(users),fn (x) -> Supervisor.child_spec(Client,id: x) end)
    Supervisor.init(children, strategy: :one_for_one)
  end


  def mapUserTopid(pid) do
    processes = Supervisor.which_children(pid)
    list =Enum.map(processes, fn (x) ->
      {_,node,_,_} = x
      IO.inspect x
      IO.inspect node
      username = GenServer.call(node,{:getUsername})
      IO.inspect username
      IO.inspect [node,username]
      [node,username] end)
    IO.inspect list
  end



  def addNewTweet(pid,list) do
    user = IO.gets "Which user do you want to tweet as ? "
    IO.inspect user
    user = String.trim(user, "\n")
    IO.inspect user
    #Add functionality to check if user exists
    #Add functinoality to make user log in if he's not logged in already

    proc = Supervisor.which_children(pid)
    Enum.each(proc, fn (x) ->
      IO.inspect "inside"
      {_,node,_,_} = x
      IO.inspect node
      IO.inspect "Response from the fucking genserver is "
      #IO.inspect (GenServer.call(node,{:getUsername}))
      username = GenServer.call(node,{:getUsername})
      IO.puts "username is "
      IO.inspect username
      cond do
        username == user ->
                            msg = IO.gets "Enter tweet msg"
                            msg = String.trim(msg,"\n")
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

  def start_link(_) do
    GenServer.start_link(__MODULE__,[])
  end

  def init(_val) do

    username = IO.gets "Enter preferred username"
    username = String.trim(username, "\n")

    password = IO.gets "Enter the password "
    password = String.trim(password,"\n")

    IO.puts "Username "
    IO.inspect username
    IO.puts "Created ! "
    TwitterEngine.registerUser(username,password)
    state= {username,1,[]}
    IO.inspect state
    {:ok,state} #state = {username,loginstatus,livenotifications}
  end

  def handle_call({:getUsername},_from,state) do
    IO.inspect "state is"
    IO.inspect state
    {username,_loginstatus,_livemsgs}=state
    {:reply,username,state}
  end

  def handle_call({:getloginStatus},_from,state) do
    {_username,loginstatus,[]}=state
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





  def handle_cast({:addTweet,msg},username) do
    IO.puts "Tweeting "
    IO.inspect msg

    #If logged in
    TwitterEngine.storeTweet(username,msg)

    #if Not logged in, then make user login. Functionality to be added later.

    {:noreply,username}
  end

  def handle_cast({:sendNotificationToLiveNodes,user,list,msg},state) do
    IO.puts "Tweeting "

    #If logged in
    TwitterEngine.sendToLiveNode(user,list,msg)

    #if Not logged in, then make user login. Functionality to be added later.

    {:noreply,state}
  end
end
