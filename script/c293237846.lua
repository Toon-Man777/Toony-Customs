local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- Always treated as "Gaia the Fierce Knight"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCARD)
	e0:SetValue(0xbd) -- "Gaia the Fierce Knight" setcode
	c:RegisterEffect(e0)
	
	-- Add "Chaos" setcode so Ritual Spells can find it
	local e_chaos=e0:Clone()
	e_chaos:SetValue(0xcf) -- "Chaos" setcode
	c:RegisterEffect(e_chaos)

	-- Name becomes "Gaia the Dragon Champion" in Monster Zone
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(66889139) -- Gaia the Dragon Champion
	c:RegisterEffect(e1)

	-- Piercing Damage
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)

	-- Target 1 monster: DEF 0 and change to Defense
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DEFCHANGE+CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1)
	e3:SetCondition(s.defcon)
	e3:SetTarget(s.deftg)
	e3:SetOperation(s.defop)
	c:RegisterEffect(e3)
	
	-- Material Check tracker
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_MATERIAL_CHECK)
	e4:SetValue(s.valcheck)
	c:RegisterEffect(e4)
end

s.listed_names={21082832, 66889139} -- Chaos Form, Gaia the Dragon Champion

-- Check if a non-Effect monster was used as material
function s.valcheck(e,c)
	local g=c:GetMaterial()
	if g:IsExists(function(mc) return not mc:IsType(TYPE_EFFECT) end,1,nil) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOHAND-RESET_LEAVE,0,1)
	end
end

function s.defcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL) and e:GetHandler():HasFlagEffect(id)
end

function s.deftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.defop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- Set DEF to 0
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_DEFENSE_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		-- Change to Defense Position
		Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)
	end
end