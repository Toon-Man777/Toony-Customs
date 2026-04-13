local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 "D/D" Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0xaf),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveSelection()
	
	-- Effect 1: Synchro Summon Burn
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.damcon)
	e1:SetTarget(s.damtg)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)

	-- Effect 2: Excavate on attack declaration
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetTarget(s.exctg)
	e2:SetOperation(s.excop)
	c:RegisterEffect(e2)
end

-- Setcodes for "D/D" (0xaf) and "D/D/D" (0x10af)
s.listed_series={0xaf,0x10af}

-- Logic for Synchro Summon Burn
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local atk=math.floor(tc:GetAttack()/2)
		-- Choice: Burn yourself or the opponent
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
		local p=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
		local target_p = (p==0) and tp or 1-tp
		Duel.Damage(target_p,atk,REASON_EFFECT)
	end
end

-- Logic for Battle Excavation
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
end
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)==0 then return end
	Duel.ConfirmDecktop(tp,1)
	local g=Duel.GetDecktopGroup(tp,1)
	local tc=g:GetFirst()
	
	if tc:IsType(TYPE_MONSTER) then
		-- Monster: Gain 1000 ATK
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
	elseif tc:IsType(TYPE_SPELL) then
		-- Spell: Opponent's monster loses 1000 ATK
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local sg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
		if #sg>0 then
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_UPDATE_ATTACK)
			e2:SetValue(-1000)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			sg:GetFirst():RegisterEffect(e2)
		end
	elseif tc:IsType(TYPE_TRAP) then
		-- Trap: Destroy this card and burn both players for 2000
		if c:IsRelateToEffect(e) and Duel.Destroy(c,REASON_EFFECT)>0 then
			Duel.Damage(tp,2000,REASON_EFFECT,true)
			Duel.Damage(1-tp,2000,REASON_EFFECT,true)
			Duel.RDV()
		end
	end
	Duel.ShuffleDeck(tp)
end