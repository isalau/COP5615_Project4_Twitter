defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(args, user_name) do
    child_spec =
      Supervisor.child_spec({User, [args, user_name]}, id: user_name, restart: :temporary)

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule User do
  use GenServer

  def handle_call({:readTweet}, from, msg) do
    IO.inspect(msg, label: "Someone I followed tweeted")
    {:reply, :ok, msg}
  end

  def start_link([args, user_name]) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: :"#{user_name}")
  end

  def init(args) do
    {:ok, args}
  end

  def sendTweet(msg, myself, follower) do
    GenServer.call(follower, {:readTweet, msg})
  end
end

defmodule PROJ4 do
  def main do
    # ask for login or register
    action = Mix.Shell.IO.prompt("Log In or Register?")

    if(action == "Register" || "register") do
      registerUser()
    end

    :registered
  end

  def registerUser do
    user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
    createPassword(user_name)
  end

  def createPassword(user_name) do
    password1 = Mix.Shell.IO.prompt("Please Create A Password:")
    password2 = Mix.Shell.IO.prompt("Please Repeat Password For Verification:")

    if(password1 == password2) do
      # start dynamic supervisor
      {:ok, _pid} = DySupervisor.start_link(1)

      # start a child
      DySupervisor.start_child(user_name, user_name)

      IO.puts("Your new username is #{user_name} and your account was created")
      showMainMenu()
    else
      IO.puts("Passwords did not match please try again")
      createPassword(user_name)
    end
  end

  def showMainMenu() do
    action =
      Mix.Shell.IO.prompt(
        "Would you like to:\n Delete account\n Send tweet\n Subscribe to user\n Re-tweet\n Query\n Check Feed\n"
      )
  end

  def getChildren do
    # get children from Supervisor to see if it registered
    children = DynamicSupervisor.which_children(DySupervisor)

    for x <- children do
      {_, pidx, _, _} = x
      _state = :sys.get_state(pidx)
    end
  end

  def makeManyKids(num) do
    # start dynamic supervisor
    {:ok, _pid} = DySupervisor.start_link(1)

    makeKids(num)
  end

  def makeKids(num) when num > 1 do
    IO.puts("making kids")

    # start a child
    DySupervisor.start_child(num, num)
    newNum = num - 1
    makeKids(newNum)
  end

  def makeKids(num) do
    IO.puts("made kids")

    # start a child
    DySupervisor.start_child(num, num)
    :registered
  end
end
