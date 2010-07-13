class Operation::Step
	attr_reader :name
	attr_accessor :result_code, :result_message

	def initialize name, &block
		@block = block
	end

	def execute
		@block.call
	end
end
