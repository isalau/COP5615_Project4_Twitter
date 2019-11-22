defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # state = username, password, subscritionList, followersList, usersTweets, feedList
  def start_child(user_name, password) do
    child_spec =
      Supervisor.child_spec({User, [user_name, password, ["testUser"], [], [], []]},
        id: user_name,
        restart: :temporary
      )

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule EngineSupervisor do
  use DynamicSupervisor

  def start_link(opts) do
    IO.puts("Its here in EngineSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_child(opts) do
    child_spec = Supervisor.child_spec({Engine, opts}, id: :engine, restart: :temporary)

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule Engine do
  use GenServer
  # state has all the current usernames, passwords
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_call({:getUsers}, _from, state) do
    # IO.inspect(state, label: "Engine state")

    usersLists =
      Enum.flat_map(state, fn [u, _p] ->
        [u]
      end)

    # IO.inspect(usersLists, label: "usersLists")

    {:reply, usersLists, state}
  end

  @impl true
  def handle_cast({:addUser, [username, password]}, state) do
    # IO.inspect("in engine add user")
    new_state = state ++ [[username, password]]
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:addFollower, follower, followee}, state) do
    GenServer.cast(:"#{followee}", {:addFollower, follower, followee})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:updateUser, username, new_state}, state) do
    # maybe update state in engine haven't decided yet
    # call user back to update their state
    GenServer.cast(:"#{username}", {:updateState, new_state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sendTweet, username, tweet, subscribers}, state) do
    # for every subscriber in followers usersLists
    Enum.each(subscribers, fn follower ->
      # send tweet message
      GenServer.cast(:"#{follower}", {:getTweet, username, tweet})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end

defmodule User do
  use GenServer

  # state = username, password, subscritionList, followersList, usersTweets

  def start_link(args) do
    user_name = Enum.at(args, 0)
    IO.inspect(user_name, label: "username for new client")
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: :"#{user_name}")
  end

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_cast({:updateState, new_state}, _state) do
    IO.inspect(new_state, label: "in update user state")

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:addFollower, follower, _followee}, state) do
    username = Enum.at(state, 0)
    password = Enum.at(state, 1)
    subscritionList = Enum.at(state, 2)
    followersList = Enum.at(state, 3)
    tweetsList = Enum.at(state, 4)

    newFollowersList = followersList ++ [follower]
    newState = [username, password, subscritionList, newFollowersList, tweetsList]
    IO.inspect(newState, label: "in addFollower user state")
    {:noreply, newState}
  end

  @impl true
  def handle_cast({:goToClient}, state) do
    IO.inspect(state, label: "in show main menu")
    showMainMenu(state)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:getTweet, tweeter, tweet}, state) do
    # IO.inspect(tweet, label: "Got tweet from #{username}")
    username = Enum.at(state, 0)
    password = Enum.at(state, 1)
    subscritionList = Enum.at(state, 2)
    followersList = Enum.at(state, 3)
    tweetsList = Enum.at(state, 4)
    feedList = Enum.at(state, 5)

    newFeedsList = feedList ++ [{tweet, tweeter}]
    newState = [username, password, subscritionList, followersList, tweetsList, newFeedsList]
    IO.inspect(newState, label: "New tweet received")
    {:noreply, newState}
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

      "Subscribe\n" ->
        new_state = subscribeToUser(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})

      "subscribe\n" ->
        new_state = subscribeToUser(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})

      "s\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})

      "sendTweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})

      "Tweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
    end
  end

  def deleteUser(state) do
    IO.inspect(state, label: "State")
    answer = Mix.Shell.IO.prompt("Are you sure you would like to delete your account?")

    case answer do
      "Yes\n" ->
        # if checkPassword passes
        _userName = Enum.at(state, 0)
        password = Enum.at(state, 1)
        enteredpassword1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        enteredpassword = String.trim(enteredpassword1)

        if password == enteredpassword do
          deleteConfirm(state)
        else
          IO.puts("Incorrect password")
        end

      "yes\n" ->
        # if checkPassword passes
        _userName = Enum.at(state, 0)
        password = Enum.at(state, 1)
        enteredpassword1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        enteredpassword = String.trim(enteredpassword1)

        if password == enteredpassword do
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
        dpid = Process.whereis(DySupervisor)
        val = Process.alive?(dpid)
        IO.inspect(val, label: "test if sup is alive")
        userName = Enum.at(state, 0)
        pid = GenServer.whereis(:"#{userName}")
        IO.inspect(pid, label: "deleting child")
        DynamicSupervisor.terminate_child(dpid, pid)
        IO.puts("Account Deleted. Goodbye.")

      "yes\n" ->
        # delete from supervisor and log out
        dpid = Process.whereis(DySupervisor)
        val = Process.alive?(dpid)
        IO.inspect(val, label: "test if sup is alive")
        userName = Enum.at(state, 0)
        pid = GenServer.whereis(:"#{userName}")
        IO.inspect(pid, label: "deleting child")
        DynamicSupervisor.terminate_child(dpid, pid)
        IO.puts("Account Deleted. Goodbye.")

      "No\n" ->
        showMainMenu(state)

      "no\n" ->
        showMainMenu(state)
    end
  end

  def subscribeToUser(state) do
    newUserToSubscribeTo1 = Mix.Shell.IO.prompt("Who do you want to subscribe to?")
    newUserToSubscribeTo = String.trim(newUserToSubscribeTo1)
    username = Enum.at(state, 0)

    usernameLists = GenServer.call(Engine, {:getUsers})
    # IO.inspect(usernameLists, label: "usernameLists")

    new_state =
      if newUserToSubscribeTo in usernameLists do
        # IO.puts("existing user")
        [_username, _password, subscritionList, _followerssList, _tweetsList] = state

        if newUserToSubscribeTo in subscritionList do
          IO.puts("You are already subscribed to this user")
          state
        else
          if newUserToSubscribeTo != username do
            newsubscritionList = subscritionList ++ [newUserToSubscribeTo]

            GenServer.cast(Engine, {:addFollower, username, newUserToSubscribeTo})
            IO.puts("You are now subscribed to #{newUserToSubscribeTo}")
            # IO.inspect(newsubscritionList, label: "subscription list")

            password = Enum.at(state, 1)
            followersList = Enum.at(state, 3)
            tweetsList = Enum.at(state, 4)
            _newState = [username, password, newsubscritionList, followersList, tweetsList]
          else
            IO.puts("You cannot subscribe to yourself")
            state
          end
        end
      else
        IO.puts("no such user")
        state
      end

    # IO.inspect(new_state, label: "new state in subscribeToUser")
    new_state
  end

  def tweet(state) do
    username = Enum.at(state, 0)
    password = Enum.at(state, 1)
    subscritionList = Enum.at(state, 2)
    _followersList = Enum.at(state, 3)
    tweetsList = Enum.at(state, 4)

    tweet1 = Mix.Shell.IO.prompt("What would you like to tweet?")
    tweet = String.trim(tweet1)
    # FOR TESTING
    followersList = ["child1", "child2", "child3", "child4", "child5", "child6"]

    GenServer.cast(Engine, {:sendTweet, username, tweet, followersList})
    IO.inspect(tweet, label: "You tweeted")

    newTweetsList = tweetsList ++ [tweet]
    _newState = [username, password, subscritionList, followersList, newTweetsList]
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
end

defmodule PROJ4 do
  use Application

  def start(_type, _args) do
    # supervisor for client
    {:ok, _pid} = DySupervisor.start_link(1)

    # # supervisor for engine
    {:ok, _pid} = EngineSupervisor.start_link(1)
    EngineSupervisor.start_child([])
    # children = [
    #   {Engine, name: Engine}
    # ]
    #
    # {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
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

      "test\n" ->
        testSendTweet()
    end

    # :registered
    Supervisor.start_link([], strategy: :one_for_one)
  end

  def testSendTweet() do
    # make a bunch of kids
    makeKids(6)

    # register a specific user
    DySupervisor.start_child("testUser", "t")
    GenServer.cast(Engine, {:addUser, ["testUser", "t"]})

    # make sure they are all there
    kids = PROJ4.getChildren()
    IO.inspect(kids)

    # goToClient
    goToClient("testUser")
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

      # start a child
      DySupervisor.start_child(user_name, password)
      GenServer.cast(Engine, {:addUser, [user_name, password]})

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
    GenServer.cast(:"#{userName}", {:goToClient})
  end

  def showMainMenu() do
    IO.puts("In wrong show main menu")
  end

  def getChildren() do
    # get children from Supervisor to see if it registered
    children = DynamicSupervisor.which_children(DySupervisor)

    for x <- children do
      {_, pidx, _, _} = x
      _state = :sys.get_state(pidx)
      # IO.inspect(state, label: "Child")
    end
  end

  def makeManyKids(num) do
    # start dynamic supervisor
    {:ok, _pid} = DySupervisor.start_link(1)

    makeKids(num)
  end

  def makeKids(num) when num > 1 do
    # IO.puts("making kids")

    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    DySupervisor.start_child(username, num)

    GenServer.cast(Engine, {:addUser, [username, num]})
    newNum = num - 1
    makeKids(newNum)
  end

  def makeKids(num) do
    # IO.puts("made kids")

    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    DySupervisor.start_child(username, num)

    GenServer.cast(Engine, {:addUser, [username, num]})
    :registered
  end
end
