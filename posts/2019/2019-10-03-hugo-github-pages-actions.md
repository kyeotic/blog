---
title: "Deploying Hugo to GitHub Pages with GitHub Actions"
pathname: "/hugo-github-pages-actions"
publish_date: 2019-10-03
tags: ["GitHub", "GitHub Actions", "Hugo", "GitHub Pages"]
---

There are a lot of strategies to hosting in-repo docs on [GitHub Pages](https://pages.github.com/) (as opposed to a dedicated repo for docs). I'm going to cover how to publish docs that are stored on the *master* branch to the *gh-pages* branch. 

This approach has several benefits

- Only the Hugo "source" files live in *master*, while *gh-pages* contains the built HTML, etc. This keeps *master* clean and lean, and makes PR diffs much easier to review.
- **Code** and **docs** both live on *master*, making it simple to ensure changes go out at the same time. Pull Requests that change code can also update docs, instead of having separate PRs for code and docs. 
- No need to explain to external contributors where doc PRs go: everything is on *master*.
- GitHub Actions workflow files all live in *master*, instead of living on a *docs* branch (or on *gh-pages*, where your built artifacts live).

> I am going to be using [Hugo](https://gohugo.io/) along with the excellent [Learn](https://learn.netlify.com/en/) theme, but for the most part any system that generates static HTML sites can be used.

## The Plan

- Create a `/docs`directory in the repo root to hold Hugo content
- Setup a Hugo theme using [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- Setup a `Makefile` to run Hugo locally
- Add a GitHub Actions workflow that will run on changes to `/docs` that builds Hugo and pushes the output to the *gh-pages*

## Setup Hugo

First install Hugo. If you are on a mac just use Homebrew. Otherwise checkout their [installation docs](https://gohugo.io/getting-started/installing/).

```
brew install hugo
```

To create the `/docs` folder, initialize a Hugo site, and install the theme run:

```
hugo new site docs
cd docs/themes
git submodule add https://github.com/matcornic/hugo-theme-learn learn
```

To finish the Hugo setup edit the `docs/config.toml` to include the following

```toml
baseURL = "https://{YOUR_GITHUB_USERNAME}.github.io/{YOUR_GITHUB_REPO}"
languageCode = "en-us"
title = "{YOUR_GITHUB_REPO}"
theme = "learn"
RelativeURLs=true
CanonifyURLs=true

[params]
  pygmentsCodeFences = true
  pygmentsStyle="monokai"
    editURL = ""
  author = "{YOUR_GITHUB_USERNAME}"
  description = "Documentation for {YOUR_GITHUB_REPO}"
  showVisitedLinks = false
  disableSearch = false
  disableAssetsBusting = false
  disableInlineCopyToClipBoard = false
  disableShortcutsTitle = false
  disableLanguageSwitchingButton = false
  disableBreadcrumb = true
  disableNextPrev = false
  ordersectionsby = "weight"
  themeVariant = "green"

[[menu.shortcuts]] 
  name = "<i class='fab fa-github'></i> Github repo"
  identifier = "ds"
  url = "https://github.com/{YOUR_GITHUB_USERNAME}/{YOUR_GITHUB_REPO}"
  weight = 10

[outputs]
  home = [ "HTML", "RSS", "JSON"]
```

For more information on the above settings see the [learn configuration docs](https://learn.netlify.com/en/basics/configuration/).

## Create Documentation Content

I'm not going to cover this here, because the [learn docs](https://learn.netlify.com/en/cont/) are good enough. I will note though that currently markdown code fences (the triple-backticks) don't seem to work. The [highlight shortcodes](https://gohugo.io/content-management/syntax-highlighting/) do, though.

## Setup Makefile

To make building and running locally easier add a `Makefile` to your project root.

```
run-docs: ## Run in development mode
  cd docs && hugo serve -D

docs: ## Build the site
  cd docs && hugo -t learn -d public --gc --minify --cleanDestinationDir
```
You can run the above commands with `make run-docs` and `make docs`.

> If you aren't familiar with make its basically `npm run <script>`. Except its decades older, faster, composes easily, and works on every system with a shell (so... not Windows) without installing anything.

This is probably a good time to stop and check that your site builds correctly and looks the way you want it to.

## Create the GitHub Action

We want changes to the `/docs` directory to result in Hugo building and pushing the resulting `/public` directory to the root of the *gh-pages* branch. There are a few ways to do this, but GitHub user peaceiris has wrapped up the nicest one into two ready-to-use GitHub actions: [actions-hugo ](https://github.com/peaceiris/actions-hugo)(to setup the Hugo cli) [actions-gh-pages](https://github.com/peaceiris/actions-gh-pages) (to handle pushing to the *gh-pages *branch).

Create a `.github/workflows/docs.yaml` with the following.

```yaml
name: Publish Docs

on:
  push:
    branches:
      - master
    paths:
      - 'docs/**'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
      - name: Checkout
        uses: actions/setup-node@v1
        with:
          node-version: 10.x
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2.2.1
        with:
          hugo-version: '0.58.3'
      - name: Prepare Hugo
        run: |
          git submodule sync && git submodule update --init
      - name: Build
        run: make docs
      - name: add nojekyll
        run: touch ./docs/public/.nojekyll
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v2.4.0
        with:
          emptyCommits: false
        env:
          ACTIONS_DEPLOY_KEY: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          PUBLISH_BRANCH: gh-pages
          PUBLISH_DIR: ./docs/public
```

This *almost* works out of the box. Unfortunately we can't use GitHub Actions's default `GITHUB_TOKEN` here, so we need to setup a repository **deploy key** to authorize pushing to the *gh-pages* branch from inside the workflow.

To do this go to **Settings > Deploy Keys > Add Deploy Key**

![](/images/2019-10-03-hugo-deploy-keys.png)

Copy the key and then add it to **Settings > Secrets**.

![](/images/2019-10-03-hugo-secrets.png)

With all of this in place you are ready to **commit to master**. This should kick off the publish workflow, which you can view under **Actions > Publish Docs**.

![](/images/2019-10-03-hugo-publish.png)

## Turn on GitHub Pages

Finally, enable GitHub pages from your repository **settings **page by selecting **gh-pages branch** on the **Source** dropdown.

![](/images/2019-10-03-hugo-enable-pages.png)

Once you've done that you should get a link to your new GitHub Pages deployment!

You can see the GitHub Pages I built for raviger [here](https://kyeotic.github.io/raviger/).
