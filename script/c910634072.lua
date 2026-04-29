local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon Procedure
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	-- 1. Direct Attack (Once per turn)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(4) -- EFFECT_TYPE_IGNITION
	e1:SetProperty(0x100) -- EFFECT_FLAG_CARD_TARGET
	e1:SetRange(4) -- LOCATION_MZONE
	e1:SetCountLimit(1,id) -- HOPT 1
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- 2. Reactive Mill 2 (Once per turn)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x4000) -- CATEGORY_DECKDES
	e2:SetType(16+0x40) -- EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F
	e2:SetCode(1013) -- EVENT_BATTLE_DAMAGE
	e2:SetRange(4)
	e2:SetCountLimit(1,id+1) -- HOPT 2
	e2:SetCondition(s.millcon1)
	e2:SetTarget(s.milltg)
	e2:SetOperation(s.millop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(1001) -- EVENT_TO_GRAVE
	e3:SetCondition(s.millcon2)
	c:RegisterEffect(e3)

	-- 3. GY Banish Search (Once per turn)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(0x2+0x1) -- CATEGORY_SEARCH + CATEGORY_TOHAND
	e4:SetType(4)
	e4:SetRange(16) -- LOCATION_GRAVE
	e4:SetCountLimit(1,id+2) -- HOPT 3
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

-- Logic for Direct Attack
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(4) and chkc:IsControler(tp) and chkc:IsSetCard(0x25) end
	if chk==0 then return Duel.IsExistingTarget(function(c) return c:IsFaceup() and c:IsSetCard(0x25) end,tp,4,0,1,nil) end
	Duel.SelectTarget(tp,function(c) return c:IsFaceup() and c:IsSetCard(0x25) end,tp,4,0,1,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(1)
		e1:SetCode(142) -- EFFECT_DIRECT_ATTACK
		e1:SetReset(0x1fe0000 + 0x80) -- End of turn
		tc:RegisterEffect(e1)
	end
end

-- Logic for Mill Trigger
function s.millcon1(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp and eg:IsExists(function(c) return c:IsSetCard(0x25) end,1,nil)
end
function s.millcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsControler,1,nil,1-tp)
end
function s.milltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,2)
end
function s.millop(e,tp,eg,ep,ev,re,r,rp)
	Duel.DiscardDeck(1-tp,2,64) -- REASON_EFFECT (64)
end

-- Logic for Searching Iron Chain Spell/Trap
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) and c:IsType(0x2+0x4) and c:IsAbleToHand() end,tp,1,0,1,nil) end
	Duel.SetOperationInfo(0,0x2,nil,1,tp,1)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,511)
	local g=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x25) and c:IsType(0x2+0x4) and c:IsAbleToHand() end,tp,1,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,64)
		Duel.ConfirmCards(1-tp,g)
	end
end