EXTENSION = msmov
DATA = msmov--0.9.2.sql
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

