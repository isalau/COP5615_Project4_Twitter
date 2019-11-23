# PROJ4

**TODO: Add description**

## **1a) Register**

[x] main asks for log in or register<br>
[x] main asks for user-name<br>
[x] main asks for password<br>
[x] main starts dynamic supervisor<br>
[x] dynamic supervisor starts client<br>
[ ] security stuff for password storage<br>
[x] present options to user (delete account, send tweet, subscribe to user, re-tweet, query, check feed)

### **Tests**

**Single Test**<br><br>
[x] test that new client is in dynamic supervisor<br><br>

**Single Test (with children already present in dynamic supervisor)**<br>
[ ] test that new client is in dynamic supervisor<br>
[ ] test to register with already taken username<br>
[ ] test that all children are in the dynamic supervisor<br><br>

**Multiples Tests**<br>
[ ] do both tests above with 10, 100, 1000 children<br><br>

**Security Tests**<br>

## **1b) Log In**

[x] main asks for log in or register<br>
[x] main asks for user-name<br>
[x] main asks for password<br>
[x] log in if correct<br>
[] after 3 attempts exponential lock out for attempts<br>

### **Tests**

[] Test for incorrect password<br>
[] Test for incorrect username<br>
[] Test that after 3 times starts exponential lock out<br>
[] Test that lock out is exponential

## **1c) Delete Account**

--> user selected delete account from menu<br>
[x] ask user if they are sure they want to delete the account<br>
[x] if no; show main options again<br>
[x] if yes; ask user for password<br>
[x] passed password check: ask again if they want to delete<br>
[x] if yes; terminate account from the supervisor<br>
BUG: Not returning from terminate<br>
[] if yes; exit application<br>
[x] if no; go back to main menu<br>
[] after failed password 3 attempts they have to wait 24 hours until they can try to delete again<br>

### **Tests**

[] Test user is gone from dynamic supervisor<br>
[] Test user cannot log in<br>
[] Test other users cannot @ them<br>
[] Test users' tweets are gone<br>

## **2) Send Tweet**

--> user selected send tweet from menu<br>
[x] first ask what they to want to tweet<br>
[] do character limit check<br>
[x] save tweet to state<br>
[x] respond tweet successful<br>
[x] go back to main menu<br>

### **Tests**
[] Test tweet is saved to users tweet list<br>
[] Test subscribers see users tweet in feed<br>
[] Test having 10 clients tweet at same time<br>
[] Test having 100 clients tweet at same time<br>
[] Test having 1000 clients tweet at same time<br>

## **3) Subscribe**

--> user selected subscribe from menu<br>
[x] first ask who you want to subscribe to<br>
[x] look that person up in supervisor<br>
[x] if they exists check not in your subscription list<br>
[x] if they exists add to subscription list<br>
[x] if they exists say you are subscribed<br>
[x] if they add user to subscribed user's followers list<br>
[x] if not say that person is not a current user<br>

### **Tests**
[] Test your subscribe lists updates and you are on others followers list<br>
[] Test one user getting 10 new subscribers at same time<br>
[] Test one user getting 100 new subscribers at same time<br>
[] Test one user getting 1000 new subscribers at same time<br>
[] Test one user subscribing to 10 others quickly<br>
[] Test one user subscribing to 100 others quickly<br>
[] Test one user subscribing to 1000 others quickly<br>

## **4) Re-Tweet**
[x]Show user's feed with numbers <br>
[x]Ask which one they would like to retweet<br>
[x]Add re-tweet to own tweets<br>

### **Tests**
[] Test tweet is saved to users retweet list<br>
[] Test subscribers see users retweet in feed<br>
[] Test having 10 clients retweet at same time<br>
[] Test having 100 clients retweet at same time<br>
[] Test having 1000 clients retweet at same time<br>

## **5) Query**

[x]Allow querying tweets subscribed to<br>
[x]tweets with specific hashtags<br>
[x]tweets in which the user is mentioned (my mentions)<br>

### **Tests**
[] Test query for something that exists<br>
[] Test query for something that does not exists<br>
[] Test having 10 clients query at same time<br>
[] Test having 100 clients query at same time<br>
[] Test having 1000 clients query at same time<br>

## **6) Deliver Tweet Immediately**

--> user selected feed from menu<br>
[x]for every subscriber in followers usersLists<br>
[x]send tweet message from engine<br>
[x]save tweet into feed<br>
[x]show tweets on feed<br>

### **Tests**
[] Test tweet shows up one feed immediately<br>
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `proj4` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:proj4, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at <https://hexdocs.pm/proj4>.
