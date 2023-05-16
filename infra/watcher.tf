module "watcher" {
  source      = "github.com/kyeotic/tf-domain-heartbeat"
  lambda_name = "blog-watcher"
  watch_url   = "blog.kye.dev"
}
