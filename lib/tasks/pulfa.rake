# frozen_string_literal: true

namespace :pulfa do
  desc "Retrieve the PULFA finding aid EAD Documents Subversion"
  task :checkout do
    check_if_lpass_installed
    check_if_logged_in

    lastpass_pulfa_svn_username = "Shared-ITIMS-Passwords/pulfa_svn_username"
    lastpass_pulfa_svn_password = "Shared-ITIMS-Passwords/pulfa_svn_password"
    lastpass_pulfa_svn_url = "Shared-ITIMS-Passwords/pulfa_svn_url"

    username = `lpass show --notes #{lastpass_pulfa_svn_username}`
    username.chomp!
    password = `lpass show --notes #{lastpass_pulfa_svn_password}`
    password.chomp!
    svn_url = `lpass show --notes #{lastpass_pulfa_svn_url}`
    svn_url.chomp!

    cmd = "/usr/bin/env svn checkout #{svn_url} eads/pulfa/ --username #{username} --non-interactive --password #{password}"

    exit_code = system(cmd)
    exit(exit_code)
  end

  namespace :aspace do
    desc "Check out ArchiveSpace EAD examples"
    task :checkout do
      check_if_lpass_installed
      check_if_logged_in

      lastpass_pulfa_svn_username = "Shared-ITIMS-Passwords/pulfa_svn_username"
      lastpass_pulfa_svn_password = "Shared-ITIMS-Passwords/pulfa_svn_password"
      lastpass_pulfa_svn_url = "Shared-ITIMS-Passwords/pulfa_aspace_eads_svn_url"

      username = `lpass show --notes #{lastpass_pulfa_svn_username}`
      username.chomp!
      password = `lpass show --notes #{lastpass_pulfa_svn_password}`
      password.chomp!
      svn_url = `lpass show --notes #{lastpass_pulfa_svn_url}`
      svn_url.chomp!

      cmd = "/usr/bin/env svn checkout #{svn_url} eads/aspace_fa/ --username #{username} --non-interactive --password #{password}"

      exit_code = system(cmd)
      exit(exit_code)
    end
  end

  # Utility methods

  # Determine if the lpass binary is installed and in the $PATH
  # @return [Boolean]
  def check_if_lpass_installed
    abort("You don't have the 'lpass' command tool") if `which lpass`.empty?
  end

  # Determine if the system user has authenticated using lpass
  # @return [Boolean]
  def check_if_logged_in
    abort("You must login first with: lpass login <login@name.com>") if system("lpass status -q") == false
  end
end
