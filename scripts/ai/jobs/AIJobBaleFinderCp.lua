--- Bale finder job.
---@class AIJobBaleFinderCp : AIJobFieldWorkCp
AIJobBaleFinderCp = {
	name = "BALE_FINDER_CP",
	translations = {
		jobName = "CP_job_baleFinder"
	}
}
local AIJobBaleFinderCp_mt = Class(AIJobBaleFinderCp, AIJobFieldWorkCp)


function AIJobBaleFinderCp.new(isServer, customMt)
	local self = AIJobFieldWorkCp.new(isServer, customMt or AIJobBaleFinderCp_mt)
	
	return self
end

function AIJobBaleFinderCp:setupTasks(isServer)
	AIJobCp.setupTasks(self, isServer)
	self.baleFinderTask = AITaskBaleFinderCp.new(isServer, self)
	self:addTask(self.baleFinderTask)
end

function AIJobBaleFinderCp:setupCpJobParameters()
	--- No cp job parameters needed for now.
end

--- Disables course generation.
function AIJobBaleFinderCp:getCanGenerateFieldWorkCourse()
	return false
end

--- Disables course generation.
function AIJobBaleFinderCp:isCourseGenerationAllowed()
	return false
end

function AIJobBaleFinderCp:getIsAvailableForVehicle(vehicle)
	return vehicle.getCanStartCpBaleFinder and vehicle:getCanStartCpBaleFinder()
end

function AIJobBaleFinderCp:getCanStartJob()
	return self.hasValidPosition
end


function AIJobBaleFinderCp:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobBaleFinderCp:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
end

function AIJobBaleFinderCp:setValues()
	AIJobCp.setValues(self)
	local vehicle = self.vehicleParameter:getVehicle()
	self.baleFinderTask:setVehicle(vehicle)
end

--- Called when parameters change, scan field
function AIJobBaleFinderCp:validate(farmId)
	local isValid, errorMessage = AIJobCp.validate(self, farmId)
	if not isValid then
		return isValid, errorMessage
	end
	isValid, errorMessage = self:validateFieldSetup(isValid, errorMessage)
	return isValid, errorMessage
end
