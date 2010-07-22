class Operations::RabbitMq < Operation
	def self.label
		'RabbitMQ'
	end

	def self.is_schedulable?
		false
	end
end
