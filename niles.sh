#!/bin/sh

# exit if pm2 doesn't exist
if ! type "pm2" > /dev/null; then
  echo "pm2 not found. Please install pm2."
  exit 1
fi

__help="
Usage:
	./niles.sh CMD ARG

Commands:
	setup - setup a new base instance
	update - update the base instance
	generate <name> - generate a new instance
  backup - backup all instances
Arguments:
	instance name, if any"

_base_secrets="{
  \"bot_token\": \"\",
  \"service_acct_keypath\": \"$(pwd)/configs/\",
  \"oauth_acct_keypath\": \"$(pwd)/configs/\",
  \"calendar_update_interval\": 300000,
  \"admins\": [],
  \"log_discord_channel\": \"\"
}"

update () {
  cd niles-base || exit
  git pull origin main
  echo "Base instance update. Please restart all instances."
}

setup () {
  [ -d "niles-base" ] && { echo "Base instance already exists. Please run update instead."; exit 1; }
  # create new shared directory for configs
  mkdir -p configs stores backups
  # set base config
  echo "$_base_secrets" > configs/secrets.json.example
  # clone niles from github
  git clone https://github.com/niles-bot/niles.git niles-base
  cd niles-base || exit
  # install dependencies
  npm install
  npm prune --production
  # remove config and stores
  echo "Base instance created. Please edit configs/secrets.json.example"
}

generate () {
  NAME="niles-$1"
  if [ -z "$1" ]; then echo "Usage: niles.sh generate <instance name>"; exit 1; fi
  # make stores
  mkdir -p "stores/$1"
  # create config file
  cp "configs/secrets.json.example" "configs/secrets-$1.json"

  # finish setup
  echo "Created $NAME"
  # start and immediately stop with pm2
  (cd "niles-base" && PM2_SILENT=true pm2 start "index.js" --name "$NAME")
  STORE_PATH="$(pwd)/stores/$1" SECRETS_PATH="$(pwd)/configs/secrets-$1.json" PM2_SILENT=true pm2 restart "$NAME" --update-env
  PM2_SILENT=true pm2 stop "$NAME"
  echo "Added $NAME to pm2"
  echo "Please edit configs/secrets-$1.json"
}

backup () {
  # get date
  date=$(date +%F)
  deleteDate=$(date +%F --date '-7 days')
  rm "backups/$deleteDate"
  tar --zstd -cf "backups/$date.tar.zst" stores/ configs/
}

# run commands
cmd=$1; shift
case "$cmd" in
	setup)
		setup
    ;;
	generate)
		generate "$@"
		;;
  update)
    update
    ;;
  backup)
    backup
    ;;
	*)
		echo "$__help"
		;;
esac