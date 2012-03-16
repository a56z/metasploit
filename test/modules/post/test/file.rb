require 'module_test'
load 'lib/msf/core/post/file.rb'

class Metasploit4 < Msf::Post

	include Msf::ModuleTest::PostTest
	include Msf::Post::File

	def initialize(info={})
		super( update_info( info,
				'Name'          => 'Testing meterpreter stuff',
				'Description'   => %q{ This module will test meterpreter API methods },
				'License'       => MSF_LICENSE,
				'Author'        => [ 'egypt'],
				'Version'       => '$Revision$',
				'Platform'      => [ 'windows', 'linux', 'java' ],
				'SessionTypes'  => [ 'meterpreter', 'shell' ]
			))
	end

	def test_file
		it "should test for existence" do
			case session.platform
			when /win/
				file_exist?("c:\\boot.ini")
			else
				file_exist?("/etc/passwd")
			end
		end

		it "should create files" do
			write_file("foo", "pwned")

			file_exist?("foo")
		end

		it "should read files" do
			read_file("foo") == "pwned"
		end

		it "should delete files" do
			file_rm("foo")

			not file_exist?("foo")
		end

	end

end

