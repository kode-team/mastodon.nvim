local vim = vim

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error("This plugin requires sqlite.lua (https://github.com/kkharji/sqlite.lua) " .. tostring(sqlite))
end

local db_table = {}
db_table.mastodon_accounts = "mastodon_accounts"


local M = {}


function M:new()
  local o = {}
  setmetatable(o, self)
  self.db = nil
  return o
end

function M:reset_database()
  self:bootstrap(nil)
  return self.db:with_open(function(db)
    return db:delete("mastodon_accounts")
  end)
end

function M:bootstrap(db_root)
  if self.db then return end

  local project_env = os.getenv("PROJECT_ENV") or "production"
  db_root = db_root or vim.fn.stdpath('data')
  local db_name = 'mastodon_accounts'
  if project_env == 'test' then
    db_name = db_name .. '_test'
  end

  local db_filename = db_root .. "/" .. db_name .. ".sqlite3"
  self.db = sqlite:open(db_filename)

  if not self.db then
    vim.notify("Mastodon.nvim: error in opening DB", vim.log.levels.ERROR)
    return
  end

  local first_run = false

  if not self.db:exists(db_table.mastodon_accounts) then
    first_run = true
    self.db:create(db_table.mastodon_accounts, {
      id           = {"INTEGER", "PRIMARY", "KEY"},
      instance_url = {"TEXT"},
      access_token = {"TEXT"},
      username     = {"TEXT"},
      description  = {"TEXT"},
      is_active    = {"BOOLEAN"},
    })
  end

  self.db:close()
  return first_run
end

function M:get_all_accounts()
  self:bootstrap(nil)
  return self.db:with_open(function(db)
    return db:select("mastodon_accounts", {})
  end)
end

function M:get_active_account()
  return self:select_account({ is_active = true })
end

function M:set_active_account(params)
  self:bootstrap(nil)
  return self.db:with_open(function(db)
    db:update("mastodon_accounts", {
      set = { is_active = false}
    })
    db:update("mastodon_accounts", {
      where = params,
      set = { is_active = true }
    })
    return true
  end)
end

function M:add_account(params)
  self:bootstrap(nil)
  return self.db:with_open(function(db)
    return db:insert("mastodon_accounts", params)
  end)
end

function M:select_account(params)
  self:bootstrap(nil)
  return self.db:with_open(function(db)
    return db:select("mastodon_accounts", params)
  end)
end


return M
