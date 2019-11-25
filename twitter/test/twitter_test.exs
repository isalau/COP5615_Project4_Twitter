defmodule TWITTERTest do
  use ExUnit.Case, async: false
  doctest TWITTER

  describe "Tweet" do
    test "if user tweets it is in their tweets list" do
      IO.puts("\n \n testing if user tweets it is in their tweets list")

      # have user1 tweet something
      sender = "isabel"
      tweet = "test tweet for #testing"
      # added line new_tweets to send_tweet function for test
      new_tweets = Tweet.send_tweet(sender, tweet)
      # assert that it is in her tweet's list
      assert new_tweets == ["test tweet for #testing"]
    end

    test "if user tweets it is in their followers feed" do
      IO.puts("\n \n testing if user tweets it is in their followers feed")
      # check that user2 has tweet in feed
      my_id = "anshika"
      id = :"#{my_id}_cssa"
      user2_feed = GenServer.call(id, {:get_feed})
      IO.inspect(user2_feed, label: "user2 feed is")
      assert user2_feed == ["test tweet for #testing"]
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

  #
  # describe "Re-Tweet" do
  # test "if user re-tweets it is in their tweets list" do
  # end
  #
  # test "if user re-tweets it is in their followers feed" do
  # end
  #
  # test "if user re-tweets it is not in a non-followers feed" do
  # end
  # end
  #
  # describe "Query" do
  # end
end
