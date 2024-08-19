#!/usr/bin/env nu

let showcases = open showcases.yaml

print '<html>'
print '<body>'
print '<ul>'

for showcase in ($showcases | transpose name config) {
    print '<li>'
    mut path = $'showcases/($showcase.name)'

    if 'url-params' in $showcase.config {
        let params = ($showcase.config.url-params | transpose key value | format pattern '{key}={value}' | str join '&')
        $path = ([$path $params] | str join '?')
    }

    print $'<a href="showcases/($path)">'
    print $showcase.name
    print '</a>'
    print '</li>'
}

print '</ul>'
print '</body>'
print '</html>'
