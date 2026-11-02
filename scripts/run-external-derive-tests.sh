#!/usr/bin/env bash
set -eu

# Runs the external-derive fixture, which checks that `derive_curve_impl`
# works across a real package boundary. The fixture is copied outside the
# repository first, as nargo cannot select a package nested inside another
# package.
cd $(dirname "$0")/../

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

cp -r tests/external_derive/. "$tmp_dir"
sed "s#path = \"../..\"#path = \"$PWD\"#" tests/external_derive/Nargo.toml > "$tmp_dir/Nargo.toml"

nargo test --program-dir "$tmp_dir"
