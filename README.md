# Niles-es
Running multiple instances of Niles while reusing as much as possible with pm2

-----

because of the single calendar/guild limit, multiple people run multiple instances of Niles on the same VPS.

Unfortunately there is no actual multi-cal support upstream, but the files can be shared between processes.

The main things that need to be changed are /config/secrets.json and /stores for each bot, so we can just pass in the values to each path and run them that way

all configs and stores are relatively centeralized, allowing for easy backups.