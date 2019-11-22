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

  def storeTweet(user,msg) do
    #Add tweets to user and tweet mappings
    current_time = :calendar.local_time()
    :ets.insert(:users, {user,current_time,msg})


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
