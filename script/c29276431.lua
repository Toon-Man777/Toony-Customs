local s,id=GetID()
function s.initial_effect(c)
	-- Continuous: Set this card from hand to S&T zone as a Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.set_tg)
	e1:SetOperation(s.set_op)
	c:RegisterEffect(e1)

	-- Effect 1: If this set card is sent to the GY: Special Summon it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id) -- Hard once per turn
	e2:SetCondition(s.sp_cond)
	e2:SetTarget(s.sp_tg)
	e2:SetOperation(s.sp_op)
	c:RegisterEffect(e2)

	-- Effect 2: When Normal/Special Summoned: Target 1 monster to place in S&T zone OR (if Toy Box is out) Special Summon 1 Level 4 or lower monster from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id+100) -- Hard once per turn
	e3:SetTarget(s.eff_tg)
	e3:SetOperation(s.eff_op)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

s.listed_names={24878656} -- Tracks "Toy Box"

-- S&T Setting Mechanics
function s.set_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.set_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or not c:IsRelateToEffect(e) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
	local e1=Effect.CreateEffect(c)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(TYPE_SPELL)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
	c:RegisterEffect(e1)
end

-- GY Trigger Condition
function s.sp_cond(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_SZONE) and c:IsPreviousPosition(POS_FACEDOWN)
end
function s.sp_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.sp_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Filters for the branching effect choices
function s.box_filter(c)
	return c:IsFaceup() and c:IsCode(24878656)
end
function s.gy_filter(c,e,tp)
	return c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Effect 2 Target Handling
function s.eff_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		if e:GetLabel()==0 then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
		return false
	end

	local has_box = Duel.IsExistingMatchingCard(s.box_filter,tp,LOCATION_ONFIELD,0,1,nil)
	local can_place = Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	local can_sp = has_box and Duel.IsExistingMatchingCard(s.gy_filter,tp,LOCATION_GRAVE,0,1,nil,e,tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0

	if chk==0 then return can_place or can_sp end

	local op=0
	if can_place and can_sp then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif can_place then
		op=Duel.SelectOption(tp,aux.Stringid(id,3))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,4))+1
	end
	e:SetLabel(op)

	if op==0 then
		-- Target 1 face-up monster to turn into a Continuous Spell
		e:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	else
		-- Special Summon from GY
		e:SetProperty(EFFECT_FLAG_DELAY)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	end
end

-- Effect 2 Execution Handling
function s.eff_op(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	if op==0 then
		-- Choice 1: Place target monster into owner's S&T Zone as a Continuous Spell
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			local p=tc:GetControler()
			if Duel.GetLocationCount(p,LOCATION_SZONE)<=0 then return end
			Duel.MoveToField(tc,tp,p,LOCATION_SZONE,POS_FACEUP,true)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
			tc:RegisterEffect(e1)
		end
	else
		-- Choice 2: Special Summon 1 Level 4 or lower monster from GY
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.gy_filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end