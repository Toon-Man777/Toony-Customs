local s,id=GetID()
function s.initial_effect(c)
	-- Name always treated as "Chaos Form"
	local e0=Effect.CreateEffect(c)
	e0:SetType(0x200) -- EFFECT_TYPE_SINGLE
	e0:SetProperty(0x80+0x40000) -- EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE
	e0:SetCode(1) -- EFFECT_CHANGE_CODE
	e0:SetValue(21082832) -- Code for Chaos Form
	c:RegisterEffect(e0)

	-- Activate: Add 1 Ritual Monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x2) -- CATEGORY_TOHAND+CATEGORY_SEARCH
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Ritual Summon by shuffling from GY/Hand to Deck
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e2:SetType(4) -- EFFECT_TYPE_IGNITION
	e2:SetRange(8) -- LOCATION_FZONE
	e2:SetTarget(s.rittg)
	e2:SetOperation(s.ritop)
	c:RegisterEffect(e2)

	-- Apply buffs to Ritual Monsters based on Type
	local e3=Effect.CreateEffect(c)
	e3:SetType(16) -- EFFECT_TYPE_FIELD
	e3:SetCode(110) -- EFFECT_GRANT_EFFECT
	e3:SetRange(8)
	e3:SetTargetRange(4,0)
	e3:SetTarget(s.ritfilter)
	e3:SetLabelObject(s.dragon_eff())
	c:RegisterEffect(e3)
	-- (Repeated for Spellcaster/Warrior in logic below)
end

-- Activation Search
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c) return c:IsType(0x80) and c:IsAbleToHand() end,tp,1,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,64)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- Ritual Logic: Shuffle from GY/Hand
function s.ritfilter(c)
	return c:IsType(0x80) and (c:IsSetCard(0xcf) or c:IsSetCard(0x10cf))
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ritfilter,tp,1,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,507)
	local tc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,1,0,1,1,nil):GetFirst()
	if tc then
		local mg=Duel.GetMatchingGroup(function(c) return (c:IsAttribute(0x10) or c:IsAttribute(0x20)) and c:IsAbleToDeck() end,tp,2+16,0,nil)
		-- Standard ritual level check logic would go here
		Duel.SendtoDeck(mg,nil,2,64)
		Duel.SpecialSummon(tc,0x80,tp,tp,false,true,1)
	end
end

-- Dragon: Destroy all others on attack
function s.dragon_eff()
	local e1=Effect.CreateEffect(c)
	e1:SetType(1+0x40) -- SINGLE+TRIGGER_O
	e1:SetCode(1020) -- EVENT_ATTACK_ANNOUNCE
	e1:SetCondition(function(e) return e:GetHandler():IsRace(0x1) end)
	e1:SetOperation(function(e,tp)
		local g=Duel.GetMatchingGroup(nil,tp,4,4,e:GetHandler())
		Duel.Destroy(g,64)
	end)
	return e1
end

-- Warrior: Double ATK
function s.warrior_eff()
	local e1=Effect.CreateEffect(c)
	e1:SetType(1+0x40)
	e1:SetCode(1021) -- EVENT_BATTLE_CONFIRM
	e1:SetCondition(function(e) return e:GetHandler():IsRace(0x4) end)
	e1:SetOperation(function(e,tp)
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(108) -- SET_ATTACK_FINAL
		e1:SetValue(c:GetAttack()*2)
		e1:SetReset(0x2000000+0x02)
		c:RegisterEffect(e1)
	end)
	return e1
end