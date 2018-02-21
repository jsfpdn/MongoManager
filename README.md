# MongoManage
This is a repository for a secondary school-leaving work regarding MongoDB and scripts for managing instances and data.

Params: mode, replicas, shards, port, logpath, datapath

## TODOS:
### Running Beta:
* get command line arguments
* logs and data directories
* create list of shards
* running mongos over shards
* create replica sets of shards
* create PID file to check for already running instances (get all running, close all running...)

### V1:
* first import/export scripts
* backups with cron, shutting down least used replicas etc.
* create HOW-TOs in markdown

### Bonus:
* HTML or some sort of GUI or interactive CLI
* CLI or HTML overview of all running instances, data etc.
* check if there's enough space for creating replicas and sharding beforehand
* remember the last start-up (save the configuration to some file after successful start and use it again if asked for a restart or shorthand start)