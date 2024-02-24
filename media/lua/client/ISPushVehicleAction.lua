require "TimedActions/ISBaseTimedAction"

ISPushVehicleAction = ISBaseTimedAction:derive("ISPushVehicleAction");

local forceVector = Vector3f.new();
local positionVector = Vector3f.new();

function ISPushVehicleAction:isValid() 
    return true;
end

function ISPushVehicleAction:start()
    self.character:facePosition(self.vehicle:getX(), self.vehicle:getY());
    self:setActionAnim("Loot");
end

--- Perform the Push Vehicle Action
function ISPushVehicleAction:perform()
    print("Starting PVA:perform()");
    local halfLen = self.vehicle:getScript():getPhysicsChassisShape():z()/2;
    local x =0; 
    local z = 0;
    local fX = 0; 
    local fZ = 0;
    local forceCoeff = 20;

    -- switch (self.pushDir) {
    local pushAction = {
        ['Front'] = function() 
            fZ = -1; forceCoeff = 140; end,
        ['Rear'] = function()
            fZ = 1; forceCoeff = 140; end,

        ['LeftFront'] = function()
            fX = -1; z = halfLen; forceCoeff = 50; end,
        ['LeftRear'] = function()
            fX = -1; z = -halfLen; forceCoeff = 50; end,

        ['RightFront'] = function()
            fX = 1; z = halfLen; forceCoeff = 50; end,
        ['RightRear'] = function()
            fX = 1; z = -halfLen; forceCoeff = 50; end,
    };

    pushAction[self.pushDir]();
    -- }

    -- Calculate the force vectors on the client
    local forceVec = self.vehicle:getWorldPos(fX, 0 , fZ, forceVector):add(-self.vehicle:getX(), -self.vehicle:getY(), -self.vehicle:getZ());
    local pushPoint = self.vehicle:getWorldPos(x, 0, z, positionVector):add(-self.vehicle:getX(), -self.vehicle:getY(), -self.vehicle:getZ())
    pushPoint:set(pushPoint:x(), 0, pushPoint:y());

    local force = 0.1 * self.character:getPerkLevel(Perks.Strength);
    -- When push axis aligned, less effort
    if self.pushDir == 'Front' or 'Rear' then
        force = force * 2
    end
    -- print("Applying '" .. force .. "' force to vehicle")
    forceVec:mul(forceCoeff * force * self.vehicle:getMass());
    forceVec:set(forceVec:x(), 0, forceVec:y());

    -- Shove the car
    self.vehicle:setPhysicsActive(true);
    self.vehicle:addImpulse(forceVec, pushPoint);

    -- Fatigue player
    local enduranceFactor = self.character:getPerkLevel(Perks.Fitness);
    enduranceFactor = math.min(1, enduranceFactor) * 2;
    
    -- When push axis aligned, less effort
    if self.pushDir == 'Front' or 'Rear' then
        enduranceFactor = enduranceFactor * 2;
    end

    -- Reduce Endurance/Increase Fatigue
    local enduranceHit = self.character:getStats():getEndurance() - (1 / enduranceFactor);
    self.character:getStats():setEndurance(enduranceHit);
    -- This part actually burns calories (AFAICT??)
    self.character:setMetabolicTarget(Metabolics.MediumWork);


    self.character:getXp():AddXP(Perks.Strength, 5);
    self.character:getXp():AddXP(Perks.Fitness, 5);

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISPushVehicleAction:stop()
    ISBaseTimedAction:stop(self);
end

--- func desc
---@param character IsoPlayer
---@param vehicle IsoVehicle
---@param pushDirection EPushType
function ISPushVehicleAction:new(character, vehicle, pushDirection)
    local o = {};
    setmetatable(o, self);
    self.__index = self;

    o.stopOnWalk, o.stopOnRun = true, true;    
    o.maxTime = 5;
    o.character = character;
    o.vehicle = vehicle;
    o.pushDir = pushDirection;
    return o;
end
