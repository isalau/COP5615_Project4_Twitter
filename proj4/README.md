# PROJ4

**TODO: Add description**

## **Register**

[x] main asks for log in or register<br>
[x] main asks for user-name<br>
[x] main asks for password<br>
[x] main starts dynamic supervisor<br>
[x] dynamic supervisor starts client<br>
[ ] security stuff for password storage<br>
[x] present options to user (delete account, send tweet, subscribe to user, re-tweet, query, check feed)

### **Tests**

**Single Test**<br>
<br>
[x] test that new client is in dynamic supervisor<br>
<br>

**Single Test (with children already present in dynamic supervisor)**<br>
[ ] test that new client is in dynamic supervisor<br>
[ ] test to register with already taken username<br>
[ ] test that all children are in the dynamic supervisor<br>
<br>

**Multiples Tests**<br>
[ ] do both tests above with 10, 100, 1000 children<br>
<br>

**Security Tests**<br>

## **Log In**

[x] main asks for log in or register<br>
[x] main asks for user-name<br>
[] main asks for password<br>
[] log in if correct<br>
[] after 3 attempts exponential lock out for attempts<br>

### **Tests**

[] Test for incorrect password<br>
[] Test for incorrect username<br>
[] Test that after 3 times starts exponential lock out<br>
[] Test that lock out is exponential

## **Delete Account**

### **Tests**

## **Send Tweet**

### **Tests**

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
