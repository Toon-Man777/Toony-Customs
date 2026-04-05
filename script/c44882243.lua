-- Curtain of Chaos
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Continuous Spell
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- Main Effect (Ignition)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

-- Filter for Level 7+ Chaos Spellcasters
function s.chaosfilter(c,e,tp)
	return c:IsLevelAbove(7) and c:IsSetCard(0xcf) and c:IsRace(RACE_SPELLCASTER) 
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and chkc:IsRace(RACE_SPELLCASTER) and chkc:IsAbleToRemove() end
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingTarget(Card.IsRace,tp,LOCATION_GRAVE,0,1,nil,RACE_SPELLCASTER) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsRace,tp,LOCATION_GRAVE,0,1,3,nil,RACE_SPELLCASTER)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg==0 then return end
	
	-- Banish targeted cards and count how many actually hit the banish zone
	local ct=Duel.Remove(tg,POS_FACEUP,REASON_EFFECT)
	if ct==0 then return end
	
	local sc=nil
	if ct==1 then
		-- 1: "Dark Magician Girl"
		sc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,nil,38033121)
	elseif ct==2 then
		-- 2: "Dark Magician"
		sc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,nil,46986414)
	elseif ct==3 then
		-- 3: Level 7+ "Chaos" Spellcaster (ignoring conditions)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.chaosfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		sc=g:GetFirst()
	end
	
	-- Perform Special Summon for turn player
	local res=false
	if sc and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		if ct==3 then
			res=Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)
		else
			res=Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
	
	-- Opponent's optional Special Summon (after resolution)
	if res and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 then
		local og=Duel.GetMatchingGroup(Card.IsRace,1-tp,LOCATION_DECK+LOCATION_EXTRA,0,nil,RACE_SPELLCASTER)
		if #og>0 and Duel.SelectYesNo(1-tp, aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
			local sg=og:Select(1-tp,1,1,nil)
			Duel.SpecialSummon(sg,0,1-tp,1-tp,false,false,POS_FACEUP)
		end
	end
end