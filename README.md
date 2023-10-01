# dimstack (in V)

This is a port of dimstack. See https://github.com/phcreery/dimstack for original and latest.

`v watch run .\examples\`

`v test . `

`v -shared -b js_browser .\dimstack\ -o dimstack.js`

```
sigmae = T / (6*Cpk)
Cpk = (UL-u)/ (3*sigma)

sigmae = T / ( 6* (UL-u) / (3*sigma) )
sigmae = T / (2*(UL-u)/sigma)
sigmae = T * ( sigma / 2*(UL-u) )
sigmae = sigma / (UL-u) * T/2
```
