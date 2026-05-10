# Monitorial Snowflake Data Governance

A **macro-only** [dbt](https://github.com/dbt-labs/dbt) package for applying Snowflake data governance features — tags, aggregation policies, projection policies, and row access policies — declaratively via model metadata and `post-hook`.

> require-dbt-version: [">=1.9.0", "<3.0.0"]

## Architecture

This package contains **no models, seeds, or sources**. It provides four public macros designed to run as `post-hook` on your dbt models. Each macro follows the same pattern:

1. **Read desired state** from the model's `meta` (or column-level `meta`) in your schema YAML
2. **Read current state** from Snowflake's `information_schema.policy_references()` or `tag_references_all_columns()` table functions
3. **Diff** desired vs. current state
4. **Apply changes** via `ALTER TABLE/VIEW` DDL — adding what's missing, removing what's no longer declared, and skipping what already matches

This makes the macros **idempotent**: re-running `dbt run` will not re-apply governance objects that are already correctly configured. This is important because Snowflake drops tags and policies when views are recreated, so the post-hooks re-apply them every run.

### Meta placement

All macros check for metadata in **two locations** (in order of precedence):

1. `columns.<name>.config.meta.<key>` — the config-level meta (used when meta is nested under `config:` in schema YAML)
2. `columns.<name>.meta.<key>` — the standard column-level meta

For model-level meta (aggregation policies, row access policies), the same precedence applies:

1. `model.config.meta.<key>`
2. `model.meta.<key>`

This dual-lookup ensures compatibility with different dbt YAML styles and versions.

### Supported materializations

All macros support: `table`, `view`, `incremental`, `snapshot`, `materialized_view`, and `immutable_table`.

Internally, `incremental`, `snapshot`, and `immutable_table` are treated as `table`; `materialized_view` is treated as `view`.

## Project Structure

```
dbt-snowflake-data-governance/
├── dbt_project.yml                          # Package definition (macro-only, no models)
├── macros/
│   ├── tags/
│   │   ├── apply_tags.sql                   # Public: post-hook entry point for tags
│   │   ├── set_column_tag_value.sql         # Internal: applies/removes a single tag
│   │   └── tags.yml                         # Macro documentation
│   ├── aggregation_policies/
│   │   ├── apply_aggregation_policies.sql   # Public: post-hook entry point for aggregation policies
│   │   ├── add_aggregation_policy.sql       # Internal: ALTER ... ADD AGGREGATION POLICY
│   │   ├── drop_aggregation_policy.sql      # Internal: ALTER ... DROP AGGREGATION POLICY
│   │   └── aggregation_policies.yml         # Macro documentation
│   ├── projection_policies/
│   │   ├── apply_projection_policies.sql    # Public: post-hook entry point for projection policies
│   │   ├── set_column_projection_policy.sql # Internal: ALTER ... SET PROJECTION POLICY
│   │   ├── unset_column_projection_policy.sql # Internal: ALTER ... UNSET PROJECTION POLICY
│   │   └── projection_policies.yml          # Macro documentation
│   ├── row_access_policies/
│   │   ├── apply_row_access_policy.sql      # Public: post-hook entry point for row access policies
│   │   ├── add_row_access_policy.sql        # Internal: ALTER ... ADD ROW ACCESS POLICY
│   │   ├── drop_row_access_policy.sql       # Internal: ALTER ... DROP ROW ACCESS POLICY
│   │   └── row_access_policies.yml          # Macro documentation
│   └── meta_data/
│       ├── model_column_meta_contains_items.sql  # Internal: checks if any column has given meta keys
│       ├── model_meta_contains_item.sql          # Internal: checks if model-level meta has a given key
│       └── meta_data.yml                         # Macro documentation
├── integration_tests/                       # Integration test dbt project
│   ├── dbt_project.yml
│   ├── packages.yml                         # References parent package via local: ../
│   ├── profiles.yml                         # Snowflake connection via env vars
│   ├── models/                              # Test models with governance post-hooks
│   └── tests/                               # Singular tests validating governance was applied
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                           # Lint + integration tests on PR (dbt 1.9.x, 1.10.x)
│   │   └── release.yml                      # Tag-triggered GitHub release
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── CHANGELOG.md
├── LICENSE                                  # Apache 2.0
└── README.md
```

## Installation

Add the following to your `packages.yml` file:

```yaml
packages:
  - git: https://github.com/monitorial-io/dbt-snowflake-data-governance.git
    revision: "1.0.0"
```

Then run `dbt deps` to install.

### Compatibility

| Runtime | Supported Versions |
| ------- | ------------------ |
| dbt-core | >= 1.9.0 |
| dbt Projects on Snowflake | dbt-core 1.9.x, 1.10.x |

This package is Snowflake-only and requires the `dbt-snowflake` adapter.

These macros are designed to be used in conjunction with the Monitorial Data Governance Native App. For more information, contact [datagovernance@monitorial.io](mailto:datagovernance@monitorial.io).

---

## Configuration

### Required dbt Variables

Define these in your `dbt_project.yml` under `vars:`:

| Variable | Description | Default Value |
| -------- | ----------- | ------------- |
| `data_governance_database` | The Snowflake database where tags and policies are stored | `MONITORIAL_DATA_GOVERNANCE` |
| `tag_store` | The schema within the governance database where tags are located | `TAGS` |
| `policy_store` | The schema within the governance database where policies are located | `POLICIES` |

```yaml
vars:
  data_governance_database: "MONITORIAL_DATA_GOVERNANCE"
  tag_store: "TAGS"
  policy_store: "POLICIES"
```

### Post-Hook Setup

The macros must be called as `post-hook` on your models. You can configure this globally in `dbt_project.yml` or per-model in schema YAML:

```yaml
# dbt_project.yml (applies to all models)
models:
  your_project:
    +post-hook:
      - "{{ dbt_monitorial_datagovernance.apply_tags(['pii_type', 'confidentiality_type', 'apply_masking_policy', 'semantic_type']) }}"
      - "{{ dbt_monitorial_datagovernance.apply_aggregation_policies() }}"
      - "{{ dbt_monitorial_datagovernance.apply_projection_policies() }}"
      - "{{ dbt_monitorial_datagovernance.apply_row_access_policy() }}"
```

### Required Snowflake Permissions

The executing role needs these grants depending on which macros you use:

```sql
-- For apply_tags
GRANT APPLY TAG ON ACCOUNT TO ROLE your_role;

-- For apply_aggregation_policies
GRANT APPLY AGGREGATION POLICY ON ACCOUNT TO ROLE your_role;

-- For apply_projection_policies
GRANT APPLY PROJECTION POLICY ON ACCOUNT TO ROLE your_role;

-- For apply_row_access_policy
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE your_role;
```

---

## Macro Reference

### Public Macros (used in post-hooks)

| Macro | Scope | Meta Location | Description |
| ----- | ----- | ------------- | ----------- |
| `apply_tags(tag_names)` | Column-level | `columns.meta.<tag_name>` | Applies/removes Snowflake tags based on column metadata |
| `apply_aggregation_policies()` | Model-level | `model.meta.aggregation_policies` | Applies/removes aggregation policies based on model metadata |
| `apply_projection_policies()` | Column-level | `columns.meta.projection_policy` | Applies/removes projection policies based on column metadata |
| `apply_row_access_policy()` | Model-level | `model.meta.row_access_policy` | Applies/removes row access policies based on model metadata |

### Internal Macros (called by public macros, `docs.show: false`)

| Macro | Signature | Description |
| ----- | --------- | ----------- |
| `set_column_tag_value` | `(materialization, model_schema, model_name, column_name, tag_name, desired_tag_value, existing_tags_for_table)` | Sets or unsets a single tag on one column |
| `add_aggregation_policy` | `(materialization, model_schema, model_name, policy_name, columns)` | `ALTER ... ADD AGGREGATION POLICY` with optional entity keys |
| `drop_aggregation_policy` | `(materialization, model_schema, model_name, policy_name, columns)` | `ALTER ... DROP AGGREGATION POLICY` |
| `set_column_projection_policy` | `(materialization, model_schema, model_name, column_name, projection_policy_name)` | `ALTER ... SET PROJECTION POLICY ... FORCE` |
| `unset_column_projection_policy` | `(materialization, model_schema, model_name, column_name)` | `ALTER ... UNSET PROJECTION POLICY` |
| `add_row_access_policy` | `(materialization, model_schema, model_name, policy_name, columns)` | `ALTER ... ADD ROW ACCESS POLICY ... ON (columns)` |
| `drop_row_access_policy` | `(materialization, model_schema, model_name, policy_name)` | `ALTER ... DROP ROW ACCESS POLICY` |
| `model_column_meta_contains_items` | `(item_names, model_node)` | Returns `True` if any column in the model has any of the given meta keys |
| `model_meta_contains_item` | `(item_name, model_node)` | Returns `True` if the model-level meta contains the given key |

---

## Tagging

### dbt_monitorial_datagovernance.apply_tags

Applies Snowflake tags to model columns based on column-level `meta` properties.

**Arguments:**
- `tag_names` (required): A list of meta key names to look for on columns. Only columns with matching meta keys will have tags applied.

**Behavior:**
- Queries existing tags via `information_schema.tag_references_all_columns()`
- For each column with a matching meta key: sets the tag if it doesn't exist or has a different value
- If the meta value is `"none"`: unsets (removes) the tag
- If the meta value is `"public"`: skips the tag (no action)
- If the tag already has the correct value: skips (no action, logged as `[IGNORE]`)

**Tag name mapping:** The macro automatically maps certain meta key names to Snowflake tag names:

| Meta Key in YAML | Snowflake Tag Name | Description |
| ---------------- | ------------------ | ----------- |
| `pii_type` | `pii_classification` | PII classification (direct or indirect individual identification) |
| `confidentiality_type` | `confidentiality_classification` | Data sensitivity classification |
| `confidential_type` | `confidentiality_classification` | Alternate spelling, same mapping |
| `apply_masking_policy` | `apply_masking_policy` | Whether to apply a masking policy (no rename) |
| `semantic_type` | `semantic_classification` | Semantic/domain classification |
| `default_mask` | `default_mask_value` | Which mask pattern to apply |

Any meta key not in the mapping table above is used as-is for the Snowflake tag name. You can add custom tags by including them in the `tag_names` list passed to the macro and defining the corresponding tags in your Snowflake account.

**Usage:**

```yaml
models:
  - name: your_model
    columns:
      - name: surname
        meta:
          pii_type: name                # Maps to tag PII_CLASSIFICATION = 'name'
          confidentiality_type: confidential  # Maps to tag CONFIDENTIALITY_CLASSIFICATION = 'confidential'
          apply_masking_policy: true     # Tag APPLY_MASKING_POLICY = 'true'
          semantic_type: name            # Maps to tag SEMANTIC_CLASSIFICATION = 'name'
          default_mask: "******"         # Maps to tag DEFAULT_MASK_VALUE = '******'
      - name: public_field
        meta:
          pii_type: none                # Removes the PII_CLASSIFICATION tag if it exists
```

---

## Aggregation Policies

### dbt_monitorial_datagovernance.apply_aggregation_policies

Applies Snowflake aggregation policies to models based on model-level `meta`.

**Arguments:** None (reads from `model.meta`).

**Behavior:**
- Queries existing policies via `information_schema.policy_references()` where `policy_kind = 'AGGREGATION_POLICY'`
- Compares existing policies with the `aggregation_policies` list in model meta
- **Adds** policies declared in meta but not on the table
- **Removes** policies on the table but not declared in meta
- **Replaces** policies where the entity keys have changed (drops then re-adds)
- **Skips** policies that already match (same name and entity keys)
- If `aggregation_policies` is present in meta but empty (`[]`): removes all existing aggregation policies
- If `aggregation_policies` is absent from meta entirely and policies exist on the table: removes all existing policies

**Usage:**

```yaml
models:
  - name: your_model
    meta:
      aggregation_policies:
        - name: your_aggregation_policy_name
          entity_keys:             # Optional: columns used as entity keys
            - first_name
            - surname
        - name: simple_policy      # No entity_keys = policy applied without ENTITY KEY clause
    columns:
      - name: first_name
        type: VARCHAR
      - name: surname
        type: VARCHAR
```

The `entity_keys` field is optional. When provided, the macro uses `ALTER ... ADD AGGREGATION POLICY <name> ENTITY KEY (<columns>)`. When omitted, it uses `ALTER ... ADD AGGREGATION POLICY <name>`.

---

## Projection Policies

### dbt_monitorial_datagovernance.apply_projection_policies

Applies Snowflake projection policies to individual columns based on column-level `meta`.

**Arguments:** None (reads from column `meta`).

**Behavior:**
- Queries existing policies via `information_schema.policy_references()` where `policy_kind = 'PROJECTION_POLICY'`
- For each column with a `projection_policy` meta key:
  - If the value is a policy name: applies it with `ALTER ... SET PROJECTION POLICY ... FORCE` (the `FORCE` keyword replaces any existing policy)
  - If the value is `"none"` and a policy exists: removes it with `ALTER ... UNSET PROJECTION POLICY`
  - If the value is `"none"` and no policy exists: no action

**Usage:**

```yaml
models:
  - name: your_model
    columns:
      - name: sensitive_column
        meta:
          projection_policy: your_projection_policy_name   # Applies this policy
      - name: declassified_column
        meta:
          projection_policy: none                          # Removes any existing policy
```

---

## Row Access Policies

### dbt_monitorial_datagovernance.apply_row_access_policy

Applies a Snowflake row access policy to a model based on model-level `meta`.

**Arguments:** None (reads from `model.meta`).

**Behavior:**
- Queries existing policies via `information_schema.policy_references()` where `policy_kind = 'ROW_ACCESS_POLICY'`
- Compares existing vs. desired policy (name + columns)
- **Adds** the policy if none exists
- **Replaces** (drop + add) if the policy name or columns differ
- **Skips** if the existing policy matches exactly
- If `row_access_policy` is present in meta but empty: removes any existing policy
- If `row_access_policy` is absent from meta and a policy exists: removes the existing policy

**Constraints:** Snowflake allows only **one** row access policy per table/view. If you need multiple policies, combine their logic into a single policy.

**Usage:**

```yaml
models:
  - name: your_model
    meta:
      row_access_policy:
        - name: your_row_access_policy_name
          columns:                    # Columns passed to the ON (...) clause
            - first_name
            - surname
    columns:
      - name: first_name
        type: VARCHAR
      - name: surname
        type: VARCHAR
```

---

## Contributing

1. Clone the repository
2. Create a feature branch from `main`
3. Make your changes
4. Run the integration tests (see below)
5. Submit a pull request

### Running Integration Tests

The integration test suite lives in `integration_tests/` and requires a Snowflake connection.

```bash
# Set environment variables for Snowflake connection (JWT auth)
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_user"
export SNOWFLAKE_ROLE="your_role"
export SNOWFLAKE_DATABASE="your_database"
export SNOWFLAKE_WAREHOUSE="your_warehouse"
export SNOWFLAKE_PRIVATE_KEY_PATH="/path/to/rsa_key.p8"
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE="your_passphrase"  # omit if key is unencrypted

# Install dependencies and run tests
cd integration_tests
dbt deps
dbt run
dbt test
```

The CI pipeline runs these tests automatically on pull requests against dbt-core 1.9.x and 1.10.x.