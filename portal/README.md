# Internal Developer Portal (Minimal)

A lightweight developer portal concept using docs and repo templates. **No Backstage required.**

## Contents

- `catalog/` — Service catalog as Markdown
- Links to golden path, runbooks, templates

## Using the Portal

1. Browse `portal/catalog/` for available services and templates
2. Follow `docs/golden-path.md` to add a new service
3. Use `templates/service-template` as the starting point

## Optional: Backstage

To adopt Backstage later:

- Add a `backstage.yaml` or `catalog-info.yaml` per service
- Point Backstage to this repo as a catalog location
- Migrate Markdown docs into Backstage TechDocs
