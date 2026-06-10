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
	e1:SetValue(24878656) -- Toy Box Card ID
	c:RegisterEffect(e1)

	-- Effect 2: Your Continuous Spell cards cannot be targeted by opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,0)
	e2:SetTarget(s.tg_protection)
	e2:SetValue(aux.tgovval)
	c:RegisterEffect(e2)

	-- Effect 3: Destroy 1 Set card on your field, then you can destroy 1 card on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTarget(s.des_target)
	e3:SetOperation(s.des_operation)
	c:RegisterEffect(e3)

	-- Effect 4: While you control 3 set cards in your Spell/Trap zone, draw 1 card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.draw_condition)
	e4:SetTarget(s.draw_target)
	e4:SetOperation(s.draw_operation)
	c:RegisterEffect(e4)
end

s.listed_names={24878656} -- Toy Box Card ID

-- Effect 2 Protection
function s.tg_protection(e,c)
	return c:IsType(TYPE_SPELL+TYPE_CONTINUOUS) and c:IsControler(e:GetHandlerPlayer())
end

-- Effect 3 Clean Handlers
function s.des_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then 
		return Duel.IsExistingTarget(Card.IsFacedown,tp,LOCATION_ONFIELD,0,1,nil)
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectTarget(tp,Card.IsFacedown,tp,LOCATION_ONFIELD,0,1,1,nil)
	e:SetLabelObject(g1:GetFirst())
	
	local g2=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,g1:GetFirst())
	if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g3=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,g1:GetFirst())
		g1:Merge(g3)
	end
	
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end

function s.des_operation(e,tp,eg,ep,ev,re,r,rp)
	local tc1=e:GetLabelObject()
	local tg=Duel.GetTargetCards(e)
	if not tc1 or not tc1:IsRelateToEffect(e) then return end
	
	local tc2=tg:Filter(function(c) return c~=tc1 end,nil):GetFirst()
	
	if Duel.Destroy(tc1,REASON_EFFECT)~=0 then
		if tc2 and tc2:IsRelateToEffect(e) then
			Duel.BreakEffect()
			Duel.Destroy(tc2,REASON_EFFECT)
		end
	end
end

-- Effect 4 Draw Handlers
function s.draw_condition(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_SZONE,0,nil)
	return #g>=3
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