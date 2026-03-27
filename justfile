dev:
    hugo server --buildDrafts --navigateToChanged

build:
    hugo

deploy: build
    wrangler pages deploy public

deploy-infra:
    ./infra/deploy

syntax style="solarized-dark256 ":
    hugo gen chromastyles --style {{ style }} > static/css/syntax.css
