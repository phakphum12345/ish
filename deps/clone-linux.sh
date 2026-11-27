#!/bin/sh -e
repo_root="$(dirname "$0")/.."
sub_path=deps/linux
sub_repo="$repo_root/$sub_path"
git submodule init "$sub_path"

# The upstream Linux fork is several gigabytes. Fetching every blob before
# applying sparse-checkout can make GitHub's upload-pack return HTTP 500.
# Use a partial clone so only blobs selected by sparse-checkout are fetched.
# Retry transient upstream failures before failing the CI job.
attempt=1
max_attempts=5
until git clone "$(git config submodule."$sub_path".url)" --depth=1 --filter=blob:none --sparse "$sub_repo"; do
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "Failed to clone Linux after $max_attempts attempts." >&2
        exit 1
    fi
    echo "Linux clone failed (attempt $attempt/$max_attempts); retrying..." >&2
    rm -rf "$sub_repo"
    sleep "$((attempt * 10))"
    attempt=$((attempt + 1))
done

git -C "$sub_repo" sparse-checkout set --no-cone --stdin < "$sub_repo/../linux-sparse.txt"
git config --local submodule."$sub_path".update checkout
git submodule update --depth=1 "$sub_path"
