# Monitorial Snowflake Data Governance Project Changelog

**This changelog is for the Monitorial Snowflake Data Governance Project. It includes all changes made to the project, including new features, bug fixes, and other improvements.*

## Version 1.0.0 (2025-05-10)
- **Breaking**: Bumped minimum dbt version to 1.9.0 and added forward compatibility for dbt 2.x/3.x (dbt-fusion)
- Fixed undefined variable `table_name` in `set_column_tag_value` macro (was `table_name`, should be `model_name`)
- Fixed undefined variable `model_alias` in `add_aggregation_policy`, `drop_aggregation_policy`, and `drop_row_access_policy` log messages
- Fixed undefined variable `column_name` in `add_aggregation_policy` and `drop_aggregation_policy` SQL statements
- Fixed parameter list mismatch in `drop_aggregation_policy` macro signature (removed extra `column_name` parameter)
- Fixed wrong tuple index in `apply_projection_policies` (`selectattr('21',...)` → `selectattr('1',...)`)
- Fixed dead code in `apply_aggregation_policies` that prevented cleanup of existing policies when meta key is absent
- Fixed typo in parameter name `materlization` → `materialization` across all helper macros
- Fixed incorrect description for `model_meta_contains_item` in macro docs
- Fixed README documentation errors (wrong macro names in section headers)
- Removed deprecated `target-path` and `clean-targets` from `dbt_project.yml`
- Added integration test suite with models and tests for all governance macros
- Added GitHub Actions CI pipeline (lint + integration tests across dbt 1.9.x and 1.10.x)
- Added GitHub Actions release workflow with version validation
- Updated LICENSE with copyright information
- Improved `.gitignore` with IDE, OS, and environment file exclusions

## Version 0.1.3 (2025-07-13)
- Fixed issue with row access policy not applying correctly.
- Added ability to handle metadata found under the config nodes of either the model or columns

## Version 0.1.2 (2025-05-16)
- Added support for new aggregation policies.
- Improved documentation for projection policies.
- Fixed logging messages for tags

## Version 0.1.1 (2025-05-15)
- Fix for applying aggregation policies

## Version 0.1.0 (2025-05-06)

- Initial release of the Monitorial Snowflake Data Governance Project.
- Added Aggregation Policies
- Added Projection Policies
- Added Row Based Access Control Policies
- Added Tags