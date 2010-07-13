require 'facter'

Facter.add(:kernel) do
    setcode do
        require 'rbconfig'
        case Config::CONFIG['host_os']
          when /(mswin|ming|w32)/i; 'windows' # fix kernel setup when using ruby compiled with ming on windows
          else Facter::Util::Resolution.exec("uname -s")
        end
    end
end

module Facter
  def self.processor_count
    loadfacts
    processors = case Facter.kernel.downcase.to_sym
      when :windows;
        require 'win32ole'
        numprocs = 1
        wmi = WIN32OLE.connect("winmgmts://")
        wmi.ExecQuery("select NumberOfProcessors from Win32_ComputerSystem").each do |ole|
          numprocs = ole.NumberOfProcessors
          break
        end
        numprocs      
      when :darwin;
        Integer(sp_number_processors)
      when :linux;
        Integer(processorcount)
      else
        1
    end
  end
end

