render "docker-compose.yaml.ctmpl"
copy_file_from_path "run-context/fiab/configs/common/indieProxy.conf", "proxy.conf"

git_branch = $env == 'prod' ? 'master' : ($env == 'qa') || ($env == 'fiab') ? 'dev' : $env
render_from_github "config.json.ctmpl", "config.json", org = "broadinstitute", repo = "martha", branch = git_branch
