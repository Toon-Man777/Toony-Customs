local s,id=GetID()
function s.initial_effect(c)
	-- Activation: Special Summon 1 Level 4 or lower "Iron Chain"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- Main Deck Lock: While controlling 2+ "Iron Chain" monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(16) -- EFFECT_TYPE_FIELD
	e2:SetCode(460) -- EFFECT_CANNOT_SPECIAL_SUMMON
	e2:SetRange(256) -- LOCATION_FZONE (Changed from 8 to 256)
	e2:SetProperty(0x4000000) -- EFFECT_FLAG_PLAYER_TARGET
	e2:SetTargetRange(1,1) 
	e2:SetCondition(s.lockcon)
	e2:SetTarget(s.locktg)
	c:RegisterEffect(e2)

	-- Stat Boost: All "Iron Chain" gain 800 ATK/DEF
	local e3=Effect.CreateEffect(c)
	e3:SetType(16)
	e3:SetCode(100) -- EFFECT_UPDATE_ATTACK
	e3:SetRange(256) -- LOCATION_FZONE
	e3:SetTargetRange(4,0) 
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x25))
	e3:SetValue(800)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(101) -- EFFECT_UPDATE_DEFENSE
	c:RegisterEffect(e4)

	-- Banish Redirect (Mill replacement)
	local e5=Effect.CreateEffect(c)
	e5:SetType(16)
	e5:SetCode(133) -- EFFECT_TO_GRAVE_REDIRECT
	e5:SetRange(256) -- LOCATION_FZONE
	e5:SetTargetRange(0,1) -- Affects opponent's cards
	e5:SetTarget(s.rdtg)
	e5:SetValue(32) -- LOCATION_REMOVED
	c:RegisterEffect(e5)
end

-- Activation Logic
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x1,nil,1,tp,1)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c,e,tp) return c:IsSetCard(0x25) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1,0,nil,e,tp)
	if #g>0 and Duel.GetLocationCount(tp,4)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(3,tp,509)
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,1)
	end
end

-- Lock Logic
function s.lockcon(e)
	return Duel.IsExistingMatchingCard(Card.IsSetCard,e:GetHandlerPlayer(),4,0,2,nil,0x25)
end
function s.locktg(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(1) and not c:IsSetCard(0x25)
end

-- Redirect Logic
function s.rdtg(e,c)
	return c:IsLocation(1) and c:GetOwner()~=e:GetHandlerPlayer()
end