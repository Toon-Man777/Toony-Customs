local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon Procedure: 2 Aqua monsters + 1 Level 10 WATER monster
	c:EnableReviveLimit()
	Fusion.AddProcedure(c,s.fusfilter,3,3,s.chk)

	-- Alternative Special Summon Condition (Contact Fusion style)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)

	-- Effect 1: If Special Summoned from Extra Deck: Add 1 "Cursed" Spell
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- Effect 2: When an Aqua monster is summoned, give it 1000 ATK
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)
	local e3c=e3:Clone()
	e3c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e3c)

	-- Effect 3: WATER Aqua monsters you control cannot be targeted or destroyed by card effects
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.prottg)
	e4:SetValue(aux.tgoval)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e5:SetValue(aux.indoval)
	c:RegisterEffect(e5)

	-- Effect 4: Gains 500 ATK for each "Slime" monster you control
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_UPDATE_ATTACK)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.atkval)
	c:RegisterEffect(e6)

	-- Effect 5: Opponent's monsters in the same column as a "Slime" monster cannot activate effects
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_CANNOT_TRIGGER)
	e7:SetRange(LOCATION_MZONE)
	e7:SetTargetRange(0,LOCATION_MZONE)
	e7:SetTarget(s.distg)
	c:RegisterEffect(e7)

	-- Effect 6: Pay LP in multiples of 100 + Banish 1 "Cursed" card: Special Summon "Slime" monsters from GY
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,2))
	e8:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e8:SetType(EFFECT_TYPE_IGNITION)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1) -- Once per turn
	e8:SetCost(s.spcost)
	e8:SetTarget(s.sptg)
	e8:SetOperation(s.spop)
	c:RegisterEffect(e8)
end

-- Fusion material helper checks
function s.fusfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_AQUA,fc,sumtype,tp) or (c:IsLevel(10) and c:IsAttribute(ATTRIBUTE_WATER,fc,sumtype,tp))
end
function s.chk(g,fc,sumtype,tp)
	if #g~=3 then return false end
	local c1=g:IsExists(Card.IsRace,2,nil,RACE_AQUA,fc,sumtype,tp)
	local c2=g:IsExists(function(c) return c:IsLevel(10) and c:IsAttribute(ATTRIBUTE_WATER,fc,sumtype,tp) end,1,nil)
	return c1 and c2
end

-- Alternative Contact-style Special Summon logic
function s.spcfilter(c,tp)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_AQUA) and c:IsAttack(3000) and c:IsCanBeTributed(tp)
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.spcfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.spcfilter,tp,LOCATION_MZONE,0,nil,tp)
	local rg=aux.SelectUnselectGroup(g,e,tp,1,1,nil,1,tp)
	if #rg>0 then
		rg:KeepAlive()
		e:SetLabelObject(rg)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=e:GetLabelObject()
	if not rg then return end
	Duel.Release(rg,REASON_COST)
	rg:Delete()
end

-- Effect 1 (Search "Cursed" Spell)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end
function s.thfilter(c)
	return c:IsSetCard(0x923) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Effect 2 (+1000 ATK on Aqua Summon)
function s.atkfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_AQUA)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.atkfilter,1,nil) end
	local g=eg:Filter(s.atkfilter,nil)
	Duel.SetTargetCard(g)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e):Filter(Card.IsFaceup,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- Effect 3 (Protection Target Conditions)
function s.prottg(e,c)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_AQUA)
end

-- Effect 4 (Gains 500 ATK per Slime)
function s.slimefilter(c)
	return c:IsFaceup() and c:IsSetCard(0x54b)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.slimefilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)*500
end

-- Effect 5 (Column Activating Disabler)
function s.distg(e,c)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(s.slimefilter,tp,LOCATION_MZONE,0,nil)
	local col=0
	for tc in aux.Next(g) do
		col=col|tc:GetColumnZone(LOCATION_MZONE)
	end
	return (c:GetColumnZone(LOCATION_MZONE)&col)~=0
end

-- Effect 6 (GY Special Summon multi-pay calculation logic)
function s.costfilter(c)
	return c:IsSetCard(0x923) and c:IsAbleToRemoveAsCost()
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x54b) and not c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_DEFENSE)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local lp=Duel.GetLP(tp)
	local max_paying=math.floor(lp/300)*300
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil)
		and max_paying>=300 and Duel.CheckLPCost(tp,300) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local cg=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(cg,POS_FACEUP,REASON_COST)
	
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	local max_count=math.min(ft,math.floor(max_paying/300))
	
	local options={}
	for i=1,max_count do
		table.insert(options,i*300)
	end
	local pay=Duel.AnnounceNumber(tp,table.unpack(options))
	Duel.PayLPCost(tp,pay)
	e:SetLabel(pay/300)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local count=e:GetLabel()
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
	local final_count=math.min(count,ft)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_GRAVE,0,1,final_count,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_DEFENSE)
	end
end