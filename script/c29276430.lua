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

	-- Effect 2: When Normal/Special Summoned: Direct attack OR destroy 1 Spell/Trap if you control "Toy Box"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
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

s.listed_names={24878656} -- Explicitly tracks "Toy Box"

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

-- Summons Branching Target Logic
function s.box_filter(c)
	return c:IsFaceup() and c:IsCode(24878656)
end
function s.eff_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	
	local has_box = Duel.IsExistingMatchingCard(s.box_filter,tp,LOCATION_ONFIELD,0,1,nil)
	local can_destroy = Duel.IsExistingTarget(Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP)
	
	if chk==0 then return true end -- This effect always succeeds because direct attack option requires no targets
	
	-- If Toy Box is controlled, offer choice path
	local op=0
	if has_box and can_destroy then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	else
		Duel.SelectOption(tp,aux.Stringid(id,3))
		op=0
	end
	e:SetLabel(op)
	
	if op==1 then
		e:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	else
		e:SetProperty(EFFECT_FLAG_DELAY)
	end
end

-- Summons Branching Operations Execution
function s.eff_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	
	if op==0 then
		-- Treat as direct attacker
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DIRECT_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
	else
		-- Destroy designated target
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.Destroy(tc,REASON_EFFECT)
		end
	end
end