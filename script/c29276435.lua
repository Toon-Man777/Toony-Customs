local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Negate an opponent's card effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id) -- Hard once per turn on activation
	e1:SetCondition(s.neg_cond)
	e1:SetTarget(s.neg_tg)
	e1:SetOperation(s.neg_op)
	c:RegisterEffect(e1)

	-- GY Effect: Banish this card to shuffle 1 "Toy Box" from GY into the deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100) -- Hard once per turn on GY effect
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.td_tg)
	e2:SetOperation(s.td_op)
	c:RegisterEffect(e2)
end

s.listed_names={24878656} -- Mentions "Toy Box"

-- Filters for "Toy Box" (Database ID: 24878656) situated in the S&T Zone
function s.box_control_filter(c)
	return c:IsFaceup() and c:IsCode(24878656) and c:IsLocation(LOCATION_SZONE)
end
function s.box_destroy_filter(c)
	return c:IsCode(24878656) and c:IsLocation(LOCATION_SZONE) and c:IsDestructable()
end
-- GY Filter for "Toy Box"
function s.td_filter(c)
	return c:IsCode(24878656) and c:IsAbleToDeck()
end

-- NEGANCE EFFECT HANDLERS (Effect 1)
function s.neg_cond(e,tp,eg,ep,ev,re,r,rp)
	-- Triggers when your opponent activates a card effect
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.neg_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Option 1: Control a face-up "Toy Box" in your S&T zone
	local opt1 = Duel.IsExistingMatchingCard(s.box_control_filter,tp,LOCATION_SZONE,0,1,nil)
	-- Option 2: Destroy a "Toy Box" in your S&T zone
	local opt2 = Duel.IsExistingMatchingCard(s.box_destroy_filter,tp,LOCATION_SZONE,0,1,nil)
	
	if chk==0 then return opt1 or opt2 end
	
	-- Determine player choice options dynamically based on card conditions
	local op=0
	if opt1 and opt2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif opt1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
	end
	e:SetLabel(op)
	
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if op==0 then
		-- Option 1 destroys the opponent's card
		if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
			Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
		end
	else
		-- Option 2 destroys your own "Toy Box" card as an effect cost component
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_SZONE)
	end
end

function s.neg_op(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	
	if op==0 then
		-- Option 1 Resolution: Negate the effect, and if you do, destroy it
		if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
			Duel.Destroy(eg,REASON_EFFECT)
		end
	else
		-- Option 2 Resolution: Select and destroy 1 "Toy Box" in your S&T Zone
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,s.box_destroy_filter,tp,LOCATION_SZONE,0,1,1,nil)
		local tc=g:GetFirst()
		if tc and Duel.Destroy(tc,REASON_EFFECT)~=0 then
			-- If destroyed, negate that card effect
			if Duel.NegateActivation(ev) then
				-- Then, set that card to your field face-down
				if tc:IsLocation(LOCATION_GRAVE) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
					Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
					-- Re-apply treated as a Spell modifier if applicable
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetCode(EFFECT_CHANGE_TYPE)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e1:SetValue(TYPE_SPELL)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
					tc:RegisterEffect(e1)
				end
			end
		end
	end
end

-- SHUFFLE GY EFFECT HANDLERS (Effect 2)
function s.td_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.td_filter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end

function s.td_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.td_filter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end