defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(user_name, password) do
    child_spec =
      Supervisor.child_spec({User, [user_name, password]}, id: user_name, restart: :temporary)

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule User do
  use GenServer

  def handle_call({:readTweet}, _from, msg) do
    IO.inspect(msg, label: "Someone I followed tweeted")
    {:reply, :ok, msg}
  end

  def start_link(args) do
    user_name = Enum.at(args, 0)
    IO.inspect(user_name, label: "username for new client")
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: :"#{user_name}")
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:showMainMenu}, state) do
    IO.inspect(state, label: "in show main menu")

    action =
      Mix.Shell.IO.prompt(
        "Would you like to:\n Delete account\n Send tweet\n Subscribe to user\n Re-tweet\n Query\n Check Feed\n"
      )

    case action do
      "Delete\n" ->
        deleteUser(state)

      "delete\n" ->
        deleteUser(state)
    end

    {:reply, :ok, state}
  end

  def showMainMenu(state) do
    action =
      Mix.Shell.IO.prompt(
        "Would you like to:\n Delete account\n Send tweet\n Subscribe to user\n Re-tweet\n Query\n Check Feed\n"
      )

    case action do
      "Delete\n" ->
        deleteUser(state)

      "delete\n" ->
        deleteUser(state)
    end
  end

  def deleteUser(state) do
    IO.inspect(state, label: "State")
    answer = Mix.Shell.IO.prompt("Are you sure you would like to delete your account?")

    case answer do
      "Yes\n" ->
        # if checkPassword passes
        userName = Enum.at(state, 0)
        password1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        password = String.trim(password1)

        if checkPassword(userName, password) == true do
          deleteConfirm(state)
        else
          IO.puts("Incorrect password")
        end

      "yes\n" ->
        # if checkPassword passes
        userName = Enum.at(state, 0)
        password1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        password = String.trim(password1)

        if checkPassword(userName, password) == true do
          deleteConfirm(state)
        else
          IO.puts("Incorrect password")
        end

      "No\n" ->
        showMainMenu(state)

      "no\n" ->
        showMainMenu(state)
    end
  end

  def deleteConfirm(state) do
    confirm = Mix.Shell.IO.prompt("Final confirmation. Delete Account?")

    case confirm do
      "Yes\n" ->
        # delete from supervisor and log out
        IO.puts("Account Deleted. Goodbye.")

      "yes\n" ->
        # delete from supervisor and log out
        IO.puts("Account Deleted. Goodbye.")

      "No\n" ->
        showMainMenu(state)

      "no\n" ->
        showMainMenu(state)
    end
  end

  def checkPassword(user_name, password) do
    # check that username exists
    kids = getChildren()
    IO.inspect(kids, label: "kids")

    # check if password is okay
    if(Enum.member?(kids, [user_name, password])) do
      true
    else
      # incorrect password
      false
    end
  end

  def getChildren() do
    # get children from Supervisor to see if it registered
    children = DynamicSupervisor.which_children(DySupervisor)

    for x <- children do
      {_, pidx, _, _} = x
      state = :sys.get_state(pidx)
      IO.inspect(state, label: "Child")
    end
  end

  def sendTweet(msg, _myself, follower) do
    GenServer.call(follower, {:readTweet, msg})
  end
end

defmodule PROJ4 do
  def main() do
    # ask for login or register
    action = Mix.Shell.IO.prompt("Log In or Register?")

    case action do
      "Register\n" ->
        registerUser()

      "register\n" ->
        registerUser()

      "Log In\n" ->
        loginUser()

      "LogIn\n" ->
        loginUser()

      "log In\n" ->
        loginUser()

      "logIn\n" ->
        loginUser()

      "log in\n" ->
        loginUser()

      "login\n" ->
        loginUser()
    end

    :registered
  end

  def registerUser() do
    user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
    userName = String.trim(user_name)
    createPassword(userName)
  end

  def createPassword(user_name) do
    password1 = Mix.Shell.IO.prompt("Please Create A Password:")
    password2 = Mix.Shell.IO.prompt("Please Repeat Password For Verification:")

    if(password1 == password2) do
      # start dynamic supervisor
      password = String.trim(password1)
      {:ok, _pid} = DySupervisor.start_link(1)

      # start a child
      DySupervisor.start_child(user_name, password)

      IO.puts("Your new username is #{user_name} and your account was created")
      IO.puts("Please Log In For First Time")
      loginUser()
    else
      IO.puts("Passwords did not match please try again")
      createPassword(user_name)
    end
  end

  def loginUser() do
    user_name = Mix.Shell.IO.prompt("Please Enter Your UserName:")
    userName = String.trim(user_name)

    password1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
    password = String.trim(password1)

    # check that username exists
    kids = getChildren()
    IO.inspect(kids, label: "kids")

    usernameLists = Enum.flat_map(kids, fn [user_name, _x] -> [user_name] end)
    IO.inspect(usernameLists, label: "usernameLists")

    if userName in usernameLists do
      if checkPassword(userName, password) == true do
        goToClient(userName)
      else
        IO.inspect(userName, label: "1 Incorrect username or password. Please try again.")
        loginUser()
      end
    else
      IO.inspect(userName, label: "2 Incorrect username or password. Please try again.")
      loginUser()
    end
  end

  def checkPassword1(user_name) do
    password1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
    password = String.trim(password1)

    # check that username exists
    kids = getChildren()
    IO.inspect(kids, label: "kids")

    usernameLists = Enum.flat_map(kids, fn [user_name, _x] -> [user_name] end)
    IO.inspect(usernameLists, label: "usernameLists")

    if user_name in usernameLists do
      # check if password is okay
      if(Enum.member?(kids, [user_name, password])) do
        showMainMenu()
      else
        IO.inspect(user_name, label: "Incorrect username or password. Please try again.")
        loginUser()
      end
    else
      IO.inspect(user_name, label: "Incorrect username or password. Please try again.")
      loginUser()
    end
  end

  def checkPassword(user_name, password) do
    # check that username exists
    kids = getChildren()
    IO.inspect(kids, label: "kids")

    # check if password is okay
    if(Enum.member?(kids, [user_name, password])) do
      true
    else
      # incorrect password
      false
    end
  end

  def goToClient(userName) do
    IO.inspect(userName, label: "in goToClient")
    GenServer.cast(:"#{userName}", {:showMainMenu})
  end

  def showMainMenu() do
    action =
      Mix.Shell.IO.prompt(
        "Would you like to:\n Delete account\n Send tweet\n Subscribe to user\n Re-tweet\n Query\n Check Feed\n"
      )
  end

  def getChildren() do
    # get children from Supervisor to see if it registered
    children = DynamicSupervisor.which_children(DySupervisor)

    for x <- children do
      {_, pidx, _, _} = x
      state = :sys.get_state(pidx)
      IO.inspect(state, label: "Child")
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

PROJ4.main()
