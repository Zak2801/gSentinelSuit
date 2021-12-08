AddCSLuaFile()

DEFINE_BASECLASS( "base_sentinelsuit" )

ENT.Spawnable = true
ENT.PrintName = "Sentinel Suit"
ENT.Category  = "Zaktak's"


--[[-------------------------
: Config Below
---------------------------]]

ENT.ArmorBonus = 300
ENT.HealthBonus = 1000
ENT.RPMBonus = 1.5 -- ( Multiplier )
--ENT.DamageBonus = 0

ENT.WalkSpeedDebuff = 0.7 -- ( Multiplier )
ENT.RunSpeedDebuff = 0.7 -- ( Multiplier )

--[[-------------------------
: End of Config
---------------------------]]


local function revertVars(ply, wep)
	ply.SentinelSuitSave = ply.SentinelSuitSave or {}

	if ( wep ~= nil ) then
		ply.SentinelSuitSave.wep = ply.SentinelSuitSave.wep or {}
		-- Return RPM Back to original
		if ( wep.Primary ~= nil  ) then
			if ( ply.SentinelSuitSave.wep.RPM ~= nil ) then
				wep.Primary.RPM = ply.SentinelSuitSave.wep.RPM
			end
		end

		-- Return DMG Back to original
		--if ( wep.Primary ~= nil  ) then
		--	if ( ply.SentinelSuitSave.wep.Damage ~= nil ) then
		--		print(wep.Primary.Damage)
		--		wep.Primary.Damage = ply.SentinelSuitSave.wep.Damage
		--	end
		--end
	end
end


local function updateWeps(ply, weps)
	ply:StripWeapons()

	timer.Simple(0, function()
		for k, wep in pairs(weps) do
			ply:Give( wep:GetClass() )
		end
	end)
end


local function oldWeps(ply)
	local weps = ply:GetWeapons()

	for k, wep in pairs(weps) do
		ply.SentinelSuitSave = ply.SentinelSuitSave or {}
		ply.SentinelSuitSave.wep = ply.SentinelSuitSave.wep or {}

		if ( wep.Base ~= nil ) then
			if ( string.find(wep.Base, "tfa") ~= nil ) then
				if ( ply.SentinelSuitSave.wep.RPM ~= nil ) then
					wep.Primary.RPM = ply.SentinelSuitSave.wep.RPM
				end

				--if ( ply.SentinelSuitSave.wep.Damage ~= nil ) then
				--	wep.Primary.Damage = ply.SentinelSuitSave.wep.Damage
				--end
			end
		end
	end

	updateWeps(ply, weps)
end

--use this to calculate the position on the parent because I can't be arsed to deal with source's parenting bullshit with local angles and position
--plus this is also called during that parenting position recompute, so it's perfect

ENT.AttachmentInfo = {
	BoneName = "ValveBiped.Bip01_Spine2",
	OffsetVec = Vector( 8 , -6 , -0.2 ),
	OffsetAng = Angle( 180 , 90 , -90 ),
}

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 36

	local ent = ents.Create( ClassName )
	ent:SetSlotName( ClassName )	--this is the best place to set the slot, only modify it ingame when it's not equipped
	ent:SetPos( SpawnPos )
	ent:SetAngles( Angle( 0 , 0 , 180 ) )
	ent:Spawn()
	
	return ent

end

function ENT:Initialize()
	BaseClass.Initialize( self )
	if SERVER then
		self:SetModel( "models/maxofs2d/hover_rings.mdl" )
		self:SetModelScale(0.5)
		self:InitPhysics()

		self:SetActive( false )
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables( self )
	self:DefineNWVar( "Bool" , "Active" )
end

function ENT:Think()
	return BaseClass.Think( self )
end

function ENT:PredictedThink( owner , movedata )
end

function ENT:PredictedMove( owner , data )
end

function ENT:PredictedFinishMove( owner , movedata )
end


if SERVER then

	function ENT:OnAttach( ply )
		ply:SetModelScale( 1.02, .6 )
		ply:EmitSound( "items/battery_pickup.wav" )
		ply:EmitSound( "HL1/fvox/activated.wav" )
		ply.HasAnnounced10Ssuit = false
		ply.HasAnnounced50Ssuit = false
		ply.HasAnnounced75Ssuit = false
		
		ply.SentinelSuit = true
		ply.OldModel = ply:GetModel()
		ply.OldArmor = ply:Armor()
		ply.OldHealth = ply:Health()
		ply.OldWalkSpeed = ply:GetWalkSpeed()
		ply.OldRunSpeed = ply:GetRunSpeed()

		ply:SetModel("models/valk/h5/unsc/spartan/spartan.mdl")

		ply:SetArmor( ply:Armor() + self.ArmorBonus )
		ply:SetHealth( ply:Health() + self.HealthBonus )

		ply:SetWalkSpeed( ply:GetWalkSpeed() * self.WalkSpeedDebuff )
		ply:SetRunSpeed( ply:GetRunSpeed() * self.RunSpeedDebuff )
		local weps = ply:GetWeapons()
		updateWeps(ply, weps)
	end
	
	function ENT:CanAttach( ply )
	end

	function ENT:OnDrop( ply , forced )
		if ( !IsValid(self) ) then return end

		if IsValid( ply ) and ply:Alive() then
			ply:SetModelScale( 1, .5 )
			self:EmitSound( "HL1/fvox/deactivated.wav" )
			ply.SentinelSuit = false
			if ( ply.OldHealth ~= nil and ply.OldArmor ~= nil ) then
				ply:SetModel( ply.OldModel )
				ply:SetArmor( ply.OldArmor )

				ply:SetWalkSpeed( ply.OldWalkSpeed )
				ply:SetRunSpeed( ply.OldRunSpeed )

				if ( ply:Health() > ply.OldHealth ) then
					ply:SetHealth( ply.OldHealth )
				end

				oldWeps(ply)
			else
				self:EmitSound( "HL1/fvox/hev_critical_fail.wav" )
				ply:SetHealth(100)
				ply:SetArmor(0)
			end

			self:SetActive( false )
			revertVars(ply, wep)
		else
			self:SetActive( false )
		end
	end

	function ENT:OnInitPhysics( physobj )
		if IsValid( physobj ) then
			physobj:SetMass( 75 )
			self:StartMotionController()
		end
		self:SetCollisionGroup( COLLISION_GROUP_NONE )
		--self:SetCollisionGroup( COLLISION_GROUP_WEAPON )	--set to COLLISION_GROUP_NONE to reenable collisions against players and npcs
	end
	
	function ENT:OnRemovePhysics( physobj )
		self:StopMotionController()
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
		--self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	end
	
	function ENT:PhysicsSimulate( physobj , delta )
		
		--no point in applying forces and stuff if something is holding our physobj
		
		if self:GetActive() and not self:GetBeingHeld() then
			physobj:Wake()
			local force = self.StandaloneLinear
			local angular = self.StandaloneAngular
			
			if self:GetGoneApeshit() then
				force = self.StandaloneApeShitLinear
				angular = self.StandaloneApeShitAngular
			end
			
			--yes I know we're technically modifying the variable stored in ENT.StandaloneApeShitLinear and that it might fuck up other jetpacks
			--but it won't because we're simply using it as a cached vector_origin and overriding the z anyway
			force.z = -self:GetJetpackVelocity()
			
			return angular * physobj:GetMass() , force * physobj:GetMass() , SIM_LOCAL_FORCE
		end
	end
	
	function ENT:PhysicsCollide( data , physobj )
		--taken straight from valve's code, it's needed since garry overwrote VPhysicsCollision, friction sound is still there though
		--because he didn't override the VPhysicsFriction
		if data.DeltaTime >= 0.05 and data.Speed >= 70 then
			local volume = data.Speed * data.Speed * ( 1 / ( 320 * 320 ) )
			if volume > 1 then
				volume = 1
			end
			
			--TODO: find a better impact sound for this model
			self:EmitSound( "SolidMetal.ImpactHard" , nil , nil , volume , CHAN_BODY )
		end
	end

else

	function ENT:Draw( flags )
		local pos , ang = self:GetCustomParentOrigin()
		
		--even though the calcabsoluteposition hook should already prevent this, it doesn't on other players
		--might as well not give it the benefit of the doubt in the first place
		if pos and ang then
			self:SetPos( pos )
			self:SetAngles( ang )
			self:SetupBones()
		end
		
		self:DrawModel( flags )
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove( self )
end

--------


hook.Add("PlayerSpawn", "SentinelSuit Handle Player Spawn", function(ply)
	if ( !IsValid(ply) ) then return end
	ply.SentinelSuit = false
	local weps = ply:GetWeapons()
	for k, v in pairs(weps) do
		revertVars(ply, v)
	end
end)


hook.Add("EntityTakeDamage", "SentinelSuit Handle Damage", function(ent, info)
	if ( !ent:IsPlayer() or !IsValid(ent) ) then return end

	if ( ent.SentinelSuit and ent:GetClass() == "zk_sentinel_suit" ) then
		local vars = scripted_ents.Get( "zk_sentinel_suit" )
		local HP_Bonus = vars.HealthBonus
		if ( ent:Health() <= 0.15 * ( ent.OldHealth + HP_Bonus ) ) then
			if ( ent.HasAnnounced10Ssuit == false or ent.HasAnnounced10Ssuit == nil ) then
				ent:EmitSound( "HL1/fvox/health_critical.wav" )
				ent.HasAnnounced10Ssuit = true
			end
		elseif ( ent:Health() <= 0.45 * ( ent.OldHealth + HP_Bonus ) ) then
			if ( ent.HasAnnounced50Ssuit == false or ent.HasAnnounced50Ssuit == nil ) then
				ent:EmitSound( "HL1/fvox/health_dropping2.wav" )
				ent.HasAnnounced50Ssuit = true
			end
		elseif ( ent:Health() <= 0.75 * ( ent.OldHealth + HP_Bonus ) ) then
			if ( ent.HasAnnounced75Ssuit == false or ent.HasAnnounced75Ssuit == nil ) then
				ent:EmitSound( "HL1/fvox/health_dropping.wav" )
				ent.HasAnnounced75Ssuit = true
			end
		end
	end
end)


hook.Add("PlayerSwitchWeapon", "SentinelSuit PlayerSwitchWeapon", function( ply, oldwep, wep )
	if CLIENT then return end

	local vars = scripted_ents.Get( "zk_sentinel_suit" )
	local RPM_Bonus = vars.RPMBonus
	--local DMG_Bonus = vars.DamageBonus

	revertVars(ply, oldwep)
	revertVars(ply, wep)

	if ( ply.SentinelSuit == false or ply.SentinelSuit == nil ) then return end
	if ( wep.Primary == nil or wep.Primary.RPM == nil --[[or wep.Primary.Damage == nil--]] ) then return end
	if ( RPM_Bonus == nil or DMG_Bonus == nil ) then return end
	
	-- Save old RPM
	ply.SentinelSuitSave.wep.RPM = wep.Primary.RPM
	-- Update RPM
	wep.Primary.RPM = wep.Primary.RPM * RPM_Bonus

	-- Save old DMG
	--ply.SentinelSuitSave.wep.Damage = wep.Primary.Damage
	-- Update DMG
	--wep.Primary.Damage = wep.Primary.Damage + DMG_Bonus
end)



-- Old method of bonus dmg and rpm under think method
--[[
	owner.sentinel_oldrpm = owner.sentinel_oldrpm or {}
	owner.sentinel_olddmg = owner.sentinel_olddmg or {}
	local wep = owner:GetActiveWeapon()

	if ( wep.Base ~= nil ) then
		if ( string.find(wep.Base, "tfa") ~= nil ) then
			if ( owner.sentinel_oldrpm.wep == nil ) then
				owner.sentinel_oldrpm.wep = wep.Primary.RPM
			end
			
			if ( owner.sentinel_olddmg.wep == nil ) then
				owner.sentinel_olddmg.wep = wep.Primary.Damage
			end	
		end

		if ( wep.Primary.RPM ~= nil ) then
			wep.Primary.RPM = wep.Primary.RPM + self.RPMBonus
		end

		if ( wep.Primary.Damage ~= nil ) then
			wep.Primary.Damage = wep.Primary.Damage + self.DamageBonus
		end
	end
	]]