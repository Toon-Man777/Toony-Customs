local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon materials: 3 "Slime" Monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,3)
	
	-- 1. Alternative Contact Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.altcon)
	e1:SetTarget(s.alttg)
	e1:SetOperation(s.altop)
	c:RegisterEffect(e1)
	
	-- 2. On Special Summoned from Extra Deck: Search "Cursed Star Crimson Eclipse"
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
	
	-- 3. Quick Effect: When a "Slime" monster is summoned, buff it and give it temporary immunity
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.bufcon)
	e3:SetTarget(s.buftg)
	e3:SetOperation(s.bufop)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)
	local e3c=e3:Clone()
	e3c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e3c)
	
	-- 4. Continuous: Gain 500 ATK for each Slime monster you control
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
	
	-- 5. Column Floodgate: If you control 3 or more Slimes, lock opponent's same-column cards
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_ACTIVATE)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,1)
	e5:SetCondition(s.colcon)
	e5:SetValue(s.colval)
	c:RegisterEffect(e5)
	
	-- 6. Pay LP in multiples of 1000 & Banish Eclipse: Special Summon non-fusion Slimes from GY
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCost(s.spcost)
	e6:SetTarget(s.sptg)
	e6:SetOperation(s.spop)
	c:RegisterEffect(e6)
end

s.eclipse_name = "Cursed Star Crimson Eclipse"

-- Standard material check (Using official hexcode 0x54b)
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x54b)
end

-- Alternative Contact Summon Filters
function s.altcfilter1(c)
	return c:IsSetCard(0x54b) and c:IsAbleToGraveAsCost()
end
function s.altcfilter2(c)
	return c:IsFaceup() and c:IsLevel(10) and c:IsRace(RACE_AQUA) and c:IsAbleToGraveAsCost()
end
function s.altcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.altcfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.altcfilter2,tp,LOCATION_MZONE,0,nil)
	return (Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and #g1>=3) or (Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and #g2>=1)
end
function s.alttg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
	local g1=Duel.GetMatchingGroup(s.altcfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.altcfilter2,tp,LOCATION_MZONE,0,nil)
	
	local b1 = #g1>=3
	local b2 = #g2>=1
	
	local op=Duel.SelectEffect(tp,
		{b1, aux.Stringid(id,3)}, -- Tribute 3 Slimes
		{b2, aux.Stringid(id,4)}) -- Tribute 1 Lvl 10 Aqua
		
	local sg=Group.CreateGroup()
	if op==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		sg=g1:Select(tp,3,3,nil)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		sg=g2:Select(tp,1,1,nil)
	end
	
	if #sg>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.altop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST)
	c:SetMaterial(g)
	g:DeleteWithCell()
end

-- Effect 2: Search Logic
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end
function s.thfilter(c)
	return c:IsCleanName(s.eclipse_name) and c:IsAbleToHand()
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

-- Effect 3: Give Summoned Slime ATK & Immunity
function s.slime_filter(c)
	return c:IsFaceup() and c:IsSetCard(0x54b)
end
function s.bufcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.slime_filter,1,nil)
end
function s.buftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=eg:Filter(s.slime_filter,nil)
	Duel.SetTargetCard(g)
end
function s.bufop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	for tc in aux.Next(g) do
		if tc:IsFaceup() and tc:IsLocation(LOCATION_MZONE) then
			-- Gain 1000 ATK
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1000)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			
			-- Grant Immunity: Unaffected by opponent's card effects
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e2:SetRange(LOCATION_MZONE)
			e2:SetCode(EFFECT_IMMUNE_EFFECT)
			e2:SetValue(s.unaffected_filter)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
			
			-- Self Destruct during the End Phase
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e3:SetCode(EVENT_PHASE+PHASE_END)
			e3:SetCountLimit(1)
			e3:SetRange(LOCATION_MZONE)
			e3:SetOperation(s.desop)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
end
function s.unaffected_filter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end

-- Effect 4: Static Slime Tracker
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.slime_filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)*500
end

-- Effect 5: Column Floodgate Logic
function s.colcon(e)
	return Duel.GetMatchingGroupCount(s.slime_filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)>=3
end
function s.colval(e,re,rp)
	local tp=e:GetHandlerPlayer()
	local rc=re:GetHandler()
	if not rc:IsOnField() then return false end
	local zone=0
	local g=Duel.GetMatchingGroup(s.slime_filter,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		zone=zone|tc:GetColumnZone(LOCATION_ONFIELD)
	end
	return rc:IsColumnZone(zone,tp)
end

-- Effect 6: Pay LP in Multiples of 1000 Engine
function s.costcfilter(c)
	return c:IsCleanName(s.eclipse_name) and c:IsAbleToBanishAsCost()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x54b) and not c:IsType(TYPE_FUSION) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_ATTACK)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local max_mzone = Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.costcfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
			and Duel.CheckLPCost(tp,1000) and max_mzone >= 2
	end
	
	local max_lp = Duel.GetLP(tp)
	local max_possible_multiples = math.floor(max_lp / 1000)
	local max_spawn_limit = math.floor(max_mzone / 2)
	
	local limit = math.min(max_possible_multiples, max_spawn_limit)
	
	local t = {}
	for i=1,limit do
		table.insert(t, i*1000)
	end
	
	local payment = Duel.AnnounceNumber(tp,table.unpack(t))
	Duel.PayLPCost(tp,payment)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costcfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	
	e:SetLabel(math.floor(payment/500))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local count = e:GetLabel()
	local mzone_count = Duel.GetLocationCount(tp,LOCATION_MZONE)
	if count <= 0 or mzone_count <= 0 then return end
	
	local max_to_summon = math.min(count, mzone_count)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,max_to_summon,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
end