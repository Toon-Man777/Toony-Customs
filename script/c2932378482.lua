local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Materials: 3 Level 5 LIGHT Machine Monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,3)

	-- Protection: Cannot be destroyed by Level/Rank 9 or lower, or Link 3 or lower
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(30) -- EFFECT_INDESTRUCTABLE_BY_BATTLE
	e1:SetValue(s.indes)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(31) -- EFFECT_INDESTRUCTABLE_BY_EFFECT
	c:RegisterEffect(e2)

	-- Standby Phase: Gains 3000 ATK
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- Atk becomes 1000 at end of damage step
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_DAMAGE_STEP_END)
	e4:SetOperation(s.atkreset)
	c:RegisterEffect(e4)

	-- On destruction: Special Summon materials from GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetCountLimit(1,id)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)
end

-- Filter for Fusion Materials
function s.matfilter(c,fc,sumtype,tp)
	return c:IsLevel(5) and c:IsAttribute(ATTRIBUTE_LIGHT,fc,sumtype,tp) and c:IsRace(RACE_MACHINE,fc,sumtype,tp)
end

-- Battle/Effect Protection Logic
function s.indes(e,c)
	local lv=c:GetLevel()
	local rk=c:GetRank()
	local lk=c:GetLink()
	-- Level/Rank 9 or lower, or Link 3 or lower
	return (lv>0 and lv<=9) or (rk>0 and rk<=9) or (lk>0 and lk<=3)
end

-- ATK Gain Logic
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(3000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- ATK Reset Logic
function s.atkreset(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToBattle() and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- Floating Effect
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>=#mg and #mg>0 
		and mg:FilterCount(aux.NecroValleyFilter(Card.IsCanBeSpecialSummoned),nil,e,0,tp,false,false)==#mg end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,mg,#mg,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<#mg then return end
	for tc in aux.Next(mg) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
			-- Negate effects
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	end
	Duel.SpecialSummonComplete()
end