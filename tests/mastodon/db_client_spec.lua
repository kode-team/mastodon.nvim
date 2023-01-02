local db_client = require("mastodon.db_client")

describe("setup", function()
  before_each(function()
    db_client:bootstrap()
    db_client:reset_database()
  end)

  it("Added accounts can be displayed in select view", function()
    db_client:add_account({
      username = "hello",
      access_token = "hello",
      instance_url = "hello",
      description = "world",
      is_active = false,
    })
    db_client:add_account({
      username = "hello",
      access_token = "hello",
      instance_url = "hello",
      description = "world",
      is_active = false,
    })
    db_client:add_account({
      username = "hello",
      access_token = "hello",
      instance_url = "hello",
      description = "world",
      is_active = false,
    })

    local accounts = db_client:get_all_accounts()
    assert(table.getn(accounts) == 3)
  end)
end)
