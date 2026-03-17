--Borrelextermination Cannon Dragon
local s,id=GetID()

function s.initial_effect(c)

	c:EnableReviveLimit()

	--4+ DARK Dragon monsters
	Link.AddProcedure(c,s.matfilter,4,99)

	--Unaffected by other effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	--Destroy monster → choose effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.tg)
	e2:SetOperation(s.op)
	c:RegisterEffect(e2)

	--Revive Borrel
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

end

------------------------------------------------
--Material filter
------------------------------------------------

function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)
end

------------------------------------------------
--Unaffected
------------------------------------------------

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

------------------------------------------------
--Target monster
------------------------------------------------

function s.filter(c)
	if not (c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)) then return false end
	if c:IsType(TYPE_LINK) then return c:GetLink()<=4 and c:IsDestructable()
	elseif c:IsType(TYPE_XYZ) then return c:GetRank()<=4 and c:IsDestructable()
	else return c:IsLevelBelow(4) and c:IsDestructable()
	end
end

function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end

	if chk==0 then
		return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)

end

------------------------------------------------
--Main effect
------------------------------------------------

function s.op(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local val=0

	if tc:IsType(TYPE_LINK) then
		val=tc:GetLink()
	elseif tc:IsType(TYPE_XYZ) then
		val=tc:GetRank()
	else
		val=tc:GetLevel()
	end

	if Duel.Destroy(tc,REASON_EFFECT)==0 then return end

	local op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))

	local c=e:GetHandler()

	--Destroy opponent cards
	if op==0 then

		local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)

		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=g:Select(tp,1,math.min(val,#g),nil)
			Duel.Destroy(sg,REASON_EFFECT)
		end

	--Multiple attacks
	else

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
		e1:SetValue(val-1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)

		c:RegisterEffect(e1)

	end

end

------------------------------------------------
--Summon Link-4 Borrel
------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsLink(4)
	and c:IsSetCard(0x10f)
	and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil,e:GetHandler())>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)

end

function s.spop(e,tp,eg,ep,ev,re,r,rp)

	if Duel.GetLocationCountFromEx(tp,tp,nil,e:GetHandler())<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil,e,tp)

	if #g>0 then
		Duel.SpecialSummon(g,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
	end

end