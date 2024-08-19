#!/usr/bin/env nu

let showcases = open showcases.yaml;
let remote_branches = git branch --remote --format "%(refname:short)" | lines | str replace --regex '^origin/' '';
let origin_url = git remote get-url origin;
let demo_template = open -r demo-template.html

rm -rf showcases;
git fetch --prune;
git fetch;

for showcase in ($showcases | transpose name config) {
    let showcase_dir = "showcases" | path join $showcase.name
    let showcase_branch = $"showcases/($showcase.name)"

    if $showcase_branch in $remote_branches {
        print $'No need to recreate ($showcase_branch)'
        git clone --depth 1 $origin_url --branch $showcase_branch $showcase_dir
        continue
    }

    git init --initial-branch $showcase_branch $showcase_dir

    do {
        cd $showcase_dir;
        git remote add origin $origin_url;
        pwd | print;

        ['repo-dir', 'build-dir'] | save --append .git/info/exclude;

        rm -rf repo-dir build-dir;
        git clone --depth 1 $showcase.config.repository --branch $showcase.config.branch repo-dir;
        mut cargo_args = [];
        if "bin" in $showcase.config {
            $cargo_args = ($cargo_args | append [--bin $showcase.config.bin]);
        }
        if "features" in $showcase.config {
            $cargo_args = ($cargo_args | append [--features ($showcase.config.features | str join ',')]);
        }
        (
         cargo build 
         --manifest-path repo-dir/Cargo.toml
         --target wasm32-unknown-unknown
         --target-dir build-dir
         --release
         ...$cargo_args
        );

        for wasm_file in (ls build-dir/wasm32-unknown-unknown/release/ | get name | filter {str ends-with .wasm}) {
            wasm-bindgen $wasm_file --out-dir . --out-name $showcase.name --target web;
        }
        cp --recursive repo-dir/assets .;

        $demo_template | str replace '$showcase' $showcase.name o> index.html;

        git add .;

        git commit -m 'Cached build';

        git push --force origin $showcase_branch;
    }
}
