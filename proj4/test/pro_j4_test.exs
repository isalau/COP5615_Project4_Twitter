defmodule PROJ4Test do
  use ExUnit.Case
  doctest PROJ4

  setup do
    # make a bunch of kids
    PROJ4.makeKids(6)

    # register a specific user
    DySupervisor.start_child("testUser", "t")
    GenServer.cast(Engine, {:addUser, ["testUser", "t"]})

    # make sure they are all there
    kids = PROJ4.getChildren()
    IO.inspect(kids)

    # goToClient
    # goToClient("testUser")
  end

  # test "goToClient" do
  #   PROJ4.goToClient("testUser")
  # end

  test "check correct username" do
    PROJ4.loginUser()
  end

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

  # test "log in user" do
  #   IO.inspect("Testing log in user")
  #   # first create a test user to test log in with
  #   PROJ4.registerUser()
  #
  #   # next test log in
  #   PROJ4.main()
  #   # Prints out the children user name to test that they were correctly registered
  #   kids = PROJ4.getChildren()
  # end

  # test "send one tweet" do
  #   IO.puts("Sending on tweet")
  # end
end
