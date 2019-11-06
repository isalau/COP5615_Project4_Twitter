defmodule PROJ4Test do
  use ExUnit.Case
  doctest PROJ4

  test "register user" do
    PROJ4.main()
    kids = PROJ4.getChildren()
    IO.inspect(kids)
  end
end
