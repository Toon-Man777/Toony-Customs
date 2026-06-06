local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2+ Level 1 Fairy monsters
	Xyz.AddProcedure(c,s.xyzfilter,1,2,nil,nil,99)
	c:EnableReviveLimit()

	-- Effect 1: Treated as "Mokey Mokey" while on the field or in the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e1:SetValue(27288416) -- Original "Mokey Mokey" card code
	c:RegisterEffect(e1)

	-- Effect 2: You take no battle damage involving this card
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- Effect 3: ATK/DEF multiplies for each Xyz material attached
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_SET_ATTACK_FINAL)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.statval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
	c:RegisterEffect(e4)

	-- Effect 4: Once per turn: Detach 1 material to draw 1 card, then attach 1 "Mokey Mokey"
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DRAW)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCost(s.drcost)
	e5:SetTarget(s.drtg)
	e5:SetOperation(s.drop)
	c:RegisterEffect(e5)
end

s.listed_names={27288416} -- "Mokey Mokey"
s.listed_series={0x184}   -- Mokey Mokey Archetype

-- Xyz Materials Filter
function s.xyzfilter(c,xyzc,sumtype,tp)
	return c:IsRace(RACE_FAIRY,xyzc,sumtype,tp)
end

-- Updated Stat Multiplication Logic (Total Xyz Material Count)
function s.statval(e,c)
	local base_atk = 600
	local base_def = 200
	local count = c:GetOverlayCount() -- Now cleanly checks total materials attached
	
	if count == 0 then 
		return e:GetCode() == EFFECT_SET_ATTACK_FINAL and base_atk or base_def
	end
	
	if e:GetCode() == EFFECT_SET_ATTACK_FINAL then
		return base_atk * count
	else
		return base_def * count
	end
end

-- Detach, Draw, and Re-attach Handlers
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.attfilter(c)
	return c:IsCode(27288416) or c:IsSetCard(0x184)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	local c=e:GetHandler()
	
	-- Draw 1 card
	if Duel.Draw(p,d,REASON_EFFECT) > 0 and c:IsRelateToEffect(e) and c:IsFaceup() then
		-- Optional: Attach 1 "Mokey Mokey" card from hand
		local g=Duel.GetMatchingGroup(s.attfilter,tp,LOCATION_HAND,0,nil)
		if #g > 0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local sg=g:Select(tp,1,1,nil)
			if #sg > 0 then
				Duel.Overlay(c,sg)
			end
		end
	end
end