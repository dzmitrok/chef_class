# => Shorten Hashes
jboss = node['jboss7']

#download cumulogic test testweb.zip

remote_file "#{Chef::Config[:file_cache_path]}/#{jboss['testweb_archive']}" do
 source "#{jboss['testweb_url']}/#{jboss['testweb_archive']}"
 action :create_if_missing
 notifies :run, 'bash[Extract testweb]', :immediately
end

#Extract testweb_archive

bash 'Extract testweb' do
 cwd Chef::Config[:file_cache_path]
 code <<-EOF
 unzip -u #{Chef::Config[:file_cache_path]}/#{jboss['testweb_archive']}
 cp "#{Chef::Config[:file_cache_path]}/testweb/*.war" "#{jboss['jboss_home']}/standalone/deployments/"
 EOF
 action :run
end
