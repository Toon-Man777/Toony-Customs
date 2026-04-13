local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Special Summon 1 "D/D" monster from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Once per turn
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Listed Series: "D/D" (0xaf)
s.listed_series={0xaf}

-- Check for 2 "D/D" cards in Pendulum Zones with different scales
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local l=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local r=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	if not (l and r and l:IsSetCard(0xaf) and r:IsSetCard(0xaf)) then return false end
	return l:GetLeftScale()~=r:GetRightScale()
end

-- Filter for a "D/D" monster with a Level between the scales
function s.spfilter(c,e,tp,lscale,rscale)
	if lscale>rscale then lscale,rscale=rscale,lscale end
	local lv=c:GetLevel()
	return c:IsSetCard(0xaf) and lv>lscale and lv<rscale and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_DEFENSE)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local l=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local r=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	if chk==0 then
		if not (l and r) then return false end
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,l:GetLeftScale(),r:GetRightScale())
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local l=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local r=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	if not (l and r) then return end
	local lscale=l:GetLeftScale()
	local rscale=r:GetRightScale()
	
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,lscale,rscale)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_DEFENSE)>0 then
		-- Cannot activate its effects this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CANNOT_TRIGGER)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		-- Destroy it during the End Phase
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_PHASE+PHASE_END)
		e2:SetCountLimit(1)
		e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e2:SetLabelObject(tc)
		e2:SetCondition(s.descon)
		e2:SetOperation(s.desop)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end

	-- Lock into "D/D" Special Summons
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetTargetRange(1,0)
	e3:SetTarget(s.splimit)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

-- Destruction logic
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc:GetLabel()~=id or tc:GetDestination()~=0 then
		e:Reset()
		return false
	end
	return true
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Destroy(tc,REASON_EFFECT)
end

-- Special Summon restriction
function s.splimit(e,c)
	return not c:IsSetCard(0xaf)
end