defmodule TwitterApp do
  use Application

  def start(_type,_args) do

    arguments = System.argv()

    pid = TwitterEngine.start_link(1)
    if (Enum.at(arguments,0)!="test")
    do
        {numUsers,_}=Integer.parse(Enum.at(arguments,0))
        {numMessages,_}=Integer.parse(Enum.at(arguments,1))
        ClientSupervisor.simulate(numUsers,numMessages)
        IO.puts " Done with simulation !"
    end

    {:ok,pid}
  end
end
