local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Set this card from hand to Spell & Trap Zone as a Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.set_target)
	e1:SetOperation(s.set_operation)
	c:RegisterEffect(e1)

	-- Effect 2: If this set card in the S&T zone is sent to the GY: Special Summon it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id) -- Hard once per turn on Effect 2
	e2:SetCondition(s.sp_condition)
	e2:SetTarget(s.sp_target)
	e2:SetOperation(s.sp_operation)
	c:RegisterEffect(e2)

	-- Effect 3: When Normal/Special Summoned: Gain direct attack OR destroy 1 Spell/Trap if you control "Toy Box"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id+100) -- Hard once per turn on Effect 3
	e3:SetTarget(s.sum_target)
	e3:SetOperation(s.sum_operation)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

s.listed_names={12345678} -- Replace 12345678 with the actual passcode of "Toy Box" in your game environment

-- Effect 1 Handlers (Set as Spell)
function s.set_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.set_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or not c:IsRelateToEffect(e) then return end
	-- Move to S&T Zone as a face-down Spell card
	Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
	local e1=Effect.CreateEffect(c)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(TYPE_SPELL)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
	c:RegisterEffect(e1)
end

-- Effect 2 Handlers (GY Floating)
function s.sp_condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Must be sent to the GY from the Spell & Trap Zone while face-down (set)
	return c:IsPreviousLocation(LOCATION_SZONE) and c:IsPreviousPosition(POS_FACEDOWN)
end
function s.sp_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Effect 3 Handlers (Summon Trigger Trigger)
function s.toybox_filter(c)
	-- Helper filter checking for the face-up Presence of "Toy Box"
	return c:IsFaceup() and c:IsCode(12345678) -- Keep this coordinated with your engine's code for Toy Box
end
function s.sum_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	
	-- If Toy Box is controlled, player chooses to either gain direct attack or target a card to destroy
	local has_toybox = Duel.IsExistingMatchingCard(s.toybox_filter,tp,LOCATION_ONFIELD,0,1,nil)
	local can_destroy = Duel.IsExistingTarget(Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP)
	
	if chk==0 then return true end -- This trigger always activates successfully upon summon
	
	if has_toybox and can_destroy and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		-- Select to destroy 1 Spell/Trap card
		e:SetLabel(1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	else
		-- Default to enabling direct attacking capability
		e:SetLabel(0)
	end
end
function s.sum_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	if e:GetLabel()==1 then
		-- Execute destruction branch
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.Destroy(tc,REASON_EFFECT)
		end
	else
		-- Execute direct attack branch
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(3205)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetCode(EFFECT_DIRECT_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
	end
end