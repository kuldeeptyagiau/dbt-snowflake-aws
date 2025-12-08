select
tx.hash_key,
tx.block_number,
tx.block_timestamp,
tx.is_coinbase,
f.value:address::STRING as output_address,
f.value:value::FLOAT as output_value

from {{ ref('stg_dbt_first')}} tx,

LATERAL FLATTEN(input => outputs) f

WHERE f.value:address is not null