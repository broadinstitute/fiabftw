copy_secret_from_path "secret/common/ca-bundle.crt", "chain"
copy_secret_from_path "secret/dsde/firecloud/#{$secret_source}/common/server.key"
copy_secret_from_path "secret/dsde/firecloud/#{$secret_source}/common/server.crt"

# Render run-context specific configs
configure "run-context/#{$run_context}/configs/martha/#{$run_context}-manifest.rb", true