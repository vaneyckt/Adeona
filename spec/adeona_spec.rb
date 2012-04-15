require 'adeona'

describe "Adeona" do
  it "should kill the child process when the main process exits nicely" do
    pipe = IO.pipe
    main_pid = fork do
      child_pid = Adeona.spawn_child do
        # make sure child process keeps existing
        while(true) do
        end
      end

      # send spec process the child_pid
      pipe[0].close
      pipe[1].sync = true
      pipe[1] << "#{child_pid}\n"
      pipe[1].close

      # make sure main process keeps existing
      while(true) do
      end
    end

    # retrieve child_pid
    pipe[1].close
    pipe[0].sync = true
    rd = IO.select([pipe[0]])
    child_pid = rd[0][0].gets.to_i
    pipe[0].close

    # check both processes exist
    process_exists?(main_pid).should be_true
    process_exists?(child_pid).should be_true

    # kill parent process nicely
    Process.kill("TERM", main_pid)
    Process.waitpid(main_pid)

    # check both processes are no longer active after a few seconds
    sleep 5
    process_exists?(main_pid).should be_false
    process_exists?(child_pid).should be_false
  end

  it "should kill the child process when the main process exits with a SIGKILL" do
    pipe = IO.pipe
    main_pid = fork do
      child_pid = Adeona.spawn_child do
        # make sure child process keeps existing
        while(true) do
        end
      end

      # send spec process the child_pid
      pipe[0].close
      pipe[1].sync = true
      pipe[1] << "#{child_pid}\n"
      pipe[1].close

      # make sure main process keeps existing
      while(true) do
      end
    end

    # retrieve child_pid
    pipe[1].close
    pipe[0].sync = true
    rd = IO.select([pipe[0]])
    child_pid = rd[0][0].gets.to_i
    pipe[0].close

    # check both processes exist
    process_exists?(main_pid).should be_true
    process_exists?(child_pid).should be_true

    # kill parent process nicely
    Process.kill("KILL", main_pid)
    Process.waitpid(main_pid)

    # check both processes are no longer active after a few seconds
    sleep 5
    process_exists?(main_pid).should be_false
    process_exists?(child_pid).should be_false
  end

  it "should kill the child process when the timeout interval expires" do
    pipe = IO.pipe
    main_pid = fork do
      child_pid = Adeona.spawn_child(:timeout => 10) do
        # make sure child process keeps existing
        while(true) do
        end
      end

      # send spec process the child_pid
      pipe[0].close
      pipe[1].sync = true
      pipe[1] << "#{child_pid}\n"
      pipe[1].close

      # make sure main process keeps existing
      while(true) do
      end
    end

    # retrieve child_pid
    pipe[1].close
    pipe[0].sync = true
    rd = IO.select([pipe[0]])
    child_pid = rd[0][0].gets.to_i
    pipe[0].close

    # check both processes exist
    process_exists?(main_pid).should be_true
    process_exists?(child_pid).should be_true

    # wait for timeout to occur
    sleep 10

    # check child process is no longer active after a few seconds
    sleep 5
    process_exists?(main_pid).should be_true
    process_exists?(child_pid).should be_false

    # kill main process as well
    Process.kill("TERM", main_pid)
    Process.waitpid(main_pid)
    process_exists?(main_pid).should be_false
  end
end

def process_exists?(pid)
  begin
    Process.getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end
end
