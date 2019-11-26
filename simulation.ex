defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(name) do
    _tweets = []
    _people = []
    child_spec = Supervisor.child_spec({CSA, name}, id: name, restart: :temporary)

    # child_spec_2 = Supervisor.child_spec({Engine, [tweets, people, name]}, restart: :temporary)

    # Start CSA
    {:ok, _child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    # Start CSSA ####### NOT SURE ###########
    # {:ok, child} = DynamicSupervisor.start_child(__MODULE__, child_spec_2)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

defmodule CSA do
  use GenServer

  def start_link(name) do
    {:ok, _pid} =
      GenServer.start_link(__MODULE__, name,
        # Check - Haven't given any state to child except name
        name: :"#{name}"
      )

    # Check 2 - should we store one state eleme in tuple
  end

  def init(name) do
    # Trigger the CSSA

    {:ok, name}
  end

  def handle_call({:tweet, mssg}, _from, name) do
    Tweet.send_tweet(name, mssg)
    {:reply, :ok, name}
  end

  def handle_call({:subscribe, subs}, _from, name) do
    Subscribe.subscribe(name, subs)
    {:reply, :ok, name}
  end

  def handle_call({:retweet}, _from, name) do
    Retweet.retweet(name)
    {:reply, :ok, name}
  end

  def handle_call({:hashtag, hashtag}, _from, name) do
    Query.get_hashtags(hashtag, name)
    {:reply, :ok, name}
  end

  def handle_call({:mention, mention}, _from, name) do
    Query.get_mentions(mention, name)
    {:reply, :ok, name}
  end
end

# Started by main
defmodule Engine do
  use GenServer

  def start_link([followers, subscribed, feed, tweets, name]) do
    # new_name = name_cssa
    {:ok, _pid} =
      GenServer.start_link(__MODULE__, {followers, subscribed, feed, tweets},
        name: :"#{name}_cssa"
      )
  end

  def init(_init_arg) do
    tweets = []
    followers = []
    subscribed = []
    feed = []
    {:ok, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:register, name, pass}, _from, {followers, subscribed, feed, tweets}) do
    subscribed = subscribed ++ [name]
    followers = followers ++ [{:"#{name}", pass}]
    # Register.get_people(name,people)#HERE everyone is on everyone's list
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:tweet, tweet}, _from, {followers, subscribed, feed, tweets}) do
    tweets = tweets ++ [tweet]

    if followers != [] do
      IO.puts("Im distributing tweets")
      Tweet.distribute_it(tweet, followers)
    end

    {:reply, tweets, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:got_mssg, tweet}, _from, {followers, subscribed, feed, tweets}) do
    feed = feed ++ [tweet]
    # pid = self()
    # IO.puts("My tweets are ")
    # IO.inspect(tweets)
    {:reply, feed, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:populate, follower}, _from, {followers, subscribed, feed, tweets}) do
    followers = followers ++ [follower]
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end

  def handle_call(
        {:subscribed, following, new_tweets},
        _from,
        {followers, subscribed, feed, tweets}
      ) do
    subscribed = subscribed ++ [following]
    feed = feed ++ new_tweets
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:get_feed}, _from, {followers, subscribed, feed, tweets}) do
    {:reply, feed, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:get_my_feed, new_feed}, _from, {followers, subscribed, feed, tweets}) do
    feed = feed ++ new_feed
    # IO.inspect(feed, label: "The feed now inside looks like")
    # IO.inspect(tweets, label: "The tweets inside look like")
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end
end

defmodule Register do
  def reg(name, pass) do
    # start a process with the given name - CSA
    DySupervisor.start_child(name)

    # Start the CSSA
    tweets = []
    followers = []
    subscribed = []
    feed = []
    Engine.start_link([followers, subscribed, feed, tweets, name])

    # Get the name on subscribed list  lst
    # Get password name key word pair list in place of followers
    pid = :"#{Engine}_cssa"
    {new_key_pass, new_subscribed, _, _} = GenServer.call(pid, {:register, name, pass})
    IO.inspect(new_key_pass, label: "The key pass list is")
    IO.inspect(new_subscribed, label: "The people's list is")
  end

  def makeKids(num, pass) when num > 1 do
    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    reg(username, pass)
    newNum = num - 1
    makeKids(newNum, pass)
  end

  def makeKids(num, pass) do
    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    reg(username, pass)
  end
end

defmodule Subscribe do
  def subscribe(from, to) do
    # Populate people's list (PLUG)
    IO.puts("Lets start subscribin !")
    pid_from = :"#{from}_cssa"
    pid_to = :"#{to}_cssa"

    # Put your name in the followers list of the person followed
    {new_followers, _, _, new_tweets} = GenServer.call(pid_to, {:populate, pid_from})

    IO.inspect(new_followers,
      label: "The followers in the person you subscribed to has your name !"
    )

    # Put their name in your subscribed list
    {_, new_subscribed, _, _} = GenServer.call(pid_from, {:subscribed, pid_to, new_tweets})
    IO.inspect(new_subscribed, label: "you have subscribed to #{to}")
  end
end

defmodule Retweet do
  def retweet(my_id) do
    id = :"#{my_id}_cssa"
    {_, _, my_feed, _} = :sys.get_state(id)
    # convert the list to a keyword list
    _c = 0
    _lst = []

    {_, my_new_feed} =
      Enum.reduce(my_feed, {0, []}, fn x, {c, lst} ->
        c = c + 1
        lst = lst ++ [{:"#{c}", x}]
        {c, lst}
      end)

    IO.inspect(my_new_feed, label: "Your feed")
    re_tweet = String.trim(IO.gets("Select a tweet from your list of tweets \n"))
    select = :"#{re_tweet}"
    # Not checked if this works
    IO.inspect(select, label: "You Selected #{select}")
    tweet = List.keyfind(my_new_feed, select, 0)

    if tweet != nil do
      tweet = elem(tweet, 1)
      newTweet = "#I am retweeting: tweet #{tweet}"
      IO.inspect(tweet, label: "You Selected this tweet")
      GenServer.call(id, {:tweet, newTweet})
    else
      IO.puts("can't find the tweet you want to retweet")
    end
  end
end

defmodule Tweet do
  def send_tweet(sender, tweet) do
    # Tell the process of sender about the tweet
    pid_sender = :"#{sender}_cssa"
    new_tweets = GenServer.call(pid_sender, {:tweet, tweet})
    IO.inspect(new_tweets, label: "My #{sender} tweets now")
  end

  def distribute_it(tweet, people) do
    # Tell the engine to distribute the tweet
    # pid = :"#{Engine}_cssa"
    # :ok = GenServer.call(pid, {:distribute, tweet, people})
    for elem <- people do
      pid = :"#{elem}"
      feed = GenServer.call(pid, {:got_mssg, tweet})
      IO.inspect(feed, label: "My #{elem} news feeds after getting the tweet")
    end
  end
end

defmodule Query do
  def get_my_results(query, my_id) do
    queryLength = String.length(query)

    if(queryLength == 0 || query == " ") do
      IO.puts("You cannot query an empty string")
      :EmptyQuery
    else
      id = :"#{my_id}_cssa"
      feedList = GenServer.call(id, {:get_feed})
      IO.inspect(feedList, label: "feedList")

      # # for every value in the feedlist, search the tweet than search the username
      # # if something interesting is found append it to results
      #
      results = []

      _results =
        for tweet <- feedList do
          _r =
            if(String.contains?(tweet, query) == true) do
              IO.inspect(tweet, label: "Found")
              _results = results ++ tweet
            end
        end
    end
  end

  def get_my_feed(my_id) do
    # Get the list of subscribers
    id = :"#{my_id}_cssa"
    {_, my_subscribed, _, _} = :sys.get_state(id)
    # Get each Subscribers tweets list and add it to my feed list
    IO.inspect(my_subscribed, label: "These are the list of people i subscribed")

    for elem <- my_subscribed do
      # IO.inspect(elem, label: "Just checking if elem has _cssa in it")
      _d_tweets = []
      # elem = :"#{elem}_cssa"
      {_, _, _, d_tweets} = :sys.get_state(elem)
      IO.inspect(d_tweets, label: "The tweets from #{elem}")
      {_, _, d_feed, _} = GenServer.call(id, {:get_my_feed, d_tweets})
      IO.inspect(d_feed, label: "Now my tweets have the feed of #{elem}")
    end
  end

  def get_hashtags(hashtag, my_id) do
    pid = :"#{Engine}_cssa"
    id = :"#{my_id}_cssa"

    {_, people, _, _} = :sys.get_state(pid)
    people = people -- [my_id]
    IO.inspect(people, label: "Total number of people who could have used this hashtag")
    # CHECK if elem is _cssa address

    for elem <- people do
      # get their tweets
      elem = :"#{elem}_cssa"
      {_, _, _, sent_tweets} = :sys.get_state(elem)
      IO.inspect(sent_tweets)
      # check their tweets and collect their hashtags
      list_of_tweets =
        Enum.reduce(sent_tweets, [], fn x, lst ->
          if String.contains?(x, hashtag) do
            _lst = lst ++ [x]
          else
            _lst = lst
          end
        end)

      IO.inspect(list_of_tweets, label: "The list of tweets that have the hashtag")
      # Get these hashtags in your feed using get_my_feed handle call
      if list_of_tweets != [] do
        IO.puts("Putting the hashtags in your feed")
        {_, _, _, _d_feed} = GenServer.call(id, {:get_my_feed, list_of_tweets})
      end
    end
  end

  def get_mentions(mention, my_id) do
    pid = :"#{Engine}_cssa"
    id = :"#{my_id}_cssa"
    {_, people, _, _} = :sys.get_state(pid)
    people = people -- [id]

    for elem <- people do
      # get their tweets
      elem = :"#{elem}_cssa"
      {_, _, _, sent_tweets} = :sys.get_state(elem)
      # check their tweets and collect their hashtags
      list_of_tweets =
        Enum.reduce(sent_tweets, [], fn x, lst ->
          if String.contains?(x, mention) do
            _lst = lst ++ [x]
          else
            _lst = lst
          end
        end)

      # Get these hashtags in your feed using get_my_feed handle call
      {_, _, _, _d_feed} = GenServer.call(id, {:get_my_feed, list_of_tweets})
    end
  end
end

defmodule Feed do
  def showfeed(sender) do
    id = :"#{sender}_cssa"
    user_feed = GenServer.call(id, {:get_feed})
    IO.inspect(user_feed, label: "Your feed is ")
  end
end

defmodule Delete do
  def deleteUser(id) do
    # IO.inspect(state, label: "State")
    answer = Mix.Shell.IO.prompt("Are you sure you would like to delete your account?")

    case answer do
      "Yes\n" ->
        # if checkPassword passes
        userName = id
        # password = Enum.at(state, 1)
        # enteredpassword1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        # enteredpassword = String.trim(enteredpassword1)

        # if password == enteredpassword do
        deleteConfirm(userName)

      # else
      #   IO.puts("Incorrect password")
      # end

      "yes\n" ->
        # if checkPassword passes
        userName = id
        # password = Enum.at(state, 1)
        # enteredpassword1 = Mix.Shell.IO.prompt("Please Enter Your Password:")
        # enteredpassword = String.trim(enteredpassword1)

        # if password == enteredpassword do
        deleteConfirm(userName)

        # else
        #   IO.puts("Incorrect password")
        # end

        # "No\n" ->
        #   showMainMenu(state)
        #
        # "no\n" ->
        #   showMainMenu(state)
    end
  end

  def deleteConfirm(state) do
    confirm = Mix.Shell.IO.prompt("Final confirmation. Delete Account?")

    case confirm do
      "Yes\n" ->
        # delete from supervisor and log out
        # deleteFromSupervisor(state)
        deleteFromCSA(state)
        deleteFromCSSA(state)

      "yes\n" ->
        # deleteFromSupervisor(state)
        deleteFromCSA(state)
        deleteFromCSSA(state)

        # "No\n" ->
        #   showMainMenu(state)
        #
        # "no\n" ->
        #   showMainMenu(state)
    end
  end

  def deleteFromCSA(_state) do
    # dpid = Process.whereis(DySupervisor)
    # # val = Process.alive?(dpid)
    # userName = Enum.at(state, 0)
    # pid = GenServer.whereis(:"#{userName}")
    # IO.inspect(pid, label: "deleting child")
    # DynamicSupervisor.terminate_child(dpid, pid)
    # IO.puts("Account Deleted From Supervisor.")
  end

  def deleteFromCSSA(_state) do
    # # find account in engine
    # GenServer.cast(Engine, {:removeUser, state})
    # IO.puts("Account Deleted From Engine.")
  end
end

# Main
defmodule Main do
  def main_task do
    # Start the supervisor \
    DySupervisor.start_link(1)
    # Start the engine \
    tweets = []
    followers = []
    subscribed = []
    feed = []
    {:ok, _pid} = Engine.start_link([followers, subscribed, feed, tweets, Engine])
  end

  def main do
    # task = String.trim(IO.gets("Want to Register or Login? \n"))

    runSimulation()

    # if task == "Register" do
    #   {_, tot_users, _, _} = :sys.get_state(:"#{Engine}_cssa")
    #   action = String.trim(IO.gets("Your name ? \n"))
    #
    #   if action in tot_users do
    #     IO.puts("username already exists")
    #   else
    #     pass = String.trim(IO.gets("Your password? \n"))
    #     Register.reg(action, pass)
    #   end
    # end
    #
    # if task == "Login" do
    #   {_, tot_users, _, _} = :sys.get_state(:"#{Engine}_cssa")
    #   IO.inspect(tot_users, label: "Total users list in Login")
    #   sender = String.trim(IO.gets("And your username is ? \n"))
    #
    #   if sender in tot_users do
    #     # After checking show
    #     IO.puts("Welcome!")
    #     pid_sender = :"#{sender}"
    #
    #     job =
    #       String.trim(
    #         IO.gets("What wouid you like to do - Tweet , Subscribe, Retweet,Feed or Query? \n")
    #       )
    #
    #     # Need more jobs to do
    #     if job == "Tweet" do
    #       # TODO _Add next line argument
    #       tweet = String.trim(IO.gets("What's on your mind? \n"))
    #       GenServer.call(pid_sender, {:tweet, tweet})
    #     end
    #
    #     if job == "Subscribe" do
    #       tot_users = tot_users -- [sender]
    #       IO.inspect(tot_users, label: "People you can subscribe")
    #       subs = String.trim(IO.gets("Who do you want to subscribe to? \n"))
    #       # CHeck if subs exist in system
    #       if subs in tot_users do
    #         GenServer.call(pid_sender, {:subscribe, subs})
    #       else
    #         IO.puts("Person you are trying to subscribe doesn't exist")
    #       end
    #     end
    #
    #     if job == "Retweet" do
    #       Retweet.retweet(pid_sender)
    #     end
    #
    #     if job == "Delete" do
    #       Delete.deleteUser(pid_sender)
    #     end
    #
    #     if job == "Query" do
    #       query = String.trim(IO.gets("What is your query:  Tweets , @mentions or #hashtags? \n"))
    #
    #       if query == "Tweets" do
    #         Query.get_my_results(pid_sender)
    #       end
    #
    #       if query == "#hashtags" do
    #         hashtag = String.trim(IO.gets("Which trend are you looking for? \n"))
    #         GenServer.call(pid_sender, {:hashtag, hashtag})
    #       end
    #
    #       if query == "@mentions" do
    #         mention = String.trim(IO.gets("Whose mention are you looking for? \n"))
    #         GenServer.call(pid_sender, {:mention, mention})
    #       end
    #     end
    #
    #     if job == "Feed" do
    #       Feed.showfeed(pid_sender)
    #     end
    #   else
    #     IO.puts("Wrong username or password")
    #   end
    # end
    #
    # main()
  end

  def runSimulation() do
    # get number of users --> makeKids(numUsers)
    Register.makeKids(5, "pwd")
    # get number of fake tweets --> makeFakeTweets(numTweets)
    testTweets_db = []
    testTweets = makeFakeTweets(3, testTweets_db)
    IO.inspect(testTweets, label: "test Tweets")
    # subscribe
    # sends that many tweets per user
    # re-tweet
    # query
    # feed
  end

  def makeFakeTweets(num, testTweets_db) when num > 1 do
    numm = Integer.to_string(num)
    numtweet = String.replace_suffix("tweet x", " x", numm)
    testTweet = "We are making a test tweet #{numtweet}"
    testTweets_db = testTweets_db ++ [testTweet]
    newNum = num - 1
    makeFakeTweets(newNum, testTweets_db)
  end

  def makeFakeTweets(num, testTweets_db) do
    numm = Integer.to_string(num)
    numtweet = String.replace_suffix("tweet x", " x", numm)
    testTweet = "We are making a test tweet #{numtweet}"
    _testTweets_db = testTweets_db ++ [testTweet]
  end
end

# Main.main_task()
# Main.main()
