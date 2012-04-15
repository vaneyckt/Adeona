module Adeona
  def Adeona::spawn_child(options = {}, &block)
    # handle default options
    # - detach (true): causes Process.detach to be called on the child process. If set to false, the
    #   parent process (ideally) needs to call Process.waitpid on the child_pid returned by spawn_child.
    # - timeout (nil): by default no timeout interval is set. Can be used to specify the number of
    #   seconds after which the child_process automatically exits.
    # - verbose (false): when set to true Adeona will write to stdout when a child process exits due to
    #   losing the connection to its parent or due to its timeout interval expiring.
    default_options = {:detach => true, :timeout => nil, :verbose => false}
    options = default_options.merge(options)

    # create a pipe that allows for communication between parent and child process. This pipe will
    # be used to let the child process know when the parent is no longer there (this works even if
    # the parent process gets killed with SIGKILL).
    lifeline = IO.pipe()

    # use fork to create the actual child process
    child_pid = fork do
      # make the child process close its write endpoint of the pipe.
      # make the child process set sync to true for its read endpoint so as to avoid message buffering.
      lifeline[1].close()
      lifeline[0].sync = true

      begin
        # here's where the magic happens that makes the child process exit as soon as the parent is no longer active.
        # In the child process we create a thread that calls IO.select on its read endpoint. This is a blocking operation that
        # causes the thread to keep waiting. Now remember that the child process has already closed its write endpoint (line 22).
        # This means that only the main process has an open write endpoint to this pipe. So when the main process disappears,
        # the kernel detects nothing can write to this pipe anymore, and causes an EOF to be sent to the pipe. This EOF causes
        # IO.select to return, letting the child process know the parent process no longer exists. IO.select can also take a
        # timeout value, which we use to kill the child process when the timeout interval has expired.
        # In both cases we cause an exception to be raised in the main thread, which exits the child process.
        lifeline_thread = Thread.new(Thread.current) do |main_thread|
          result = IO.select([lifeline[0]], nil, nil, options[:timeout])
          main_thread.raise 'Adeona: Connection with parent process was lost.' if !result.nil?
          main_thread.raise 'Adeona: Connection with parent process was lost due to timeout.' if result.nil?
        end

        # this is where the user specified code in the block is executed.
        block.call

      # this exception handler will handle exceptions thrown by the user specified code in the block, as well as
      # exceptions thrown by the lifeline_thread that cause the child process to exit when the parent process is
      # no longer active.
      rescue Exception => e
        if(options[:verbose])
          puts "Exception caught: #{e.message}"
          puts e.backtrace
        end
      end
    end

    # here we are back in the parent process. The parent process closes its read endpoint of the pipe, as it has no use for it.
    # The write endpoint is kept open in order for the lifeline mechanism to work (line 29). We also set sync to true so as to
    # prevent message buffering.
    lifeline[0].close()
    lifeline[1].sync = true

    # detaching the child process is ideal for fire-and-forget type child processes. You want to set the detach option to false
    # when you want to use Process.waitpid to make the parent process wait for the child.
    if(options[:detach])
      Process.detach(child_pid)
    end

    child_pid
  end
end
