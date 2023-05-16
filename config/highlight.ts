import 'https://esm.sh/prismjs@1.27.0/components/prism-typescript'
import 'https://esm.sh/prismjs@1.27.0/components/prism-yaml'
import 'https://esm.sh/prismjs@1.27.0/components/prism-toml'
import 'https://esm.sh/prismjs@1.27.0/components/prism-javascript'
import 'https://esm.sh/prismjs@1.27.0/components/prism-json'
import 'https://esm.sh/prismjs@1.27.0/components/prism-markup'
import 'https://esm.sh/prismjs@1.27.0/components/prism-hcl'
import 'https://esm.sh/prismjs@1.27.0/components/prism-bash'
import 'https://esm.sh/prismjs@1.27.0/components/prism-ini'

export const theme = `

ol, ul {
	list-style: revert;
}

/*
	Override variables
	full list: https://github.com/denoland/deno-gfm/issues/36#issuecomment-1441034903
*/

.markdown-body {
  /* --color-canvas-subtle: #272822 !important; */
}

`
