local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon: 4 Level 5 Monsters
	Xyz.AddProcedure(c,nil,5,4,s.ovfilter,aux.Stringid(id,0))
	c:EnableReviveLimit()

	-- Search "Cursed" Spell on Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x2) -- CATEGORY_TOHAND+CATEGORY_SEARCH
	e1:SetType(1+0x40) -- EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O
	e1:SetCode(1011) -- EVENT_SPSUMMON_SUCCESS
	e1:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Detach to Negate and Half ATK
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x10+0x2000) -- CATEGORY_ATKCHANGE+CATEGORY_DISABLE
	e2:SetType(4) -- EFFECT_TYPE_IGNITION
	e2:SetRange(4) -- LOCATION_MZONE
	e2:SetProperty(0x100) -- EFFECT_FLAG_CARD_TARGET
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- Battle Phase: Banish 2 "Cursed" Spells to multi-attack
	local e3=Effect.CreateEffect(c)
	e3:SetType(4)
	e3:SetRange(4)
	e3:SetCountLimit(1,id+2)
	e3:SetCondition(s.atkcon)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- End of turn: Switch to defense
	local e4=Effect.CreateEffect(c)
	e4:SetType(1+0x40)
	e4:SetCode(1022) -- EVENT_DAMAGE_STEP_END
	e4:SetRange(4)
	e4:SetCondition(s.poscon)
	e4:SetOperation(s.posop)
	c:RegisterEffect(e4)
end

-- Alternative Summon: Rank 4 DARK Dragon
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsType(0x800) and c:IsRank(4) and c:IsAttribute(0x20) and c:IsRace(0x1)
end

-- Search Logic
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(0x40) -- SUMMON_TYPE_XYZ
end
function s.thfilter(c)
	return c:IsSetCard(0x923) and c:IsType(0x2) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,1,0,1,nil) end
	Duel.SetOperationInfo(0,0x2,nil,1,tp,1)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,506)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,1,0,1,1,nil)
	if #g>0 then Duel.SendtoHand(g,nil,64) Duel.ConfirmCards(1-tp,g) end
end

-- Negate/Half ATK Logic
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,64) end
	local n=e:GetHandler():GetOverlayCount()
	local ct=Duel.GetMatchingGroupCount(Card.IsCanBeEffectTarget,tp,0,4,nil,e)
	if ct>n then ct=n end
	local oct=Duel.AnnounceNumber(tp,1,ct)
	e:GetHandler():RemoveOverlayCard(tp,oct,oct,64)
	e:SetLabel(oct)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(4) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,4,1,nil) end
	local ct=e:GetLabel()
	Duel.Hint(3,tp,504)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,4,ct,ct,nil)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	local total_rating=0
	for tc in aux.Next(g) do
		local lv=tc:GetLevel()
		local rk=tc:GetRank()
		local lk=tc:GetLink()
		total_rating = total_rating + lv + rk + lk
		-- Negate and half ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(108) -- SET_ATTACK_FINAL
		e1:SetValue(tc:GetAttack()/2)
		e1:SetReset(0x1fe0000)
		tc:RegisterEffect(e1)
		Duel.NegateRelatedChain(tc,64)
		local e2=Effect.CreateEffect(c)
		e2:SetType(1)
		e2:SetCode(11) -- EFFECT_DISABLE
		e2:SetReset(0x1fe0000)
		tc:RegisterEffect(e2)
	end
	if total_rating>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(1)
		e3:SetCode(100) -- EFFECT_UPDATE_ATTACK
		e3:SetValue(total_rating*250)
		e3:SetReset(0x1fe0000)
		c:RegisterEffect(e3)
	end
end

-- Multi-Attack Logic
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsPhase(0x08) -- PHASE_BATTLE_START
end
function s.atkcostfilter(c)
	return c:IsSetCard(0x923) and c:IsType(0x2) and c:IsAbleToBanishAsCost()
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkcostfilter,tp,18,0,2,nil) end
	local g=Duel.SelectMatchingCard(tp,s.atkcostfilter,tp,18,0,2,2,nil)
	Duel.Remove(g,0,64)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- Attack all monsters with modified ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(141) -- EFFECT_ATTACK_ALL
		e1:SetValue(function(e,tc) return tc:GetAttack()~=tc:GetBaseAttack() end)
		e1:SetReset(0x2000000+0x08) -- RESET_PHASE+PHASE_BATTLE
		c:RegisterEffect(e1)
	end
end

-- Defense switch logic
function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetAttackedCount()>0
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsAttackPos() then
		Duel.ChangePosition(c,0x8) -- POS_FACEUP_DEFENSE
	end
end