require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up OPA in the K8s Cluster"
task "install_opa" do |_, args|
  response = String::Builder.new
  Process.run("echo installing opa", shell: true) do |proc|
    while line = proc.output.gets
      response << line
      puts "#{line}" if check_args(args)
    end
  end
end

