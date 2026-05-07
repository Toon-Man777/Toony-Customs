local s,id=GetID()
function s.initial_effect(c)
	-- 1. Name is always "Chaos Form"
	local e0=Effect.CreateEffect(c)
	e0:SetType(1) -- EFFECT_TYPE_SINGLE
	e0:SetProperty(0x400+0x800) -- CANNOT_DISABLE+UNCOPYABLE
	e0:SetCode(100) -- EFFECT_CHANGE_CODE
	e0:SetValue(21082832) -- Chaos Form ID
	c:RegisterEffect(e0)

	-- 2. Basic Activation (Ensures you can always play the card)
	local e1=Effect.CreateEffect(c)
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	c:RegisterEffect(e1)

	-- 3. Search Effect (Triggered after activation)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(0x2+0x4) -- CATEGORY_TOHAND+CATEGORY_SEARCH
	e2:SetType(16+0x40) -- EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O
	e2:SetCode(1000) -- EVENT_CHAIN_SOLVED
	e2:SetRange(256) -- LOCATION_FZONE
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- 4. Ritual Summon Effect (Ignition)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(0x800) -- CATEGORY_SPECIAL_SUMMON
	e3:SetType(4) -- EFFECT_TYPE_IGNITION
	e3:SetRange(256)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.rittg)
	e3:SetOperation(s.ritop)
	c:RegisterEffect(e3)

	-- 5. Grant LIGHT Effect: Double ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(16+0x40) -- FIELD+TRIGGER_O
	e4:SetCode(1015) -- EVENT_BATTLE_START
	e4:SetRange(256)
	e4:SetCondition(s.atkcon)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)

	-- 6. Grant DARK Effect: Banish S/T
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(0x20) -- CATEGORY_REMOVE
	e5:SetType(4)
	e5:SetRange(256)
	e5:SetProperty(0x100) -- CARD_TARGET
	e5:SetCountLimit(1)
	e5:SetCondition(s.darkcon)
	e5:SetTarget(s.darktg)
	e5:SetOperation(s.darkop)
	c:RegisterEffect(e5)
end

-- Search Logic
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler()==e:GetHandler()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(function(c) return c:IsType(0x80) and c:IsAbleToHand() end,tp,1,0,1,nil) end
	Duel.SetOperationInfo(0,0x2,nil,1,tp,1)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(3,tp,511)
	local g=Duel.SelectMatchingCard(tp,function(c) return c:IsType(0x80) and c:IsAbleToHand() end,tp,1,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,64)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Ritual Logic (Shuffling Materials)
function s.ritfilter(c,e,tp)
	return (c:IsSetCard(0xcf) or c:IsSetCard(0x10cf)) and c:IsType(0x80)
		and c:IsCanBeSpecialSummoned(e,130,tp,false,true)
end
function s.mfilter(c)
	return (c:IsAttribute(0x1) or c:IsAttribute(0x2)) and c:IsAbleToDeck()
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mfilter,tp,2+16,0,nil)
		return Duel.IsExistingMatchingCard(aux.RitualUltimateFilter,tp,1,0,1,nil,s.ritfilter,e,tp,mg,nil,Card.GetLevel,"Equal")
	end
	Duel.SetOperationInfo(0,0x800,nil,1,tp,1)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.mfilter,tp,2+16,0,nil)
	local tg=Duel.SelectMatchingCard(tp,aux.RitualUltimateFilter,tp,1,0,1,1,nil,s.ritfilter,e,tp,mg,nil,Card.GetLevel,"Equal")
	local tc=tg:GetFirst()
	if tc then
		mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
		local mat=mg:SelectWithSumEqual(tp,Card.GetLevel,tc:GetLevel(),1,99,tc)
		tc:SetMaterial(mat)
		Duel.SendtoDeck(mat,nil,2,64) -- Shuffle to Deck
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,130,tp,tp,false,true,1)
		tc:CompleteProcedure()
	end
end

-- LIGHT Effect Logic
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not d then return false end
	if a:IsControler(1-tp) then a,d=d,a end
	return a:IsType(0x80) and a:IsAttribute(0x1) and a:IsControler(tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	if tc:IsControler(1-tp) then tc=Duel.GetAttackTarget() end
	if tc and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(1)
		e1:SetCode(100) -- UPDATE_ATTACK
		e1:SetValue(tc:GetAttack()) -- Effectively doubles
		e1:SetReset(0x1fe0000+0x80)
		tc:RegisterEffect(e1)
	end
end

-- DARK Effect Logic
function s.darkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsType(0x80) and c:IsAttribute(0x2) and c:IsFaceup() end,tp,4,0,1,nil)
end
function s.darktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,4,0,nil,0x80)
	if chkc then return chkc:IsOnField() and chkc:IsType(8+128) and chkc:IsAbleToRemove() end
	if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsAbleToRemove,tp,8+128,8+128,1,nil) end
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,8+128,8+128,1,ct,nil)
	Duel.SetOperationInfo(0,0x20,g,#g,0,0)
end
function s.darkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,0x20000):Filter(Card.IsRelateToEffect,nil,e)
	if #g>0 then Duel.Remove(g,0,64) end
end