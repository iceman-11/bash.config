# Zoxide
# ------

if type zoxide > /dev/null 2>&1; then
  eval "$(zoxide init bash)"
else
  alias z='cd'
fi
