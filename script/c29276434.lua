local s,id=GetID()
function s.initial_effect(c)
	-- Activate Field Spell Card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effect 1: This card's name becomes "Toy Box" while on the field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_FZONE)
	e1:SetValue(24878656) -- "Toy Box" Database ID
	c:RegisterEffect(e1)

	-- Effect 2: While on the field, your set cards cannot be targeted by opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0)
	e2:SetTarget(s.tg_protection)
	e2:SetValue(aux.tgovval)
	c:RegisterEffect(e2)

	-- Effect 3: Once per turn: Destroy 1 Set card in your S&T Zone to add 1 "Toy Box" from Deck to hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1) -- "Once per turn" ignition
	e3:SetTarget(s.th_target)
	e3:SetOperation(s.th_operation)
	c:RegisterEffect(e3)

	-- Effect 4: While you control 3 "Toy" set cards in your S&T Zone, draw 1 card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	-- Shared hard once per turn clause ("You can only use this effect of 'Toy Playtime Kingdom' once per turn")
	e4:SetCountLimit(1,id) 
	e4:SetCondition(s.draw_condition)
	e4:SetTarget(s.draw_target)
	e4:SetOperation(s.draw_operation)
	c:RegisterEffect(e4)
end

s.listed_names={24878656} -- Mentions "Toy Box"

-- Helper filter to check for "Toy" cards (Setcode 0x1a0)
function s.toy_filter(c)
	return c:IsSetCard(0x1a0) or string.find(c:GetOriginalName() or "","Toy")~=nil
end

-- Helper filter to count Set "Toy" cards in Spell/Trap Zone
function s.set_toy_st_filter(c)
	return c:IsFacedown() and c:IsLocation(LOCATION_SZONE) and s.toy_filter(c)
end

-- Effect 2 Target Protection Handler
function s.tg_protection(e,c)
	return c:IsFacedown() and c:IsControler(e:GetHandlerPlayer()) -- Protects only face-down cards you control
end

-- Effect 3 Search Filter
function s.toybox_search_filter(c)
	return c:IsCode(24878656) and c:IsAbleToHand() -- Targets "Toy Box"
end

-- Effect 3 Handlers (Destroy 1 Set to Search 1 "Toy Box")
function s.th_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_SZONE,0,nil)
	if chk==0 then return #g>0 and Duel.IsExistingMatchingCard(s.toybox_search_filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_SZONE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.th_operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,Card.IsFacedown,tp,LOCATION_SZONE,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.toybox_search_filter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

-- Effect 4 Handlers (Control 3 "Toy" set cards to draw 1)
function s.draw_condition(e,tp,eg,ep,ev,re,r,rp)
	-- Verifies that you currently control 3 or more Set "Toy" cards in your S&T zone
	return Duel.IsExistingMatchingCard(s.set_toy_st_filter,tp,LOCATION_SZONE,0,3,nil)
end

function s.draw_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.draw_operation(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end