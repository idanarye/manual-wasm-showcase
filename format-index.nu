#!/usr/bin/env nu

let showcases = open showcases.yaml

print '<html>'
print '<body>'
print '<ul>'

for showcase in ($showcases | transpose name config) {
    print '<li>'
    print $'<a href="showcases/($showcase.name)">'
    print $showcase.name
    print '</a>'
    print '</li>'
}

print '</ul>'
print '</body>'
print '</html>'
