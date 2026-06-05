local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Materials: 1 "Edge Imp" Monster + 2 "Fluffal" Monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter2,2,2,s.matfilter1)

	-- 1. Continuous Effect: Cannot be destroyed by opponent's card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(aux.indoval)
	c:RegisterEffect(e1)

	-- 2. Continuous Effect: "Frightfur" monsters gain 200 ATK for every Fairy/Fiend in both GYs
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xad))
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- 3. Trigger Effect: When this card destroys a monster by battle, Special Summon it as a "Frightfur" monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdgcon)
	e3:SetTarget(s.sptg1)
	e3:SetOperation(s.spop1)
	c:RegisterEffect(e3)

	-- 4. Ignition Effect: Banish 1 monster from either GY to Special Summon 1 "Frightfur" from Extra Deck with equal or lower Level
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

s.listed_series={0xc1, 0xa9, 0xad} -- Edge Imp, Fluffal, Frightfur

-- Material Helper Filters
function s.matfilter1(c,fc,sumtype,tp)
	return c:IsSetCard(0xc1,fc,sumtype,tp) -- "Edge Imp"
end
function s.matfilter2(c,fc,sumtype,tp)
	return c:IsSetCard(0xa9,fc,sumtype,tp) -- "Fluffal"
end

-- 2. Global ATK Calculation Logic
function s.atkfilter(c)
	return c:IsMonster() and (c:IsRace(RACE_FAIRY) or c:IsRace(RACE_FIEND))
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,e:GetHandlerPlayer(),LOCATION_GRAVE,LOCATION_GRAVE,nil)*200
end

-- 3. Battle Destruction Steal & Sub-Archetype Overwrite Logic
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=e:GetHandler():GetBattleTarget()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and tc:IsLocation(LOCATION_GRAVE) and tc:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		local c=e:GetHandler()
		-- Dynamically alters its identity traits to legally count as a "Frightfur" monster on your field
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_SETCODE)
		e1:SetValue(0xad) -- "Frightfur" setcode
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- 4. Graveyard Banish & Cheat Out From Extra Deck Logic
function s.rmfilter(c,e,tp)
	return c:IsMonster() and c:IsAbleToRemove() and c:HasLevel()
		and Duel.IsExistingMatchingCard(s.exspfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c:GetLevel())
end
function s.exspfilter(c,e,tp,lv)
	return c:IsSetCard(0xad) and c:IsType(TYPE_FUSION) and c:HasLevel() and c:GetLevel()<=lv
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,e,tp)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 then
		local lv=g:GetFirst():GetLevel()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=Duel.SelectMatchingCard(tp,s.exspfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv):GetFirst()
		if sc then
			Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end