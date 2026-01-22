# Fix gcloud Command Not Found

## Quick Fix (Temporary)

Run this in your terminal:
```bash
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
gcloud auth login
```

## Permanent Fix (Already Done)

I've added gcloud to your `.zshrc` file. 

**To use it now:**
1. Close and reopen your terminal, OR
2. Run: `source ~/.zshrc`

Then you can use:
```bash
gcloud auth login
```

## Verify It Works

After adding to PATH, test:
```bash
gcloud --version
```

You should see the version number.

## Next Steps

Once gcloud is working:
1. Authenticate: `gcloud auth login` (use your Drive account email)
2. Set project: `gcloud config set project wedecorenquries`
3. Create OAuth clients: `./scripts/create_oauth_clients_curl.sh`

