# PROJ4

**TODO: Add description**

## **Register**

-main asks for log in or register -main asks for user-name -main asks for password main starts dynamic supervisor dynamic supervisor starts client security stuff for password storage present options to user (delete account, send tweet, subscribe to user, re-tweet, query, check feed)

### **Tests**

Single Test test that new client is in dynamic supervisor Single Test (with children already present in dynamic supervisor) test that new client is in dynamic supervisor test to register with already taken username test that all children are in the dynamic supervisor Multiples Tests do both tests above with 10, 100, 1000 children Security Tests ???

## **Log In**

main asks for log in or register main asks for user-name main asks for password log in if correct after 3 attempts exponential lock out for attempts

### **Tests**

Test for incorrect password Test for incorrect username Test that after 3 times starts exponential lock out Test that lock out is exponential

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
