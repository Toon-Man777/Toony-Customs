local s,id=GetID()
function s.initial_effect(c)
	-- 1. Name is always treated as "Chaos Form"
	local e0=Effect.CreateEffect(c)
	e0:SetType(1) -- EFFECT_TYPE_SINGLE
	e0:SetProperty(0x400 + 0x800) -- CANNOT_DISABLE + UNCOPYABLE
	e0:SetCode(511002961) -- EFFECT_ADD_CODE (or 100 for CHANGE_CODE)
	e0:SetValue(21082832) -- Chaos Form ID
	c:RegisterEffect(e0)

	-- 2. Activation: Search 1 Ritual Monster
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x2 + 0x4) -- CATEGORY_TOHAND + CATEGORY_SEARCH
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 3. Ritual Summon: Shuffle from hand/GY to Deck
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x800) -- CATEGORY_SPECIAL_SUMMON
	e2:SetType(4) -- EFFECT_TYPE_IGNITION
	e2:SetRange(256) -- LOCATION_FZONE
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.rittg)
	e2:SetOperation(s.ritop)
	c:RegisterEffect(e2)

	-- 4. Grant LIGHT effect: Double ATK
	local e3=Effect.CreateEffect(c)
	e3:SetType(16) -- EFFECT_TYPE_FIELD
	e3:SetCode(0x1000000) -- EFFECT_GRANT
	e3:SetRange(256)
	e3:SetTargetRange(4,0)
	e3:SetTarget(function(e,c) return c:IsType(0x80) and c:IsAttribute(0x1) end)
	e3:SetValue(s.light_eff)
	c:RegisterEffect(e3)

	-- 5. Grant DARK effect: Banish Spells/Traps
	local e4=e3:Clone()
	e4:SetTarget(function(e,c) return c:IsType(0x80) and c:IsAttribute(0x2) end)
	e4:SetValue(s.dark_eff)
	c:RegisterEffect(e4)
end

-- Search Operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(function(c) return c:IsType(0x80) and c:IsAbleToHand() end,tp,1,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(3,tp,511)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,64)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- Ritual Logic
function s.ritfilter(c,e,tp)
	return (c:IsSetCard(0xcf) or c:IsSetCard(0x10cf)) and c:IsType(0x80)
		and c:IsCanBeSpecialSummoned(e,130,tp,false,true)
end
function s.mfilter(c)
	return (c:IsAttribute(0x1) or c:IsAttribute(0x2)) and c:IsAbleToDeck()
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mfilter,tp,2+16,0,nil)
		return Duel.IsExistingMatchingCard(aux.RitualUltimateFilter,tp,1,0,1,nil,s.ritfilter,e,tp,mg,nil,Card.GetLevel,"Equal")
	end
	Duel.SetOperationInfo(0,0x800,nil,1,tp,1)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.mfilter,tp,2+16,0,nil)
	Duel.Hint(3,tp,507)
	local tg=Duel.SelectMatchingCard(tp,aux.RitualUltimateFilter,tp,1,0,1,1,nil,s.ritfilter,e,tp,mg,nil,Card.GetLevel,"Equal")
	local tc=tg:GetFirst()
	if tc then
		mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
		Duel.Hint(3,tp,524)
		local mat=mg:SelectWithSumEqual(tp,Card.GetLevel,tc:GetLevel(),1,99,tc)
		tc:SetMaterial(mat)
		Duel.SendtoDeck(mat,nil,2,64)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,130,tp,tp,false,true,1)
		tc:CompleteProcedure()
	end
end

-- Granted Effects Logic
s.light_eff = function()
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(16+0x40) -- TRIGGER_O
	e1:SetCode(1015) -- EVENT_BATTLE_START
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local e2=Effect.CreateEffect(c)
		e2:SetType(1)
		e2:SetCode(100)
		e2:SetValue(c:GetAttack()*2)
		e2:SetReset(0x1fe0000 + 0x80)
		c:RegisterEffect(e2)
	end)
	return e1
end

s.dark_eff = function()
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(4) -- IGNITION
	e1:SetProperty(0x100) -- TARGET
	e1:SetCountLimit(1)
	e1:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,4,0,nil,0x80)
		if chkc then return chkc:IsLocation(8+128) and chkc:IsAbleToRemove() end
		if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,8+128,8+128,1,nil) and ct>0 end
		Duel.Hint(3,tp,502)
		local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,8+128,8+128,1,ct,nil)
		Duel.SetOperationInfo(0,0x20,g,#g,0,0)
	end)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local g=Duel.GetChainInfo(0,0x20000) -- CHAININFO_TARGET_CARDS
		local sg=g:Filter(Card.IsRelateToEffect,nil,e)
		Duel.Remove(sg,0,64)
	end)
	return e1
end