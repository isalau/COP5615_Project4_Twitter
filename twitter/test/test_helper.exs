ExUnit.start()
# Start the supervisor
DySupervisor.start_link(1)
# Start the engine
tweets = []
followers = []
subscribed = []
feed = []
{:ok, _pid} = Engine.start_link([followers, subscribed, feed, tweets, Engine])

# make three users
Register.reg("isabel", "p")
Register.reg("anshika", "p")
Register.reg("dobra", "p")

# subscribe them to each other
# pid_sender1 = :"#{"isabel"}"
# GenServer.call(pid_sender1, {:subscribe, "anshika"})

pid_sender2 = :"#{"anshika"}"
GenServer.call(pid_sender2, {:subscribe, "isabel"})

pid_sender2 = :"#{"dobra"}"
GenServer.call(pid_sender2, {:subscribe, "anshika"})

# make x number of users
# Register.makeKids(100_000)
