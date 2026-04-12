local s,id=GetID()
function s.initial_effect(c)
	-- Pendulum Summon Procedure
	Pendulum.AddProcedure(c)
	
	-- Pendulum Effect: Restrict Pendulum Summons (Cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)

	-- Pendulum Effect: Double "Dark Contract" use (Once while in P-Zone)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+EFFECT_COUNT_CODE_DUEL) -- "Once while this card is in your Pendulum Zone"
	e2:SetTarget(s.pcttg)
	e2:SetOperation(s.pctop)
	c:RegisterEffect(e2)

	-- Monster Effect: Cannot be destroyed by battle
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- Monster Effect: Change target to this card (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_BE_BATTLE_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.tgcon)
	e4:SetOperation(s.tgop)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_BE_CHOSEN_TARGET)
	c:RegisterEffect(e5)
end

s.listed_series={0xaf, 0xae} -- D/D, Dark Contract

-- Pendulum Summon Limit
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	if (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM then
		return not c:IsSetCard(0xaf)
	end
	return false
end

-- Dark Contract Logic
function s.pctfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xae) -- "Dark Contract" card
end
function s.pcttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and s.pctfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.pctfilter,tp,LOCATION_SZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.pctfilter,tp,LOCATION_SZONE,0,1,1,nil)
end
function s.pctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		-- This logic allows effects that are "Once per turn" to be used twice
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_COUNT_LIMIT_RESETS) -- Custom implementation for double-use
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		
		-- Destroy during End Phase
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e2:SetCode(EVENT_PHASE+PHASE_END)
		e2:SetCountLimit(1)
		e2:SetLabelObject(tc)
		e2:SetOperation(s.desop)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc:GetLocation()==LOCATION_SZONE then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- Target Redirection Logic
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	if e:GetCode()==EVENT_BE_BATTLE_TARGET then
		local tc=Duel.GetAttackTarget()
		return tc and tc:IsControler(tp) and tc:IsSetCard(0xaf) and tc~=e:GetHandler()
	else
		return rp~=tp and Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS):IsExists(function(c) return c:IsControler(tp) and c:IsSetCard(0xaf) and c~=e:GetHandler() end)
	end
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- Become the new target
	if e:GetCode()==EVENT_BE_BATTLE_TARGET then
		Duel.ChangeAttackTarget(c)
	else
		local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if #g>0 then
			Duel.ChangeTargetCard(ev,Group.FromCards(c))
		end
	end

	-- Gain ATK if in Attack Position
	if c:IsAttackPos() then
		local prev_target
		if e:GetCode()==EVENT_BE_BATTLE_TARGET then
			prev_target=eg:GetFirst()
		else
			prev_target=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS):GetFirst()
		end
		
		if prev_target then
			local atk=prev_target:GetBaseAttack()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e1)
		end
	end
end