#!/usr/bin/env nu

rm -rf showcases;
git worktree prune;
git fetch --prune;

git branch --format "%(refname:short)" | lines | filter {str starts-with "showcases/"} | each { |branch|
    git branch -d $branch
}

let showcases = open showcases.yaml;
let remote_branches = git branch --remote --format "%(refname:short)" | lines | str replace --regex '^(remotes/)?origin/' '';
let origin_url = git remote get-url origin;
let demo_template = open -r demo-template.html;

$showcases | transpose name config | each { |showcase|
    let showcase_dir = "showcases" | path join $showcase.name
    let showcase_branch = $"showcases/($showcase.name)"

    if $showcase_branch in $remote_branches {
        print $'No need to recreate ($showcase_branch)';
        git worktree add $showcase_dir;
        do {
            cd $showcase_dir;
            git checkout $"origin/($showcase_branch)"
        }
        return;
    }

    do {
        git worktree add -B $showcase_branch $showcase_dir
        cd $showcase_dir;
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

        rm -rf repo-dir build-dir;
        git add .;
        git commit -m 'Cached build';

        git push --force origin $showcase_branch;
    }
}

null
