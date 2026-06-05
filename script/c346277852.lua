local s,id=GetID()
function s.initial_effect(c)
	-- Equip Procedure
	aux.AddEquipProcedure(c,nil,s.eqfilter)

	-- 1. Continuous Effect: Equipped monster's Ignition effects become Quick Effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_IGNITION_TO_QUICK)
	e1:SetCondition(s.quickcon)
	c:RegisterEffect(e1)

	-- 2. Ignition Effect: Once per turn, Special Summon 1 "Meklord Army" monster from your GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 3. Trigger Effect: If sent to the GY by your own card effect, draw 2 cards (Twice per Duel)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(2,id,EFFECT_COUNT_CODE_DUEL)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

s.listed_series={0x13, 0x3013, 0x5013, 0x6013} -- Meklord, Meklord Emperor, Meklord Astro, Meklord Army

-- Equip filter target check
function s.eqfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0x3013) or c:IsSetCard(0x5013))
end

-- 1. Ignition to Quick Effect Condition
function s.quickcon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and (ec:IsSetCard(0x3013) or ec:IsSetCard(0x5013))
end

-- 2. "Meklord Army" GY Special Summon Logic
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x6013) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- 3. Self-Destruction / Send to GY Draw 2 Logic
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Checks if it was sent to GY by a card effect you controlled
	return c:IsReason(REASON_EFFECT) and rp==tp
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end