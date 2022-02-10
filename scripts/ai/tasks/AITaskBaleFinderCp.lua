AITaskBaleFinderCp = {}
local AITaskBaleFinderCp_mt = Class(AITaskBaleFinderCp, AITask)

function AITaskBaleFinderCp.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskBaleFinderCp_mt)
	self.vehicle = nil
	return self
end

function AITaskBaleFinderCp:reset()
	self.vehicle = nil

	AITaskBaleFinderCp:superClass().reset(self)
end

function AITaskBaleFinderCp:update(dt)
end

function AITaskBaleFinderCp:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskBaleFinderCp:start()
	if self.isServer then
		self.vehicle:startCpBaleFinder()
	end

	AITaskBaleFinderCp:superClass().start(self)
end

function AITaskBaleFinderCp:stop()
	AITaskBaleFinderCp:superClass().stop(self)

	if self.isServer then
		self.vehicle:stopFieldWorker()
	end
end
