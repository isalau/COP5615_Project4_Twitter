defmodule PROJ4Test do
  use ExUnit.Case, async: false
  doctest PROJ4

  # setup do
  #   :ok
  # end

  describe "Register" do
    test "that new client is in dynamic supervisor" do
      IO.puts("\n \n test that new client is in dynamic supervisor")
      # insert asd as password
      assert PROJ4.registerPassword("testUser1") == [["testUser1", "asd"]]
    end

    # with children already present
    test "that new client is in dynamic supervisor with children already present" do
      PROJ4.makeKids(6)
      IO.puts("\n \n test that new client is in dynamic supervisor with children already present")

      # insert asd as password
      assert PROJ4.registerPassword("testUser") == [
               ["testUser1", "asd"],
               ["child6", "asd"],
               ["child5", "asd"],
               ["child4", "asd"],
               ["child3", "asd"],
               ["child2", "asd"],
               ["child1", "asd"],
               ["testUser", "asd"]
             ]
    end

    # test "to register with already taken username" do
    #   IO.puts("test to register with already taken username")
    #
    #   PROJ4.registerPassword("testUser3")
    #   assert PROJ4.registerPassword("testUser3") == :registerFailed
    # end
    #
    # test "that all children are in the dynamic supervisor" do
    # end
    #
    # test " do both tests above with 10, 100, 1000 children" do
    # end
  end

  describe "Log In" do
    # test "testing incorrect log in user child3" do
    #   IO.puts("\n \n testing incorrect log in user child3")
    #   assert PROJ4.loginUserGetPassWord("child3") == :incorrectLogIn
    # end

    test "testing correct log in user testUser" do
      IO.puts("\n \n testing correct log in user testUser")
      assert PROJ4.loginUserGetPassWord("testUser") == :correctLogIn
    end
  end

  # describe "Delete Account" do
  #   test "delete account" do
  #     IO.puts("\n \n testing delete child2")
  #     User.deleteUser(["child2", "asd"])
  #
  #     assert GenServer.cast(Engine, {:getUsers}) == [
  #              ["testUser1", "asd"],
  #              ["child6", "asd"],
  #              ["child5", "asd"],
  #              ["child4", "asd"],
  #              ["child3", "asd"],
  #              ["child1", "asd"],
  #              ["testUser", "asd"]
  #            ]
  #   end
  # end

  # describe "Send Tweet" do
  # end
  #
  describe "Subscribe" do
    test "subscribe child2 to testUser's feed" do
      IO.puts("\n \n subscribe child2 to testUser's feed")

      assert User.subscribeToUser(["testUser", "asd"]) == :ok
    end
  end

  describe "Feed" do
    test "show testUser's feed" do
      IO.puts("\n \n testing show testUser feed")

      assert User.feed(["testUser", "asd"]) == [{"init feed tweet #testing123", "wise_one"}]
    end
  end

  describe "Query" do
    test "test query for normal word" do
      IO.puts("\n \n testing query for normal word")

      assert User.query(["testUser", "asd"]) == [[{"init feed tweet #testing123", "wise_one"}]]
    end

    test "test query for hashtag word" do
      IO.puts("\n \n testing query for hashtag")

      assert User.query(["testUser", "asd"]) == :ok
    end

    test "test query for person" do
      IO.puts("\n \n testing query for hashtag")

      assert User.query(["testUser", "asd"]) == :ok
    end
  end
end
