defmodule PROJ4Test do
  use ExUnit.Case
  doctest PROJ4

  test "register user" do
    PROJ4.main()
    # Prints out the children user name to test that they were correctly registered
    kids = PROJ4.getChildren()
    IO.inspect(kids)
  end
end
