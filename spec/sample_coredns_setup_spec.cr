require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "SampleCoreDNS" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr helm_local_install`
    $?.success?.should be_true
  end

  after_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
  end

  before_each do
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
  end

  after_each do
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
  end

  it "'wait_for_install' should wait for a cnf to be installed" do
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true

    current_dir = FileUtils.pwd 
    puts current_dir
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm
    helm_install = `#{helm} install coredns stable/coredns`
    puts helm_install
    wait_for_install("coredns-coredns")
    current_replicas = `kubectl get deployments coredns-coredns -o=jsonpath='{.status.readyReplicas}'`
    (current_replicas.to_i > 0).should be_true
  end

  it "'sample_setup' should set up a sample cnf" do
    args = Sam::Args.new
    sample_setup(sample_dir: "sample-cnfs/sample-generic-cnf", release_name: "coredns", deployment_name: "coredns-coredns", helm_chart: "stable/coredns", helm_directory: "helm_chart", git_clone_url: "https://github.com/coredns/coredns.git", wait_count: 0 )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-generic-cnf").should be_true
    (File.exists?("cnfs/sample-generic-cnf/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/sample-generic-cnf/helm_chart/Chart.yaml")).should be_true
    sample_cleanup(sample_dir: "sample-cnfs/sample-generic-cnf", verbose: true)
  end
  #
  it "'sample_setup_args' should set up a sample cnf from a argument" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-generic-cnf").should be_true
    (File.exists?("cnfs/sample-generic-cnf/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/sample-generic-cnf/helm_chart/Chart.yaml")).should be_true
    sample_cleanup(sample_dir: "sample-cnfs/sample-generic-cnf", verbose: true)
  end

  it "'sample_cleanup' should clean up a sample cnf from a argument" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    cleanup = sample_cleanup(sample_dir: "sample-cnfs/sample-generic-cnf", verbose: true)
    (cleanup.success?).should be_true 
    (Dir.exists? "cnfs/sample-generic-cnf").should be_false
    (File.exists?("cnfs/sample-generic-cnf/cnf-conformance.yml")).should be_false
    (File.exists?("cnfs/sample-generic-cnf/helm_chart/Chart.yaml")).should be_false
  end

  it "'sample_setup_args' should be able to deploy using a helm_directory" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
    (Dir.exists? "cnfs/sample_privileged_cnf").should be_true
    # should not clone
    (Dir.exists? "cnfs/sample_privileged_cnf/privileged-coredns").should be_false
    (File.exists? "cnfs/sample_privileged_cnf/cnf-conformance.yml").should be_true
    (File.exists? "cnfs/sample_privileged_cnf/chart/Chart.yaml").should be_true
  end

  it "'cnf_conformance_dir' should return the short name of the destination cnf directory", tags: "WIP" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    (cnf_conformance_dir).should eq("sample-generic-cnf")
  end

  it "'sample_destination_dir' should return the full path of the potential destination cnf directory based on the source sample cnf directory", tags: "WIP" do
    args = Sam::Args.new
    sample_destination_dir("sample-generic-cnf").should contain("cnf-conformance/cnfs/sample-generic-cnf")
  end

  it "'cnf_conformance_yml(sample_cnf_destination_dir)' should return the yaml for the passed cnf directory", tags: "WIP" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    yml = cnf_conformance_yml("sample_privileged_cnf")
    ("#{yml.get("release_name").as_s?}").should eq("privileged-coredns")
    yml = cnf_conformance_yml("cnfs/sample_privileged_cnf")
    ("#{yml.get("release_name").as_s?}").should eq("privileged-coredns")
  end

  it "'cnf_conformance_dir(source_short_dir)' should full cnfs path for passed source cnf", tags: "WIP" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    cnf_conformance_dir("sample_privileged_cnf").should contain("sample_privileged_cnf")
    cnf_conformance_dir("sample-cnfs/sample_privileged_cnf").should contain("sample_privileged_cnf")
  end
end
