require 'models/instance'

class Operation::InstanceLifecycle < Operation
	def self.is_schedulable?
		false
	end
end
