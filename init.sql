-- Executed by the official image only when initializing an empty data volume.
-- Each application owns its database and applies its own versioned migrations.
CREATE DATABASE authguard;
CREATE DATABASE mmms;
CREATE DATABASE neola_subscriptions;
