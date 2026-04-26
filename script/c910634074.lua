local s,id=GetID()
function s.initial_effect(c)
	-- Activation: Special Summon 1 Level 4 or lower "Iron Chain"
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x1) -- CATEGORY_SPECIAL_SUMMON
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Opponent cannot Special Summon 2 or more at once
	local e2=Effect.CreateEffect(c)
	e2:SetType(16) -- EFFECT_TYPE_FIELD
	e2:SetCode(460) -- EFFECT_CANNOT_SPECIAL_SUMMON
	e2:SetRange(8) -- LOCATION_FZONE
	e2:SetProperty(0x4000000) -- EFFECT_FLAG_PLAYER_TARGET
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.limcon)
	e2:SetTarget(s.sumlimit)
	c:RegisterEffect(e2)

	-- All "Iron Chain" monsters gain 800 ATK/DEF
	local e3=Effect.CreateEffect(c)
	e3:SetType(16)
	e3:SetCode(100) -- EFFECT_UPDATE_ATTACK
	e3:SetRange(8)
	e3:SetTargetRange(4,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x25))
	e3:SetValue(800)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(101) -- EFFECT_UPDATE_DEFENSE
	c:RegisterEffect(e4)

	-- Once per turn: Banish instead of sending to GY
	local e5=Effect.CreateEffect(c)
	e5:SetType(16)
	e5:SetCode(133) -- EFFECT_BUREAU_REDIRECT
	e5:SetRange(8)
	e5:SetProperty(0x100) -- EFFECT_FLAG_CARD_TARGET
	e5:SetCountLimit(1)
	e5:SetCondition(s.banishcon)
	e5:SetOperation(s.banishop)
	c:RegisterEffect(e5)
end

-- Activation Summon Logic
function s.filter(c,e,tp)
	return c:IsSetCard(0x25) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,1+16,0,nil,e,tp)
	if #g>0 and Duel.GetLocationCount(tp,4)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(3,tp,509)
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,1)
	end
end

-- Summon Restriction Logic (When controlling 2+ Iron Chains)
function s.limcon(e)
	return Duel.IsExistingMatchingCard(Card.IsSetCard,e:GetHandlerPlayer(),4,0,2,nil,0x25)
end
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- Blocks effects that summon multiple monsters (like Pendulum or Soul Charge)
	return se and se:IsHasCategory(0x1) and Duel.GetLocationCount(targetp,4)>1
end

-- Redirection Logic
function s.banishcon(e,tp,eg,ep,ev,re,r,rp)
	-- Triggers when an "Iron Chain" effect is about to send an opponent's card to GY
	return re and re:GetHandler():IsSetCard(0x25)
end
function s.banishop(e,tp,eg,ep,ev,re,r,rp)
	-- Replaces the "Send to GY" event with Banish
	Duel.Banish(eg,0,64)
end