Gem::Specification.new do |s|
  s.name        = 'adeona'
  s.version     = '0.0.1'
  s.date        = '2012-04-15'
  s.summary     = "A module that makes it easy to create child processes that die when their parent process is killed."
  s.description = "A module that makes it easy to create child processes that die when their parent process is killed. It works even if the parent is disabled with SIGKILL. It also avoids busy waiting."
  s.authors     = ["Tom Van Eyck"]
  s.email       = 'tomvaneyck@gmail.com'
  s.files       = ["lib/adeona.rb"]
  s.homepage    = 'https://github.com/vaneyckt/Adeona'
end
