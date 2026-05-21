local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Only 1 "SKY FIRE Minefield" can be controlled
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	c:SetUniqueOnField(1,0,id)
	
	-- 1. All Level 8 Machine monsters are "Reactor" on the field
	-- Updated: Removed DARK attribute requirement per SKY FIRE Minefield_2.jpg
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.setcode_tg)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetValue(0x63) -- Reactor Hex
	c:RegisterEffect(e1)
	
	-- 2. Extra Burn Damage (Triggered by effect damage)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_DAMAGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.burn_con)
	e2:SetOperation(s.burn_op)
	c:RegisterEffect(e2)
	
	-- 3. Target 1 "Reactor", SS 1 "Reactor" from Deck with lower Level
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.sp_tg)
	e3:SetOperation(s.sp_op)
	c:RegisterEffect(e3)
end

-- Filter for Effect 1 (Now applies to any Level 8 Machine)
function s.setcode_tg(e,c)
	return c:IsLevel(8) and c:IsRace(RACE_MACHINE)
end

-- Effect 2: Extra Burn Logic
function s.burn_con(e,tp,eg,ep,ev,re,r,rp)
	-- Opponent takes damage (ep~=tp) from card effect (r&REASON_EFFECT) not caused by this card
	return ep~=tp and (r&REASON_EFFECT)~=0 and re:GetHandler()~=e:GetHandler()
end

function s.burnfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_MACHINE)
end

function s.burn_op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_CARD,0,id)
		-- Note: This still counts DARK Machines specifically per the card text
		local ct=Duel.GetMatchingGroupCount(s.burnfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		if ct>0 then
			Duel.InflictDamage(1-tp,ct*200)
		end
	end
end

-- Effect 3: Special Summon Logic
function s.sp_filter(c,e,tp,lv)
	return c:IsSetCard(0x63) and c:IsLevelBelow(lv-1) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sp_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsSetCard(0x63) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(Card.IsSetCard,tp,LOCATION_MZONE,0,1,nil,0x63) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsSetCard,tp,LOCATION_MZONE,0,1,1,nil,0x63)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.sp_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsFacedown() or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sp_filter,tp,LOCATION_DECK,0,1,1,nil,e,tp,tc:GetLevel())
	local sc=g:GetFirst()
	
	if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Register the End Phase destruction
		local fid=e:GetHandler():GetFieldID()
		sc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,fid)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUTABLE)
		e1:SetLabel(fid)
		e1:SetLabelObject(sc)
		e1:SetCondition(s.des_con)
		e1:SetOperation(s.des_op)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.des_con(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc:GetFlagEffectLabel(id)==e:GetLabel() then
		return true
	else
		e:Reset()
		return false
	end
end

function s.des_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Destroy(tc,REASON_EFFECT)
end