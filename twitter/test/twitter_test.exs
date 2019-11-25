defmodule TWITTERTest do
  use ExUnit.Case, async: false
  doctest TWITTER

  describe "Tweet" do
    test "if user tweets it is in their tweets list" do
      IO.puts("\n \n testing if user tweets it is in their tweets list")

      # have user1 tweet something
      sender = "isabel"
      tweet = "test tweet for #testing i love puppies"
      # added line new_tweets to send_tweet function for test
      new_tweets = Tweet.send_tweet(sender, tweet)
      # assert that it is in her tweet's list
      assert new_tweets == ["test tweet for #testing i love puppies"]
    end

    test "if tweet is too long it should not pass" do
      sender = "isabel"

      tweet =
        "test too long tweet  test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet  test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet  test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet test too long tweet  "

      # added new checks to send_tweet function for test
      response = Tweet.send_tweet(sender, tweet)
      assert response == :TweetToLong
    end

    test "if tweet is empty it should not pass" do
      sender = "isabel"

      tweet = " "

      # added new checks to send_tweet function for test
      response = Tweet.send_tweet(sender, tweet)
      assert response == :EmptyTweet
    end

    test "if user tweets it is in their followers feed" do
      IO.puts("\n \n testing if user tweets it is in their followers feed")
      # check that user2 has tweet in feed
      my_id = "anshika"
      id = :"#{my_id}_cssa"
      user2_feed = GenServer.call(id, {:get_feed})
      IO.inspect(user2_feed, label: "user2 feed is")
      assert user2_feed == ["test tweet for #testing i love puppies"]
    end

    test "if user tweets it is not in a non-followers feed" do
      IO.puts("\n \n testing if user tweets it is not in a non-followers feed")
      # check that user3 does not have tweet in feed
      my_id = "dobra"
      id = :"#{my_id}_cssa"
      user3_feed = GenServer.call(id, {:get_feed})
      IO.inspect(user3_feed, label: "user3 feed is")
      assert user3_feed == []
    end
  end

  describe "Feed" do
    test "show testUser's feed" do
      IO.puts("\n \n testing show testUser feed")

      sender = "anshika"
      pid_sender = :"#{sender}"
      Feed.showfeed(pid_sender)
    end
  end

  describe "Re-Tweet" do
    test "if user re-tweets it is in their tweets list" do
      IO.puts("\n \n testing if user re-tweets it is in their tweets list")

      # have user2 re-tweet something
      sender = "anshika"
      pid_sender = :"#{sender}"
      new_tweets = Retweet.retweet(pid_sender)
      # assert that it is in her tweet's list
      assert new_tweets == ["qwe: respond to tweet test tweet for #testing i love puppies"]
    end

    test "if re-tweet is too long it should not pass" do
      IO.puts("\n \n testing if user re-tweets is too long it should not pass")

      # have user2 re-tweet something
      sender = "anshika"
      pid_sender = :"#{sender}"
      new_tweets = Retweet.retweet(pid_sender)
      assert new_tweets == :TweetToLong
    end

    # test "if re-tweet is empty it should pass" do
    #   IO.puts("\n \n testing if user re-tweets is empty it should pass")
    #   # have user2 re-tweet something
    #   sender = "dobra"
    #   pid_sender = :"#{sender}"
    #   new_tweets = Retweet.retweet(pid_sender)
    #
    #   assert new_tweets == [
    #            ": respond to tweet qwe: respond to tweet test tweet for #testing i love puppies"
    #          ]
    # end

    test "if user re-tweets it is in their followers feed" do
      IO.puts("\n \n testing if user re-tweets it is in their followers feed")
      # check that user3 has tweet in feed
      my_id = "dobra"
      id = :"#{my_id}_cssa"
      user3_feed = GenServer.call(id, {:get_feed})
      IO.inspect(user3_feed, label: "user3 feed is")
      assert user3_feed == ["qwe: respond to tweet test tweet for #testing i love puppies"]
    end

    test "if user re-tweets it is not in a non-followers feed" do
      IO.puts("\n \n testing if user tweets it is not in a non-followers feed")
      # check that user1 does not have tweet in feed
      my_id = "isabel"
      id = :"#{my_id}_cssa"
      user1_feed = GenServer.call(id, {:get_feed})
      IO.inspect(user1_feed, label: "user1 feed is")
      assert user1_feed == []
    end
  end

  describe "Query" do
    test "query for normal word: puppies" do
      IO.puts("\n \n testing query for normal word: puppies")

      sender = "dobra"
      pid_sender = :"#{sender}"
      query = "puppies"
      results = Query.get_my_results(query, pid_sender)
      assert results == ["qwe: respond to tweet test tweet for #testing i love puppies"]
    end

    test "if query is empty it should not pass" do
      IO.puts("\n \n testing if query is empty it should not pass")

      sender = "dobra"
      pid_sender = :"#{sender}"
      query = " "
      results = Query.get_my_results(query, pid_sender)
      assert results == :EmptyQuery
    end

    test "query for hashtag" do
      IO.puts("\n \n testing query for hashtag")
      sender = "dobra"
      my_id = :"#{sender}"
      hashtag = "testing"
      Query.get_hashtags(hashtag, my_id)
    end

    test "query for person" do
      IO.puts("\n \n testing query for person")
      sender = "anshika"
      my_id = :"#{sender}"
      mention = "puppies"
      Query.get_mentions(mention, my_id)
    end
  end

  # CHANGES
  # added line new_tweets to send_tweet function for test
  # added line new_tweets to re_tweet function for test
  # added Feed module
  # added new checks to send_tweet function for test
end
