local s,id=GetID()
function s.initial_effect(c)
	-- Synchro: 1 Tuner + 1+ Non-Tuner
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	-- Once per turn: Target 1 "Iron Chain" to attack directly
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(4) -- EFFECT_TYPE_IGNITION
	e1:SetRange(4) -- LOCATION_MZONE
	e1:SetCountLimit(1)
	e1:SetProperty(0x100) -- EFFECT_FLAG_CARD_TARGET
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- Once per turn: Mill when "Iron Chain" deals damage or Opp card sent to GY
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(0x4000) -- CATEGORY_DECKDES
	e2:SetType(16+0x40) -- FIELD+TRIGGER_O
	e2:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e2:SetCode(1013) -- EVENT_BATTLE_DAMAGE (Using Battle Destroyed/ToGrave logic)
	e2:SetRange(4)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.millcon)
	e2:SetTarget(s.milltg)
	e2:SetOperation(s.millop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(1001) -- EVENT_TO_GRAVE
	c:RegisterEffect(e3)

	-- Banish from GY: Search 1 "Iron Chain" Spell/Trap
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(0x2) -- CATEGORY_TOHAND+SEARCH
	e4:SetType(4)
	e4:SetRange(16) -- LOCATION_GRAVE
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

-- Direct Attack Logic
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
		e1:SetReset(0x1fe0000)
		tc:RegisterEffect(e1)
	end
end

-- Mill Logic
function s.millcon(e,tp,eg,ep,ev,re,r,rp)
	if e:GetCode()==1013 then -- From Battle
		return ep~=tp and eg:IsExists(function(c) return c:IsSetCard(0x25) end,1,nil)
	else -- From ToGrave
		return eg:IsExists(function(c) return c:IsControler(1-tp) and (not re or re:GetHandler():IsSetCard(0x25)) end,1,nil)
	end
end
function s.milltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x4000,nil,0,1-tp,2)
end
function s.millop(e,tp,eg,ep,ev,re,r,rp)
	Duel.DiscardDeck(1-tp,2,64)
end

-- Search Logic
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) and c:IsType(0x2+0x4) and c:IsAbleToHand() end,tp,8,0,1,nil) end
	Duel.SetOperationInfo(0,0x2,nil,1,tp,8)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,511)
	local g=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x25) and c:IsType(0x2+0x4) and c:IsAbleToHand() end,tp,8,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,64)
		Duel.ConfirmCards(1-tp,g)
	end
end