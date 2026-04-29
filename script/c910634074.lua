local s,id=GetID()
function s.initial_effect(c)
	-- Activation: Special Summon 1 Level 4 or lower "Iron Chain"
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Main Deck Lock: While controlling 2+ "Iron Chain" monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(16) -- EFFECT_TYPE_FIELD
	e2:SetCode(460) -- EFFECT_CANNOT_SPECIAL_SUMMON
	e2:SetRange(8) -- LOCATION_SZONE (Field slot)
	e2:SetProperty(0x4000000) -- EFFECT_FLAG_PLAYER_TARGET
	e2:SetTargetRange(1,1) -- Both players
	e2:SetCondition(s.lockcon)
	e2:SetTarget(s.locktg)
	c:RegisterEffect(e2)

	-- Stat Boost: All "Iron Chain" gain 800 ATK/DEF
	local e3=Effect.CreateEffect(c)
	e3:SetType(16)
	e3:SetCode(100) -- EFFECT_UPDATE_ATTACK
	e3:SetRange(8)
	e3:SetTargetRange(4,0) -- Your monsters
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x25))
	e3:SetValue(800)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(101) -- EFFECT_UPDATE_DEFENSE
	c:RegisterEffect(e4)

	-- Banish Mill Replacement
	local e5=Effect.CreateEffect(c)
	e5:SetType(16)
	e5:SetCode(133) -- EFFECT_BUREAU_REDIRECT (Redirecting to Grave)
	e5:SetProperty(0x800000) -- EFFECT_FLAG_SET_AVAILABLE
	e5:SetRange(8)
	e5:SetTargetRange(0,1) -- Affects opponent's cards
	e5:SetTarget(s.rdtg)
	e5:SetValue(32) -- LOCATION_REMOVED
	c:RegisterEffect(e5)
end

-- Activation SS Logic
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c,e,tp) return c:IsSetCard(0x25) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,tp,1,0,nil,e,tp)
	if #g>0 and Duel.GetLocationCount(tp,4)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,1)
	end
end

-- Special Summon Lock Logic
function s.lockcon(e)
	-- Requirement: Control 2+ Iron Chains
	return Duel.IsExistingMatchingCard(Card.IsSetCard,e:GetHandlerPlayer(),4,0,2,nil,0x25)
end
function s.locktg(e,c,sump,sumtype,sumpos,targetp,se)
	-- Blocks SS from Main Deck (Location 1) except Iron Chains
	return c:IsLocation(1) and not c:IsSetCard(0x25)
end

-- Banish Redirect Logic (Mill replacement)
function s.rdtg(e,c)
	-- Triggered if a card from the opponent's Deck is headed to the GY
	return c:IsLocation(1) and c:GetOwner()~=e:GetHandlerPlayer()
end