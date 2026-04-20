local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Ritual Summoning Requirement
	-- Must be Ritual Summoned with "Chaos Form"
	
	-- Multi-choice effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

s.listed_names={21082832} -- Chaos Form
s.listed_series={0xcf} -- Chaos

-- Cost: Tribute 1 "Chaos" monster from hand or field
function s.costfilter(c)
	return c:IsSetCard(0xcf)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.costfilter,1,false,nil,nil,tp,LOCATION_HAND+LOCATION_MZONE) end
	local g=Duel.SelectReleaseGroupCost(tp,s.costfilter,1,1,false,nil,nil,tp,LOCATION_HAND+LOCATION_MZONE)
	Duel.Release(g,REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local b1=Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	local b2=Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_GRAVE,0,1,nil,TYPE_SPELL)
	local b3=true -- ATK gain is always applicable if there are monsters on field
	
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)}, -- Reduce ATK to 0 and negate
		{b2,aux.Stringid(id,2)}, -- Add Spell from GY, skip draw
		{b3,aux.Stringid(id,3)}) -- Gain half of combined ATK
	e:SetLabel(op)
	
	if op==1 then
		e:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
	elseif op==2 then
		e:SetCategory(CATEGORY_TOHAND)
	elseif op==3 then
		e:SetCategory(CATEGORY_ATKCHANGE)
	end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	
	if op==1 then
		-- All opponent's monsters: ATK to 0 and negate
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(0)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
			local e3=e2:Clone()
			e3:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e3)
		end
	elseif op==2 then
		-- Add 1 Spell from GY to hand
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_GRAVE,0,1,1,nil,TYPE_SPELL)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
		-- Skip next Draw Phase
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_SKIP_DP)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE+PHASE_DRAW+RESET_SELF_TURN)
		Duel.RegisterEffect(e1,tp)
	elseif op==3 then
		-- Gain half of combined ATK
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
			local sum=g:GetSum(Card.GetAttack)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(math.floor(sum/2))
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end