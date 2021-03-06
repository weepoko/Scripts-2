require "VPrediction"
require "SourceLib"

function OnLoad()
	VP = VPrediction()
	qRng, wRng, eRng, rRng = 600, 625, 1040, 700
	Q = Spell(_Q, qRng)
	W = Spell(_W, wRng):SetSkillshot(VP, SKILLSHOT_CIRCULAR, 300, 0.5, 1750, false)
	E = Spell(_E, eRng):SetSkillshot(VP, SKILLSHOT_LINEAR, 90, 0.5, 1210, false)
	R = Spell(_R, rRng):SetSkillshot(VP, SKILLSHOT_CIRCULAR, 250, 0.5, 1210, false)
	DFG = Item(3128,750)
	Config = scriptConfig("RyukViktor","RyukViktor")
	Config:addParam("active", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("stun", "Stun Prediction", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	Config:addParam("useUlt", "Use Ult", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useStun", "Use Stun", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawq", "Draw Q", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("draww", "Draw W", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawe", "Draw E", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawr", "Draw R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawtext", "Draw Text", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LESS_CAST,rRng,DAMAGE_MAGIC,false)
	ts.name = "Viktor"
	Config:addTS(ts)
	PrintChat("<font color='#E97FA5'>> RyukViktor!</font>")
end

function OnTick()
	ts:update()
	
	if Config.active then 
		fullCombo()
	end
	if ts.target then
		stormControl(ts.target)
	end
	if Config.stun then
		stun()
	end
	
end

function stun()
	if ts.target then
		if W:IsReady() and W:IsInRange(ts.target,myHero) then
			posw = W:GetPrediction(ts.target)
			if posw ~= nil then
					W:Cast(ts.target.x,ts.target.z)
			end
		end
	end
end

function fullCombo()
	if ts.target then
		-- Casting DFG
		if DFG:IsReady() and DFG:InRange(ts.target) then
			DFG:Cast(ts.target)
		end	
		-- Casting Q
		if Q:IsReady() and Q:IsInRange(ts.target,myHero) then
			CastSpell(_Q,ts.target)
		end
		-- Casting W
		if W:IsReady() and W:IsInRange(ts.target,myHero) and Config.useStun then
			posw = W:GetPrediction(ts.target)
			if posw ~= nil then
				if W:IsInRange(ts.target,myHero) and W:IsReady() then
					W:Cast(ts.target.x,ts.target.z)
				end
			end
		end
		-- Casting E
		if E:IsReady() and E:IsInRange(ts.target, myHero) then
			pose = E:GetPrediction(ts.target)
			if pose ~= nil then
				if GetDistance(ts.target) < 540 then
					Packet('S_CAST', { spellId = SPELL_3, fromX = ts.target.x, fromY = ts.target.z, toX = pose.x, toY = pose.z }):send()
				else
					start = Vector(myHero) - 540 * (Vector(myHero) - Vector(ts.target)):normalized()
					Packet('S_CAST', { spellId = SPELL_3, fromX = start.x, fromY = start.z, toX = pose.x, toY = pose.z }):send()
				end
			end
		end
		-- Casting R
		if Config.useUlt and R:IsReady() and R:IsInRange(ts.target, myHero) then
			posr = R:GetPrediction(ts.target)
			if posr ~= nil then
				R:Cast(ts.target.x,ts.target.z)
			end
		end
	end
end

function stormControl(target)
	if myHero:GetSpellData(_R).name == "viktorchaosstormguide" then
		CastSpell(_R, target.x, target.z)
	end
end

function Damage(target)
  if target then
    local qDmg = getDmg("Q", target, myHero)
    local wDmg = getDmg("W", target, myHero)
    local rDmg = getDmg("R", target, myHero)
    local dfgDmg = (GetInventorySlotItem(3128) ~= nil and getDmg("DFG", target, myHero)) or 0
    local damageAmp = (GetInventorySlotItem(3128) ~= nil and 1.2) or 1
		local currentDamage = 0
    
    if Q:IsReady() then
     currentDamage = currentDamage + qDmg
    end
   
    if W:IsReady() then
     currentDamage = currentDamage + wDmg
    end
  
		if R:IsReady() then
			currentDamage = currentDamage + rDmg
		end
	 
    if DFG:IsReady() then
     currentDamage = (currentDamage * damageAmp) + dfgDmg
    end
		return currentDamage
  end
	
end

function OnDraw()
	if Config.drawq then
		DrawCircle(myHero.x,myHero.y,myHero.z,qRng,0xFFFF0000)
	end 
	if Config.draww then
		DrawCircle(myHero.x,myHero.y,myHero.z,wRng,0xFFFF0000)
	end
	if Config.drawe then
		DrawCircle(myHero.x,myHero.y,myHero.z,eRng,0xFFFF0000)
	end
	if Config.drawr then
		DrawCircle(myHero.x,myHero.y,myHero.z,rRng,0xFFFF0000)
	end
	if Config.drawtext then
		for i, target in ipairs(GetEnemyHeroes()) do
			if ValidTarget(target) and target.team ~= myHero.team and target.dead ~= true then
				if Damage(target) > target.health then
					PrintFloatText(target,0,"Killable")
				end
			end
		end
	end
end