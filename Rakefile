ROOT = File.dirname __FILE__

task :default => :build

desc "Build Maestro"
build_deps = [
    'dist/lib/controller.js',
    'dist/lib/proxy.js',
    'dist/lib/rpcserver.js',
    'dist/lib/service.js',
    'dist/package.json',
    'dist/cli.js'
]
task :build => build_deps do
    puts "Built Maestro"
end

desc "Run Treadmill tests for Maestro"
task :test => [:build, :setup] do
    system 'bin/runtests'
end

task :setup => 'tmp/setup.dump' do
    puts "dev environment setup done"
end

desc "Publish a Maestro tarball to GitHub for deployment"
task :publish do
    version = `bin/getversion.js`
    tarball = "/tmp/maestro-#{version}.tar.gz"
    sh "tar -C ./dist -czf #{tarball} ./"
    puts "upload the tarbal from #{tarball}"
end

task :clean do
    rm_rf 'tmp'
    rm_rf 'node_modules'
    rm_rf 'dist'
end

file 'tmp/setup.dump' => ['dev.list', 'tmp'] do |task|
    list = File.open(task.prerequisites.first, 'r')
    list.each do |line|
        npm_install(line)
    end
    File.open(task.name, 'w') do |fd|
        fd << "done"
    end
end

directory 'tmp'
directory 'dist'
directory 'dist/lib'

file 'dist/package.json' => ['package.json', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
    Dir.chdir 'dist'
    sh 'npm install' do |ok, id|
        ok or fail "npm could not install Maestro dependencies"
    end
    Dir.chdir ROOT
end

file 'dist/cli.js' => ['cli.coffee', 'dist'] do |task|
    brew_javascript task.prerequisites.first, task.name, true
    File.chmod(0764, task.name)
end

file 'dist/lib/service.js' => ['lib/service.coffee', 'dist/lib'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

file 'dist/lib/rpcserver.js' => ['lib/rpcserver.coffee', 'dist/lib'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

file 'dist/lib/proxy.js' => ['lib/proxy.coffee', 'dist/lib'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

file 'dist/lib/controller.js' => ['lib/controller.coffee', 'dist/lib'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

def npm_install(package)
    sh "npm install #{package}" do |ok, id|
        ok or fail "npm could not install #{package}"
    end
end

def brew_javascript(source, target, node_exec=false)
    File.open(target, 'w') do |fd|
        if node_exec
            fd << "#!/usr/bin/env node\n\n"
        end
        fd << %x[coffee -pb #{source}]
    end
end
