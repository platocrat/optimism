\connect ethdb;

CREATE TABLE IF NOT EXISTS ancient_headers (
  block_number INTEGER PRIMARY KEY,
  header BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS ancient_bodies (
  block_number INTEGER PRIMARY KEY,
  body BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS ancient_receipts (
  block_number INTEGER PRIMARY KEY,
  receipts BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS ancient_tds (
  block_number INTEGER PRIMARY KEY,
  td BYTEA NOT NULL
);



CREATE TABLE IF NOT EXISTS ancient_hashes (
  block_number INTEGER PRIMARY KEY,
  hash BYTEA NOT NULL
);

/* ROLLBACK SCRIPT
DROP TABLE ancient_headers;
DROP TABLE ancient_bodies;
DROP TABLE ancient_receipts;
DROP TABLE ancient_tds;
DROP TABLE ancient_hashes;
*/