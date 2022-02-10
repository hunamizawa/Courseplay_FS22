AITaskFieldWorkCp = {}
local AITaskFieldWorkCp_mt = Class(AITaskFieldWorkCp, AITaskFieldWork)

function AITaskFieldWorkCp.new(isServer, job, customMt)
	local self = AITaskFieldWork.new(isServer, job, customMt or AITaskFieldWorkCp_mt)

	return self
end

--- Makes sure the cp fieldworker gets started.
function AITaskFieldWorkCp:start()
	if self.isServer then
		self.vehicle:cpStartFieldWorker(self.job:getCpJobParameters())
	end
	AITask.start(self)
	
end
