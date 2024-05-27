import gleam/dict
import gleam/dynamic
import gleam/option.{None, Some}
import gleeunit/should
import glow_auth/access_token.{AccessToken}

pub fn token() {
  access_token.new("123")
}

pub fn new_test() {
  let token = token()

  token.access_token
  |> should.equal("123")

  token.token_type
  |> should.equal("Bearer")
}

pub fn expiry_test() {
  token()
  |> access_token.has_an_expiry
  |> should.be_false

  token()
  |> access_token.is_expired
  |> should.be_false

  let now = access_token.time_now()
  let expired_token = AccessToken(..token(), expires_at: Some(now - 1))

  expired_token
  |> access_token.has_an_expiry
  |> should.be_true

  expired_token
  |> access_token.is_expired
  |> should.equal(False)
}

pub fn expired_test() {
  let unexpired_token = AccessToken(..token(), expires_at: Some(120))
  unexpired_token
  |> access_token.is_expired
  |> should.be_false
}

pub fn decoder_test() {
  [#("access_token", "xyz"), #("token_type", "Bearer")]
  |> dict.from_list
  |> dynamic.from()
  |> access_token.decoder()
  |> should.equal(Ok(access_token.new("xyz")))
}

pub fn decoder_with_expires_test() {
  [
    #("access_token", dynamic.from("xyz")),
    #("token_type", dynamic.from("Bearer")),
    #("expires_in", dynamic.from(120)),
  ]
  |> dict.from_list
  |> dynamic.from()
  |> access_token.decoder()
  |> should.equal(
    Ok(AccessToken(
      "xyz",
      "Bearer",
      None,
      Some(120 + access_token.time_now()),
      None,
    )),
  )
}

pub fn decoder_with_expires_and_refresh_token_test() {
  [
    #("access_token", dynamic.from("xyz")),
    #("token_type", dynamic.from("Bearer")),
    #("expires_in", dynamic.from(120)),
    #("refresh_token", dynamic.from("abc")),
  ]
  |> dict.from_list
  |> dynamic.from()
  |> access_token.decoder()
  |> should.equal(
    Ok(AccessToken(
      "xyz",
      "Bearer",
      Some("abc"),
      Some(120 + access_token.time_now()),
      None,
    )),
  )
}
