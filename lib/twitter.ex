defmodule TwitterEngine do
  use GenServer

  def start_link(_) do
    {:ok,pid} = GenServer.start_link(__MODULE__,[])
    IO.puts "Engine is now running"
    pid
  end

  def init() do
  # Create all ets tables
  #Registration table
  #User -> Password mapping

  
  #User -> Tweets he needs to see

  #User -> Following mapping
  #Tweets -> User mapping
    :ets.new(:registrations, [:set, :public, :named_table])
    :ets.new(:users, [:set, :public, :named_table])
  end


  def registerUser(username, password) do
    :ets.insert(:registrations, {})
  end

  def deleteUser() do
  end

  def getTweets() do
  end

  def addTweet() do
    #Add tweets to user and tweet mappings
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

  def displayUsers(pid) do
    proc = Supervisor.which_children(pid)
    Enum.each(proc, fn (x) -> IO.inspect x end)
  end


end

defmodule Client do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__,[])
  end

  def init(_val) do

    username = IO.gets "Enter preferred username" |> String.trim
    state = {username,[],[]}
    IO.puts "Username "
    IO.inspect username
    IO.puts "created ! "
    {:ok,state}
  end
end
