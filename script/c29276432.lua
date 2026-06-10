local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2 Level 4 LIGHT monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),4,2)
	c:EnableReviveLimit()

	-- Effect 1: Detach 1 material to add 1 "Toy" monster from Deck into S&T Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.set_deck_tg)
	e1:SetOperation(s.set_deck_op)
	c:RegisterEffect(e1)

	-- Effect 2: Once per turn: When a set card is destroyed, target 1 monster on field; place it face-down
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.place_cond)
	e2:SetTarget(s.place_tg)
	e2:SetOperation(s.place_op)
	c:RegisterEffect(e2)

	-- Effect 3: When this card is destroyed, you can set this card in your Spell/Trap zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.set_self_cond) -- Ensures it was destroyed from a Monster/Hand zone, not S&T
	e3:SetTarget(s.set_self_tg)
	e3:SetOperation(s.set_self_op)
	c:RegisterEffect(e3)

	-- Effect 4: FIXED - Special Summon itself when destroyed while in the Spell/Trap zone
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_GRAVE+LOCATION_REMOVED) -- Checks wherever the card lands after being popped
	e4:SetCountLimit(1,id+300)
	e4:SetCondition(s.sp_cond_fixed) -- Rewritten to securely track its backrow heritage
	e4:SetTarget(s.sp_tg_fixed)
	e4:SetOperation(s.sp_op_fixed)
	c:RegisterEffect(e4)

	-- Effect 5: While you control "Toy Box", this card cannot be negated
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_CANNOT_DISABLE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.prot_cond)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_CANNOT_DISABLE_EFFECT)
	c:RegisterEffect(e6)
end

s.listed_names={24878656} -- Toy Box Card ID

-- Cost handler
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.toy_filter(c)
	if not c:IsMonster() then return false end
	return c:IsSetCard(0x1a4) or string.find(c:GetOriginalName() or "","Toy")~=nil
end

-- Effect 1
function s.set_deck_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.toy_filter,tp,LOCATION_DECK,0,1,nil) end
end
function s.set_deck_op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.toy_filter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
		tc:RegisterEffect(e1)
	end
end

-- Effect 2
function s.cfilter(c)
	return c:IsPreviousPosition(POS_FACEDOWN) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.place_cond(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil)
end
function s.place_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end
function s.place_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(TYPE_SPELL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
		tc:RegisterEffect(e1)
	end
end

-- Effect 3
function s.set_self_cond(e,tp,eg,ep,ev,re,r,rp)
	-- Only lets you set it if it was NOT destroyed in the S&T Zone (prevents effect overlapping)
	return not e:GetHandler():IsPreviousLocation(LOCATION_SZONE)
end
function s.set_self_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.set_self_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		local e1=Effect.CreateEffect(c)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(TYPE_SPELL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
		c:RegisterEffect(e1)
	end
end

-- FIXED Effect 4 Handlers: Secures validation checking from the Spell/Trap Zone
function s.sp_cond_fixed(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Filters through the global trigger group to find itself and make sure it lived in S&T before pop
	return eg:IsContains(c) and c:IsPreviousLocation(LOCATION_SZONE)
end
function s.sp_tg_fixed(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp_op_fixed(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Effect 5
function s.toybox_filter(c)
	return c:IsFaceup() and c:IsCode(24878656)
end
function s.prot_cond(e)
	return Duel.IsExistingMatchingCard(s.toybox_filter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end