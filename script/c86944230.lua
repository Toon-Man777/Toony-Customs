local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 5 "roid" monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter,5,5)

	-- 1. Trigger Effect: Banish all cards on the field and GY, then inflict 4000 damage to both players
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	-- Hard Once Per Duel Count Limit Clause
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.bancon)
	e1:SetTarget(s.bantg)
	e1:SetOperation(s.banop)
	c:RegisterEffect(e1)
end

s.listed_series={0x16} -- "roid"

-- Material filter checking for "roid" archetype cards
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x16,fc,sumtype,tp) and c:IsType(TYPE_MONSTER,fc,sumtype,tp)
end

-- 1. Execution Logic
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- Check if there are any cards on the field or in either GY that can be banished
		return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil)
	end
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,4000)
end
function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,nil)
	if #g>0 then
		-- Banish all legal targets across the field and both GYs simultaneously
		if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
			Duel.BreakEffect()
			-- Inflict 4000 damage to the turn player first, then the opponent
			Duel.Damage(tp,4000,REASON_EFFECT,true)
			Duel.Damage(1-tp,4000,REASON_EFFECT,true)
			Duel.RDamage() -- Synchronizes both damage applications perfectly
		end
	end
end