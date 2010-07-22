class Operation::Emissary < Operation
	def self.label
		'Emissary'
	end

	def self.is_schedulable?
		false
	end
end
