json.error do
  json.message t('.disabled_account', user: @account.name)
end
