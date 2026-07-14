local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon Procedure: 2 Aqua monsters + 1 Level 10 WATER monster
	c:EnableReviveLimit()
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetCondition(s.fuscon)
	e0:SetOperation(s.fusop)
	c:RegisterEffect(e0)

	-- Alternative Special Summon Condition (Contact Fusion style by Tributing)
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

	-- Effect 4: Opponent's monsters in the same column as an Aqua monster cannot activate effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CANNOT_TRIGGER)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(0,LOCATION_MZONE)
	e6:SetTarget(s.distg)
	c:RegisterEffect(e6)

	-- Effect 5: Once per turn: Banish 1 "Cursed" card, then Special Summon 1 Aqua monster from GY
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1)
	e7:SetCost(s.spcost)
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)
end

-- Custom Fusion material checking logic to completely prevent nil field errors
function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_AQUA,fc,sumtype,tp) or (c:IsLevel(10) and c:IsAttribute(ATTRIBUTE_WATER,fc,sumtype,tp))
end
function s.fuscon(e,g,gc,chkf)
	if g==nil then return true end
	local fc=e:GetHandler()
	local tp=fc:GetControler()
	local mg=g:Filter(s.matfilter,nil,fc,SUMMON_TYPE_FUSION,tp)
	if gc then
		if not s.matfilter(gc,fc,SUMMON_TYPE_FUSION,tp) then return false end
		return mg:IsExists(s.chk,1,gc,mg,gc)
	end
	return mg:IsExists(s.chk,1,nil,mg,nil)
end
function s.chk(c,mg,gc)
	local g=Group.FromCards(c)
	if gc then g:AddCard(gc) end
	if #g==1 then return mg:IsExists(s.chk,1,c,mg,c) end
	if #g==2 then return mg:IsExists(s.chk,1,g,mg,g) end
	local aqua_count=g:FilterCount(Card.IsRace,nil,RACE_AQUA)
	local lv10_count=g:FilterCount(function(tc) return tc:IsLevel(10) and tc:IsAttribute(ATTRIBUTE_WATER) end,nil)
	return aqua_count>=2 and lv10_count>=1
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
	local fc=e:GetHandler()
	local mg=eg:Filter(s.matfilter,nil,fc,SUMMON_TYPE_FUSION,tp)
	local g=Group.CreateGroup()
	if gc then g:AddCard(gc) end
	while #g<3 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local sg=mg:FilterSelect(tp,s.chk,1,1,g,mg,g)
		g:Merge(sg)
	end
	Duel.SetFusionMaterial(g)
end

-- Contact Fusion alternative summon logic (Tribute 1 Aqua Fusion with 3000 ATK)
function s.spcfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsRace(RACE_AQUA) and c:IsAttack(3000) and c:IsCanBeTributed(tp)
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.spcfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local g=Duel.GetMatchingGroup(s.spcfilter,tp,LOCATION_MZONE,0,nil,tp)
	if chk==0 then return #g>0 and ft>-1 end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=Duel.SelectMatchingCard(tp,s.spcfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
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

-- Effect 1 (Search 1 "Cursed" Spell)
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

-- Effect 2 (+1000 ATK on any Aqua monster Summoned)
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

-- Effect 3 Target Filters (Protects WATER Aqua monsters)
function s.prottg(e,c)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_AQUA)
end

-- Effect 4 (Disables zones in the same column as an Aqua monster)
function s.distg(e,c)
	local tp=e:GetHandlerPlayer() or e:GetOwnerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsRace,tp,LOCATION_MZONE,LOCATION_MZONE,nil,RACE_AQUA)
	local col=0
	for tc in aux.Next(g) do
		col=col|tc:GetColumnZone(LOCATION_MZONE)
	end
	return (c:GetColumnZone(LOCATION_MZONE)&col)~=0
end

-- Effect 5 (Banish 1 "Cursed" card -> Special Summon 1 Aqua monster from GY)
function s.costfilter(c)
	return c:IsSetCard(0x923) and c:IsAbleToRemoveAsCost()
end
function s.spfilter2(c,e,tp)
	return c:IsRace(RACE_AQUA) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end