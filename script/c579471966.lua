local s,id=GetID()
function s.initial_effect(c)
	-- Activate Card
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- EFFECT 1: Discard 1, destroy 1 Fairy monster in hand/field, then draw 1
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_HANDES+CATEGORY_DESTROY+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id) -- Hard once per turn on Effect 1
	e2:SetCondition(s.drcon)
	e2:SetCost(s.drcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)

	-- EFFECT 2: If a "Mokey Mokey" monster is Normal or Special Summoned: Opponent's non-Fairy monsters lose ATK
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+100) -- Hard once per turn on Effect 2
	e3:SetCondition(s.atkcon)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- EFFECT 3: If this card is destroyed or vanished: Special Summon 1 "Mokey Mokey" Fusion from Extra Deck (treated as Fusion Summon)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetCountLimit(1,id+200) -- Hard once per turn on Effect 3
	e5:SetTarget(s.spftg)
	e5:SetOperation(s.spfop)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e6)
end

s.listed_names={27288416} -- "Mokey Mokey"
s.listed_series={0x184}   -- Mokey Mokey archetype

-- EFFECT 1 SUBROUTINES
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() -- Only during your Main Phase
end
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD) -- Discard 1 card
end
function s.desfilter(c)
	return c:IsRace(RACE_FAIRY) and (c:IsFaceup() or c:IsLocation(LOCATION_HAND)) -- 1 Fairy monster in hand or face-up field
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)~=0 then -- Destroy it, and if you do
		Duel.Draw(tp,1,REASON_EFFECT) -- Draw 1 card
	end
end

-- EFFECT 2 SUBROUTINES
function s.cfilter(c)
	return (c:IsCode(27288416) or c:IsSetCard(0x184)) and c:IsMonster() -- A "Mokey Mokey" monster(s)
end
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil) -- Normal or Special Summoned
end
function s.atkfilter(c)
	return c:IsFaceup() and not c:IsRace(RACE_FAIRY) -- All non-Fairy monsters your opponent controls
end
function s.fairyfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_FAIRY) -- Fairy monsters you currently control
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkfilter,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingMatchingCard(s.fairyfilter,tp,LOCATION_MZONE,0,1,nil) end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local tg=Duel.GetMatchingGroup(s.atkfilter,tp,0,LOCATION_MZONE,nil)
	local fg=Duel.GetMatchingGroup(s.fairyfilter,tp,LOCATION_MZONE,0,nil)
	if #tg==0 or #fg==0 then return end
	
	-- Calculate total original ATK of all Fairy monsters currently controlled
	local val=0
	for fc in aux.Next(fg) do
		val=val+fc:GetBaseAttack()
	end
	if val==0 then return end

	-- Apply stat deduction
	for tc in aux.Next(tg) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-val)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- EFFECT 3 SUBROUTINES
function s.spffilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x184) -- "Mokey Mokey" Fusion Monster
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.spftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spfop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spffilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)~=0 then -- Treated as a Fusion Summon
		tc:CompleteProcedure()
		
		-- Also, its ATK becomes 3000
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(3000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end