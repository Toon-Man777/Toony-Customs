local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: 5 "Roid" monsters
	Fusion.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x16),5)
	c:EnableReviveSelection()

	-- Banish all and Burn 4000
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	-- Once per duel activation
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL) 
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

s.listed_series={0x16} -- Roid setcode

-- Check if it was Fusion Summoned
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-- Target logic for banishing field and GY
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc = LOCATION_ONFIELD + LOCATION_GRAVE
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,loc,loc,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,loc,loc,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,4000)
end

-- Execution: Banish and deal 4000 damage to both
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local loc = LOCATION_ONFIELD + LOCATION_GRAVE
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,loc,loc,nil)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		-- Inflict damage to both players simultaneously
		Duel.Damage(tp,4000,REASON_EFFECT,true)
		Duel.Damage(1-tp,4000,REASON_EFFECT,true)
		Duel.RDPMsgForBoth(tp,4000)
	end
end