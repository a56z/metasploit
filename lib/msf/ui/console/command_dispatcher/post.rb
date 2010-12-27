module Msf
module Ui
module Console
module CommandDispatcher

###
#
# Recon module command dispatcher.
#
###
class Post

	include Msf::Ui::Console::ModuleCommandDispatcher


	@@post_opts = Rex::Parser::Arguments.new(
		"-h" => [ false, "Help banner."                                          ],
		"-j" => [ false, "Run in the context of a job."                          ],
		"-o" => [ true,  "A comma separated list of options in VAR=VAL format."  ],
		"-q" => [ false, "Run the module in quiet mode with no output"           ]
	)

	#
	# Returns the hash of commands specific to post modules.
	#
	def commands
		{
			"run"   => "Launches the post exploitation module",
			"rerun" => "Reloads and launches the module",
			"exploit"  => "This is an alias for the run command",
			"rexploit" => "This is an alias for the rerun command",
			"reload"   => "Reloads the post exploitation module"
		}.merge( (mod ? mod.post_commands : {}) )
	end

	#
	# Allow modules to define their own commands
	#
	def method_missing(meth, *args)
		$stdout.puts("Post#method_missing")
		if (mod and mod.respond_to?(meth.to_s))

			# Initialize user interaction
			mod.init_ui(driver.input, driver.output)

			return mod.send(meth.to_s, *args)
		end
		return
	end

	#
	#
	# Returns the command dispatcher name.
	#
	def name
		"Post"
	end

	#
	# This is an alias for 'rerun'
	#
	def cmd_rexploit(*args)
		cmd_rerun(*args)
	end

	#
	# Reloads an auxiliary module
	#
	def cmd_reload(*args)
		begin
			omod = self.mod
			self.mod = framework.modules.reload_module(mod)
			if(not self.mod)
				print_error("Failed to reload module: #{framework.modules.failed[omod.file_path]}")
				self.mod = omod
			end
		rescue
			log_error("Failed to reload: #{$!}")
		end
	end

	#
	# Reloads an auxiliary module and executes it
	#
	def cmd_rerun(*args)
		if mod.job_id
			print_status("Stopping existing job...")

			framework.jobs.stop_job(mod.job_id)
			mod.job_id = nil
		end

		omod = self.mod
		self.mod = framework.modules.reload_module(mod)

		if(not self.mod)
			print_error("Failed to reload module: #{framework.modules.failed[omod.file_path]}")
			self.mod = omod
			return
		end

		cmd_run(*args)
	end

	#
	# This is an alias for 'run'
	#
	def cmd_exploit(*args)
		cmd_run(*args)
	end

	#
	# Executes an auxiliary module
	#
	def cmd_run(*args)
		defanged?

		opt_str = nil
		jobify  = false
		quiet   = false

		@@post_opts.parse(args) { |opt, idx, val|
			case opt
				when '-j'
					jobify = true
				when '-o'
					opt_str = val
				when '-a'
					action = val
				when '-q'
					quiet  = true
				when '-h'
					print(
						"Usage: run [options]\n\n" +
						"Launches a post module.\n" +
						@@auxiliary_opts.usage)
					return false
			end
		}

		# Always run passive modules in the background
		if (mod.passive)
			jobify = true
		end

		begin
			mod.run_simple(
				'OptionStr'      => opt_str,
				'LocalInput'     => driver.input,
				'LocalOutput'    => driver.output,
				'RunAsJob'       => jobify,
				'Quiet'          => quiet
			)
		rescue ::Timeout::Error
			print_error("Post triggered a timeout exception")
		rescue ::Interrupt
			print_error("Post interrupted by the console user")
		rescue ::Exception => e
			print_error("Post failed: #{e.class} #{e}")
			if(e.class.to_s != 'Msf::OptionValidateError')
				print_error("Call stack:")
				e.backtrace.each do |line|
					break if line =~ /lib.msf.base.simple/
					print_error("  #{line}")
				end
			end

			return false
		end

		if (jobify)
			print_status("Post module running as background job")
		else
			print_status("Post module execution completed")
		end
	end

end

end end end end

