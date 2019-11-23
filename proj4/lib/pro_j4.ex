defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # state = username, password, subscritionList, followersList, usersTweets, feedList
  def start_child(user_name, password) do
    init_tweet = {"init feed tweet #testing123", "init_user"}

    child_spec =
      Supervisor.child_spec(
        {User, [user_name, password, ["testUser"], [], [], [init_tweet]]},
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

  def start_child(_opts) do
    init_tweet = {"init feed tweet #testing123", "childtest"}

    child_spec =
      Supervisor.child_spec({Engine, [[], [init_tweet]]}, id: :engine, restart: :temporary)

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule Engine do
  use GenServer
  # state has all the current {usernames, passwords}, allTweets
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call({:getUsers}, _from, state) do
    # IO.inspect(state, label: "Engine state")

    usersLists =
      Enum.flat_map(state, fn [uPL, _aT] ->
        {username, _password} = uPL
        [username]
      end)

    # IO.inspect(usersLists, label: "usersLists")

    {:reply, usersLists, state}
  end

  @impl true
  def handle_cast({:addUser, [username, password]}, state) do
    # IO.inspect("in engine add user")

    usernamePasswordTuple = Enum.at(state, 0)
    newusernamePasswordTuple = usernamePasswordTuple ++ [{username, password}]
    allTweetsList = Enum.at(state, 1)
    new_state = [newusernamePasswordTuple, allTweetsList]

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

    usernamePasswordTuple = Enum.at(state, 0)
    allTweetsList = Enum.at(state, 1)
    newallTweetsList = allTweetsList ++ {tweet, username}
    new_state = [usernamePasswordTuple, newallTweetsList]
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:findHashtag, query}, state) do
    feedList = Enum.at(state, 1)
    IO.inspect(feedList, label: "feedList")
    # for every value in the feedlist, search the tweet than search the username
    # if something interesting is found append it to results

    results = []

    results =
      for x <- feedList do
        {tweet, username} = x

        if(String.contains?(tweet, query) == true) do
          IO.inspect(tweet, label: "Found In Engine")
          _results = results ++ [{tweet, username}]
        end
      end

    IO.inspect(results, label: "found query in engine")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:findPerson, query}, state) do
    feedList = Enum.at(state, 1)
    IO.inspect(feedList, label: "feedList")
    # for every value in the feedlist, search the tweet than search the username
    # if something interesting is found append it to results

    results = []

    results =
      for x <- feedList do
        {tweet, username} = x

        if(String.contains?(username, query) == true) do
          IO.inspect(username, label: "Found In Engine")
          _results = results ++ [{tweet, username}]
        end
      end

    IO.inspect(results, label: "found query in engine")
    {:noreply, state}
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

      ###########################
      "SendTweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
        showMainMenu(new_state)

      "Tweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
        showMainMenu(new_state)

      "sendTweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
        showMainMenu(new_state)

      "tweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
        showMainMenu(new_state)

      "send tweet\n" ->
        new_state = tweet(state)
        IO.inspect(new_state, label: "new state in showMainMenu")
        # tell engine to update their list and  my state
        username = Enum.at(state, 0)
        GenServer.cast(Engine, {:updateUser, username, new_state})
        showMainMenu(new_state)

      ###########################

      "check feed\n" ->
        feed(state)
        showMainMenu(state)

      "c\n" ->
        feed(state)
        showMainMenu(state)

      ###########################
      "q\n" ->
        query(state)
        showMainMenu(state)

      "query\n" ->
        query(state)
        showMainMenu(state)

      ###########################
      "r\n" ->
        retweet(state)
        showMainMenu(state)

      "retweet\n" ->
        retweet(state)
        showMainMenu(state)
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

  def feed(state) do
    feedList = Enum.at(state, 5)
    IO.inspect(feedList, label: "Your feed")
  end

  def retweet(state) do
    feedList = Enum.at(state, 5)
    indexedFeedList = Enum.with_index(feedList)
    numberedFeedList = []

    numberedFeedList =
      for x <- indexedFeedList do
        {tweet, index} = x
        _numberedFeedList = numberedFeedList ++ [index, tweet]
      end

    IO.inspect(numberedFeedList, label: "Your feed")

    index1 =
      Mix.Shell.IO.prompt("Which tweet would you like to retweet? (Please write index only)")

    index = String.to_integer(String.trim(index1))
    [_index, {tweetToReTweet, _user_nameToReTweet}] = Enum.at(numberedFeedList, index)

    confirm1 = Mix.Shell.IO.prompt("You selected #{tweetToReTweet} is this correct?")
    confirm = String.trim(confirm1)

    if confirm == "yes" || confirm == "Yes" do
      addedToTweet1 = Mix.Shell.IO.prompt("What would you like to add to the tweet?")
      addedToTweet = String.trim(addedToTweet1)
      newTweet = "#{addedToTweet} : respond to tweet #{tweetToReTweet}"
      IO.inspect(newTweet, label: "new Tweet")

      # FOR TESTING
      followersList = ["child1", "child2", "child3", "child4", "child5", "child6"]

      # save retweet
      username = Enum.at(state, 0)
      password = Enum.at(state, 1)
      subscritionList = Enum.at(state, 2)

      _followersList = Enum.at(state, 3)
      tweetsList = Enum.at(state, 4)
      feedList = Enum.at(state, 5)
      GenServer.cast(Engine, {:sendTweet, username, newTweet, followersList})
      IO.inspect(newTweet, label: "You tweeted")

      newTweetsList = tweetsList ++ [newTweet]
      _newState = [username, password, subscritionList, followersList, newTweetsList, feedList]
    else
      showMainMenu(state)
      state
    end
  end

  def query(state) do
    query1 = Mix.Shell.IO.prompt("What would you like to search?")
    query = String.trim(query1)

    # person
    if String.contains?(query, "@") do
      # go to engine
      {_at, name} = String.split_at(query, 1)
      GenServer.cast(Engine, {:findPerson, name})
    else
      # hashtag
      if String.contains?(query, "#") do
        # go to engine
        GenServer.cast(Engine, {:findHashtag, query})
        # normal search
      else
        feedList = Enum.at(state, 5)
        IO.inspect(feedList)

        # for every value in the feedlist, search the tweet than search the username
        # if something interesting is found append it to results

        results = []

        results =
          for x <- feedList do
            {tweet, username} = x

            if(String.contains?(tweet, query) == true) do
              IO.inspect(tweet, label: "Found")
              _results = results ++ [{tweet, username}]
            end

            if(String.contains?(username, query) == true) do
              IO.inspect(username, label: "Found")
              _results = results ++ [{tweet, username}]
            end
          end

        IO.inspect(results, label: "found query")
        # Enum.each(feedList, fn {tweet, username} ->
        # end)
      end
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

    enterTwitter()

    # Supervisor.start_link([], strategy: :one_for_one)
  end

  def enterTwitter() do
    # ask for login or register
    action = Mix.Shell.IO.prompt("Log In or Register?")

    case action do
      "Register\n" ->
        registerUserName()

      "register\n" ->
        registerUserName()

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

      _ ->
        enterTwitter()
        # "test\n" ->
        #   test()
    end

    # :registered
  end

  def registerUserName() do
    user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
    userName = String.trim(user_name)
    registerPassword(userName)
    :registerComplete
  end

  def registerPassword(user_name) do
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
      registerPassword(user_name)
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

  def getChildren() do
    # get children from Supervisor to see if it registered
    children = DynamicSupervisor.which_children(DySupervisor)

    for x <- children do
      {_, pidx, _, _} = x
      _state = :sys.get_state(pidx)
      # IO.inspect(state, label: "Child")
    end
  end

  # def test() do
  #   # make a bunch of kids
  #   makeKids(6)
  #
  #   # register a specific user
  #   DySupervisor.start_child("testUser", "t")
  #   GenServer.cast(Engine, {:addUser, ["testUser", "t"]})
  #
  #   # make sure they are all there
  #   kids = PROJ4.getChildren()
  #   IO.inspect(kids)
  #
  #   # goToClient
  #   goToClient("testUser")
  # end
end
