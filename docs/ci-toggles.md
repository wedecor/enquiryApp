# CI Toggles

- DEPLOY_MOBILE=false (default) → Android/iOS store deploys skipped
- Set to true:

  gh variable set DEPLOY_MOBILE -b true

- Disable again:

  gh variable set DEPLOY_MOBILE -b false

