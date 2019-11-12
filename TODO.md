# TODO

- Rsync hardlinks
- user and group in backup
- Output to console instead of file?
- Config files to arguments?
- Docker compose;

## Client

- No need to configure private key path;
- No need to configure BACKUP_SOURCE_DIR. Should be `/source/`
- BACKUP_NAME as parameter;
- Make sure private key has correct permissions (otherwise ssh will not load it);
- generate KnownHost and remove the `-o StrictHostKeyChecking=false` ssh option.
