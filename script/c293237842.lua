local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	-- Restriction: Once per turn this way
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	
	-- Effect 2: Entire requirement for "Chaos" Ritual
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_RITUAL_LEVEL)
	e2:SetValue(s.rlevel)
	c:RegisterEffect(e2)
	
	-- Effect 3: Search based on Type (Dragon/Spellcaster)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

-- Archetype: Chaos (0xcf)
s.listed_series={0xcf}

-- SS Condition: Control LIGHT Dragon or DARK Spellcaster
function s.spfilter(c)
	return c:IsFaceup() and ((c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_DRAGON)) 
		or (c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_SPELLCASTER)))
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Ritual logic: Entire level substitute
function s.rlevel(e,c)
	local lv=e:GetHandler():GetLevel()
	if c:IsSetCard(0xcf) then
		local clv=c:GetLevel()
		return (clv<<16)+lv
	else return lv end
end

-- Search logic: Cost is discarding 1 Spell
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) 
		and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND,0,1,nil,TYPE_SPELL) end
	Duel.DiscardHand(tp,Card.IsType,1,1,REASON_COST+REASON_DISCARD,nil,TYPE_SPELL)
end

-- Target/Operation logic for Type-based search
function s.cfilter1(c) return c:IsFaceup() and c:IsRace(RACE_DRAGON) end
function s.cfilter2(c) return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER) end

-- Dragon path filters
function s.thfilter1a(c) return c:IsRitualMonster() and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_DRAGON) and c:IsAbleToHand() end
function s.thfilter1b(c) return c:IsRitualSpell() and c:IsSetCard(0xcf) and c:IsAbleToHand() end

-- Spellcaster path filters
function s.thfilter2a(c) return c:IsRitualMonster() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_SPELLCASTER) and c:IsAbleToHand() end
function s.thfilter2b(c) return c:IsRitualSpell() and c:IsSetCard(0xcf) and c:IsAbleToHand() end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.cfilter1,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter1a,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter1b,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter2a,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter2b,tp,LOCATION_DECK,0,1,nil)
	if chk==0 then return b1 or b2 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.IsExistingMatchingCard(s.cfilter1,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter1a,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter1b,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter2a,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter2b,tp,LOCATION_DECK,0,1,nil)
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3)) -- Choice if you control both Types
	elseif b1 then op=0
	elseif b2 then op=1
	else return end
	
	local f1,f2
	if op==0 then f1,f2=s.thfilter1a,s.thfilter1b else f1,f2=s.thfilter2a,s.thfilter2b end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,f1,tp,LOCATION_DECK,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g2=Duel.SelectMatchingCard(tp,f2,tp,LOCATION_DECK,0,1,1,nil)
	g1:Merge(g2)
	if #g1==2 then
		Duel.SendtoHand(g1,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g1)
	end
end