render "docker-compose.yaml.ctmpl"
copy_file_from_path "run-context/fiab/configs/common/indieProxy.conf", "proxy.conf"

git_branch = ($env == 'dev') || ($env == 'qa') || ($env == 'fiab') ? 'develop' : $env == 'prod' ? 'master' : $env
render_from_github "app.yaml.ctmpl", "app.yaml", org = "DataBiosphere", repo = "bond", branch =  git_branch
render_from_github "config.ini.ctmpl", "config.ini", org = "DataBiosphere", repo = "bond", branch = git_branch
