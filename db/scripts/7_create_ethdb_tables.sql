\connect ethdb;


CREATE UNLOGGED TABLE IF NOT EXISTS kvstore (
  eth_key BYTEA PRIMARY KEY,
  eth_data BYTEA NOT NULL,
  prefix BYTEA
);

CREATE INDEX prefix_index ON kvstore USING btree (prefix);



CREATE TABLE IF NOT EXISTS headers (
  header_key BYTEA PRIMARY KEY,
  header BYTEA NOT NULL,
  height BIGINT NOT NULL
);

CREATE INDEX header_height_index ON headers USING brin (height);



CREATE TABLE IF NOT EXISTS hashes (
  hash_key BYTEA PRIMARY KEY,
  hash BYTEA NOT NULL,
  header_fk BYTEA NOT NULL REFERENCES headers (header_key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX hashes_header_fk ON hashes USING btree (header_fk);



CREATE TABLE IF NOT EXISTS bodies (
  body_key BYTEA PRIMARY KEY,
  body BYTEA NOT NULL,
  header_fk BYTEA NOT NULL REFERENCES headers (header_key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX bodies_header_fk ON bodies USING btree (header_fk);



CREATE TABLE IF NOT EXISTS receipts (
  receipt_key BYTEA PRIMARY KEY,
  receipts BYTEA NOT NULL,
  header_fk BYTEA NOT NULL REFERENCES headers (header_key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX receipts_header_fk ON receipts USING btree (header_fk);



CREATE TABLE IF NOT EXISTS tds (
  td_key BYTEA PRIMARY KEY,
  td BYTEA NOT NULL,
  header_fk BYTEA NOT NULL REFERENCES headers (header_key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX tds_header_fk ON tds USING btree (header_fk);



CREATE TABLE IF NOT EXISTS bloom_bits (
  bb_key BYTEA PRIMARY KEY,
  bits BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS tx_lookups (
  lookup_key BYTEA PRIMARY KEY,
  lookup BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS preimages (
  preimage_key BYTEA PRIMARY KEY,
  preimage BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS numbers (
  number_key BYTEA PRIMARY KEY,
  number BYTEA NOT NULL,
  header_fk BYTEA NOT NULL REFERENCES headers (header_key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX numbers_header_fk ON numbers USING btree (header_fk);



CREATE TABLE IF NOT EXISTS configs (
  config_key BYTEA PRIMARY KEY,
  config BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS bloom_indexes (
  bbi_key BYTEA PRIMARY KEY,
  index BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS tx_meta (
  meta_key BYTEA PRIMARY KEY,
  meta BYTEA NOT NULL
);

/* ROLLBACK SCRIPT
DROP TABLE kvstore;
DROP INDEX prefix_index;
DROP TABLE headers;
DROP INDEX header_height_index;
DROP TABLE header_hashes;
DROP INDEX hashes_header_fk;
DROP TABLE block_bodies;
DROP INDEX bodies_header_fk;
DROP TABLE receipts;
DROP INDEX receipts_header_fk;
DROP TABLE tds;
DROP INDEX tds_header_fk;
DROP TABLE bloom_bits;
DROP TABLE tx_lookups;
DROP TABLE preimages;
DROP TABLE numbers;
DROP INDEX numbers_header_fk;
DROP TABLE configs;
DROP TABLE bloom_indexes;
DROP TABLE tx_meta;
*/