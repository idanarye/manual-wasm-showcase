#!/usr/bin/env nu

let showcases = open showcases.yaml

let local_branches = git branch --format "%(refname:short)" | lines
let remote_branches = git branch --remote --format "%(refname:short)" | lines | str replace --regex '^origin/' ''

for showcase in ($showcases | transpose name config) {
    let showcase_dir = "showcases" | path join $showcase.name

    if ($showcase_dir | path exists) {
        continue
    }

    rm -rf repo-dir build-dir
    git clone --depth 1 $showcase.config.repository --branch $showcase.config.branch repo-dir
    mut cargo_args = []
    if "bin" in $showcase.config {
        $cargo_args = ($cargo_args | append [--bin $showcase.config.bin])
    }
    if "features" in $showcase.config {
        $cargo_args = ($cargo_args | append [--features ($showcase.config.features | str join ',')])
    }
    (
     cargo build 
     --manifest-path repo-dir/Cargo.toml
     --target wasm32-unknown-unknown
     --target-dir build-dir
     --release
     ...$cargo_args
    )

    for wasm_file in (ls build-dir/wasm32-unknown-unknown/release/ | get name | filter {str ends-with .wasm}) {
        # let name = $wasm_file | path basename | parse '{name}.wasm' | get name | first
        wasm-bindgen $wasm_file --out-dir $showcase_dir --out-name $showcase.name --target web
    }
    cp --recursive repo-dir/assets $showcase_dir

    open -r demo-template.html | str replace '$variant' $showcase.name o> ($showcase_dir | path join 'index.html')
    
}
