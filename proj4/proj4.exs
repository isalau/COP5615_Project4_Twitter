defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(args, user_name) do
    child_spec =
      Supervisor.child_spec({User, [args, user_name]}, id: user_name, restart: :temporary)

    {:ok, child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule User do
  use GenServer

  def start_link([args, user_name]) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: :"#{user_name}")
  end

  def init(args) do
    {:ok, args}
  end
end

defmodule PROJECT4 do
  @moduledoc """
  Documentation for PROJ4.
  """

  @doc """
  Hello world.

  ## Examples

      iex> PROJ4.hello()
      :world

  """
  def hello do
    :world
  end
end

# ask for login or register
action = Mix.Shell.IO.prompt("LogIn or Register?")

if(action == "Register" || "register") do
  user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
  IO.puts("Your new username is #{user_name}")

  # start dynamic supervisor
  {:ok, pid} = DySupervisor.start_link(1)

  # start a child
  DySupervisor.start_child("testArg", user_name)
end
