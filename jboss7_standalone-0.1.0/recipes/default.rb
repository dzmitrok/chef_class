#
# Cookbook Name:: jboss7_standalone
# Recipe:: default
#
#
include_recipe 'java'
# => Shorten Hashes
jboss = node['jboss7']

#create new user for jboss
user node['jboss7']['jboss_user'] do
  comment 'jboss User'
  home node['jboss7']['jboss_home']
  system true
  shell '/bin/false'
end

#create new group for new user
group node['jboss7']['jboss_group'] do
  action :create
end

# => Download jboss Tarball
remote_file "#{Chef::Config[:file_cache_path]}/#{jboss['version']}.tar.gz" do
  source jboss['url']
  action :create
  notifies :run, 'bash[Extract jboss]', :immediately
end

# => Extract jboss
bash 'Extract jboss' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
  mkdir -p #{jboss['jboss_home']}
  tar xzf #{Chef::Config[:file_cache_path]}/#{jboss['version']}.tar.gz -C #{jboss['jboss_home']} --strip 1
  chown #{jboss['jboss_user']}:#{jboss['jboss_group']} -R #{jboss['jboss_home']}
  EOF
  action :run
end


#create standalone.xml from template
template "#{node['jboss7']['jboss_home']}/standalone/configuration/standalone.xml" do
  source 'standalone_xml.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed  #not sure what it does
end

template "#{node['jboss7']['jboss_home']}/bin/standalone.conf" do
  source 'standalone_conf.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, "service[jboss]", :delayed  #not sure what it does
end

dist_dir, conf_dir = value_for_platform_family(
  ['debian'] => %w{ debian default },
  ['rhel'] => %w{ redhat sysconfig },
)

template '/etc/jboss-as.conf' do
  source "#{dist_dir}/jboss-as.conf.erb"
  mode 0775
  owner 'root'
  group node['root_group']
  only_if { platform_family?("rhel") }
  notifies :restart, 'service[jboss]', :delayed
end

template '/etc/init.d/jboss' do
  source "#{dist_dir}/jboss-init.erb"
  mode 0775
  owner 'root'
  group node['root_group']
  notifies :enable, 'service[jboss]', :delayed
  notifies :restart, 'service[jboss]', :delayed
end


service 'jboss' do
  supports :restart => true
  action :nothing
end
