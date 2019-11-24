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
      assert PROJ4.registerPassword("testUser2") == [
               ["testUser1", "asd"],
               ["child6", "asd"],
               ["child5", "asd"],
               ["child4", "asd"],
               ["child3", "asd"],
               ["child2", "asd"],
               ["child1", "asd"],
               ["testUser2", "asd"]
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
    test "testing correct log in user child2" do
      IO.puts("\n \n testing correct log in user child2")
      assert PROJ4.loginUserGetPassWord("child2") == :correctLogIn
    end

    test "testing incorrect log in user child3" do
      IO.puts("\n \n testing incorrect log in user child3")
      assert PROJ4.loginUserGetPassWord("child3") == :incorrectLogIn
    end
  end

  # test "delete account" do
  #   userName = "testUser"
  #   new_state = GenServer.cast(:"#{userName}", {:goToClient})
  #   User.deleteUser(new_state)
  # end

  # test "goToClient" do
  #   PROJ4.goToClient("testUser")
  #   assert true
  # end

  # test "check correct username" do
  #   PROJ4.loginUser()
  # end

  # test "show login screen" do
  #   assert PROJ4.enterTwitter() == :showLogIn
  # end
  #
  # describe "register tests" do
  #   # **Single Test**<br><br>
  #   # [x] test that new client is in dynamic supervisor<br><br>
  #   test "register user" do
  #     IO.inspect("Register one user")
  #     assert PROJ4.registerPassword("testUser1") == :goToLogin
  #   end

  #
  # **Single Test (with children already present in dynamic supervisor)**<br>
  # [ ] test that new client is in dynamic supervisor<br>
  # [ ] test to register with already taken username<br>
  # [ ] test that all children are in the dynamic supervisor<br><br>
  #
  # **Multiples Tests**<br>
  # [ ] do both tests above with 10, 100, 1000 children<br><br>
  # end

  # test "register multiple users" do
  #   IO.puts("Now making multiple users")
  #   PROJ4.makeManyKids(10)
  #   # Prints out the children user name to test that they were correctly registered
  #   kids = PROJ4.getChildren()
  #   IO.inspect(kids)
  # end

  # test "send one tweet" do
  #   IO.puts("Sending on tweet")
  # end
end
