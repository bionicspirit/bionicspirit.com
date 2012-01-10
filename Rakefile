require 'bundler/setup'
require 'yaml'

include Rake::DSL
CONFIG = YAML::load(File.open('./_config.yml'))


desc "Deploys assets to GAE"
task :gae do
  Dir.entries('./lib/gae/').find_all{|x| x =~ /app\d+.ya?ml/}.each do |app|
    config = YAML::load(File.read "./lib/gae/#{app}")

    puts
    puts "Deploying CDN #{config['application']}.appspot.com ..."
    puts

    rm_rf "/tmp/gaecdn"
    mkdir "/tmp/gaecdn"
    sh "cp -rf ./#{CONFIG['destination']}/assets /tmp/gaecdn/"

    sh "cp -rf ./lib/gae/* /tmp/gaecdn/"
    sh "cp ./lib/gae/#{app} /tmp/gaecdn/app.yaml"    
    sh "rm /tmp/gaecdn/#{app}"

    Dir.chdir("/tmp/gaecdn") do
      sh "appcfg.py update ."
    end  
  end
end

