defmodule PROJECT4 do
  @moduledoc """
  Documentation for PROJ4.
  """

  @doc """
  Hello world.

  ## Examples

      iex> PROJ4.hello()
      :world

  """
  def hello do
    :world
  end
end

# ask for login or register
action = Mix.Shell.IO.prompt("LogIn or Register?")

if(action == "Register" || "register") do
  user_name = Mix.Shell.IO.prompt("Please Create A UserName:")
  IO.puts("Your new username is #{user_name}")
end
