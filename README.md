
# Monitorial Snowflake Data Governance

This [dbt](https://github.com/dbt-labs/dbt) package contains macros that can be (re)used across dbt projects.

> require-dbt-version: [">=1.9.0", "<2.0.0"]
----

## Installation Instructions

Add the following to your packages.yml file

```
  - git: https://github.com/monitorial-io/dbt-snowflake-data-governance.git
    revision: "0.1.0"
```

These macros are designed to be used in conjunction with the Monitorial Data Governance Native App. The Monitorial Data Governance Native App is a Snowflake application that provides a set of tools and features to help organizations manage their data governance processes more effectively.
For more information on the Monitorial Data Governance Native App, please contact us at [datagovernance@monitorial.io](mailto:datagovernance@monitorial.io)

----

## Contents

**tags**

- `apply_tags`

**policies**

- `apply_aggregation_policies`
- `apply_projection_policy`
- `apply_row_access_policy`

---

## dbt_project.yml changes
The macros must be called as part of the models post-hook for example:

```yaml
post-hook:
    - "{{ dbt_monitorial_datagovernance.apply_tags(['pii_type', 'confidentiality_type', 'apply_masking_policy', 'semantic_type']) }}"
    - "{{ dbt_monitorial_datagovernance.apply_aggregation_policies() }}"
    - "{{ dbt_monitorial_datagovernance.apply_projection_policies() }}"
    - "{{ dbt_monitorial_datagovernance.apply_row_access_policy() }}"
```

The variables must be defined in your dbt_project.yml:

```yaml
  ###############################################
  ### dbt_monitorial_datagovernance variables ###
  ###############################################
  #The database name where tags and masking policies live
  data_governance_database: "MONITORIAL_DATA_GOVERNANCE"
  #The schema name where tags are located
  tag_store: "TAGS"
  policy_store: "POLICIES"
```


### Tagging

#### dbt_monitorial_datagovernance.apply_meta_as_tags

This macro applies specific model meta properties as Snowflake tags during `post-hook`. This allows you to apply Snowflake tags as part of your dbt project. Tags should be defined outside dbt and stored in a separate database.
When dbt re-runs and re-creates the views the tags will be re-applied as they will disappear from the deployed view.

##### Permissions

The users role running the macro must have the `apply tag` permissions on the account. For example if you have a `developers` role:
```sql
grant apply tag on account to role developers;
```

##### Arguments

- tag_names(required): A list of tag names to apply to the model if they exist as part of the metadata. These should be defined in your Snowflake account.

##### Usage

```yaml
models:
  - name: your_view_name
    columns:
      - name: surname
        description: surname
        type: VARCHAR
        data_type: VARCHAR
        meta:
          pii_type: name
          confidentiality_type: name
          apply_masking_policy: true
          semantic_type: name
          default_mask: "******"
```


##### Defined Tags
The following tags are defined by the Monitorial Data Governance Native App and should be defined in your Snowflake account and are catered for in the macro. The tags are defined in the `MONITORIAL_DATA_GOVERNANCE` database and `TAGS` schema by default.

| meta_data_name         | tag_name                         | description                                                                                                                                                                     |
| ---------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pii_type`             | `pii_classification`             | PII classification is the process of categorizing data that could potentially identify an individual, whether directly or indirectly                                            |
| `confidentiality_type` | `confidentiality_classification` | Confidentiality classification is the process of categorizing data based on its sensitivity and the impact to the organization if it were to be disclosed without authorization |
| `apply_masking_policy` | `apply_masking_policy`           | Tag to determine of to apply a masking policy or not to the column which would then utilize the `pii_classification` and `confidentiality_classification` tags                  |
| `semantic_type`        | `semantic_classification`        | Semantic classification is the process of categorizing data based on its meaning and context within a specific domain or industry                                               |
| `default_mask`         | `default_mask_value`             | Tag to determine which mask should be applied to the column                                                                                                                     |

If you want additional tags to be applied, you can define them in the meta_data of the column and then add them to the 'post-hook' in the dbt_project.yml file. The macro will look for the tags in the `MONITORIAL_DATA_GOVERNANCE` database and `TAGS` schema by default.


### Aggregation Policies
#### dbt_monitorial_datagovernance.apply_aggregation_policies
This macro applies aggregation policies to the model during `post-hook`. This allows you to apply Snowflake aggregation policies as part of your dbt project. The aggregation policies should be defined in your Snowflake account and are catered for in the macro. The aggregation policies are defined in the `MONITORIAL_DATA_GOVERNANCE` database and `POLICIES` schema by default.

When dbt re-runs and re-creates the views the aggregation policies will be re-applied as they will disappear from the deployed view.
##### Permissions

The users role running the macro must have the `apply aggregation policy` permissions on the account. For example if you have a `developers` role:
```sql
grant apply aggregation policy on account to role developers;
```

##### Usage

```yaml
models:
  - name: your_view_name
    meta:
      aggregation_policies:
        - name: your_aggregation_policy_name
          entity_keys:
            - first_name
            - surname
    columns:
      - name: first_name
        description: Given name
        type: VARCHAR
      - name: surname
        description: Last name
        type: VARCHAR

```


### Projection Policies
#### dbt_monitorial_datagovernance.apply_row_access_policy
This macro applies projection policies to the model during `post-hook`. This allows you to apply Snowflake projection policies as part of your dbt project. The projection policies should be defined in your Snowflake account and are catered for in the macro. The projection policies are defined in the `MONITORIAL_DATA_GOVERNANCE` database and `POLICIES` schema by default.

When dbt re-runs and re-creates the views the projection policies will be re-applied as they will disappear from the deployed view.

If you want to remove a projection policy from a column, you can set the `projection_policy` to `none` in the meta data of the column. This will remove the projection policy from the column when the model is run.

##### Permissions

The users role running the macro must have the `apply projection policy` permissions on the account. For example if you have a `developers` role:
```sql
grant apply projection policy on account to role developers;
```

##### Usage

```yaml
models:
  - name: your_view_name
    columns:
      - name: first_name
        description: Given name
        type: VARCHAR
        meta:
          projection_policy: your_projection_policy_name
      - name: surname
        description: Last name
        type: VARCHAR
        meta:
          projection_policy: none

```

### Row Access Policies
#### dbt_monitorial_datagovernance.apply_row_access_policies
This macro applies row access policies to the model during `post-hook`. This allows you to apply Snowflake row access policies as part of your dbt project. The row access policies should be defined in your Snowflake account and are catered for in the macro. The row access policies are defined in the `MONITORIAL_DATA_GOVERNANCE` database and `POLICIES` schema by default.

Only one row access policy can be applied to a model. If you want to apply multiple row access policies you will need to create a new row access policy that combines the logic of the multiple policies. The macro will look for the row access policy in the `MONITORIAL_DATA_GOVERNANCE` database and `POLICIES` schema by default.

When dbt re-runs and re-creates the views the row access policies will be re-applied as they will disappear from the deployed view.
##### Permissions

The users role running the macro must have the `apply row access policy` permissions on the account. For example if you have a `developers` role:
```sql
grant apply row access policy on account to role developers;
```

##### Usage

```yaml
models:
  - name: your_view_name
    meta:
      row_access_policy:
        - name: your_row_access_name
          columns:
            - first_name
            - surname
    columns:
      - name: first_name
        description: Given name
        type: VARCHAR
      - name: surname
        description: Last name
        type: VARCHAR

```