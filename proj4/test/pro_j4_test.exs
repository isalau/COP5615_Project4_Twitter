defmodule PROJ4Test do
  use ExUnit.Case
  doctest PROJ4

  # test "register multiple users" do
  #   IO.puts("Now making multiple users")
  #   PROJ4.makeManyKids(10)
  #   # Prints out the children user name to test that they were correctly registered
  #   kids = PROJ4.getChildren()
  #   IO.inspect(kids)
  # end

  # test "register user" do
  #   IO.inspect("Register one user")
  #   PROJ4.main()
  #   # Prints out the children user name to test that they were correctly registered
  #   kids = PROJ4.getChildren()
  # end

  test "log in user" do
    IO.inspect("Testing log in user")
    # first create a test user to test log in with
    PROJ4.registerUser()

    # next test log in
    PROJ4.main()
    # Prints out the children user name to test that they were correctly registered
    kids = PROJ4.getChildren()
  end

  # test "send one tweet" do
  #   IO.puts("Sending on tweet")
  # end
end
