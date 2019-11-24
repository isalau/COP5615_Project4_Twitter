defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Its here in DynamicSupervisor")
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # state = [username, password]
  def start_child(user_name, password) do
    child_spec =
      Supervisor.child_spec(
        {User, [user_name, password]},
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
    # state = [[username, password, subscritionList, followersList, usersTweets, feedList],[username, password, subscritionList, followersList, usersTweets, feedList],[username, password, subscritionList, followersList, usersTweets, feedList]]
    child_spec = Supervisor.child_spec({Engine, []}, id: :engine, restart: :temporary)

    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule Engine do
  use GenServer
  # state has all the current {usernames, passwords}, allTweets
  # state = username, password, subscritionList, followersList, usersTweets,feedList
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
      Enum.flat_map(state, fn cssa ->
        [username, _password, _subscritionList, _followersList, _usersTweets, _feedList] = cssa
        [username]
      end)

    # IO.inspect(usersLists, label: "usersLists")

    {:reply, usersLists, state}
  end

  @impl true
  def handle_call({:getSubscribers, userName}, _from, state) do
    # IO.inspect(state, label: "Engine state")

    subsList =
      for user <- state do
        [username, _password, subscritionList, _followersList, _usersTweets, _feedList] = user

        if(username == userName) do
          subscritionList
        end
      end

    # IO.inspect(usersLists, label: "usersLists")

    {:reply, subsList, state}
  end

  @impl true
  def handle_call({:getFeedList, userName}, _from, state) do
    # IO.inspect(state, label: "Engine state")

    fList =
      for user <- state do
        [username, _password, _subscritionList, _followersList, _usersTweets, feedList] = user

        if(username == userName) do
          feedList
        end
      end

    usersFeed = List.flatten(Enum.filter(fList, fn x -> x != nil end))
    {:reply, usersFeed, state}
  end

  @impl true
  def handle_cast({:addUser, [username, password]}, state) do
    # CSSA = [username, password, subscritionList, followersList, usersTweets, feedList]

    # for testing
    init_tweet = {"init feed tweet #testing123", "wise_one"}
    # for testing
    init_subscribed = "testUser"
    newCSSA = [[username, password, [init_subscribed], [], [init_tweet], []]]
    new_state = state ++ newCSSA

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:addToSubscribeList, follower, toBeFollowed}, state) do
    new_state =
      for user <- state do
        [username, password, subscritionList, followersList, usersTweets, feedList] = user

        if(username == follower) do
          newsubscritionList = subscritionList ++ [toBeFollowed]
          _x = [username, password, newsubscritionList, followersList, usersTweets, feedList]
        else
          [username, password, subscritionList, followersList, usersTweets, feedList]
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:addSubToFeed, follower, toBeFollowed}, state) do
    new_state =
      for user <- state do
        [username, password, subscritionList, followersList, usersTweets, feedList] = user

        if(username == follower) do
          newTweetsForFeed = getUsersTweets(state, toBeFollowed)
          newFeedList = feedList ++ List.flatten(newTweetsForFeed)
          _x = [username, password, subscritionList, followersList, usersTweets, newFeedList]
        else
          [username, password, subscritionList, followersList, usersTweets, feedList]
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:addFollower, follower, toBeFollowed}, state) do
    new_state =
      for user <- state do
        [username, password, subscritionList, followersList, usersTweets, feedList] = user

        if(username == toBeFollowed) do
          newFollowersList = followersList ++ [follower]
          _x = [username, password, subscritionList, newFollowersList, usersTweets, feedList]
        else
          [username, password, subscritionList, followersList, usersTweets, feedList]
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:updateUser, username, new_state}, state) do
    # maybe update state in engine haven't decided yet
    # call user back to update their state
    GenServer.cast(:"#{username}", {:updateState, new_state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:removeUser, user_state}, state) do
    user_name = Enum.at(user_state, 0)

    _new_state = state

    new_state =
      for x <- state do
        [username, _password, _subscritionList, _followersList, _usersTweets, _feedList] = x

        if(username == user_name) do
          _newList = List.delete(state, x)
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:sendTweet, userName, tweet}, state) do
    # get followersList
    _followersList =
      for user <- state do
        [username, _password, _subscritionList, followersList, _usersTweets, _feedList] = user

        if(username == userName) do
          followersList
        end
      end

    # for every follower use :getTweet in genserver

    # for testing
    followersList = ["child1", "child2", "child3", "child4", "child5", "child6"]

    Enum.each(followersList, fn follower ->
      # send tweet message
      GenServer.cast(:"#{follower}", {:getTweet, userName, tweet})
    end)

    # save tweet to engine
    new_state =
      for user <- state do
        [username, password, subscritionList, followersList, usersTweets, feedList] = user

        if(username == userName) do
          newusersTweets = usersTweets ++ [{tweet, username}]
          _x = [username, password, subscritionList, followersList, newusersTweets, feedList]
        else
          [username, password, subscritionList, followersList, usersTweets, feedList]
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:getTweet, tweeter, tweet, user_name}, state) do
    # IO.inspect(tweet, label: "got something ")

    new_state =
      for user <- state do
        [username, password, subscritionList, followersList, usersTweets, feedList] = user

        if(username == user_name) do
          newfeedList = feedList ++ [{tweet, tweeter}]
          _x = [username, password, subscritionList, followersList, usersTweets, newfeedList]
        else
          [username, password, subscritionList, followersList, usersTweets, feedList]
        end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:findHashtag, query}, state) do
    # for every value in the feedlist, search the tweet than search the username
    # if something interesting is found append it to results

    results = []

    results =
      for x <- state do
        [_username, _password, _subscritionList, _followersList, usersTweets, _feedList] = x

        for tweeter <- usersTweets do
          {tweet, username} = tweeter

          if(String.contains?(tweet, query) == true) do
            # IO.inspect(usersTweets, label: "Found In Engine")
            _results = results ++ {tweet, username}
          end
        end
      end

    results = Enum.filter(results, fn x -> x != [nil] end)

    if(results == [[nil, nil]]) do
      IO.puts("No results found")
    else
      IO.inspect(results, label: "found query in engine")
    end

    results
    {:noreply, state}
  end

  @impl true
  def handle_cast({:findPerson, query}, state) do
    # for every value in the feedlist, search the tweet than search the username
    # if something interesting is found append it to results

    results = []

    results =
      for x <- state do
        [_username, _password, _subscritionList, _followersList, usersTweets, _feedList] = x

        for tweeter <- usersTweets do
          {tweet, username} = tweeter

          if(String.contains?(tweet, query) == true) do
            # IO.inspect(usersTweets, label: "Found In Engine")
            _results = results ++ [{tweet, username}]
          end
        end
      end

    results = Enum.filter(results, fn x -> x != [nil] end)

    if(results == []) do
      IO.puts("No results found")
    else
      IO.inspect(results, label: "found query in engine")
    end

    {:noreply, state}
  end

  def getUsersTweets(state, userName) do
    usersTweetsForFeed =
      for user <- state do
        [username, _password, _subscritionList, _followersList, usersTweets, _feedList] = user

        if(username == userName) do
          usersTweets
        end
      end

    usersTweetsForFeed = Enum.filter(usersTweetsForFeed, fn x -> x != nil end)
    # IO.inspect(usersTweetsForFeed, label: "usersTweets")
    usersTweetsForFeed
  end
end

defmodule User do
  use GenServer

  def start_link(args) do
    user_name = Enum.at(args, 0)
    # IO.inspect(user_name, label: "username for new client")
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

  # @impl true
  # def handle_cast({:addFollower, follower, _followee}, state) do
  #   username = Enum.at(state, 0)
  #   password = Enum.at(state, 1)
  #   subscritionList = Enum.at(state, 2)
  #   followersList = Enum.at(state, 3)
  #   tweetsList = Enum.at(state, 4)
  #
  #   newFollowersList = followersList ++ [follower]
  #   newState = [username, password, subscritionList, newFollowersList, tweetsList]
  #   IO.inspect(newState, label: "in addFollower user state")
  #   {:noreply, newState}
  # end

  @impl true
  def handle_cast({:goToClient}, state) do
    # showMainMenu(state)
    state
    {:noreply, state}
  end

  @impl true
  def handle_cast({:getTweet, tweeter, tweet}, state) do
    username = Enum.at(state, 0)
    # IO.inspect(username, label: "User got tweet")
    GenServer.cast(Engine, {:getTweet, tweeter, tweet, username})
    {:noreply, state}
  end

  def showMainMenu(state) do
    showEngine()

    action =
      Mix.Shell.IO.prompt(
        "Would you like to:\n Delete account\n Send tweet\n Subscribe to user\n Re-tweet\n Query\n Check Feed\n"
      )

    case action do
      "D\n" ->
        deleteUser(state)

      "d\n" ->
        deleteUser(state)

      "Delete\n" ->
        deleteUser(state)

      "delete\n" ->
        deleteUser(state)

      ###########################
      "sub\n" ->
        subscribeToUser(state)
        showMainMenu(state)

      "Subscribe\n" ->
        subscribeToUser(state)
        showMainMenu(state)

      "subscribe\n" ->
        subscribeToUser(state)
        showMainMenu(state)

      ###########################
      "SendTweet\n" ->
        tweet(state)
        showMainMenu(state)

      "Tweet\n" ->
        tweet(state)
        showMainMenu(state)

      "sendTweet\n" ->
        tweet(state)
        showMainMenu(state)

      "tweet\n" ->
        tweet(state)
        showMainMenu(state)

      "send tweet\n" ->
        tweet(state)
        showMainMenu(state)

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

      _ ->
        showMainMenu(state)
    end
  end

  def deleteUser(state) do
    # IO.inspect(state, label: "State")
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
          deleteUser(state)
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
        # deleteFromSupervisor(state)
        deleteFromEngine(state)

      "yes\n" ->
        # deleteFromSupervisor(state)
        deleteFromEngine(state)

      "No\n" ->
        showMainMenu(state)

      "no\n" ->
        showMainMenu(state)
    end
  end

  def deleteFromSupervisor(state) do
    dpid = Process.whereis(DySupervisor)
    # val = Process.alive?(dpid)
    userName = Enum.at(state, 0)
    pid = GenServer.whereis(:"#{userName}")
    IO.inspect(pid, label: "deleting child")
    DynamicSupervisor.terminate_child(dpid, pid)
    IO.puts("Account Deleted From Supervisor.")
  end

  def deleteFromEngine(state) do
    # find account in engine
    GenServer.cast(Engine, {:removeUser, state})
    IO.puts("Account Deleted From Engine.")
  end

  def subscribeToUser(state) do
    newUserToSubscribeTo1 = Mix.Shell.IO.prompt("Who do you want to subscribe to?")
    newUserToSubscribeTo = String.trim(newUserToSubscribeTo1)
    username = Enum.at(state, 0)

    usernameLists = GenServer.call(Engine, {:getUsers})

    if newUserToSubscribeTo in usernameLists do
      subscritionList = GenServer.call(Engine, {:getSubscribers, username})

      if newUserToSubscribeTo in subscritionList do
        IO.puts("You are already subscribed to this user")
      else
        if newUserToSubscribeTo != username do
          GenServer.cast(Engine, {:addFollower, username, newUserToSubscribeTo})
          GenServer.cast(Engine, {:addToSubscribeList, username, newUserToSubscribeTo})
          GenServer.cast(Engine, {:addSubToFeed, username, newUserToSubscribeTo})
          IO.puts("You are now subscribed to #{newUserToSubscribeTo}")
        else
          IO.puts("You cannot subscribe to yourself")
        end
      end
    else
      IO.puts("There is no such user")
    end
  end

  def tweet(state) do
    username = Enum.at(state, 0)
    _password = Enum.at(state, 1)

    tweet1 = Mix.Shell.IO.prompt("What would you like to tweet?")
    tweet = String.trim(tweet1)

    GenServer.cast(Engine, {:sendTweet, username, tweet})
    IO.inspect(tweet, label: "You tweeted")

    # newTweetsList = tweetsList ++ [tweet]
    # _newState = [username, password, subscritionList, followersList, newTweetsList]
  end

  def feed(state) do
    userName = Enum.at(state, 0)
    feedList = GenServer.call(Engine, {:getFeedList, userName})
    # IO.inspect(feedList, label: "Your feed")
  end

  def retweet(state) do
    userName = Enum.at(state, 0)
    feedList = GenServer.call(Engine, {:getFeedList, userName})
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
      # IO.inspect(newTweet, label: "new Tweet")

      username = Enum.at(state, 0)
      GenServer.cast(Engine, {:sendTweet, username, newTweet})
      IO.inspect(newTweet, label: "You tweeted")
    else
      showMainMenu(state)
    end
  end

  def query(state) do
    IO.inspect(state, label: "genserver state in query")
    userName = Enum.at(state, 0)
    query1 = Mix.Shell.IO.prompt("What would you like to search?")
    query = String.trim(query1)

    # person
    results =
      r_person =
      if String.contains?(query, "@") do
        # go to engine
        {_at, name} = String.split_at(query, 1)
        GenServer.cast(Engine, {:findPerson, name})
      else
        # hashtag
        r_hashtag =
          if String.contains?(query, "#") do
            # go to engine
            hashtag_results = GenServer.cast(Engine, {:findHashtag, query})
            IO.inspect(hashtag_results, label: "hashtag_results")
            # normal search
          else
            feedList = GenServer.call(Engine, {:getFeedList, userName})
            IO.inspect(feedList, label: "feedList")

            # for every value in the feedlist, search the tweet than search the username
            # if something interesting is found append it to results

            results = []

            results =
              for x <- feedList do
                {tweet, username} = x

                _r =
                  if(String.contains?(tweet, query) == true) do
                    IO.inspect(tweet, label: "Found")
                    _results = results ++ [{tweet, username}]
                  else
                    if(String.contains?(username, query) == true) do
                      IO.inspect(username, label: "Found")
                      _results = results ++ [{tweet, username}]
                    end
                  end
              end

            IO.inspect(results, label: "found query")
          end
      end
  end

  def showEngine() do
    epid = Process.whereis(Engine)
    IO.inspect(epid, label: "engine pid")
    state = :sys.get_state(epid)
    IO.inspect(state, label: "Engine")
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

    # enterTwitter()

    Supervisor.start_link([], strategy: :one_for_one)
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
        loginUserGetUserName()

      "LogIn\n" ->
        loginUserGetUserName()

      "log In\n" ->
        loginUserGetUserName()

      "logIn\n" ->
        loginUserGetUserName()

      "log in\n" ->
        loginUserGetUserName()

      "login\n" ->
        loginUserGetUserName()

      "test\n" ->
        test()

      _ ->
        enterTwitter()
    end

    # :showLogIn
    # :registered
  end

  def registerUserName() do
    user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
    userName = String.trim(user_name)
    registerPassword(userName)
    # :registerComplete
  end

  def registerPassword(user_name) do
    password1 = Mix.Shell.IO.prompt("Please Create A Password:")
    password2 = Mix.Shell.IO.prompt("Please Repeat Password For Verification:")

    if(password1 == password2) do
      # start dynamic supervisor
      password = String.trim(password1)

      # check if username already taken
      usernameLists = GenServer.call(Engine, {:getUsers})

      if user_name in usernameLists do
        IO.puts("Username already taken please try again")
        :registerFailed
        # registerPassword(user_name)
      else
        # start a child
        DySupervisor.start_child(user_name, password)
        GenServer.cast(Engine, {:addUser, [user_name, password]})

        IO.puts("Your new username is #{user_name} and your account was created")
        IO.puts("Please Log In For First Time")
        # :goToLogin
        # loginUser()
      end
    else
      IO.puts("Passwords did not match please try again")
      # :registerFailed
      registerPassword(user_name)
    end

    # check that child is in DySupervisor
    children = DynamicSupervisor.which_children(DySupervisor)

    _state =
      for x <- children do
        {_, pidx, _, _} = x
        _state = :sys.get_state(pidx)
      end
  end

  def loginUserGetUserName() do
    user_name = Mix.Shell.IO.prompt("Please Enter Your UserName:")
    userName = String.trim(user_name)
    loginUserGetPassWord(userName)
  end

  def loginUserGetPassWord(userName) do
    password1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
    password = String.trim(password1)

    # check that username exists
    kids = getChildren()

    usernameLists = Enum.flat_map(kids, fn [user_name, _x] -> [user_name] end)

    val =
      if userName in usernameLists do
        if checkPassword(userName, password) == true do
          :correctLogIn
          # goToClient(userName)
        else
          IO.inspect(userName, label: "1 Incorrect username or password. Please try again.")
          :incorrectLogIn
          # loginUser()
        end
      else
        IO.inspect(userName, label: "2 Incorrect username or password. Please try again.")
        :incorrectLogIn
        # loginUser()
      end
  end

  def checkPassword(user_name, password) do
    # check that username exists
    kids = getChildren()
    # IO.inspect(kids, label: "kids")

    # check if password is okay
    if(Enum.member?(kids, [user_name, password])) do
      true
    else
      # incorrect password
      false
    end
  end

  def goToClient(userName) do
    # IO.inspect(userName, label: "in goToClient")
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

  def test() do
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

  def makeKids(num) when num > 1 do
    # IO.puts("making kids")

    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    DySupervisor.start_child(username, "asd")

    GenServer.cast(Engine, {:addUser, [username, "asd"]})
    newNum = num - 1
    makeKids(newNum)
  end

  def makeKids(num) do
    # IO.puts("made kids")

    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)

    DySupervisor.start_child(username, "asd")
    GenServer.cast(Engine, {:addUser, [username, "asd"]})
  end
end
