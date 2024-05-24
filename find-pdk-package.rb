# frozen_string_literal: true

require "open-uri"
require "oga"
require "json"

UBUNTU_RELEASE = ENV.fetch("UBUNTU_RELEASE", "jammy")
TAG = ENV.fetch('TAG', '')

def pdk_packages_html(base_url)
  URI.parse("#{base_url}/index_by_lastModified_reverse.html").read
rescue OpenURI::HTTPError
  nil
end

def pdk_packages(release_type)
  if release_type == :nightly
    pdk_url_base = "https://nightlies.puppetlabs.com/apt/pool/#{UBUNTU_RELEASE}/puppet-nightly/p/pdk"
    pdk_pkg_regex = /^pdk_(?<version>\d+\.\d+\.\d+\.\d+\..*)-(\d+)#{UBUNTU_RELEASE}_(?<arch>[^\.]+)/
  else
    pdk_url_base = "https://apt.puppetlabs.com/pool/#{UBUNTU_RELEASE}/puppet/p/pdk"
    pdk_pkg_regex = /^pdk_(?<version>\d+\.\d+\.\d+\.\d+)-(\d+)#{UBUNTU_RELEASE}_(?<arch>[^\.]+)/
  end

  doc = Oga.parse_html(pdk_packages_html(pdk_url_base))

  version_map = doc.css('a[href$="deb"]').collect do |el|
    if matches = el['href'].match(pdk_pkg_regex)
      docker_platform = if matches[:arch] == 'amd64'
                          'linux/amd64'
                        elsif matches[:arch] == 'arm64'
                          'linux/arm64/v8'
                        else
                          $stder.puts "::warning::Unhandled package architecture #{matches[:arch]}"
                          next
                        end
      {
        :version => matches[:version],
        :released_at => Time.parse(el.parent.next_element.text),
        :docker_platform => docker_platform,
        :href => "#{pdk_url_base}/#{el['href']}",
        :type => release_type,
      }
    else
      nil
    end
  end

  version_map.compact.sort_by { |p| p[:released_at] }.reverse
end

docker_platforms = []
pkgs = if TAG.eql? 'nightly'
         pdk_packages(:nightly).select { |p| docker_platforms << p[:docker_platform] unless docker_platforms.include? p[:docker_platform] }
       elsif TAG.eql? 'latest'
         pdk_packages(:release).select { |p| docker_platforms << p[:docker_platform] unless docker_platforms.include? p[:docker_platform] }
       elsif TAG =~ /^(\d+.*)/
         (pdk_packages(:release) + pdk_packages(:nightly))
           .sort_by { |p| p[:released_at] }
           .reverse
           .select { |p| p[:version].eql? $1 }
           .select { |p| docker_platforms << p[:docker_platform] unless docker_platforms.include? p[:docker_platform] }
       else
         $stderr.puts '::error::TAG environment variable with valid value required'
         exit(1)
       end

if pkgs.empty?
  $stderr.puts "::error::No packages found that match: #{TAG}"
  exit(1)
else
  puts JSON.pretty_generate({ version: pkgs.first[:version], platforms: docker_platforms, packages: pkgs })
end
