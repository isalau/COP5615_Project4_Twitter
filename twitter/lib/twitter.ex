defmodule TWITTER do
  @moduledoc """
  Documentation for TWITTER.
  """

  def hello do
    :world
  end
end

defmodule DySupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    {:ok, _pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(name) do
    tweets = []
    people = []
    child_spec = Supervisor.child_spec({CSA, name}, id: name, restart: :temporary)

    # child_spec_2 = Supervisor.child_spec({Engine, [tweets, people, name]}, restart: :temporary)

    # Start CSA
    {:ok, child} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    # Start CSSA ####### NOT SURE ###########
    # {:ok, child} = DynamicSupervisor.start_child(__MODULE__, child_spec_2)
  end

  def init(init_arg) do
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

  def init(init_arg) do
    tweets = []
    followers = []
    subscribed = []
    feed = []
    {:ok, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:register, name}, _from, {followers, subscribed, feed, tweets}) do
    subscribed = subscribed ++ [name]
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

  def handle_call({:get_my_tweets}, _from, {followers, subscribed, feed, tweets}) do
    tweets

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

  def handle_call({:subscribed, following}, _from, {followers, subscribed, feed, tweets}) do
    subscribed = subscribed ++ [following]
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:get_feed}, _from, {followers, subscribed, feed, tweets}) do
    {:reply, feed, {followers, subscribed, feed, tweets}}
  end

  def handle_call({:get_my_feed, new_feed}, _from, {followers, subscribed, feed, tweets}) do
    feed = feed ++ new_feed
    {:reply, {followers, subscribed, feed, tweets}, {followers, subscribed, feed, tweets}}
  end
end

defmodule Register do
  def reg(name) do
    # start a process with the given name - CSA
    DySupervisor.start_child(name)

    # Start the CSSA
    tweets = []
    followers = []
    subscribed = []
    feed = []
    Engine.start_link([followers, subscribed, feed, tweets, name])

    # Get the name on people's lst
    # TODO - Check if name is okay
    pid = :"#{Engine}_cssa"
    {_, new_subscribed, _, _} = GenServer.call(pid, {:register, name})
    # IO.puts("The people's list is")
    # IO.inspect(new_subscribed)
  end

  def makeKids(num) when num > 1 do
    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    reg(username)
    newNum = num - 1
    makeKids(newNum)
  end

  def makeKids(num) do
    # start a child
    numm = Integer.to_string(num)
    username = String.replace_suffix("child x", " x", numm)
    reg(username)
  end
end

defmodule Subscribe do
  def subscribe(from, to) do
    # Populate people's list (PLUG)
    IO.puts("Lets start subscribin !")
    pid_from = :"#{from}_cssa"
    pid_to = :"#{to}_cssa"

    # Put your name in the followers list of the person followed
    {new_followers, _, _, _} = GenServer.call(pid_to, {:populate, pid_from})

    IO.inspect(new_followers,
      label: "The followers in the person you subscribed to has your name !"
    )

    # Put their name in your subscribed list
    {_, new_subscribed, _, _} = GenServer.call(pid_from, {:subscribed, pid_to})
    IO.inspect(new_subscribed, label: "you have subscribed to #{to}")
  end
end

defmodule Retweet do
  def retweet(my_id) do
    id = :"#{my_id}_cssa"
    {_, _, my_feed, _} = :sys.get_state(id)
    # convert the list to a keyword list
    c = 0
    lst = []

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

    new_tweets =
      if tweet != nil do
        tweet = elem(tweet, 1)
        IO.inspect(tweet, label: "You Selected this tweet")
        new_tweets = GenServer.call(id, {:tweet, tweet})
      else
        IO.puts("can't find the tweet you want to retweet")
        new_tweets = []
      end

    new_tweets
  end
end

defmodule Tweet do
  def send_tweet(sender, tweet) do
    # Tell the process of sender about the tweet
    pid_sender = :"#{sender}_cssa"
    tweetLength = String.length(tweet)

    if(tweetLength > 280) do
      overby = tweetLength - 280
      IO.puts("Tweet is too long by #{overby} characters please try again. ")
      :TweetToLong
    else
      new_tweets = GenServer.call(pid_sender, {:tweet, tweet})
      IO.inspect(new_tweets, label: "My #{sender} tweets now")
      new_tweets
    end
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
    id = :"#{my_id}_cssa"
    feedList = GenServer.call(id, {:get_feed})
    IO.inspect(feedList, label: "feedList")

    # # for every value in the feedlist, search the tweet than search the username
    # # if something interesting is found append it to results
    #
    results = []

    results =
      for tweet <- feedList do
        _r =
          if(String.contains?(tweet, query) == true) do
            IO.inspect(tweet, label: "Found")
            _results = results ++ tweet
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
      IO.inspect(elem, label: "Just checking if elem has _cssa in it")
      d_tweets = []
      # elem = :"#{elem}_cssa"
      {_, _, _, d_tweets} = :sys.get_state(elem)
      IO.inspect(d_tweets, label: "The tweets from #{elem}")
      {_, _, _, d_feed} = GenServer.call(id, {:get_my_feed, d_tweets})
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
            lst = lst ++ [x]
          else
            lst = lst
          end
        end)

      IO.inspect(list_of_tweets, label: "The list of tweets that have the hashtag")
      # Get these hashtags in your feed using get_my_feed handle call
      if list_of_tweets != [] do
        IO.puts("Putting the hashtags in your feed")
        {_, _, _, d_feed} = GenServer.call(id, {:get_my_feed, list_of_tweets})
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
            lst = lst ++ [x]
          else
            lst = lst
          end
        end)

      # Get these hashtags in your feed using get_my_feed handle call
      {_, _, _, d_feed} = GenServer.call(id, {:get_my_feed, list_of_tweets})
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
    {:ok, pid} = Engine.start_link([followers, subscribed, feed, tweets, Engine])
  end

  def main do
    task = String.trim(IO.gets("Want to Register or Login? \n"))

    if task == "Register" do
      action = String.trim(IO.gets("Your name ? \n"))
      # IO.inspect(action)
      Register.reg(action)
    end

    if task == "Login" do
      {_, tot_users, _, _} = :sys.get_state(:"#{Engine}_cssa")
      IO.inspect(tot_users, label: "Total users list in Login")
      sender = String.trim(IO.gets("And your username is ? \n"))

      if sender in tot_users do
        # After checking show
        IO.puts("Welcome!")
        pid_sender = :"#{sender}"

        job =
          String.trim(
            IO.gets("What wouid you like to do - Tweet , Subscribe, Retweet or Query? \n")
          )

        # Need more jobs to do
        if job == "Tweet" do
          # TODO _Add next line argument
          tweet = String.trim(IO.gets("What's on your mind? \n"))
          # check to make sure tweet is only 280 or less characters
          tweetLength = String.length(tweet)

          if(tweetLength > 280) do
            overby = tweetLength - 280
            IO.puts("Tweet is too long by #{overby} characters please try again. ")
          else
            GenServer.call(pid_sender, {:tweet, tweet})
          end
        end

        if job == "Subscribe" do
          tot_users = tot_users -- [sender]
          IO.inspect(tot_users, label: "People you can subscribe")
          subs = String.trim(IO.gets("Who do you want to subscribe to? \n"))
          # CHeck if subs exist in system
          if subs in tot_users do
            GenServer.call(pid_sender, {:subscribe, subs})
          else
            IO.puts("Person you are trying to subscribe doesn't exist")
          end
        end

        if job == "Retweet" do
          Retweet.retweet(pid_sender)
        end

        if job == "Feed" do
          Feed.showfeed(pid_sender)
        end

        if job == "Query" do
          query = String.trim(IO.gets("What is your query:  Tweets , @mentions or #hashtags? \n"))

          if query == "Tweets" do
            Query.get_my_feed(pid_sender)
          end

          if query == "#hashtags" do
            hashtag = String.trim(IO.gets("Which trend are you looking for? \n"))
            GenServer.call(pid_sender, {:hashtag, hashtag})
          end

          if query == "@mentions" do
            mention = String.trim(IO.gets("Whose mention are you looking for? \n"))
            GenServer.call(pid_sender, {:mention, mention})
          end
        end
      else
        IO.puts("Wrong username or password")
      end
    end

    main()
  end
end

# Main.main_task()
# Main.main()
