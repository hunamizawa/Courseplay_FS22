--- AI job derived of AIJobCp.
---@class AIJobFieldWorkCp : AIJobCp
AIJobFieldWorkCp = {
	name = "FIELDWORK_CP",
	translations = {
		jobName = "CP_job_fieldWork",
		GenerateButton = "FIELDWORK_BUTTON"
	}
}
local AIJobFieldWorkCp_mt = Class(AIJobFieldWorkCp, AIJobCp)

function AIJobFieldWorkCp.new(isServer, customMt)
	local self = AIJobCp.new(isServer, customMt or AIJobFieldWorkCp_mt)
		
	self.lastPositionX, self.lastPositionZ = math.huge, math.huge
	self.hasValidPosition = false

	self.selectedFieldPlot = FieldPlot(g_currentMission.inGameMenu.ingameMap)
	self.selectedFieldPlot:setVisible(false)
	return self
end

function AIJobFieldWorkCp:setupTasks(isServer)
	AIJobFieldWorkCp:superClass().setupTasks(self, isServer)
	self.fieldWorkTask = AITaskFieldWorkCp.new(isServer, self)
	self:addTask(self.fieldWorkTask)
end

function AIJobFieldWorkCp:setupJobParameters()
	AIJobFieldWorkCp:superClass().setupJobParameters(self)

	-- Adds field position parameter
	self.fieldPositionParameter = AIParameterPosition.new()
	self.fieldPositionParameter.setValue = function (self, x, z)
		self:setPosition(x, z)		
	end
	self.fieldPositionParameter.isCpFieldPositionTarget = true

	self:addNamedParameter("fieldPosition", self.fieldPositionParameter )
	local positionGroup = AIParameterGroup.new(g_i18n:getText("CP_jobParameters_fieldPosition_title"))
	positionGroup:addParameter(self.fieldPositionParameter )
	table.insert(self.groupedParameters, positionGroup)

	self:setupCpJobParameters(nil)
end

function AIJobFieldWorkCp:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobFieldWorkCp:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	
	local x, z = nil

	if vehicle.getLastJob ~= nil then
		local lastJob = vehicle:getLastJob()

		if not isDirectStart and lastJob ~= nil and lastJob.cpJobParameters then
			x, z = lastJob.fieldPositionParameter:getPosition()
		end
	end

	if x == nil or z == nil then
		x, _, z = getWorldTranslation(vehicle.rootNode)
	end

	self.fieldPositionParameter:setPosition(x, z)
end

--- Checks the field position setting.
function AIJobFieldWorkCp:validateFieldSetup(isValid, errorMessage)
	
	local vehicle = self.vehicleParameter:getVehicle()

	-- everything else is valid, now find the field
	local tx, tz = self.fieldPositionParameter:getPosition()
	if tx == self.lastPositionX and tz == self.lastPositionZ then
		CpUtil.debugVehicle(CpDebug.DBG_HUD, vehicle, 'Position did not change, do not generate course again')
		return isValid, errorMessage
	else
		self.lastPositionX, self.lastPositionZ = tx, tz
	end
	
	self.customField = nil
	local fieldNum = CpFieldUtil.getFieldIdAtWorldPosition(tx, tz)
	CpUtil.infoVehicle(vehicle,'Scanning field %d on %s', fieldNum, g_currentMission.missionInfo.mapTitle)
	self.hasValidPosition, self.fieldPolygon = g_fieldScanner:findContour(tx, tz)
	if not self.hasValidPosition then
		local customField = g_customFieldManager:getCustomField(tx, tz)
		if not customField then
			self.selectedFieldPlot:setVisible(false)
			return false, g_i18n:getText("CP_error_not_on_field")
		else
			CpUtil.infoVehicle(vehicle, 'Custom field found: %s, disabling island bypass', customField:getName())
			self.fieldPolygon = customField:getVertices()
			self.customField = customField
			vehicle:getCourseGeneratorSettings().islandBypassMode:setValue(Island.BYPASS_MODE_NONE)
			self.hasValidPosition = true
		end
	end
	if self.fieldPolygon then
		self.selectedFieldPlot:setWaypoints(self.fieldPolygon)
		self.selectedFieldPlot:setVisible(true)
		self.selectedFieldPlot:setBrightColor(true)
	end
end

function AIJobFieldWorkCp:setValues()
	AIJobFieldWorkCp:superClass().setValues(self)
	local vehicle = self.vehicleParameter:getVehicle()
	self.fieldWorkTask:setVehicle(vehicle)
end

--- Called when parameters change, scan field
function AIJobFieldWorkCp:validate(farmId)
	local isValid, errorMessage = AIJobFieldWork:superClass().validate(self, farmId)
	if not isValid then
		return isValid, errorMessage
	end

	local vehicle = self.vehicleParameter:getVehicle()

	isValid, errorMessage = self:validateFieldSetup(isValid, errorMessage)
	if not isValid then
		return isValid, errorMessage
	end

	self.cpJobParameters:validateSettings()
	if not vehicle:hasCpCourse() then 
		return false, g_i18n:getText("CP_error_no_course")
	end
	return true, ''
end

function AIJobFieldWorkCp:drawSelectedField(map)
	if self.selectedFieldPlot then
		self.selectedFieldPlot:draw(map)
	end
end

function AIJobFieldWorkCp:getFieldPositionTarget()
	return self.fieldPositionParameter:getPosition()
end

---@return CustomField or nil Custom field when the user selected a field position on a custom field
function AIJobFieldWorkCp:getCustomField()
	return self.customField
end

function AIJobFieldWorkCp:getCanGenerateFieldWorkCourse()
	return self.hasValidPosition
end

--- Is course generation allowed ?
function AIJobFieldWorkCp:isCourseGenerationAllowed()
	return true
end

function AIJobFieldWorkCp:getCanStartJob()
	local vehicle = self:getVehicle()
	return vehicle and vehicle:hasCpCourse()
end

--- Button callback to generate a field work course.
function AIJobFieldWorkCp:onClickGenerateFieldWorkCourse()
	local vehicle = self.vehicleParameter:getVehicle()
	local settings = vehicle:getCourseGeneratorSettings()
	local status, ok, course = CourseGeneratorInterface.generate(self.fieldPolygon,
			{x = self.lastPositionX, z = self.lastPositionZ},
			settings.isClockwise:getValue(),
			settings.workWidth:getValue(),
			AIUtil.getTurningRadius(vehicle),
			settings.numberOfHeadlands:getValue(),
			settings.startOnHeadland:getValue(),
			settings.headlandCornerType:getValue(),
			settings.headlandOverlapPercent:getValue(),
			settings.centerMode:getValue(),
			settings.rowDirection:getValue(),
			settings.manualRowAngleDeg:getValue(),
			settings.rowsToSkip:getValue(),
			settings.rowsPerLand:getValue(),
			settings.islandBypassMode:getValue(),
			settings.fieldMargin:getValue(),
			settings.multiTools:getValue(),
			self:isPipeOnLeftSide(vehicle)
	)
	CpUtil.debugFormat(CpDebug.DBG_COURSES, 'Course generator returned status %s, ok %s, course %s', status, ok, course)
	if not status then
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_ERROR,
			text = g_i18n:getText('CP_error_could_not_generate_course')
		})
		return false
	end

	vehicle:setFieldWorkCourse(course)
end

function AIJobFieldWorkCp:isPipeOnLeftSide(vehicle)
	if AIUtil.getImplementOrVehicleWithSpecialization(vehicle, Combine) then
		local pipeAttributes = {}
		local combine = ImplementUtil.findCombineObject(vehicle)
		ImplementUtil.setPipeAttributes(pipeAttributes, vehicle, combine)
		return pipeAttributes.pipeOnLeftSide
	else
		return true
	end
end

function AIJobFieldWorkCp:getIsAvailableForVehicle(vehicle)
	return vehicle.getCanStartCpFieldWork and vehicle:getCanStartCpFieldWork()
end

function AIJobFieldWorkCp:resetStartPositionAngle(vehicle)
	AIJobFieldWorkCp:superClass().resetStartPositionAngle(self, vehicle)
	local x, _, z = getWorldTranslation(vehicle.rootNode) 
	self.fieldPositionParameter:setPosition(x, z)
end

--- Ugly hack to fix a mp problem from giants, where the helper is not always reset correctly on the client side.
function AIJobFieldWorkCp:stop(aiMessage)	
	AIJobFieldWorkCp:superClass().stop(self, aiMessage)

	local vehicle = self.vehicleParameter:getVehicle()
	if vehicle and vehicle.spec_aiFieldWorker.isActive then 
		vehicle.spec_aiFieldWorker.isActive = false
	end
end