defmodule TwitterApp do
  use Application

  def start(_type,_args) do

    arguments = System.argv()
    {numUsers,_}=Integer.parse(Enum.at(arguments,0))
    {numMessages,_}=Integer.parse(Enum.at(arguments,1))

    IO.puts "Users "
    IO.inspect numUsers
    IO.puts "Number of messages"
    IO.inspect numMessages

    pid = TwitterEngine.start_link(1)
    ClientSupervisor.simulate(numUsers, numMessages)

    IO.puts "Started application"

    {:ok,pid}
  end
end
