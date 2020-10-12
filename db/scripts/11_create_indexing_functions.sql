\connect indexing;


CREATE FUNCTION eth.graphql_subscription() returns TRIGGER as $$
declare
    table_name text = TG_ARGV[0];
    attribute text = TG_ARGV[1];
    id text;
begin
    execute 'select $1.' || quote_ident(attribute)
        using new
        into id;
    perform pg_notify('postgraphile:' || table_name,
                      json_build_object(
                              '__node__', json_build_array(
                              table_name,
                              id
                          )
                          )::text
        );
    return new;
end;
$$ language plpgsql;

CREATE TRIGGER header_cids_ai
    after INSERT ON eth.header_cids
    for each row
    execute procedure eth.graphql_subscription('header_cids', 'id');

CREATE TRIGGER receipt_cids_ai
    after INSERT ON eth.receipt_cids
    for each row
    execute procedure eth.graphql_subscription('receipt_cids', 'id');

CREATE TRIGGER state_accounts_ai
    after INSERT ON eth.state_accounts
    for each row
    execute procedure eth.graphql_subscription('state_accounts', 'id');

CREATE TRIGGER state_cids_ai
    after INSERT ON eth.state_cids
    for each row
    execute procedure eth.graphql_subscription('state_cids', 'id');

CREATE TRIGGER storage_cids_ai
    after INSERT ON eth.storage_cids
    for each row
    execute procedure eth.graphql_subscription('storage_cids', 'id');

CREATE TRIGGER transaction_cids_ai
    after INSERT ON eth.transaction_cids
    for each row
    execute procedure eth.graphql_subscription('transaction_cids', 'id');

CREATE TRIGGER uncle_cids_ai
    after INSERT ON eth.uncle_cids
    for each row
    execute procedure eth.graphql_subscription('uncle_cids', 'id');



CREATE OR REPLACE FUNCTION eth.header_weight(hash VARCHAR(66)) RETURNS BIGINT
AS $$
  WITH RECURSIVE validator AS (
          SELECT block_hash, parent_hash, block_number
          FROM eth.header_cids
          WHERE block_hash = hash
      UNION
          SELECT eth.header_cids.block_hash, eth.header_cids.parent_hash, eth.header_cids.block_number
          FROM eth.header_cids
          INNER JOIN validator
            ON eth.header_cids.parent_hash = validator.block_hash
            AND eth.header_cids.block_number = validator.block_number + 1
  )
  SELECT COUNT(*) FROM validator;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION eth.canonical_header(height BIGINT) RETURNS INT AS
$BODY$
DECLARE
  current_weight INT;
  heaviest_weight INT DEFAULT 0;
  heaviest_id INT;
  r eth.header_cids%ROWTYPE;
BEGIN
  FOR r IN SELECT * FROM eth.header_cids
  WHERE block_number = height
  LOOP
    SELECT INTO current_weight * FROM header_weight(r.block_hash);
    IF current_weight > heaviest_weight THEN
        heaviest_weight := current_weight;
        heaviest_id := r.id;
    END IF;
  END LOOP;
  RETURN heaviest_id;
END
$BODY$
LANGUAGE 'plpgsql';

/* ROLLBACK SCRIPT
DROP TRIGGER uncle_cids_ai ON eth.uncle_cids;
DROP TRIGGER transaction_cids_ai ON eth.transaction_cids;
DROP TRIGGER storage_cids_ai ON eth.storage_cids;
DROP TRIGGER state_cids_ai ON eth.state_cids;
DROP TRIGGER state_accounts_ai ON eth.state_accounts;
DROP TRIGGER receipt_cids_ai ON eth.receipt_cids;
DROP TRIGGER header_cids_ai ON eth.header_cids;
DROP FUNCTION eth.graphql_subscription();
DROP FUNCTION eth.header_weight;
DROP FUNCTION eth.canonical_header;
*/