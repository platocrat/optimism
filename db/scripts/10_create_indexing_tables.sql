\connect indexing;


CREATE TABLE IF NOT EXISTS blocks (
  key TEXT UNIQUE NOT NULL,
  data BYTEA NOT NULL
);

CREATE TABLE nodes (
  id            SERIAL PRIMARY KEY,
  client_name   VARCHAR,
  genesis_block VARCHAR(66),
  network_id    VARCHAR,
  node_id       VARCHAR(128),
  chain_id      INTEGER,
  UNIQUE (genesis_block, network_id, node_id, chain_id);
);

COMMENT ON TABLE public.nodes IS E'@name NodeInfo';
COMMENT ON COLUMN public.nodes.node_id IS E'@name ChainNodeID';


CREATE SCHEMA eth;


CREATE TABLE eth.header_cids (
  id                    SERIAL PRIMARY KEY,
  block_number          INTEGER NOT NULL,
  block_hash            VARCHAR(66) NOT NULL,
  parent_hash           VARCHAR(66) NOT NULL,
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  td                    NUMERIC NOT NULL,
  node_id               INTEGER NOT NULL REFERENCES nodes (id) ON DELETE CASCADE,
  reward                NUMERIC NOT NULL,
  state_root            VARCHAR(66) NOT NULL,
  tx_root               VARCHAR(66) NOT NULL,
  receipt_root          VARCHAR(66) NOT NULL,
  uncle_root            VARCHAR(66) NOT NULL,
  bloom                 BYTEA NOT NULL,
  timestamp             NUMERIC NOT NULL,
  times_validated       INTEGER NOT NULL DEFAULT 1,
  UNIQUE (block_number, block_hash)
);

COMMENT ON TABLE eth.header_cids IS E'@name EthHeaderCids';
COMMENT ON COLUMN eth.header_cids.node_id IS E'@name EthNodeID';

CREATE INDEX block_number_index ON eth.header_cids USING brin (block_number);
CREATE INDEX block_hash_index ON eth.header_cids USING btree (block_hash);
CREATE INDEX header_cid_index ON eth.header_cids USING btree (cid);
CREATE INDEX header_mh_index ON eth.header_cids USING btree (mh_key);
CREATE INDEX state_root_index ON eth.header_cids USING btree (state_root);
CREATE INDEX timestamp_index ON eth.header_cids USING brin (timestamp);



CREATE TABLE eth.uncle_cids (
  id                    BIGSERIAL PRIMARY KEY,
  header_id             INTEGER NOT NULL REFERENCES eth.header_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  block_hash            VARCHAR(66) NOT NULL,
  parent_hash           VARCHAR(66) NOT NULL,
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  reward                NUMERIC NOT NULL,
  UNIQUE (header_id, block_hash)
);

CREATE TABLE eth.transaction_cids (
  id                    BIGSERIAL PRIMARY KEY,
  header_id             INTEGER NOT NULL REFERENCES eth.header_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  tx_hash               VARCHAR(66) NOT NULL,
  index                 INTEGER NOT NULL,
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  dst                   VARCHAR(66) NOT NULL,
  src                   VARCHAR(66) NOT NULL,
  deployment            BOOL NOT NULL,
  tx_data               BYTEA,
  l1_rollup_tx_id       BIGINT,
  l1_msg_sender         VARCHAR(66),
  signature_hash_type   SMALLINT,
  queue_origin          BIGINT,
  UNIQUE (header_id, tx_hash)
);

COMMENT ON TABLE eth.transaction_cids IS E'@name EthTransactionCids';

CREATE INDEX tx_header_id_index ON eth.transaction_cids USING btree (header_id);
CREATE INDEX tx_hash_index ON eth.transaction_cids USING btree (tx_hash);
CREATE INDEX tx_cid_index ON eth.transaction_cids USING btree (cid);
CREATE INDEX tx_mh_index ON eth.transaction_cids USING btree (mh_key);
CREATE INDEX tx_dst_index ON eth.transaction_cids USING btree (dst);
CREATE INDEX tx_src_index ON eth.transaction_cids USING btree (src);
CREATE INDEX tx_data_index ON eth.transaction_cids USING btree (tx_data);
CREATE INDEX tx_l1_rollup_tx_id ON eth.transaction_cids USING btree (l1_rollup_tx_id);
CREATE INDEX tx_l1_msg_sender_index ON eth.transaction_cids USING btree (l1_msg_sender);



CREATE TABLE eth.receipt_cids (
  id                    BIGSERIAL PRIMARY KEY,
  tx_id                 BIGINT NOT NULL REFERENCES eth.transaction_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  contract              VARCHAR(66),
  contract_hash         VARCHAR(66),
  topic0s               VARCHAR(66)[],
  topic1s               VARCHAR(66)[],
  topic2s               VARCHAR(66)[],
  topic3s               VARCHAR(66)[],
  log_contracts         VARCHAR(66)[],
  UNIQUE (tx_id)
);

CREATE INDEX rct_tx_id_index ON eth.receipt_cids USING btree (tx_id);
CREATE INDEX rct_cid_index ON eth.receipt_cids USING btree (cid);
CREATE INDEX rct_mh_index ON eth.receipt_cids USING btree (mh_key);
CREATE INDEX rct_contract_index ON eth.receipt_cids USING btree (contract);
CREATE INDEX rct_contract_hash_index ON eth.receipt_cids USING btree (contract_hash);
CREATE INDEX rct_topic0_index ON eth.receipt_cids USING gin (topic0s);
CREATE INDEX rct_topic1_index ON eth.receipt_cids USING gin (topic1s);
CREATE INDEX rct_topic2_index ON eth.receipt_cids USING gin (topic2s);
CREATE INDEX rct_topic3_index ON eth.receipt_cids USING gin (topic3s);
CREATE INDEX rct_log_contract_index ON eth.receipt_cids USING gin (log_contracts);



CREATE TABLE eth.state_cids (
  id                    BIGSERIAL PRIMARY KEY,
  header_id             INTEGER NOT NULL REFERENCES eth.header_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  state_leaf_key        VARCHAR(66),
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  state_path            BYTEA,
  node_type             INTEGER NOT NULL,
  diff                  BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (header_id, state_path)
);

CREATE INDEX state_header_id_index ON eth.state_cids USING btree (header_id);
CREATE INDEX state_leaf_key_index ON eth.state_cids USING btree (state_leaf_key);
CREATE INDEX state_cid_index ON eth.state_cids USING btree (cid);
CREATE INDEX state_mh_index ON eth.state_cids USING btree (mh_key);
CREATE INDEX state_path_index ON eth.state_cids USING btree (state_path);



CREATE TABLE eth.storage_cids (
  id                    BIGSERIAL PRIMARY KEY,
  state_id              BIGINT NOT NULL REFERENCES eth.state_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  storage_leaf_key      VARCHAR(66),
  cid                   TEXT NOT NULL,
  mh_key                TEXT NOT NULL REFERENCES public.blocks (key) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  storage_path          BYTEA,
  node_type             SMALLINT NOT NULL,
  diff                  BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (state_id, storage_path)
);

CREATE INDEX storage_state_id_index ON eth.storage_cids USING btree (state_id);
CREATE INDEX storage_leaf_key_index ON eth.storage_cids USING btree (storage_leaf_key);
CREATE INDEX storage_cid_index ON eth.storage_cids USING btree (cid);
CREATE INDEX storage_mh_index ON eth.storage_cids USING btree (mh_key);
CREATE INDEX storage_path_index ON eth.storage_cids USING btree (storage_path);



CREATE TABLE eth.state_accounts (
  id                    BIGSERIAL PRIMARY KEY,
  state_id              BIGINT NOT NULL REFERENCES eth.state_cids (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  balance               NUMERIC NOT NULL,
  nonce                 INTEGER NOT NULL,
  code_hash             BYTEA NOT NULL,
  storage_root          VARCHAR(66) NOT NULL,
  UNIQUE (state_id)
);

CREATE INDEX account_state_id_index ON eth.state_accounts USING btree (state_id);
CREATE INDEX storage_root_index ON eth.state_accounts USING btree (storage_root);

/* ROLLBACK SCRIPT
DROP SCHEMA eth;
DROP TABLE blocks;
DROP TABLE nodes;
DROP TABLE eth.header_cids;
DROP INDEX eth.timestamp_index;
DROP INDEX eth.state_root_index;
DROP INDEX eth.header_mh_index;
DROP INDEX eth.header_cid_index;
DROP INDEX eth.block_hash_index;
DROP INDEX eth.block_number_index;
DROP TABLE eth.uncle_cids;
DROP TABLE eth.transaction_cids;
DROP INDEX eth.tx_data_index;
DROP INDEX eth.tx_src_index;
DROP INDEX eth.tx_dst_index;
DROP INDEX eth.tx_mh_index;
DROP INDEX eth.tx_cid_index;
DROP INDEX eth.tx_hash_index;
DROP INDEX eth.tx_header_id_index;
DROP INDEX eth.tx_l1_rollup_tx_id;
DROP INDEX eth.tx_l1_msg_sender_index;
DROP TABLE eth.receipt_cids;
DROP INDEX eth.rct_log_contract_index;
DROP INDEX eth.rct_topic3_index;
DROP INDEX eth.rct_topic2_index;
DROP INDEX eth.rct_topic1_index;
DROP INDEX eth.rct_topic0_index;
DROP INDEX eth.rct_contract_hash_index;
DROP INDEX eth.rct_contract_index;
DROP INDEX eth.rct_mh_index;
DROP INDEX eth.rct_cid_index;
DROP INDEX eth.rct_tx_id_index;
DROP TABLE eth.state_cids;
DROP INDEX eth.state_path_index;
DROP INDEX eth.state_mh_index;
DROP INDEX eth.state_cid_index;
DROP INDEX eth.state_leaf_key_index;
DROP INDEX eth.state_header_id_index;
DROP TABLE eth.storage_cids;
DROP INDEX eth.storage_path_index;
DROP INDEX eth.storage_mh_index;
DROP INDEX eth.storage_cid_index;
DROP INDEX eth.storage_leaf_key_index;
DROP INDEX eth.storage_state_id_index;
DROP TABLE eth.state_accounts;
DROP INDEX eth.storage_root_index;
DROP INDEX eth.account_state_id_index;
*/