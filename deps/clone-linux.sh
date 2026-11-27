#!/bin/sh -e
repo_root="$(dirname "$0")/.."
sub_path=deps/linux
sub_repo="$repo_root/$sub_path"
git submodule init "$sub_path"

# GitHub may intermittently return HTTP 5xx while cloning the large Linux
# source repository. Retry the clone before failing the CI job.
attempt=1
max_attempts=5
until git clone "$(git config submodule."$sub_path".url)" --depth=1 --sparse "$sub_repo"; do
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
