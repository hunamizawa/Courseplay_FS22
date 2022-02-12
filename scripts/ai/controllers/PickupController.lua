--- Raises/lowers the pickup.
---@class PickupController : ImplementController
PickupController = CpObject(ImplementController)

function PickupController:init(vehicle, implement)
    ImplementController.init(self, vehicle, implement)
    self.pickupSpec = self.implement.spec_pickup
end

function PickupController:onLowering()
	self.implement:setPickupState(true)
end

function PickupController:onRaising()
	self.implement:setPickupState(false)
end

function PickupController:onFinished()
	self.implement:setPickupState(false)
end
