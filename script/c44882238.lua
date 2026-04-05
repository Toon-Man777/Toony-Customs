--Dark Magician Girl, Warlock
local s,id=GetID()

function s.initial_effect(c)
	-- Link summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_SPELLCASTER),2,99)

	---------------------------------------------------
	-- Cannot be destroyed by opponent's effects
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(s.indval)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Name becomes Dark Magician Girl
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetValue(CARD_DARK_MAGICIAN_GIRL)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Gain ATK for each DM/DMG monster in GY
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	---------------------------------------------------
	-- Quick Effect when you activate Spell/Trap
	---------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.qecon)
	e4:SetTarget(s.qetg)
	e4:SetOperation(s.qeop)
	c:RegisterEffect(e4)
end

---------------------------------------------------
-- Indestructible by opponent effects
---------------------------------------------------

function s.indval(e,re,tp)
	return tp~=e:GetHandlerPlayer()
end

---------------------------------------------------
-- ATK gain (UPDATED WITH SETCODES)
---------------------------------------------------

function s.atkfilter(c)
	return c:IsType(TYPE_MONSTER) and (c:IsSetCard(0x10a2) or c:IsSetCard(0x30a2))
end

function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.atkfilter,c:GetControler(),LOCATION_GRAVE,LOCATION_GRAVE,nil)
	return #g*100
end

---------------------------------------------------
-- Quick Effect condition
---------------------------------------------------

function s.qecon(e,tp,eg,ep,ev,re,r,rp)
	return rp==tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

---------------------------------------------------
-- Target (choose effect)
---------------------------------------------------

function s.qetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	local b1=Duel.IsPlayerCanDraw(tp,1)
	local b2=Duel.IsExistingMatchingCard(Card.IsDestructable,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)

	local op=aux.SelectOption(tp,
		b1,aux.Stringid(id,0),
		b2,aux.Stringid(id,1))

	e:SetLabel(op)
end

---------------------------------------------------
-- Operation
---------------------------------------------------

function s.qeop(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	if op==0 then
		-- Draw 1, discard 1
		if Duel.Draw(tp,1,REASON_EFFECT)>0 then
			Duel.BreakEffect()
			Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	else
		-- Destroy 1 monster
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,Card.IsDestructable,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end